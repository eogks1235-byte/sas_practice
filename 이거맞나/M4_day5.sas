/* 1. 시스템 ID를 userid 변수에 저장 */
%let userid = &sysuserid;
%put &userid;
/* 2. 경로(root)와 DB 이름을 선언 (여기서는 따옴표를 뺍니다) */
%let root = /home/&userid;
%let db = shop_db;
%put &root;
/* 3. 디버깅 출력 (로그 창 확인) */
%put &userid &root &db &root/&db;

/* 4. 라이브러리 할당 (전체 경로를 큰따옴표로 감쌉니다) */
libname shop "&root/&db";

/*[목표] %let 으로 yyyymm +cutoff 정의 후 title/where/file 에 적용
	[산출물] 월별 매출 top n 보고서 (자동파일명)*/
%let yyyymm =202605;
%let cutoff =100000;
%let report_dir= &root/sas_practice/report;

ods pdf file="&report_dir/&yyyymm._매출.pdf";
title"&yyyymm 월간 매출 (cutoff=&cutoff)";
data month;
	set shop.orders;
	where put(order_date, yymmn6.) ="&yyyymm"
	and total_amount >=&cutoff;
run;
proc print data=month(obs=10) noobs; run;
title;
ods pdf close;
/*매크로 사용할때는 쌍따옴표사용하기 */

/*---s1.3 시스템 매크로 변수 -&sysdate  &systime ---*/
%put sysdate  = &sysdate (오늘날짜);
%put systime  = &systime (현재시간);
%put sysday  = &sysday (요일);
%put sysuserid  = &sysuserid (본인id);

title "[s1.3] 시스템 매크로 변수--&sysdate &sysday 보고서";
proc print data=shop.users (obs=5) noobs;
	var user_id name age channel;
run;
	title;

/*macro*/

%let target = paid;
%let min_ant =50000;
%let top_n =10;

%put target= &target;
%put min_ant = &min_ant;
%put top_n= &top_n;

title"[s1.2] let 사용 -- &target 주문 &min_ant + top_n";
proc sql outobs=&top_n;
	select order_id, user_id, total_amount, channel
from shop.orders
	where status="&target"
and total_amount >=&min_ant
	order by total_amount desc;
quit;
title;

/* session 2: %macro ~ %mend; */
%macro vip_report(grade=);
proc print data= shop.users(obs=10);
where vip_grade = "&grade"; var user_id name total_spent vip_grade;
run;
%mend;
%vip_report(grade=gold);
%vip_report(grade=silver);

/*1. channel별 kpi >> 주문건수, 주문총금액 >>
 정상거래만, channel을 값을 받아서 실행*/
%macro ch_kpi(ch=);
	title "&ch 채널 KPI";
	proc sql;
	select "&ch" as channel length=15,
	count(*) as 주문건수,
	sum(total_amount) as 주문총금액 format comma15.
	from shop.orders
	where status='paid'
	and channel="&ch";
quit;
title;
%mend;

/* 호출 >> channel : organic, email */
%ch_kpi(ch=organic);
%ch_kpi(ch=email);

/*다중 매개변수 + 기본값*/
/*채널, 나이 하안, 상한, top=디폴트값*/
%macro ch_age_kpi(ch=organic, lo=20,hi=60,top=10);
	title "&ch (&lo~&hi 세 ) top &top";
	proc sql outobs=&top;
select u.user_id, u.name, u.age, o.total_amount
	from shop.users u inner join shop.orders o 
on u.user_id =o.user_id
	where u.age between &lo and &hi 
and o.channel="&ch"
and o.status='paid'
	order by o.total_amount desc;
quit;
title;
%mend;

options mprint mlogic symbolgen; /*디버깅시작*/
%ch_age_kpi(); /*기본값*/
%ch_age_kpi(ch=social);
%ch_age_kpi(ch=social, lo=30, hi=70, top=20);


options nomprint nomlogic nosymbolgen; /*디버깅종료*/

/* vip 등급별 매크로 - kpi집계 >> vip_kpi(grade=)
	grade, 건수, 평균주문액(total_spent), 평균주문건수(order_count)
						format 8.1
보고서 title >> gold 등급 통계 */
%macro vip_kpi(grade=);
title"&grade 등급 통계";
proc sql outobs=10;
	select vip_grade length 10 , count(*), 
avg(total_spent) as 평균주문액 format comma15.,
avg(order_count) as 평균주문건수 format 8.1
from shop.users
where vip_grade="&grade"/* 매크로 조건을 맞추기위해서*/
	group by vip_grade;
quit;

%mend;

%vip_kpi(grade=gold);
%vip_kpi(grade=vip);

/* session 3 : %DO %IF */
%macro  yearly_pdf(year=);
	%do m=1 %to 12;
		%let m2=%sysfunc(
			putn(&m, z2.));
		%let ym =&year.&m2;
		ods pdf file ="&report_dir/&ym._매출.pdf";
		proc print data=shop.orders;
			where put(order_date,yymmn6.)
		="&ym";
run;
ods pdf close;
%end;
%mend;
%yearly_pdf(year=2024);

/* %DO ~ %END*/

%let channel = organic paid_search social referral email other;

%macro ch_kpi(ch=);
	title "&ch 채널 KPI";
	proc sql;
	select "&ch" as channel length=15,
	count(*) as 주문건수,
	sum(total_amount) as 주문총금액 format comma15.
	from shop.orders
	where status='paid'
	and channel="&ch";
quit;
title;
%mend;

/* users에서 검색해서 channels를 생성*/
proc sql;
	select distinct channel into :channels separated by " "
	from shop.users;
quit;
%put channels : &channels;
%macro  loop_channels;
	%do i=1 %to 6;
		%let ch=%scan (&channel, &i);
		%put [&i] &ch;
		%ch_kpi(ch=&ch);
	%end;
	%mend loop_channels;
%loop_channels;

%macro smart_kpi(ch=);
	%if &ch =paid_search or &ch=email %then %do;
	title"[광고] &ch -ROI 분석";
	proc sql;
	select sum(total_amount) as sales format=comma15.
	from shop.orders
	where channel="&ch" and status='paid';
quit;
title;
	%end;
	%else %do;
title "[자연] &ch -일반 KPI";
	proc freq data=shop.users;
	where channel="&ch";
	table vip_grade/nocum;
run;
title;
%end;
%mend smart_kpi;

%smart_kpi(ch=organic);
%smart_kpi(ch=paid_search);

; *'; *"; */; quit; run;/*초기화*/

%macro countdown;
	%let n=5;
	%do %while (&n >0);
	%put 카운트 &n;
	%let n=%eval(&n-1);
	%end;
	%put 발사!
%mend countdown;
%countdown;

%macro countdown_until;
	%let n=5;
	%do %until (&n=0);
	%put 카운트 &n;
	%let n=%eval(&n-1);
	%end;
	%put 발사!;
%mend countdown_until;
%countdown_until;

proc sql;
	select distinct channel into :channels separated by ' '
	from shop.users;
quit;
%put channels : &channels;

/*session 4 into 변수 */
/* proc sql noprint; */
/* 	select count(*) into: n_users	from shop.users; */
/* 	select max(total_amount) into:max_amt from shop.orders */
/* 	where status='paid'; */
/* 	select put(avg(total_amount), comma10.) into: avg_amg */
/* 	from shop. */
/* ; */
proc sql;
	select count(distinct vip_grade) 
	from shop.users;
quit;

proc sql noprint;
	select vip_grade, count(*) format=comma10.
	into :vip1-:vip5, :cnt1-:cnt5
	from shop.users
	where vip_grade is not null
	group by vip_grade;
quit;

%put vip1=&vip1 cnt1=&cnt1;
%put vip2=&vip2 cnt2=&cnt2;
%put vip3=&vip3 cnt3=&cnt3;

/* 완전 자동화 매크로 작성 - 채널 자동 반복*/
/* 1. channel 을 검색해서 변수(리스트) 저장*/
proc sql noprint;
	select distinct channel into :ch_list separated by ' '
	from shop.users;
quit;

%put ch_list ->&ch_list;, ch_list 갯수 ->%sysfunc(countw(&ch_list)) ;
%macro auto_all_channels;
	%local n_ch i ch;
	%let n_ch =%sysfunc(countw(&ch_list));
/*word 갯수세기 countw*/

/*자동 계싼된 n_ch 수만큼 반복 루프 생성*/
%do i=1 %to &n_ch;
	%let ch=%scan(&ch_list,&i);
	%put [동적 [&i /&n_ch]] &ch;
	%ch_kpi(ch=&ch);
%end;
%mend;

%auto_all_channels;

/*vip list [산출물] &vip_list + 동적 분석 결과*/
proc sql noprint;
	select user_id into :vip_list separeted by ' '
from shop.users
	where vip_grade ='gold';
quit;
%put &vip_list;
%put vip 수:&sqlobs;

title'[미니실습4] vip 고객 주문 내역 (동적 in절)';
proc sql outobs=10;
	where user_id in(&vip_list);
quit;
title;




