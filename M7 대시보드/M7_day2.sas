libname shop_db '/home/student/shop_db';

cas mysession sessopts=(caslib='casuser' timeout=1800);
caslib _all_ assign;

/* 기존 글로벌public 테이블 삭제 casuser도 삭제가능*/
proc casutil;
/* 	droptable casdata='user' incaslib='public' quiet; */
	droptable casdata='shop_joined_data_1' incaslib='casuser' quiet;

quit;


/* 테이블을 cas memory에 load*/
proc casutil;
	load data=shop_db.users outcaslib='casuser' casout='user' promote;
	load data=shop_db.orders outcaslib='casuser' casout='order' promote;
	load data=shop_db.order_items outcaslib='casuser' casout='order_items' promote;
	load data=shop_db.products outcaslib='casuser' casout='products' promote;
	load data=shop_db.categories outcaslib='casuser' casout='categories' promote;
	load data=shop_db.monthly outcaslib='casuser' casout='monthly' promote;
quit;


proc fedsql sessref=mySession;
	create table casuser.shop_joind_data_device as
	select u.user_id, u.age, u.gender, u.channel, u.vip_grade,
o.order_id, o.order_date, o.payment_method, o.total_amount,
		oi.item_id, oi.quantity, oi.unit_price, p.product_id,p.product_name, p.category_id,
c.category_name, p.brand, p.price, o.device
from CASUSER.users u inner join CASUSER.orders o on
u.user_id =o.user_id
inner join CASUSER.order_items oi on o.order_id = oi.order_id
inner join CASUSER.products p on oi.product_id = p.product_id
inner join CASUSER.categories c on p.category_id= c.category_id;
quit;

/* 생성된 shop_joined_data_1 > grobal로 승격 */
proc casutil;
	promote casdata='shop_joind_data_device' incaslib='casuser' outcaslib='casuser';
quit;

/* 생성된 데이터 셋 확인*/
title 'Top10 베스트셀러';
proc fedsql sessref=mySession;
	select brand, sum(quantity * unit_price) as revenue,
	sum(quantity) as total_quantity,
	count(distinct user_id) as unique_buyers,
	count(distinct order_id) as order_cnt
from shop_joined_data_1
	group by 1
order by 2 desc;
quit;
title;