libname shop_db '/home/student/shop_db';

title'[slide 5] Population (전체) vs Sample (10%)';
proc sql;
	select 'population' as type length=12, count(*) as n
from shop_db.orders
	union all
	select 'sample 10%', count(*)
from shop_db.orders(where=(ranuni(1)<0.1));
quit;
title;


title '[slide 10] 미니 실습 1 - orders 첫 인상 (3proc 종합)';
/*데이터 구조 파악*/
proc contents data= shop_db.orders;
run;
/*문자-명목 숫자-수치 요약*/

/* 수치 요약
	var*/
proc means data= shop_db.orders n mean std min max maxdec=2;
var total_amount;
run;

/* 범주 빈도
	table*/
proc freq data=shop_db.orders;
	tables status payment_method /nocum;
run;
title;

/*표준 편차가 큼 -> 외도 첨도 확인*/
/*univariate는 매줄 세미콜론주기*/
proc univariate data= shop_db.orders;
	var total_amount;
	histogram total_amount / normal ;
run;

/*mean median mode 평균 중앙값 최빈값*/

/*기술 통계 풀세트 드가자~~*/
/* proc means */
proc means data=shop_db.orders n nmiss mean std min max median q1 q3 maxdec=2;
	var total_amount ;
run;

/* 그룹별 집계*/
proc means data=shop_db.orders 
	n mean std median maxdec=2;
class payment_method; /*해당 컬럼 값들을 */
	var total_amount; /*var 의 값들로 파악*/
run;

/* 출력 저장 - output */
proc means data=shop_db.orders noprint;
	class payment_method;
var total_amount;
	output out=summary 
		mean=avg std=std ;/*위에서 만든 테이블에서 보고싶은변수 컬럼명 바꿔서 넣기 */
/* 	n=n nmiss=nmiss min=min max=max q1=q1 q3=q3 median=median; */
run;

proc print data=summary noobs;
run;

/* proc means data= shop_db.orders  */

/*기술통계 시각화 -5 지표 한눈에*/

/*1. 평균/중앙값/최빈값 histogram*/

proc sgplot data=shop_db.users;
	histogram total_spent / transparency=0.4;
	refline 78500 / axis=x label='평균'
		lineattrs=(color=red thickness=2);
	refline 60000 / axis=x label='중앙값'	
		lineattrs=(color=blue thickness=2);
	density total_spent /type=kernel;
run;

/*2. IQR boxplot (Q1중앙값Q3)*/
proc sgplot data=shop_db.users;
	vbox total_spent / category=channel
			boxwidth=0.5;
	title'채널별 매출 IQR boxplot';
run;

/*3. 왜도 density 곡선비교*/
proc sgplot data=shop_db.users;
	density total_spent /type=kernel
		legendlabel='실제분포';
	density total_spent /type=normal
		legendlabel='정규분포 비교';
run;


/*step 2 : join*/
proc sql;
	create table work.uo as
	select u.channel, o.total_amount
from shop_db.users u inner join	shop_db.orders o
on u.user_id =o.user_id
where o.status='paid';
quit;

/*채널별 기술통계*/
proc means data=work.uo
	n mean std median q1 q3 maxdec=0;
class channel;
	var total_amount
;run;

/*시각 비교*/
proc sgplot data=work.uo;
	vbox total_amount /category=channel;
run;

proc sgplot data=work.uo;
	histogram total_amount /transparency=0.4;
	density total_amount / type=kernel;
	fringe total_amount;
	xaxis label ='total amount';
run;


/* 구조 + 결측치 */
proc contents data =shop_db.orders;
run;

proc means data=shop_db.orders n nmiss;
	var _numeric_;
run;

/*수치통계*/
proc means data=shop_db.orders
	n mean std min max median q1 q3 maxdec=2;
	var total_amount;
run;

/*그룹별*/
proc means data=shop_db.orders
	n mean std maxdec=2;
class status payment_method;
var total_amount;
run;

/*시각화*/
proc sgplot data=shop_db.orders;
	histogram total_amount;
	density total_amount / type=normal;
run;

/*채널별 매출 eda*/
proc means data=shop_db.orders
	n mean std median p25 p75
	skewness kurtosis
	maxdec=2;
class channel;
var total_amount;
run;

/*boxplot 시각화*/
proc sgplot data= shop_db.users;
vbox total_spent /category=channel;
run;
/*알수없음 ㄷ */
proc means data=shop_db.users
	n mean std median p25 p75
	skewness kurtosis
	maxdec=2;
class vip_grade;
var total_spent;
run;

proc sgplot data= shop_db.users;
vbox total_spent /category=vip_grade;
run;


/*proc univariate 풀세트 */
title'[slide 30]proc univariate - 정규성 + 시각화';
proc univariate data=shop_db.users normal
	cibasic plots;
var age;
	histogram age /normal;
	qqplot age / normal(mu=est sigma=est);
run;
title;

/*q1, q3 계싼*/
proc means data=shop_db.orders
	noprint q1 q3;
	var total_amount;
	output out=work.qstat
	q1=q1 q3=q3;
run;

proc sql noprint;
	select q1,q3 into :q1, :q3
from work.qstat;
quit;

/*매크로 변수 지정*/
data _null_;
	set work.qstat;
	iqr =q3-q1;
	call symputx('lower',q1-1.5*iqr); /*sysputx 최신함수? 문자 숫자다가능*/
	call symputx('upper',q3+1.5*iqr);
run;

%put note: IQR 하한=&lower/ 상한=&upper q1:&q1/ q3:&q3 ;
/*이상치 추출*/
data work.outliers;
	set shop_db.orders;
	if total_amount <&lower
	or total_amount >&upper
	then output;
run; /*output은 outliers에 들어간다 */

proc sql ;
	select count(*) as n_outliers from work.outliers;
quit;

/*box plot*/
proc sgplot data=shop_db.orders;
	vbox total_amount / category=channel;
run;

/*실습3*/
proc univariate data=shop_db.users normal;
	var total_spent;
	histogram total_spent /normal;
	qqplot total_spent /normal (mu=est sigma=est);
run; 

/*session 4 :t-test*/
PROC TTEST DATA=shop_db.users
H0=35 /*귀무가설 */
ALPHA=0.05;
VAR age;
RUN;

/*proc ttest -1 -sample*/
proc ttest data=shop_db.orders
	h0=50000 alpha=0.05;
	var total_amount;
	where status='paid';
run;/*평균매출이 5만원이 아니다*/

PROC UNIVARIATE DATA=shop_db.orders
MU0=50000;
VAR total_amount;
RUN;

title '[slide 45] proc ttest - 1-sample 풀세트, paid';
/*모수 t-test*/
PROC TTEST DATA=shop_db.orders
H0=680000 ALPHA=0.05;
WHERE status='paid';
VAR total_amount;
RUN;
title;

title'[slide 47]미니실습 5-products.price가설검정';
/*실습 5 신제품가격 t-test*/
proc ttest data=shop_db.products
h0=50000 alpha=0.05;
var price;
run;/*50000원으로 팔수없다 평균 11.5~13.9만원이다 */

/*정규성위배시 비모수대안*/
/*중위수 확인 */
proc univariate data=shop_db.products normal;
var price;
run;

proc univariate data=shop_db.products mu0=50000;
	var price;
run;
title;

/* 실습 6 - 숙제 */
%LET TODAY = %SYSFUNC(TODAY(), YYMMDDN8.);
ODS PDF FILE="...&TODAY..pdf"
STYLE=journal;
TITLE "평균 주문금액 검정 -APA";
PROC TTEST DATA=shop_db.orders
H0=50000;
VAR total_amount;
WHERE status='paid';
RUN;
PROC SQL;
SELECT (MEAN(total_amount) -total_amount)/STD(total_amount)
AS d FORMAT=8.3
FROM shop.orders
WHERE status='paid';
QUIT;
ODS PDF close;


















