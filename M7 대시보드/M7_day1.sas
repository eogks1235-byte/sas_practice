/* sgplot 
비교-막대, 추세-선, 구성-누적 파이 
관계-산점도 버블, 분포-히스토그램 */


libname shop_db '/home/student/shop_db';
%let csvdir=/home/student/shop_csv;

/* csv to sas macro*/
%macro imp(name=);
	proc import datafile="&csvdir/&name..csv"
	out=shop_db.&name
	dbms=csv replace;
	getnames=yes;
	guessingrows=max;
run;
%put note:=====&name..csv -> shop_db.&name 변환완료=====;
%mend;

%imp(name=users);
%imp(name=orders);
%imp(name=order_items);
%imp(name=products);
%imp(name=sales_data);
%imp(name=categories);


/*==========================================*/

%let ROOT =/home/student;
libname shop_db '/home/student/shop_db';

/* 월별 집계 데이터 생성*/
proc sql;
	create table shop_db.monthly as	
	select intnx('month',order_date,0,'b') format=yymmd7. as year_month,
			sum(total_amount) as total_revenue format=comma15.,
			count(*) as n_orders,
			sum(case when status='paid' then 1 else 0 end ) as n_paid
from shop_db.orders
group by 1
order by 1;
quit;


/* session 1 : SGPLOT 그래프 그리기 */
title 'Before  - 데이터 잉크비율 0.2'
ods html style=analysis;
proc sgplot data=shop_db.monthly;
	vbar3d year_month / response=total_revenue
	varwidth=0.9 transparency=0.3;
	XAXIS grid;
	YAXIS grid;
run;
title;

title 'After - 데이터 잉크비율 -0.85';
ods html style =Journal;
proc sgplot data=shop_db.monthly noautolegend;
	vbar year_month / response=total_revenue
fillattrs=(color=cx2E75B6) /*강조색 1개 */
datalabel
datalabelattrs=(size=9);
xaxis display =(noline noticks);
yaxis display =(noline noticks nolabel) grid;
run;
title;




/* session 2 : 채널별 매출현황 >> 막대 그래프로 표현 */
/* 채널별 매출 데이터셋 작성 */
proc sql;
	create table work.channel_sales as 
	select u.channel, 
		sum(o.total_amount) as total_revenue
from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id
where o.status='paid'
group by 1;
quit;

title '채널별 매출 총합';
ods html style=jorunal;
proc sgplot data=channel_sales noautolegend;
	vbar channel / response=total_revenue
	categoryorder=respdesc
	fillattrs=(color=cx2e75b6)
	datalabel/*막대바 위에 숫자 */
	datalabelattrs=(size=9);
	xaxis display =(noline noticks nolabel);
	yaxis min=0 display =(noline noticks nolabel) grid;
/* min=0시각적 착시와 데이터 왜곡을 방지하여 
정확한 정보(비율)를 전달하기 위함*/
run;
title;


proc sort data=channel_sales out=temp_sorted;
	by descending total_revenue;
run;

data _null_;
set temp_sorted(obs=1);
call symputx('max_channel',channel);
run;

data channel_sales_prep;
	set work.channel_sales;
	if channel ="&max_channel" then highlight_group ="Highlight";
	else highlight_group ="normal";
run;

ods html style=jorunal;
	proc sgplot data=channel_sales_prep noautolegend;
	/* 강조색 과 일반색 팔레트지정*/
	styleattrs datacolor=(cx2E75B6 cxD9D9D9);

vbar channel/
	response=total_revenue
	group=highlight_group
	grouporder=date
	categoryorder=respdesc
	datalabel
	datalabelattrs=(size=9);

yaxis min=0 display=(noline noticks nolabel) grid;
xaxis display=(noline niticks nolabel);
run;


/* session 3 : 목적별 그래프 선택 */
/* 1. 비교 - 막대 그래프 : VBAR, HBAR */
title '채널별 매출 현황 비교 - 막대 그래프 이용 ';
proc sgplot data=channel_sales noautolegend;
	vbar channel/ response =total_revenue
	categoryorder=respasc
	datalabel;
run;
title;


/* 월별 매출 현황 - 막대 그래프 */
proc sgplot data= shop_db.monthly noautolegend;
	hbar year_month /response= total_revenue
	categoryorder=respasc
	datalabel;
run;


/* session 3 : 목적별 그래프 선택 */
/* 1. 비교 - 막대 그래프 : VBAR, HBAR */
title '채널별 매출 현황 비교 - 막대 그래프 이용 ';
proc sgplot data=channel_sales noautolegend;
	vbar channel/ response =total_revenue
	categoryorder=respasc
	datalabel;
run;
title;


/* 월별 매출 현황 - 막대 그래프 */
proc sgplot data= shop_db.monthly noautolegend;
	hbar year_month /response= total_revenue
	categoryorder=respasc
	datalabel;
run;

/* 2. 추세 그래프 - series */
/* 월별 매출 추세 */
title '월별 매출 추이';
proc sgplot data=shop_db.monthly;
	series x=year_month y=total_revenue / markers
	lineattrs=(thickness=2 color=IndianRed);
xaxis display=(noline) label='월';
yaxis min=0 display=(noline) label='매출';
run;
title;


proc print data=shop_db.monthly (obs=10);
run;


/* 3. 비율: 파이 그래프  */
/* 결제 수단별 결제 비율 구하기 */
proc sql;
	create table pay as 
	select payment_method, count(*) as n
	from shop_db.orders
	where status='paid'
	group by payment_method
;run;

proc contents data=pay; run;
proc print data=pay(obs=10); run;
title '결제 수단별 결제 비율';
proc gchart data=pay;
	pie payment_method / sumvar=n percent=arrow value= none slice=arrow;
run;
title;
proc gchart data=pay;
	pie payment_method / sumvar=n percent=arrow value= arrow slice=arrow;
run;


/* session 4 : 주문수와 매출의 관계 산점도(관계) */
/* 1. 관계 - 산점도 그래프 */
title '주문수와 매출의 관계';

proc sgplot data=shop_db.users;
	scatter x=order_count y=total_spent /
markerattrs= (color=red symbol=circlefilled size=4)
transparency=0.5
;
reg x=order_count y=total_spent / 
nomarkers
	lineattrs=(color=blue thickness=2);

xaxis label='주문수' display=(noline);
yaxis label='총매출' display=(noline);

run;title;


/* session 5 : 매출의 관계 히스토그램(분포) */
/* 1. 분포 - 히스토그램 */
title '분포-histogram';
proc sgplot data=shop_db.users;
	histogram total_spent/binwidth=1000000
	fillattrs=(color=DodgerBlue) transparency=0.3;
	density total_spent / type=kernel
	lineattrs=(color=IndianRed thickness=2);
xaxis label='총 매출' display=(noline);
yaxis label='빈도' display=(noline);
run;
title;

proc sgplot data=shop_db.users;
	histogram age/binwidth=10
	fillattrs=(color=DodgerBlue) transparency=0.3;
	density age / type=kernel
	lineattrs=(color=IndianRed thickness=2);
xaxis label='나이' display=(noline);
yaxis label='빈도' display=(noline);
run;




/* session 6 : 실습 */
/* 1. 채널별 매출순위 막대 */

proc sql;
	create table channel_sale as 
	select u.channel , sum(o.total_amount) as osale format=comma15.
from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id
where status='paid'
group by 1;
run;
proc sgplot data=channel_sale noautolegend;
	vbar channel / response= osale categoryorder=respdesc
	fillattrs=(color=IndianRed) datalabel;
run;

/* 2. 일별 주문 횟수 */
proc sql;
    create table day_order_count as
    select intnx('day', order_date, 0, 'b') as day_count format=yymmdd10., /* 포맷 변경 */
           count(*) as n_orders
    from shop_db.orders
    where status='paid'
    group by 1
    order by 1;
quit; 

proc sgplot data=day_order_count noautolegend; 
    series x=day_count y=n_orders / markers 
           lineattrs=(color=IndianRed) datalabel;
run;


/* 결제 방법 비중*/
proc sgplot data= work.pay noautolegend;
	vbar payment_method /response=n categoryorder=respdesc
 datalabel;
yaxis min=0;
run;


/*vip_grade vs 매출상관*/
proc sql;
create table vip_revenue as 
select vip_grade, sum(total_spent) format=comma15. as total_revenue
from shop_db.users
group by vip_grade
;quit;

proc sgplot data=vip_revenue;
	scatter x=vip_grade y=total_revenue /
	markerattrs=(size=5) transparency=0.5;
	xaxis label='고객등급' display=(noline);
	yaxis label='총매출' display=(noline)max=40000000000 ;
run;

/*주문금액이상치*/
proc sgplot data= shop_db.orders;
	vbox total_amount / category=payment_method;
yaxis min=0; run;




