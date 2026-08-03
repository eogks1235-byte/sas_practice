libname shop '/home/student/shop_csv';

PROC IMPORT DATAFILE="/home/student/shop_csv/orders_dirty.csv"
	OUT = shop.orders_dirty 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=max;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/*컬럼의 데이터 타입 확인
 필수 3가지*/
title '칼럼 정보 확인';
proc contents data=shop.orders_dirty;
run;
title '처음5개 행 데이터 보기';
proc print data=shop.orders_dirty(obs=5);
run;
title '적제된 데이터 갯수확인';
proc sql ;
 select count(*)
from shop.orders_dirty;
quit;
title;

/* sashelp 에 있는 cars의 정보 확인*/
proc print data=sashelp.cars(obs=10);
quit;

proc contents data=sashelp.cars;
run;

proc sql ;
	select count(*)
from sashelp.cars;
quit;

/* shop.users tax 칼럼을 추가 tax=total_amount * 0.1 로 
저장 후 work.temp
work.temp -> channel 별로 누적 매출을 출력후
shop.user_tax로 저장*/

PROC IMPORT DATAFILE="/home/student/shop_csv/users.csv"
	OUT = shop.users 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=max;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

data work.temp;
	set shop.users;
tax= total_spent * 0.1;
run;

proc sort data=work.temp;
    by channel;
run;

data shop.user_tax;
	set work.temp;
    
    retain 누적합계 0; 
    
    if first.channel then 누적합계 = 0; 
    
    누적합계 + total_spent;

run;

proc sql outobs=5;
	select *
from shop.user_tax;
	order by 누접합계;
quit;
proc contents data=shop.user_tax;
run;

/*by 와 class의 차이 찾아보기*/
/*means 프로시듀어 는 수치형 컬럼만 가능*/

PROC IMPORT DATAFILE="/home/student/shop_csv/users_dirty.csv"
	OUT = shop.users_dirty 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=max;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/* session3 proc means*/
/* users_dirty의 age 컬럼에 대한 통계정보 확인 */
proc means data=shop.users_dirty maxdec=1;
	var age;
run;

proc means data=shop.users_dirty N mean median q1 q3 std maxdec=1;
	var age;
run;/*maxdec는 소수점자리수*/

proc means data=shop.users_dirty skewness p95 maxdec=1;
	var age;
run;


proc means data=shop.users_dirty min max var range maxdec=1;
	var age;
run;

proc means data=shop.users_dirty mean median mode maxdec=1;
	var age;
run;

proc means data=shop.users_dirty N nmiss kurtosis p75 q3 p90 maxdec=1;
	var age;
run;

/* 그룹별로 데이터 평균, 그룹은 channel*/
proc means data=shop.users_dirty n nmiss sum maxdec=1;
	var age;
	class channel;
run;

/* 채널별, 성별, 교차 */
proc means data=shop.users_dirty N mean std maxdec=1;
	var age;
class channel gender;
	
run;

proc means data=shop.users N mean std maxdec=1;
	var age;
class channel signup_device gender;
	types channel * gender ; /*class중에 선택된 두개*/
run;



