libname shop "/home/student/shop_db";

proc sql outobs=10;
	select name, channel,
case channel
when 'paid_search' then '검색광고'
when 'social' then '소셜'
when 'organic' then '오가닉'
when 'referral' then '추천'
else '기타'
end as 채널_한
from shop.users;
quit;

proc sql outobs=10;
	select name, vip_grade,
	case 
	when vip_grade is null then '미입력'
	when vip_grade ='vip' then 'vip'
	else '미입력'
	end as 분류
	from shop.users;
quit;

/* 연령대별 회원수를 출력 <30 -> 20대, <40 ->30대, <50 -> 50대, '50+' 
as 회원수*/

proc sql outobs=10;
	select *
	from shop.users;
quit;

proc sql outobs=10;
    select 
        case 
            when age between 0 and 29 then '20대이하'
            when age between 30 and 39 then '30대'
            when age between 40 and 49 then '40대'
            when age between 50 and 59 then '50대'
            else '60대이상'
        end as 연령대,
        count(user_id) as 회원수
    from shop.users
    group by calculated 연령대;
quit;

proc sql outobs=20;
	select user_id, name, age, city, vip_grade, total_spent
	from shop.users
	where city='서울'and age between 30 and 50 and vip_grade='gold'
	order by total_spent desc;
quit;

proc sql outobs=20;
	select order_id, user_id, order_date, channel, total_amount
	from shop.orders
	where status='paid'
order by channel, total_amount desc;
quit;

proc sql outobs=10;
	select *
from shop.orders;
quit;

proc sql outobs=10;
    select user_id, 
           name, 
           age,
           case 
               when age < 20 then '10대 이하'
               when age < 30 then '20대'
               when age < 40 then '30대'
               when age < 50 then '40대'
               when age < 60 then '50대'
               else '60대 이상'
           end as 연령대,
           case 
               when total_spent >= 1000000 then 'VIP'
               when total_spent >= 100000  then 'Gold'
               else '일반'
           end as 등급
    from shop.users
    where age is not null
    order by age, calculated 등급 desc;
quit;

proc sql outobs=10;
	select *
	from shop.users;
quit;

proc sql outob=10;
	select channel, count(*) as 회원수,
	count(distinct vip_grade) as 등급수,
	avg(total_spent) as 평균매출
from shop.users
where channel is not null 
order by 회원수 desc;
quit;

proc sql;
	select count(*) as 건수 format=comma16.,
	sum(total_amount) as 총매출 format=comma16.,
	avg(total_amount) as 객단가,
	min(total_amount) as 최소,
	max(total_amount) as 최대 format=comma16.
from shop.orders;
quit;

proc sql;
    select channel,
           count(*) as 회원수,
           count(distinct vip_grade) as 등급수,
           avg(total_spent) as 평균매출 format=comma16.2
    from shop.users
    where channel is not null
    group by channel
    order by calculated 회원수 desc;
quit;

/* 채널별 총주문수, 매출총액, 객단가*/
proc sql;
	select channel as 채널, count(*) as 총주문수, sum(total_amount) as 매출총액,
	avg(total_amount) as 객단가
from shop.orders
	where status='paid'
	group by channel, device;
quit;

/* 채널별 device별 총주문수, 매출총액, 객단가*/
proc sql;
	select channel as 채널, device as device, count(*) format=comma16. as 총주문수,
	cat(put(sum(total_amount), comma16.), '원') as 매출총액, avg(total_amount) format=comma16. as 객단가
from shop.orders
	where status='paid'
	group by channel, device;
quit;

/* 고객의 등급별 주문채널별 주문수, 매출총액*/
proc sql outobs=20;
	select u.vip_grade as 고객등급, o.channel as 주문채널, count(o.order_id) as 총주문수, sum(o.total_amount) as 주문총액
from shop.users as u, shop.orders as o 
	where u.user_id=o.user_id
	and o.status='paid'
	group by u.vip_grade, o.channel;
quit;

/* 고객의 가입채널별 매출총액 단, 매출총액이 500만원 이상인 채널만 구하세요
매출총액이 많은 채널순으로 출력*/
proc sql outobs=20;
	select *
from shop.orders;
quit;

proc sql outobs=20;
	select device as device, sum(total_amount) format comma16. as 매출총액
from shop.orders
	
	group by device
	having calculated 매출총액 >=21000000000	
order by calculated 매출총액 desc
;
quit;

/* 고객별 누적매출, 주문수를 출력, 누적매출이 5000000만원 이상인 고객만, 20건만 출력
주문건수가 1건 이상인 고객일것(정상주문만) 누적매출이 많은 순으로 정렬*/
proc sql outobs=20;
	select user_id, sum(total_amount) as 누적매출, count(user_id) as 주문수
from shop.orders
	where status ='paid'
	group by user_id
	having calculated 누적매출>=5000000
	order by 누적매출 desc;
quit;

/* 연도별 주문수, 주문총액, 정상주문만만*/
proc sql;
	select year(order_date) as 연도,
	count(*) as 주문수, sum(total_amount) as 주문총액
from shop.orders
	where status='paid'
	gruop by calculated 연도
	order by 주문총액 desc;
quit;

proc sql;
	select year(order_date) as 연도, month(order_date) as 월,
 	count(*) as 주문수, sum(total_amount) as 주문총액 format comma16.
from shop.orders
	where status='paid' and calculated 연도 =2026
	gruop by calculated 연도, calculated 월
	order by 연도, 월 desc;
quit;

/* 날짜함수 year(), month(), day(), qtr()분기, 
intnx('month', order_date,0, 'B') -> 0: 금월, 1: 다음월, 'B': 달의 첫날, 'E': 마지막날*/

/* 고객명, 마지막 접속한 연, 월, 일, 분기, 접속한 달의 1일 출력*/
proc sql outobs=20;
	select name, year(last_login_date) as 연도, 
           month(last_login_date) as 달, 
           day(last_login_date) as 일, 
           qtr(last_login_date) as 분기,
           intnx('month', last_login_date, 0, 'B') as 접속월초일 format=yymmdd10.,
		intnx('month', last_login_date,1,'e') as 다른것 format=yymmdd15.
from shop.users
	where last_login_date is not null
order by 연도, 달, 일 desc;
quit;

/* 월별 주문수, 매출 총액을 영구 저장 -> monthly_kpi 테이블명 */
proc sql;
	create table shop.monthly_kpi
	as select intnx('month', order_date,0,'b') format yymmdd10. as 월,
	count(*) as 주문수, sum(total_amount) as 총매출액
from shop.orders
	group by calculated 월
	order by 월; 
quit;

proc sql outobs=10;
	select * from shop.monthly_kpi;
quit;

/* view로 vw_monthly_kpi*/
proc sql;
	create view shop.vw_monthly_kpi
	as select intnx('month', order_date,0,'b') format yymmdd10. as 월,
	count(*) as 주문수, sum(total_amount) as 총매출액
from shop.orders
	group by calculated 월
	order by 월; 
quit;

proc sql outobs=10;
	select *
	from shop.vw_monthly_kpi;
quit;
/*뷰는 원본테이블과 연동 최신데이터를 받아볼수있고 
테이블은 최신데이터를 받아올수없다 사진찍히는개념*/

proc sql outobs=10;
	select year(order_date),month(order_date)
from shop.orders;
quit;

proc sql;
	create table shop.monthly_kkpi as	
	select year(order_date)*100 + month(order_date) as 년월,
	count(*) as 주문수 format=comma16.,
	sum(total_amount) as GMV format=comma16.,
	avg(total_amount) as AOV format=comma16.,
	count(distinct user_id) as MAU format=comma16.
	from shop.orders
	group by calculated 년월
	order by 년월;
quit;

proc sql outobs=10;
	select * from shop.monthly_kkpi;
quit;

proc sql;
	create view shop.vw_channel_monthly_1 as	
	select channel as 채널, year(order_date)*100 + month(order_date) as 년월,
	count(*) as 주문수 format=comma16.,
	sum(total_amount) as 매출 format=comma16.
	from shop.orders
	where order_date>='01JAN2025'd
	group by channel, calculated 년월
	;
quit;

proc sql outobs=10;
	select * from shop.vw_channel_monthly_1
;
quit;

proc sql;
    create view shop.vw_users_masked as
    select name,
           strip(substr(name, 1, 1)) || '**' as 마스킹이름
    from shop.users;
quit;

proc sql outobs=10;
	select *
	from shop.vw_users_masked ;
quit;

/* users_csv to order_items.sasdat 로 변환*/
PROC IMPORT DATAFILE="/home/student/shop_csv/order_items.csv"
	OUT = shop.order_items 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/* 3 테이블 inner join*/

proc sql outobs=20;
	select u.vip_grade as 고객등급, o.channel as 주문채널, count(o.order_id) as 총주문수, sum(o.total_amount) as 주문총액
from shop.users as u, shop.orders as o 
	where u.user_id=o.user_id
	and o.status='paid'
	group by u.vip_grade, o.channel;
quit;

proc sql outobs=20;
	select u.vip_grade as 고객등급, o.channel as 주문채널, count(o.order_id) as 총주문수, sum(o.total_amount) as 주문총액
from shop.users as u inner join shop.orders as o on u.user_id = o.user_id
	
	where o.status='paid'
	group by u.vip_grade, o.channel
	order by o.channel;
quit;

/* 고객명, 주문일자, 상품id, 주문금액을 출력 : 정상 거래만
	users, orders, order_items join
1. order_items.csv -> sas database로 shop_db에 저장
2. 컬럼 정보 확인 
3. 쿼리 문장 작성 */

proc sql outobs=10;
	select* from shop.order_items;
quit;

proc sql outobs=20;
	select u.name, o.order_date, i.product_id, i.unit_price *i.quantity,
		p.product_name
	from shop.users as u 
inner join shop.orders as o 
on u.user_id = o.user_id
inner join shop.order_items as i
on o.order_id = i.order_id
inner join shop.products as p
on i.product_id = p.product_id
    where o.status = 'paid'
	order by 3;
quit;

/* 상품명별로 누적주문건수와 누적주문금액을 출력*/
proc sql outobs=20;
    select p.product_name,
           count(i.order_id) as 누적주문건수 format=comma16.,
           sum(i.unit_price * i.quantity) as 누적주문금액 format=comma16.
	from shop.users as u 
inner join shop.orders as o 
on u.user_id = o.user_id
inner join shop.order_items as i
on o.order_id = i.order_id
inner join shop.products as p
on i.product_id = p.product_id
    where o.status = 'paid'
    group by p.product_name
    order by 누적주문금액 desc;
quit;

/* 채널별 상품명별 누적 주문 금액*/
proc sql outobs=20;
	select o.channel, p.product_name, sum(i.unit_price * i.quantity)
	from shop.users as u 
inner join shop.orders as o 
on u.user_id = o.user_id
inner join shop.order_items as i
on o.order_id = i.order_id/* on and 같이 사용가능
결과행수가 작은쪽 사용시 inner조인 사용*/
inner join shop.products as p
on i.product_id = p.product_id
group by o.channel, p.product_name
;
quit;

/* 비활성고객의 명단 추출, 이름, 가입일자 출력*/
proc sql outobs=20;
	select name, u.signup_date format=yymmdd10.
	from shop.users as u left join shop.orders as o on u.user_id = o.user_id
	where o.user_id is null
order by 2;
quit;

/* 상품명, 누적주문금액, 주문이 없는 상품도 출력 */
proc sql outobs=20;
	select p.product_name, sum(i.unit_price * i.quantity) format=comma16.
	from shop.orders as o
left join shop.order_items as i
on o.order_id = i.order_id
left join shop.products as p
on p.product_id =i.product_id
group by p.product_name;
quit;

proc sql outobs=20;
	select p.product_name
from shop.products as p left join shop.order_items as i 
on i.product_id = p.product_id
where i.product_id is null;
quit;
/*1*/
proc sql outobs=20;
    select u.vip_grade, 
           year(o.order_date)*100 + month(o.order_date) as 년월, 
           count(*) as 주문수 format=comma16.
    from shop.users as u 
    inner join shop.orders as o
        on u.user_id = o.user_id
    where calculated 년월 > 202501 
      and u.vip_grade = 'vip'   
    group by u.vip_grade, calculated 년월
    order by u.vip_grade, calculated 년월;
quit;
/*2*/
proc sql outobs=20;
    select u.user_id, 
           u.name, 
           u.city, 
           count(o.order_id) as 주문수, 
           202501 as 년분기  
    from shop.users as u 
    left join shop.orders as o
        on u.user_id = o.user_id
       and year(o.order_date) = 2025 
       and qtr(o.order_date) = 1
    group by u.user_id, u.name, u.city
	having calculated 주문수 =0
    order by u.user_id;
quit;
/*3*/
proc sql outobs=20;
	select p.product_name,p.brand, i.quantity, i.line_total
	from shop.orders as o inner join shop.order_items as i
on o.order_id = i.order_id
inner join shop.products as p
on i.product_id = p.product_id
order by i.quantity desc;
quit;

/*4*/
proc sql outobs=20;
	select u.channel, year(o.order_date)*100 + month(o.order_date) as 년월,
	count(*) as 주문수, avg(o.total_amount) as AOV format=comma16.,
	sum(o.total_amount) as 매출 format=comma16.
	from shop.users as u inner join shop.orders as o
on u.user_id = o.user_id

group by u.channel, calculated 년월 
having calculated 년월 >202501
order by u.channel, calculated 년월
;
quit;

/*5*/
proc sql outobs=20;
	create view shop.vw_city_vip as
	select city, count(*) as 총회원, sum(case when vip_grade ='vip' then 1 else 0 end) as vip수,
	calculated vip수 / calculated 총회원 format percent8.2 as vip비율
from shop.users
/*where vip_grade ='gold'*/
group by city
;
quit;


proc sql outobs=10;
select* from shop.vw_city_vip
;
quit;
