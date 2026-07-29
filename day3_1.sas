libname shop "/home/student/shop_db";

/* 주문번호, 주문금액, 주문평균, 
주문금액이 주문평균보다 큰 주문내역만*/

proc sql outobs=20;
	select order_id as 주문번호, total_amount as 주문금액,
	(select avg(total_amount) from shop.orders) as 주문평균 
	from shop.orders
	where total_amount > (select avg(total_amount) from shop.orders);
/*	where total_amount > (주문평균)*/
quit;


/* 주문번호, 주문금액, 주문평균, 주문금액과 평균금약차이,
주문금액이 주문평균보다 큰주문*/
proc sql outobs=10;
    select order_id, 
           total_amount, 
           (select avg(total_amount) from shop.orders) as 평균, 
           total_amount - (select avg(total_amount) from shop.orders) as 차이
    from shop.orders
    where total_amount > (select avg(total_amount) from shop.orders)
    order by 차이 desc; 
quit;

proc sql outobs=10;
	select u.vip_grade as 등급,
sum(o.total_amount) as 등급매출 format=comma16.
from shop.orders as o inner join shop.users as u
on o.user_id = u.user_id
where o.status='paid'
group by u.vip_grade
having sum(o.total_amount) >= (select avg(total_amount) from shop.orders where status = 'paid') * 100
order by 등급매출 desc
;quit;


proc sql outobs=20;
    select order_id, 
           total_amount format=dollar15.,
           (select max(total_amount) from shop.orders) as max_amount,
           (select min(total_amount) from shop.orders) as min_amount,
           (select std(total_amount) from shop.orders) as std_amount,
           /* Z-score 수식: (값 - 평균) / 표준편차 */
           (total_amount - (select avg(total_amount) from shop.orders)) / (select std(total_amount) from shop.orders) as z_score
    from shop.orders
    order by z_score desc;
quit;

/* 고객등급이 'gold'인 회원이 주문한 주문번호, 주문금액, 고객번호 출력*/
proc sql outobs=10;
	select order_id as 주문번호, total_amount as 주문금액, user_id as 고객번호 
	from shop.orders
	where user_id in (select user_id from shop.users where vip_grade='gold');
quit;

/*휴면 고객의 회원번호, 이름, 가입일자 출력*/
proc sql outobs=5;
	select user_id as 회원번호, name as 이름, signup_date as 가입일자 format=yyddmm10.
	from shop.users
	where user_id not in (select distinct user_id from shop.orders where status='paid')
;
quit;

/* 활동 고객의 회원번호, 이름, 등급, 주문수*/
proc sql outobs=5;
	select user_id as 회원번호, name as 이름, vip_grade as 등급, (select count(*) from shop.orders where u.user_id = user_id) as 주문수
	from shop.users as u
where exists (select 1 from shop.orders where u.user_id =user_id and status='paid')

;quit;

/* 고객 자신의 등급의 평균 주문액보다 많은 고객의 정보
	주문번호, 등급, 주문액 출력*/
proc sql outobs=20;
	select order_id as 주문번호, vip_grade as 등급, total_amount as 주문액,
	(select avg(total_amount)from shop.orders where user_id in (select user_id from shop.users where u.vip_grade=vip_grade)) as 등급평균
	from shop.orders as o inner join shop.users as u
on o.user_id = u.user_id
/* where o.tatal_amount > (고객 등급의 평균주문액) */
	where o.total_amount > (select avg(total_amount) from shop.orders as oo inner join shop.users as uu 
on oo.user_id = uu.user_id
where u.vip_grade =uu.vip_grade)
order by 2 desc
;quit;
/*상관커리 처음 inner는 1.두개의 테이블 2.두개의 테이블 복제 
3. 같은 테이블인데 1번과 2번에서 사용하느것 */

/*등급별 매출 + 취소율 + 우수 필터*/
proc sql outobs=10;
	select u.vip_grade,
	 sum(case when u.status ='paid' then u.total_amount else 0 end)as 정상매출,
	 avg(case when u.status='cancelled' then 1 else 0 end)/count(*) as 취소율
from shop.users as u inner join shop.orders as o 
on u.user_id = o.user_id
group by u.vip_grade
having calculated 정상매출 >=100000000;
quit;

proc sql outobs=10;
    select 
        u.vip_grade,
        
        sum(case when o.status = 'paid' then o.total_amount else 0 end) as 정상매출 format=comma16.,
        
        
        sum(case when o.status = 'cancelled' then 1 else 0 end) / count(*) as 취소율 format=percent8.2
    from shop.users as u 
    inner join shop.orders as o 
        on u.user_id = o.user_id
    group by u.vip_grade
    having calculated 정상매출 >= 100000000
order by 3 desc;
quit;

proc sql outobs=10;
	select u.vip_grade, u.city,
sum(case when o.status = 'paid' then o.total_amount else 0 end) as 정상매출 format=comma16.,
        
        
        sum(case when o.status = 'cancelled' then o.total_amount else 0 end) as 취소매출 format=comma16.
    from shop.users as u 
    inner join shop.orders as o 
        on u.user_id = o.user_id
group by u.vip_grade, u.city
/* having calculated 정상매출, calculated 취소매출 */
order by 취소매출 desc
 ;quit;

proc sql outobs=10;
	select order_id, total_amount,
	(select avg(total_amount) from shop.orders) 
	from shop.orders
where total_amount > (select avg(total_amount) from shop.orders)
;quit;

proc sql outobs=10;
	

/* 등급내 누적합*/
/* 1단계 테이블 조인 -> 새로운 테이블 생성*/
proc sql;
	create table work.joined as 
	select o.order_id, u.vip_grade, o.order_date, o.total_amount
	from shop.orders as o inner join shop.users as u
	on o.user_id = u.user_id
;quit; 

/* 2단계 work.joined 정렬*/
proc sort data=work.joined;
	by vip_grade order_date;
run;
/*원테이블 정렬 변경 by*/
/*joined 테이블이 정렬된다*/

/* 3단계 등급내 누적합 ->data +retain */
data work.result;
set work.joined;
by vip_grade;
retain 등급내누적 0;
if first.vip_grade then 등급내누적 =0;
등급내누적 + total_amount;
run;

proc sql otuobs=30;
	select * from work.result;
quit;


/* 화면에 데이터 출력 */
proc print data=work.result(obs=20);
	var vip_grade order_date total_amount 등급내누적
;run; /*바로 결과 확인은 var*/

/* 2개의 view 생성 : vip_grade='gold'인 회원의 회원id
	total_amount >=50000 이상인 주문만 */

proc sql ;
	create view vip_view as 
select user_id from shop.users
where vip_grade ='gold';


create view big_orders_vw as
select * from shop.orders where total_amount>=50000
;quit;

/* view를 활용해서 데이터 검색*/
proc sql outobs=20;
	select order_id, user_id, total_amount, order_date
from big_orders_vw
	where user_id in(select user_id from vip_view)
	order by total_amount desc;
quit; 

proc sql;
create table shop.big_orders_vw as
select *
from work.big_orders_vw;
quit;

/* 고객명, 등급, 주문수, 총매출, 평균주문
	1. 등급='gold' 인회원만 검색하는 view 생성
	2. 1단계서 작성한 view와 orders를 조인해서 새로운 view생성*/

proc sql;
   create view work.vw_grade_gold as
   select user_id, vip_grade, name
   from shop.users
   where vip_grade = 'gold';

   create view work.vip_orders_vw as
   select gg.user_id, gg.vip_grade, gg.name, o.order_id, o.total_amount
   from shop.orders o 
   inner join work.vw_grade_gold gg
   on o.user_id = gg.user_id;
quit;

proc sql outobs=10;
   select name, 
          vip_grade,
          count(order_id) as 주문수,
          sum(total_amount) as 총매출,
          avg(total_amount) as 평균주문
   from work.vip_orders_vw
   group by name, vip_grade;
quit;

/*매출 최상위 5건 최하위5건 주문번호, 주문금액
1. 정상거래인 주문의 주문번호 주문금액으로 view생성
2. 주문금액으로 sort 해서 5건만 desc asc*/
proc sql;
	create view paid_v as
select order_id, total_amount
from shop.orders
where status='paid'
;quit;

proc sort data=paid_v out=paid_v_sorted;
	by descending total_amount; 
run;

data top5;
set paid_v_sorted (obs=5)
;
run;
proc sort data=paid_v out=paid_v_sorted;
	by total_amount; 
run;

data bot5;
set paid_v_sorted(obs=5)
;
run;
proc sql;
select 'TOP' as 구분, order_id, total_amount from top5
union all
select 'BOTTOM' as 구분 , order_id, total_amount from bot5
order by 1, 2 desc;
quit; 
/*union all 은 컬럼갯수가 맞아야 한다*/