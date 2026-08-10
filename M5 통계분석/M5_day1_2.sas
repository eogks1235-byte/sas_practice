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

















