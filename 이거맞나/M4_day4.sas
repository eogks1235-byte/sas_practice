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


/* [추가] 월별/일자별 정렬 후 월별 최초 주문 상품 추출 */
proc sort data=report out=report_sorted;
	by 월 order_date;
run;

data first_orders;
	set report_sorted;
	by 월 order_date;
	if first.월; 
	
	keep 월 order_date product_id product_name brand line_total; 

run;

proc print data=first_orders label ;
	title '월별 최초 주문 상품 및 브랜드 정보';
	label 월='주문월'
	      order_date='주문일자'
	      product_id='상품ID'
	      product_name='상품명'
	      brand='브랜드명'
	      line_total='주문금액';
run;
title;


