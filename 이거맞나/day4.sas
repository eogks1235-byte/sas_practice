libname shop "/home/student/shop_db";

proc sql;
	create table shop.monthly_kpi as
select 
	intnx('month', order_date, 0,'b') as 월 format=yymmdd10.,
	count(*) as 주문수,
	sum(total_amount) as 매출 format=DOLLAR16.,
	avg(total_amount) as 객단가 format=DOLLAR16.
	from shop.orders where status='paid'
group by calculated 월;
quit;

proc sql;
	select user_id into :vips
	separated by ','
from shop.users
where vip_grade='gold'
;quit;

proc sql noprint;
	select count(*) into: n_users
	
from shop.users;
 quit;
%put 회원수 :&n_users;
proc sql noprint;
	select user_id into :vip_list
	separated by ','
from shop.users
	where vip_grade='gold';
quit;
%put vip_list : &vip_list;

proc sql outobs=10;
	select user_id, vip_grade
from shop.users
	where user_id in(&vip_list);
quit;

%let tbl = shop.users;
proc sql outobs=10;
	select user_id, vip_grade
from &tbl
	where user_id in(&vip_list);
quit;

/*202601 이후 주문한 내역만 출력*/
%let day = '01JAN2026'd;
proc sql outobs=10;
	select * from shop.orders
where order_date > &day;
quit;

%let year =202601;
proc sql;
	create table shop.kpi_&year as
select * from shop.orders
	where order_date >= '01JAN2026'd;
quit;

/* 고객명, 고객매출총합, 마지막주문일자, 주문건수를 출력 
	1. users에서 gold 또는 vip 회원의 명단만 동적변수에 저장
	2. 1단계에서 저장한 고객만 해당자료 추출*/
 
%let grade = ('gold', 'vip');
proc sql outobs=10;
	select u.name as 고객명, 
u.vip_grade,
	u.total_spent as 고객매출총합,
	(select max(o.order_date) from shop.orders
	where user_id=u.user_id) as 마지막주문일자 format=yymmdd7.,
	(select count(*) from shop.orders 
where user_id=o.user_id) as 주문건수
from shop.users u inner join shop.orders o
on u.user_id = o.user_id

where u.vip_grade in &grade;
quit;

proc sql noprint;
	select user_id into :vip_list separated by','
from shop.users
where vip_grade ='gold'
order by vip_grade;
quit;

proc sql outobs=20;
select u.name as 고객명,u.total_spent,
(select max(o.order_date) from shop.orders
	where user_id=u.user_id) as 마지막주문일자 format=yymmdd7.,
	(select count(*) from shop.orders 
where user_id=o.user_id) as 주문건수
from shop.users u inner join shop.orders o
on u.user_id = o.user_id

where u.user_id in(&vip_list);
quit;

/*library 검색*/
/*테이블의 정보*/
proc sql;
	select memname, nobs as 행수, crdate as 생성일
	from dictionary.tables
	where libname='SHOP';
quit;

proc sql outobs=10;
	select * from dictionary.tables;
quit;

/* 칼럼 정보 -> dictionary.columns */
proc sql;
	select memname as 테이블명 , name as 컬럼명, type as 데이터타입, length as 길이
from dictionary.columns
	where libname ='SHOP'
	and memname in('USERS',"ORDERS");
/* 	and memname='USERS'; */
quit;

/* index 정보*/
proc sql;
	select * from dictionary.indexes
	where libname='SHOP';
quit;

/*라이브러리 정보확인*/
proc sql;
	select * from dictionary.members;
quit;

/* user_id 컬럼이 존재하는 테이블명을 검색*/
proc sql;
	select memname as 테이블명 , name as 컬럼명, 
		type as 데이터타입, length as 길이
from dictionary.columns
	where libname ='SHOP'
	and upcase(name) like '%USER_ID%';
quit;

/* 전체 데이터의 사이즈*/
proc sql;
	select libname, count(*) as 테이블의개수, sum(nobs) as 총행의수
from dictionary.tables
	group by libname;
quit;

/* 디서너리의 테이블과 컬럼의 정보 검색*/
proc sql;
select t.memname,
t.nobs, t.crdate format=datetime20.,
count(c.name)
from DICTIONARY.TABLES as t
left join DICTIONARY.COLUMNS as c
on t.libname = c.libname
and t.memname = c.memname
where t.libname ='SHOP'
group by t.memname, t.nobs, t.crdate
order by t.memname;
quit;

option fullstimer msglevel=I; /*on*/

/* user_id=42 인 고객의 주문 정보 출력 */
proc sql;
	select * from shop.orders
	where user_id =42;
quit;

/* index 생성 전*/
proc sql _method;
	select * from shop.orders
	where user_id =42;
quit;

/* index 생성 -> orders의 user_id 컬럼*/
proc sql;
	create index user_id on shop.orders(user_id);
quit;


/* index 정보*/
proc sql;
	select * from dictionary.indexes
	where libname='SHOP';
quit;

/* index 생성 후*/
proc sql _method;
	select * from shop.orders
	where user_id =42;
quit;

proc datasets lib=shop nolist;
	modify orders;
	drop index user_id; 
	repair orders;
quit;

proc sql;
	select * from dictionary.indexes
	where libname ='SHOP';
quit;

/* 주문 상품명, 총주문금액
	-> order_items (product_id, line_total),
		products(product_id, product_name)*/
proc sql _method;
	select p.product_name as 상품명, sum(i.line_total) as 주문총액
	from shop.order_items i inner join shop.products p
on i.product_id = p.product_id
	where i.product_id < 50
		group by p.product_name
;quit;

/* products(product_id) index */
proc sql;
	create index product_id on shop.products(product_id);
quit;

proc sql outobs=20 _method;
	select p.product_name as 상품명, sum(i.line_total) as 주문총액
	from shop.order_items i inner join shop.products p
on i.product_id = p.product_id
	group by p.product_name
;quit;

option fullstimer;
proc sql _method;
select * from shop.orders
where user_id=12345;
quit;

proc sql;
	create index idx_user_id
	on shop.orders(user_id);
quit;

proc sql _method;
select * from shop.orders
where user_id=12345;
quit;

/* orders -> user_id, order_date
	 복합인덱스 생성:	idx_user_date
	
	고객명, 주문일자, 주문총액
	고객 id 가 42인 고객의 주문 중 260101이후 주문한 내용만
	주문일자로 정렬 */

proc sql;
	create index idx_user_date on shop.orders(order_date, user_id);
quit;

proc sql _method;
	select name as 고객명, order_date, sum(total_amount) as 총주문액
	from shop.orders o inner join shop.users u 
on o.user_id = u.user_id
where o.user_id =42
and o.order_date >= '01JAN2026'd
group by order_date, o.user_id;
quit;
/* 1. 복합 인덱스(Composite Index) 생성 */
/* orders 테이블의 user_id와 order_date 컬럼을 묶어서 idx_user_date 인덱스 생성 */
proc sql;
    create index idx_user_date
    on shop.orders(user_id, order_date);
quit;

/* 2. 조건에 맞는 데이터 조회 및 정렬 */
options fullstimer; /* 성능/시간 측정을 위한 상세 로그 옵션 */

proc sql _method;
    select 
        u.name as 고객명,
        o.order_date as 주문일자, /*format=yymmdd10.,*/
        o.total_amount as 주문총액
    from shop.users u inner join shop.orders o
        on u.user_id = o.user_id
    where o.user_id = 42 
      and o.order_date >= '01JAN2026'd  /* 2026년 1월 1일 이후 주문 */
    order by o.order_date;           /* 주문일자 기준 오름차순 정렬 */
quit;

option nofullstimer msglevel=n; /*off*/

/* sql로 고객 매출을 집계한 뒤 DATA step IF-ELSE로 4등급으로 분류하세요
	1. (SQL): cust_sales 테이블 - user_id, 주문수, 총매출
	2. (DATA): cust_seg 테이블 - 등급 + 캠페인 컬럼 추가
	등급: VIP(100만+) / gold(50만+), silver(10만+), bronze
	캠페인: 등급별 추천 메시지 자동 부여*/

proc sql;
	create table cust_sales as
	select user_id,
	count(*) as 주문수,
	sum(total_amount) as 총매출
from shop.orders where status='paid'
	group by user_id;
quit;

data cust_seg;
	set cust_sales;
	length 등급 $10 캠페인 $40;
	if 총매출 >=1000000 then do;
		등급 ='VIP'; 캠페인='VIP 행사 초대'; END;
	else if 총매출 >=500000 then do;
		등급 ='GOLD'; 캠페인='신상품 우선안내'; END;
	else if 총매출 >=100000 then do;
		등급 ='SILVER'; 캠페인='10% 할인 쿠폰'; END;
	else do;
		등급 ='Bronze'; 캠페인='복귀 30% 쿠폰'; END;
run;

proc sql outobs=20;
	select * from cust_seg;
quit;

/* 빈도, 비율, 백분율 계산하는 proc freq*/
proc freq data=cust_seg;
	tables 등급;
run;

/* by + first 첫주문 추출*/
/* 고객의 첫 주문내역 user_id, order_id, ordeer_date,
	total_amount 출력*/
proc sort data=shop.orders out=sorted_orders;
by user_id order_date;
run;

/*고객의 첫 주문만 테이블 생성*/
data first_roders;
	set work.sorted_orders;
	by user_id;
	if first.user_id
;run;

/* 누적 매출 cum_orders 생성 고객별로 */
data cum_orders;
	set sorted_orders;
	by user_id;
	retain 누적매출 0;
	if first.user_id then 누적매출 =0;
	누적매출 + total_amount;
format 누적매출  dollar15.
;run;

proc sql outobs=20;
	select user_id, order_date, total_amount, 누적매출
from cum_orders
order by 누적매출 desc;
quit;

/*고객의 마지막 주문만 테이블 생성*/
data last_roders;
	set work.sorted_orders;
	by user_id;
	if last.user_id
;run;

/* 고객의 첫 주문과 마지막 주문의 일자 주문금액 출력 */
proc sql outobs=20;
	select f.user_id as 고객번호, f.order_date as 첫주문일자,
	f.total_amount as 첫주문금액, l.order_date as 마지막주문일, l.total_amount as 마지막주문금액
from work.first_roders f inner join work.last_roders l 
on f.user_id = l.user_id;
quit;

/*sas base vs viya cas 속도 비교*/
options fullstimer;

/*디스크 기반 - 순차 처리*/
proc sql;
	select u.vip_grade,
	count(*) as 주문수,
	sum(o.total_amount) as 매출,
	avg(o.total_amount) as 평균
from shop.orders o inner join shop.users u
on o.user_id = u.user_id
where o.status='paid'
group by u.vip_grade
order by 매출 desc;
quit;

/* cas환경*/
cas mysession;
caslib _all_ assign; /*cas viya 들어가기*/

proc cas;
	builtins.serverStatus;
quit;

/* sas data -> cas memory로 load*/
proc casutil;
load data = shop.users outcaslib='casuser'
	casout='users' replace;
	load data = shop.orders outcaslib='casuser'
	casout='orders' replace;
quit;

/*cas 기반 - 병렬 처리*/
proc fedsql sessref=mysession;
	select u.vip_grade,
	count(*) as 주문수,
	sum(o.total_amount) as 매출,
	avg(o.total_amount) as 평균
from casuser.orders o inner join casuser.users u
on o.user_id = u.user_id
where o.status='paid'
group by u.vip_grade
order by 매출 desc;
quit;

proc casutil;
load data = shop.users outcaslib='public'
	casout='users' promote;
quit;

cas mysession terminate;/* cas viya 나가기 */

