/* 실행은 f3이다.*/
libname shop "/home/student/shop_db";

/* users_csv to users.sasdat 로 변환*/
PROC IMPORT DATAFILE="/home/student/shop_csv/users.csv"
	OUT = shop.users 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;
/*해당 파일 폴더 속성보면 경로 알수있음*/

/* 실행은 f3이다.*/
libname shop "/home/student/shop_db";

/* users_csv to orders.sasdat 로 변환*/
/* 드래그로 묶어서 f3하면 해당 부분만 실행된다.*/
PROC IMPORT DATAFILE="/home/student/shop_csv/orders.csv"
	OUT = shop.orders 	/*shop라이브러리에 orders만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/* 사용자의 이름, 아이디, 나이, 지역 출력*/
proc sql outobs=10; /* 출력할 행 갯수 10개*/
	select user_id, name, age, city
	from shop.users;
quit;

/* DATA step seoul 인 고객만 추출 */
DATA work.seoul_users;
	set shop.users;
	keep user_id name city; /*가져올 컬럼 지정, 컬럼명간 쉼표 X*/
	WHERE city = '서울';
run;

proc sql outobs=10;
	select * from work.seoul_users;
quit;

/* 서울지역의 30대 고객의 정보 출력*/
proc SQL;
	select *
	from shop.users /* 라이브러리에서 찾음*/
	where city ='서울' and age between 30 and 39;
quit;

/* 문제 1-1 */
proc sql outobs=20;
	select user_id, name, age, city, vip_grade
	from shop.users
	where city='서울';
quit;

/* 한글 alias + 계산 컬럼*/
proc sql outobs=20;
	select name as 고객명, 
		age as 나이,
		age*12 as 개월수,
		CAT(city, ' ', vip_grade) as 지역등급,
		vip_grade as 등급
	from shop.users;
quit;

libname shop "/home/student/shop_db";

/* users_csv to products.sasdat 로 변환*/
PROC IMPORT DATAFILE="/home/student/shop_csv/products.csv"
	OUT = shop.products 	/*shop라이브러리에 products만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

proc sql outobs=20;
	select *
	from shop.products;
quit;

proc sql outobs=20;
	select product_id, product_name, price as 정가,
			rating_avg as 별점
	from shop.products;
quit;

proc sql outobs=20;
	select
		upcase(payment_method) as 결제수단,
	payment_method,
		round(total_amount, 100) as 금액반올림 format=comma12.,
		substr(channel, 1, 3) as 채널약어,
		total_amount as 금액 format=comma12.
	from shop.orders;
quit; 

proc sql outobs=20;
	select
		count(*) as 주문수 format=comma12.,
		sum(total_amount) as GMV format=comma15.,
		avg(total_amount) as AOV format=comma12.,
		calculated GMV/calculated 주문수 as 재계산AOV format=comma12.
	from shop.orders;
quit;

/* 정상 지불인 주문의 주문 금액이 100만 이상인 주문의 
order_id, user_id, total_amount, status, channel 찾기*/
proc sql outobs=20;
	select order_id, user_id, total_amount, status, channel
	from shop.orders
	where status='paid' and total_amount>=1000000;
quit;

/* 지역이 서울, 부산, 대구인 고객의 이름, 나이, 지역을 출력*/
proc sql outobs=10;
	select *
	from shop.users;
quit; 

proc sql outobs=10;
	select name, age, city
	from shop.users
	where city in('서울','부산','대구');
quit;

/* 성이 김씨이고 사는 지역기 서울, 부산, 대구인 
고객의 이름, 나이, 지역을 출력*/
proc sql outobs=10;
	select name,age,city
	from shop.users
	where name like '김%' and city in('서울', '부산', '대구');
quit;

proc sql outobs=10;
	select order_id, user_id, total_amount, status, channel
	from shop.orders
	where status='paid' and total_amount>=1000000 
	and	channel in('social','email')
	order by order_date desc;
quit;

proc sql outobs=10;
	select channel
	from shop.orders;
quit;

/* channel 이 null인 데이터 찾기*/
proc sql outobs=10;
	select *
	from shop.orders
	where channel is null;
quit;

/* 등급별 총 금액 출력, 이름, 등급, 총금액(total_spent)*/
proc sql;
	select name as 고객명,
	vip_grade as 등급,
	total_spent as 누적매출
	from shop.users
	order by 2, 누적매출 desc;
quit;

/* count(*), count(user_id_), count(distinct user_id)를 oreders에서*/
proc sql;
	select count(*) as 총주문수,count(user_id) as 고객수,
	count(distinct user_id) as 유효고객수
	from shop.orders
	;
quit;

/* 도시종류를 구하는데 count(*),count(city),count(distinct city) 출력 users에서구하기*/
proc sql;
	select count(*) as 총지역수,count(city) as 지역수,
	count(distinct city) as 유효지역수 /*17*/
	from shop.users;
quit;

proc sql;
	select count(*) as 총지역수,count(channel) as 지역수,
	count(distinct channel) as 유효지역수 /*6*/
	from shop.users;
quit;

proc sql;
	select count(*) as 총지역수,count(channel) as 지역수,
	count(distinct channel) as 유효지역수 /*5*/
	from shop.orders;
quit;

/* 전체주문수, 고객수, 인당 주문수(전체 고객수/ 고객수)*/
proc sql;
	select 
		sum(order_count) as 총주문수,
		
		count(distinct user_id) as 고객수,
		   
		calculated 총주문수 / calculated 고객수 as 인당주문수      
	from shop.users   
	;
quit;

proc sql outobs=10;
	select *
	from shop.orders;
quit;

/*ordeers 에서 총주문금액, 주문고객수, 인당주문금액, 정상거래만 status='paid'*/
proc sql;
	select sum(total_amount) as 총주문금액,
	count(distinct user_id) as 주문고객수,
	(calculated 총주문금액 / calculated 주문고객수) as 인당주문금액
	from shop.orders
	where status='paid'
;
quit;

/* 연령이 60이상이면 시니어 아니면 청년으로 출력
	이름, 나이, 연령 출력*/
proc sql outobs=20;
	select name as 이름, age as 나이,
	case when age >=60 then '시니어'
	else '청년' 

	end as 연령대
	
	from shop.users;
quit;


/* 10대, 20대, 30대, 40대, 50대, 아니면 시니어*/ 
proc sql outobs=20;
	select name as 이름, age as 나이,
	case when age <20 then '10대'
		when age <30 then '20대'
		when age <40 then '30대'
		when age <50 then '40대'
		when age <60 then '50대'
		else '시니어'
	end as 연령 
from shop.users;
quit;

/* 이름, 나이, 총주문금액(total_spent) 출력
	60이상이면 시니어, 40이상이면 중장년, 20이상이면 청년 아니면 미성년 as 연령대
	total_spent >=1000000 이상이면 'vip*,
				>=100000 이상이면 '우수'
				아니면 일반 as 고객등급*/
proc sql outobs=20;
	select name as 이름, age as 나이, total_spent as 총주문금액,
	case when age>=60 then '시니어'
		when age >=40 then '중장년'
		when age >=20 then '청년'
	else '미성년'
	end as 연령대,
	case when total_spent >=1000000 then 'vip'
		when total_spent >=100000 then '우수'
		else '일반 '
	end as 고객등급
	from shop.users;
quit;

