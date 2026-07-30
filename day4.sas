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