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

proc means data= shop.users noprint;
	var age;
	class channel;
	output out= work.ch_stats/*저장위치*/
	n=cnt mean= age_mean std=age_std;
run;
/*채널기준으로 class 만들었고
type과 freq는 자동생성 out 아래 n mean std 생성 */
proc print data=work.ch_stats noobs;
	where _type_=1;
	var channel cnt age_mean age_std;
	format age_mean age_std 8.1;
run;

/*그래프그리기*/
proc sgplot data=work.ch_stats;
	where _type_=1;
	vbar channel / response= age_mean;
	/*x좌표 : vbar , y좌표 : response*/
	run;
proc sgplot data=work.ch_stats;
	where _type_=1;
	hbar channel / response= age_mean;
	/*x축 : vbar , y좌표 : response
	y축 : hbar*/
	run;

proc sgplot data=ch_stats;
	where _type_=1;
vbar channel / response =age_mean;
xaxis label ='가입채널';
yaxis label ='평균매출';
run;

/*means + noprint == summary*/

proc means data=shop.users n nmiss sum maxdec=1;
	
run;
proc means data= shop.users noprint;
	
	output out= work.ch_stats/*저장위치*/
	n=cnt mean= age_mean std=age_std;
run;

proc means data= shop.users noprint;
	class channel;	
	output out= work.ch_stats/*저장위치*/
	n=cnt mean= age_mean std=age_std;
run;

/* proc means data= work.ch_stats noprint; */
/* 	var age; */
/* 	class channel gender;	 */
/* 	where _type_=2; */
/* 	output out= work.ch_stats/*저장위치 */
/*  */
/* 	n=cnt mean= age_mean std=age_std; */
/* run; */

proc freq data=shop.users_dirty;
	table channel;
run; /* 채널기준 = 빈도 백분율 누적빈도 누적백분율 freq*/

proc freq data=shop.users_dirty;
	tables channel/ nocum;
run; /*누적 안보이게 하는 nocum*/

proc freq data=shop.users_dirty order=freq;
	table channel/nocum;
run;/*order=freq 정렬 desc?*/
	

proc freq data=shop.users_dirty order=internal;
	table channel/nocum;
run;/*order=internal 정렬 channel 순 기본 */

proc freq data=shop.users_dirty order=data;
	table channel/nocum;
run;/*order=data 정렬 원본테이블 들어간순서대로*/

proc freq data=shop.users_dirty;
	table gender/nocum missing;
run;/* 결측값 포함*/

proc freq data=shop.users_dirty order=freq;
	table channel/nocum plots=freqplot;
run; /*빈도수로 그래프그리기*/

/*2차원 교차표
 channel * gender */
proc freq data=shop.users_dirty ;
	table channel * gender;
run;

proc freq data=shop.users_dirty ;
	table channel * gender / nocol;
run;

proc freq data=shop.users_dirty ;
	table channel * gender / norow nocol nopercent;
run; /*빈도수만출력			행백분율	칼럼백분율 백분율*/
/* nofreq 빈도 삭제*/

/*3차원 교차표*/
data shop.user_dirty_y;
    set shop.users_dirty;
    year = year(signup_date);
run;
proc freq data=shop.user_dirty_y;
	table year*channel*gender/ norow nocol nopercent;
run;

proc freq data=shop.users_dirty ;
	table channel * gender / chisq;
run;

proc freq data=shop.users_dirty ;
	table channel * gender / fisher;
run;

proc freq data=shop.users_dirty ;
	table channel * gender / chisq expected;
run;

PROC IMPORT DATAFILE="/home/student/shop_csv/users.csv"
	OUT = shop.users	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=max;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

PROC IMPORT DATAFILE="/home/student/shop_csv/orders.csv"
	OUT = shop.orders	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=max;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;
/*실습4 proc freq*/
proc freq data=shop.orders;
	tables channel * device /nocum;
run;

proc freq data=shop.orders;
	tables channel * device /norow nocol;
run;

proc freq data=shop.orders;
	tables channel * device /chisq;
run;/*0.5 두변수간 상관관계 없음*/ 

proc freq data=shop.orders noprint;
	tables channel * device /norow nocol nopercent chisq;
	output out= work.ch_cross 
;run;

/*univariate 정규성 검증 normal*/
proc univariate data=shop.orders normal;
	var total_amount;
	histogram total_amount / normal;
	qqplot total_amount/ normal(mu=est sigma=est);
run;
/*sort*/
proc sort data=shop.users out=u1;
	by user_id;
run;

proc sort data=shop.users out=u2;
	by descending age;
run;

proc sort data=shop.users out=u3;
	by channel age;
run;

proc sort data=shop.users out=u4;
	by channel descending age;
run;

proc sort data=shop.users out=u5 nodupkey;
	by user_id signup_date;
run;

/*users_dirty*/
proc sort data=shop.users_dirty out=u_nuiq nodupkey;
	by user_id;
run;/*10005>>10000*/

proc sort data=shop.users_dirty out=u_uniq dupout=u_dup nodupkey;
	by user_id;
run;
proc print data=u_dup; run;

proc sort data=shop.users_dirty out=u_dup_all noduplicates;
	by user_id;
run;

/*orders_dirty*/
proc sort data=shop.orders_dirty out=u_nuiq nodupkey;
	by user_id;
run;/*5000 >> 4749*/

proc sort data=shop.orders_dirty out=u_uniq dupout=u_dup nodupkey;
	by user_id;
run;
proc print data=u_dup; run;

proc sort data=shop.orders_dirty out=u_dup_all noduplicates;
	by user_id;
run;

/*merge*/
proc sort data=shop.users_dirty; by user_id;
run;
proc sort data=shop.orders_dirty; by user_id;
run;
data combined; merge shop.users_dirty shop.orders_dirty; by user_id; run;

/*통합*/
/* 1. CSV 파일 불러오는 매크로 정의 */
%MACRO load_csv(name);
    PROC IMPORT DATAFILE="&CSV_DIR/&name..csv"
        OUT=shop.&name DBMS=CSV REPLACE;
        GETNAMES=YES;
        GUESSINGROWS=MAX;
    RUN;
%MEND load_csv;

/* 2. 매크로 실행 (원하는 파일명 입력) */
%load_csv(users);
%load_csv(orders);

/* 3. shop 라이브러리 테이블 정보 확인 (PROC SQL) */
PROC SQL;
    SELECT memname, nobs, nvar, crdate FORMAT=DATETIME20.
    FROM dictionary.tables
    WHERE libname = 'SHOP'   /* SAS dictionary에서는 라이브러리명을 반드시 '대문자'로 작성 */
    ORDER BY nobs DESC;
QUIT;

/* 실습 2 답안- 빈칸 채우기 */
PROC MEANS DATA = shop.users NOPRINT;
CLASS  channel vip_grade;                    /* channel, vip_grade */
VAR    total_spent;
OUTPUT OUT = work.seg_stats
N=고객수 MEAN=평균매출 STD=표준편차 sum=총매출;  /* SUM */
RUN;
PROC PRINT DATA = work.seg_stats NOOBS;
WHERE _TYPE_ = 3;                
/* 3 (양쪽 그룹) */
FORMAT 평균매출 표준편차 총매출 COMMA15.;
RUN;
/* _TYPE_=0 전체 / =1 vip_grade / =2 channel / =3 양쪽 */

/* 실습 3 답안- 빈칸 채우기 */
PROC FREQ DATA = shop.orders;
TABLES payment_method / nocum;             /* NOCUM */
TABLES payment_method* status         /* * */
/ NOROW NOCOL chisq;                  /* CHISQ */
RUN;
/* === 결과 해석 === */
Pr 값 0.05 미만- 의존성 있음
Pr 값 0.05 이상- 독립 (결제수단 무관 분포)
예상: card / kakao / naver 환불율 차이 (Pr < 0.0001)

/* 실습 4 답안- 빈칸 채우기 */
/* (1) 원본 진단 */
PROC UNIVARIATE DATA = shop.orders(WHERE=(status='paid')) normal;
/* UNIVARIATE, NORMAL */
VAR total_amount;
HISTOGRAM total_amount / normal;           /* NORMAL */
QQPLOT    total_amount / NORMAL(MU=EST SIGMA=EST);
RUN;
/* (2) LOG 변환 */
DATA work.orders_log;  SET shop.orders(WHERE=(status='paid'));
log_amount = log(total_amount + 1);     /* LOG */
RUN;
PROC UNIVARIATE DATA = work.orders_log NORMAL;
VAR log_amount;  HISTOGRAM log_amount / NORMAL;  RUN;

/* 실습 5 답안- 빈칸 채우기 */
/* (1) 중복 제거 */
PROC SORT DATA = shop.users_dirty
OUT    = work.step1_unique
DUPOUT = work.dup_removed
nodupkey;                              /* NODUPKEY */
BY user_id;
RUN;
/* (2) 이상치 제거 + 영구 저장 */
DATA shop.users_clean;  SET work.step1_unique;
WHERE age >0 AND age <=120;        /* >, <= */
IF MISSING(email) THEN email = 'unknown';   /* unknown */
RUN;
/* (3) 검증- dirty 10005 - unique 10000 - clean ~9900 */

