libname shop '/home/student/shop_db';

/*session 1 - data step merge*/
proc sort data=shop.users out=work.us; by user_id; run;
proc sort data=shop.orders out=work.od; by user_id; run;


DATA work.merge1n;
   MERGE work.us (KEEP=user_id name vip_grade)
         work.od (KEEP=user_id order_id total_amount);
   BY user_id;
RUN;

TITLE "[S1] 1:N MERGE 결과";
PROC PRINT DATA = work.merge1n (OBS=10); RUN;
TITLE;

data work.uo;
	merge work.us work.od;
	by user_id;
	if status='paid';
run;

data work.season;
	merge us(keep=user_id vip_grade)
		od(keep=user_id total_amount
order_date status
	where=(status='paid'));
	by user_id;

월=month(order_date);
run;
proc print data= work.uo(obs=10); title'[실습1]';run;
title;


proc means data=season n mean sum;
	var total_amount;
	class vip_grade 월;
	types 월 /*월과 등급의 교차 집계*/;
	title '월별/ vip 등급별 매출 통계 요약';
run;

proc tabulate data=work.season;
	class 월 vip_grade;
	var total_amount;
	table 월 all='합계' , vip_grade*total_amount=''*(n='주문건수'*format=comma8. sum='매출합계'*format=comma10.);
	title '월별 등급별 매출현황';
run;

data work.inner;
	merge work.us(in=ua) work.od(in=ob);
	by user_id;
if ua and ob; /*inner 조인효과*/
run;

data work.dormant;
	merge us (in=ua)
			od(in=ob);
by user_id;
	if ua and not ob;
	휴면일수 =today() -signup_date;
	if 휴면일수>720 then 쿠폰='30%';
	else if 휴면일수>365 then 쿠폰='20%';
	else 					쿠폰='10%';
	format signup_date yymmdd10.;
run;

proc print data=work.inner;
title'[s2]inner join 효과';
	
;run;		


proc print data=work.dormant(obs=10);
title'[s2]inner join 효과';
	var user_id name 휴면일수 signup_date 쿠폰
;run;

PROC IMPORT DATAFILE="/home/student/shop_csv/products.csv"
	OUT = shop.products 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/* 월별 판매된 제품의 매출 총액을 구하세요
	order_items, products */
proc sort data=shop.orders out=work.or; by order_id; run;
/* proc sort data=shop.order_items out=work.oii; by order_id ; run; */
proc sort data=shop.order_items out=work.oi; by order_id product_id; run;
proc sort data=shop.products out=work.pd; by product_id; run;

/*나*/
DATA work.mergeord;
   MERGE work.or (keep=order_id order_date)
			work.oi (KEEP=order_id product_id);
/*          work.pd (KEEP=product_id product_name); */
   BY order_id ;
RUN;

data order_detail;
	merge or(keep=order_id order_date in=a)
		oi(keep=order_id product_id line_total in=b);
	by order_id;
	if a and b;
run;

proc sort data=order_detail; by product_id; run;

data report;
	merge order_detail (in=a)
	shop.products (in=b);
	by product_id;
	if a;
	월=month(order_date);
run;

proc print data=report (obs=10);run;

proc print data= report(obs=10);
	var order_id order_date product_id product_name line_total 월;
	title '주문 병합 데이터 상위 10건 샘플';
run;

proc means data=report sum mean n maxdec=0 ;
	var line_total;
	class 월 product_name;
	types 월* product_name ;

label line_total='매출액'
	월='주문월'
	product_name='상품명';
title '월별 /상품별 매출 요약 통계(proc means);'
;run;
/*나*/
DATA work.mergeordd;
   MERGE work.or (keep=order_id order_date)
			work.oii (KEEP=order_id product_id unit_price);
/*          work.pd (KEEP=product_id product_name); */
   BY order_id;
RUN;
/* 주문명없는 상품명 도출*/
proc sort data=shop.order_items out=oi ; by product_id; run;
data no_order_product;
	merge oi(in=a)
	pd(in=b);
by product_id;

if b and not a;
run;

proc print data=no_order_product; run;

/* session 3 LTV*/
proc sort data =shop.orders out = work.osort; by user_id order_date;
run;

data work.first_last;
	set work.osort;
	by user_id;
	retain 첫주문;
	if first.user_id then do;
	누적매출 =0; 주문수=0; 첫주문=order_date;

end;
주문수+1;
누적매출 + total_amount;
	if last.user_id;
	마지막주문=order_date;
	format 누적매출 comma16. 첫주문 yymmdd10. 마지막주문 yymmdd10.;
	keep user_id order_id 주문수 첫주문 마지막주문 누적매출 order_date;
run;

/*월별로 처음 주문한 상품의 주문일자, 상품명, 브랜드명을 검색*/
proc sort data=shop.order_items out=work.sorted_order_items; by order_id product_id; run;
proc sort data=shop.products out=work.sorted_products; by product_id; run;



/* 1. 먼저 report 데이터셋에 '연도' 변수를 추가하고 정렬 */
data report_with_year;
	set report;
	연도 = year(order_date);
run;

proc sort data=report_with_year out=report_sorted;
	by 연도 월 order_date; /* by 문은 하나로 합쳐서 작성 */
run;

/* 2. 연도별/월별 최초 주문 건 추출 */
data first_orders;
	set report_sorted;
	by 연도 월 order_date;
	
	/* 연도 내에서 월이 시작하는 첫번째 행 추출 */
	if first.월; 
	
	keep 연도 월 order_date product_id product_name brand line_total; 
run;

/* 3. 결과 출력 */
proc report data=first_orders nowd
	style(header)={asis=on}; /* 줄바꿈 방지 */
	
	title '연도별/월별 최초 주문 상품 및 브랜드 정보';
	column order_date product_id line_total product_name brand 월 연도;
	
	define order_date   / display '주문일자' style(column)={cellwidth=100pt};
	define product_id   / display '상품ID'   style(column)={cellwidth=70pt};
	define line_total   / display '주문금액' style(column)={cellwidth=90pt};
	define product_name / display '상품명'   style(column)={cellwidth=150pt};
	define brand        / display '브랜드명' style(column)={cellwidth=100pt};
	define 월           / display '주문월'   style(column)={cellwidth=60pt};
	define 연도         / display '주문연도' style(column)={cellwidth=60pt};
run;
title;

proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent;
	output out=work.kpi
	n=고객수 mean=평균매출 std=표준편차 sum=총매출;
run;

proc print data=work.kpi noobs;
format 평균매출 표준편차 총매출 comma15.2;
run;

proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent;
	output out=work.kpi n=고객수 sum=총매출;
run;

proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent;
n(total_spent)=고객수
mean(total_spent)=평균매출
median(total_spent)=중위매출
sum(total_spent)=총매출
mean(age)=평균나이;
run;

proc print data=work.kpi noobs;
	format 평균매출 표준편차 총매출 comma15.;

/*실습 4 최종 보고서는 pdf :M4_day4.pdf*/

ods pdf file='/home/student/M4_day4..pdf' ;
proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent age;
	output out=work.kpi(drop=_type_ _freq)
	n(total_spent) =고객수 mean(total_spent)=평균매출
	median(total_spent)=중위매출 mean(age)=평균나이;
run;
ods pdf close;

/* 열려 있는 ODS 강제 닫기 */
ods pdf close;

/* 1. PDF 출력 시작 */
ods pdf file='/home/student/M4_day4.pdf';

/* 2. 요약 데이터셋 생성 */
proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent age;
	output out=work.kpi(drop=_type_ _freq_) 
		n(total_spent) = 고객수 
		mean(total_spent) = 평균매출
		median(total_spent) = 중위매출 
		mean(age) = 평균나이;
run;


proc print data=work.kpi noobs;
	title 'VIP 등급 및 채널별 고객 요약 통계';
run;


ods pdf close;

proc sql outobs=10;

select u.name, p.product_name, oi.line_total
from shop.users as u inner join shop.orders as o 
on u.user_id = o.user_id
				inner join shop.order_items as oi
on o.order_id=oi.order_id
				inner join shop.products as p
on oi.product_id =p.product_id

where o.status='paid'
and o.order_date>'01JAN2026'd
;quit;

proc sql outobs=10;
	create table user_product as 
select u.name, p.brand, sum(oi.line_total)
from shop.users as u inner join shop.orders as o 
on u.user_id = o.user_id
				inner join shop.order_items as oi
on o.order_id=oi.order_id
				inner join shop.products as p
on oi.product_id =p.product_id

where o.status='paid'
and o.order_date>'01JAN2026'd
group by u.name, p.brand
;quit;

proc print data=user_product ;
run;


/*session 6*/
data work.items_lookup;
if 0 then set shop.products(keep=product_id product_name brand price);
if _n_= 1 then do;
	declare hash h(dataset:'shop.products');
	h.definekey('product_id');
	h.definedata('product_name','brand','price');
	h.definedone();
	call missing(product_name, brand, price);

	end;
set shop.order_items;
rc=h.find();
if rc=0;
drop rc;

run;

title '[실습6] hash looup - order_items + products';
proc print data = work.items_lookup (obs=10); run;
title;

/* users를 lookup으로, orders 검색, 고객명, 고객등급 >> orders_grade*/

data orders_grade;
	if 0 then set shop.users;
	if _n_=1 then do;
	declare hash hu(dataset:'shop.users');
hu.definekey('user_id');
hu.definedata('name','vip_grade');
hu.definedone();
call missing(name,vip_grade);
	end;
/*대용량 데이터 정의*/
set shop.orders;
/*데이터 복사*/
if (hu.find())=0;
run;

PROC PRINT DATA=orders_grade (obs=20);run;

/* 실습 1 */
proc sort data = shop.users out=work.s_us; by user_id; run;
proc sort data = shop.orders out=work.s_od; by user_id; run;

data work.r1_season;
	/* s_od를 불러올 때 미리 status='paid' 건만 필터링 */
	merge work.s_us (keep=user_id vip_grade in=in_us)
	      work.s_od (keep=user_id total_amount order_date status 
	                 where=(status='paid') in=in_od);
	by user_id;

	/* 유저 정보와 결제완료 주문 정보가 모두 존재하는 건만 추출 */
	if in_us and in_od;

	월 = month(order_date);
run;

data work.r2_dormant;
	merge work.s_us(in=in_us) work.s_od(in=in_od);
	by user_id;
	if in_us and not in_od;
	휴면일수 =today()-signup_date;
	if 휴면일수 >720 then 쿠폰='30%';
	else if 휴면일수 >365 then 쿠폰='20%';
	else 				 쿠폰 ='10%';
run;

proc sort data=shop.orders out = work.s_od2;
	by user_id order_date;
	run;

data work.r2_ltv;
	set work.s_od2;
	by user_id;
	if first.user_id then do;
		누적매출=0; 주문수=0; 첫주문=order_date;
end;
	주문수+1;
	누적매출 + total_amount;
if last.user_id;
	마지막주문 =order_date;
run;

proc summary data=shop.users nway;
	class vip_grade channel;
	var total_spent age;
	output out=work.r4_kpi(drop=_type_ _freq_)
	n(total_spent)=고객수
	mean(total_spent)=평균매출
	median(total_spent)=중위매출
	mean(age)=평균나이;
run;

data work.r5_shortage;
if 0 then set shop.products(keep=product_id product_name stock);
	if _n_ =1 then do;
	declare hash p(dataset:'shop.products');
	p.definekey('product_id');
	p.definedata('product_name','stock');
	p.definedone();
	call missing(product_name, stock);
	end;
set shop.order_items;
rc=p.find();
if rc=0 and stock < quantity;
부족수량 =quantity-stock;
drop rc;
run;
