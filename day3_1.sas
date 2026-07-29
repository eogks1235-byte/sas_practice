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
order by 정상매출, 취소매출
;quit;







