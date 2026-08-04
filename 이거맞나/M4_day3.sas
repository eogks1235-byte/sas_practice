/*session 1 : 결측치 처리 연습*/
libname shop '/home/student/shop_db';

PROC IMPORT DATAFILE="/home/student/shop_csv/users_dirty.csv"
	OUT = shop.users_dirty 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

title '[s1.2] before - user_dirty 상태';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg

from shop.users_dirty;
quit;
title;

/*users_clean 데이터 셋으로 정제된 dataset 생성*/
data shop.users_clean;
	set shop.users_dirty;
	length age_grp $6 email_status $10;
	if missing(age) then age=0;
	if missing(city) then city ='미상';

if age =999 or age<0 then delete;
age_grp=floor(age/10)*10;
format signup_date datetime16.;
run;

/*before - 정제전 데이터 확인 */
proc freq data=shop.users_dirty;
	tables age city /nocum missing;
run;

/*after - 정제전 데이터 확인 */
proc freq data=shop.users_clean;
	tables age city /nocum missing;
run;

title '[s1.2] after - user_clean 상태';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg

from shop.users_clean;
quit;
title;

data work.users_chk;
	set shop.users_dirty;
if missing(age) then age_missing=1;
	else 			age_missing=0;

nmiss_cnt =nmiss(age, total_spent);

cmiss_cnt =cmiss(age,email,city);

if not missing(age) and age>0
then	age_valid=1;
run;

proc print data=work.users_chk(obs=10);
	var age total_spent nmiss_cnt cmiss_cnt age_valid
;run;

/*age 평균으로 결측값 대체 */
proc sql noprint;
	select mean(age),median(age) into: age_mean, :age_med
	from shop.users_dirty
	where age between 1 and 99;
run;
%put 정상 평균 = &age_mean 중앙값 = &age_med;
/*정상 평균 = 34.68155 중앙값 =       34*/

/*age가 결측이면 중앙값으로 대체 >> 결과 확인 user2*/
data user2;
	set shop.users_dirty;
if missing(age) then age= &age_med;
run;

proc print data=user2 (obs=10);
	var age;
run;

proc print data=shop.users_dirty (obs=10);
	var age;
run;

/*이상치를 null로 바꾸고 null 데이터 처리*/
data user3;
	set shop.users_dirty;

	/*이상치 null로 대체*/
	if age = 999 or ag1<1 then age =0;
	if age =. then  age=&age_med;
	
	if missing(city) then city='미상';
	if missing(email) then email='no email';
	if missing(gender) then gender='U';
run;

title '이상치 처리 전';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
	sum(missing(age=999)) as n_age_999,
	sum(missing(age<0)) as n_age_neg

from shop.users_dirty;
quit;
title;

title '이상치 처리 후';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg

from user3;
quit;
title;

proc contents data=shop.users_dirty;
run;

/*coalesces() 함수로 결측값 처리*/
%let personal_email='abcd@naver.com';
data user4;
	set shop.users_dirty;
	/*email 없으면 user_noemail.local*/
	email_fix = coalescec(email,&personal_email,'unknown@unknown');
		/*coalesce숫자 or coalescec문자	(a,b,기본값)*/
	keep user_id user_name email email_Fix;
run;

proc print data=user4(obs=10);
	where missing(email);
run;

/* 결측행 제거*/
data user5;
set shop.users_dirty;
	if missing(age) or missing(city) then delete;
run;

proc sql;
	select count(*) as users_dirty_rows 
from shop.users_dirty;
	select count(*) as user5_rows 
from user5;
quit;

/* 결측진단*/
/*1*/
proc freq data=shop.users_dirty;
    tables age city email / missing;
run;

/*2*/
data work.u_zero;
set shop.users_dirty;
if missing(age) then age=0;
if missing(city) then city='미상';
run;

proc print data=u_zero;
if missing(age) or missing(city)
run;
/*3*/
proc sql noprint;
    select mean(age) into :age_mean
    from shop.users_dirty;
quit;

data work.u_mean;
    set shop.users_dirty;
    age_mean = &age_mean; 
run;
/*4*/
data work.u_coalesce;
	set shop.users_dirty;
	age= coalesce(age,&age_mean);
	city= coalesce(city, '미상');
	email= coalesce(email, 'unknown');
run;
/*5*/
data work.u_delete;
	set shop.users_dirty;
	if missing(age) then delete;
run;

title'[s2.6-5] step 5-4가지 방법 행 수 비교';
proc sql;
	select 'u_zero' as ds length=15,
count(*) as n from work.u_zero
union all select 'u_mean', count(*) from work.u_mean
union all select 'u_coalesce', count(*) from work.u_coalesce

union all select 'u_delete', count(*) from work.u_delete
;quit;
title;

/* session 3 이상치 처리(제거) */
/* IRQ 기준으로 범위 지정 */
proc means data =shop.users_dirty n min max;
	var age;
run;

/* 1) 단순 값 제거*/
data u_no_outlier;
	set shop.users_dirty;
	if age = 999 then delete;
	if age <0 then delete;
	if age >120 then delete;
run;
proc means data=u_no_outlier n min max;
	var age;
run;

/*IRQ 기준으로 범위 지정*/
proc means data=shop.users_dirty n min max;
	var age;
run;

/* IRQ 기준으로 제거*/
proc univariate data= shop.users_dirty;
	var age;
run;
%let q1=27;
%let q3=46;

proc sql noprint;
	select min(age), max(age), pctl(25,age),pctl(75,age)
	into :age_min, :age_max, :age_q1, :age_q3
from shop.users_dirty
where age>00;
quit;
%put &age_q1 &age_q3;

%let iqr =%sysevalf(&age_q3-&age_q1);
%let lo = %sysevalf(&age_q1 -1.5*&iqr);
%let hi= %sysevalf(&age_q3+1.5*&iqr);

%put &iqr &lo &hi;
/*where 절과 if 절의 차이 속도*/
/* 1. proc summary 로 통계량(min, max, q1, q3) 구하기 */
proc summary data=shop.users_dirty noprint;
    where age > 0; /* 필요 시 이상치/정상 범위 조건 지정 */
    var age;
    output out=work.age_stats
        min=age_min
        max=age_max
        q1=age_q1
        q3=age_q3;
run;

/* 2. 계산된 통계량을 매크로 변수에 저장 */
data _null_;
    set work.age_stats;
    call symputx('age_min', age_min);
    call symputx('age_max', age_max);
    call symputx('age_q1', age_q1);
    call symputx('age_q3', age_q3);
run;

/* 3. IQR 및 상/하안 경계값 계산 */
%let age_iqr = %sysevalf(&age_q3 - &age_q1);
%let lower_bound = %sysevalf(&age_q1 - 1.5 * &age_iqr);
%let upper_bound = %sysevalf(&age_q3 + 1.5 * &age_iqr);

/* 4. 결과 확인 */
%put =========================================;
%put [기본 통계량];
%put 최소값(Min)   : &age_min;
%put 최대값(Max)   : &age_max;
%put 1사분위수(Q1) : &age_q1;
%put 3사분위수(Q3) : &age_q3;
%put -----------------------------------------;
%put [IQR 및 이상치 경계값];
%put 사분위범위(IQR) : &age_iqr;
%put 하안 경계값(Lower Bound) : &lower_bound;
%put 상안 경계값(Upper Bound) : &upper_bound;
%put =========================================;

data work.orders_no_outlier;
	set shop.orders_dirty;
	if age > &hi then delete;
	if age < &lo then delete;
run;

/* orders_dirty 데이터셋에서 이상치 제거 IRQ 기준 
	하한과 상한을 검색한 뒤 화면에 출력,
	orders_dirty에 적용한 뒤 orders_clean 생성*/
PROC IMPORT DATAFILE="/home/student/shop_csv/orders_dirty.csv"
	OUT = shop.orders_dirty 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

proc summary data= shop.orders_dirty noprint;
	where total_amount>0;
	var total_amount;
	output out= work.total_amount_stats
	min= ta_min
	max=ta_max
	q1=ta_q1
	q3=ta_q3
;run;

data _null_;
	set work.total_amount_stats;
	call symputx('ta_min', ta_min);
	call symputx('ta_max', ta_max);
	call symputx('ta_q1',ta_q1);
	call symputx('ta_q3',ta_q3);
run;

%let ta_iqr =%sysevalf(&ta_q3-&ta_q1);
%let lo_ta=%sysevalf(&ta_q1-1.5*&ta_iqr);
%let hi_ta=%sysevalf(&ta_q3+1.5*&ta_iqr);


%put =========================================;
%put [기본 통계량];
%put 최소값(Min)   : &ta_min;
%put 최대값(Max)   : &ta_max;
%put 1사분위수(Q1) : &ta_q1;
%put 3사분위수(Q3) : &ta_q3;
%put -----------------------------------------;
%put [IQR 및 이상치 경계값];
%put 사분위범위(IQR) : &ta_iqr;
%put 하안 경계값(Lower Bound) : &lo_ta;
%put 상안 경계값(Upper Bound) : &hi_ta;
%put =========================================;

/*orders_dirty 데이터셋에서 이상치 제거 IRQ 기준 하안과 상한을
검색한뒤 화면에 출력 ,orders_dirty에 적용한뒤 orders_clean 생성
total_amount*/
proc means data=shop.orders_dirty;
	where total_amount>0;
	var total_amount;
	output out =orders_status
	min=t_min
	max=t_max
p25=t_q1
p75=t_q3;

run;

proc sql;
	select t_q1, t_q3 into :t_q1, :t_q3 from orders_status;
quit;

%put IQR: &iqr, lo_t: &lo, hi_t:&hi;

%let iqr = %sysevalf(&t_q3 -&t_q1);
%let lo = %sysevalf(&t_q1-1.5*&iqr);
%let hi = %sysevalf(&t_q3+1.5*&iqr);

data orders_clean;
    set shop.orders_dirty;
    
proc means data=shop.orders_dirty n mean std min max q1 q3 maxdec=2;
    where total_amount > 0; /* 필요한 경우 조건 지정 */
    var total_amount;
    title "total_amount 기본 통계량 분석 (Q1, Q3 포함)";
run;

/* 1. 1%와 99% 백분위수 계싼 후 테이블로 저장*/
proc means data=shop.users_dirty;
	where age>0 and age <99;
	var age;
	output out=work.age_pctl p1=age_p1 p99=age_p99;
run;

/*2. 매크로 변수에 저장*/
proc sql noprint;
	select age_p1, age_p99
	into :age_p1, :age_p99
	from work.age_pctl;
quit;

data users_clean;
	set shop.users_dirty;
	if age< &age_p1 then age = &age_p1;
	if age> &age_p99 then age = &age_p99;
if age =999 then age=&age_p99;

run;

proc means data=users_clean n mean min max nmiss;
	var age;
run;

/*비대칭 분포 정규화*/
data work.orders_log;
	set shop.orders_dirty;
	where total_amount>0;
	amt_log=log(max(0,total_amount)+1); /*max는 마이너스대비해서 해놓음*/
run;

proc univariate data =work.orders_log normal noprint;
	var total_amount amt_log;
	histogram total_amount amt_log /normal;
	title '[s3.5]log변환 -정규성개선';
run;

data work.ordeers_back;
	set work.orders_log;
	amt_log =exp(amt_log)-1;
run;

proc univariate data= work.ordeers_back normal noprint;
	var total_amount amt_log;
	title'[s3.55]log변환 -원데이터로';	
histogram total_amount amt_log /normal;
run;

/*session 4 문자 변환함수*/
data work.users_scan;
	set shop.users;
	
length email_id $30 email_dom $30
	city_main $10 city_dist $20;

email_id= scan(email,1,'@');
email_dom=scan(email,2,'@');

email_co=scan(email_dom,1,'.');

city_main=scan(city,1,' ');
city_dist=scan(city,2,'');

run; 

proc freq data=work.users_scan order=freq;
	table email_dom /nocum;
run;

proc freq data=work.users_scan order=freq;
	table city_main /nocum;
run;

proc sql outobs=5;
select email
from shop.users;
run;

proc sql outobs=5;
select email_id
from work.users_scan;
run;

proc freq data=shop.users_dirty ;
	table channel email /nocum;
run;

data users_clean;
    set shop.users_dirty;
	channel = upcase(strip(channel));
    email   = upcase(strip(tranwrd(email, "_at_", "@")));
    city    = upcase(strip(city));

	email_dom = scan(eamil,2,'@');
	city_main = scan(city, 1, ' ');
run;

proc freq data=users_clean nlevels;
	table channel email_dom city_main/nocum;

    title "STEP 5 - 정제 후 주요 변수 유형 수 및 빈도 비교";
run;


/*session 5 날짜 변환*/
data work.users_date;
	set shop.users;
	length _s_str $25;
/*문자를 date로*/
_s_str = strip(vvalue(signup_date));
	signup_d =input(_s_str,anydtdte25.);
	format signup_d yymmdd10.;
/*datetime*/
signup_dt= input(_s_str,anydtdtm25.);
format signup_dt datetime16.;
/*date9*/
d1=input('01JAN2025',date9.);
/*yymmdd*/
d2=input('2025-01-01',yymmdd10.);

format d1 date9. d2 yymmdd10.;
drop _s_str;
run;

proc print data=users_date(obs=10);
	var signup_date signup_d signup_dt d1 d2;
run;

/*put - 날짜(num) >> 문자*/
data work.users_put;
	set users_date;
month_key =put(signup_d, yymmd6.);

signup_kr =put(signup_d,yymmdd10.);

wkday=put(signup_d,downame.);

mon_name=put(signup_d,monname.);
run;

proc freq data=work.users_put;
table month_key/nocum;
run;

/*datepart timepart dhms*/
/* [SESSION 5-2] DATEPART, TIMEPART, 날짜 요소 추출, DHMS 활용 */
data work.users_d;
    set shop.users;
    
    /* 0) 먼저 문자열을 SAS Datetime 숫자값으로 변환해둡니다 */
    _s_str    = strip(vvalue(signup_date));
    signup_dt = input(_s_str, anydtdtm25.); 
    
    /* 1) DATETIME → DATE (DATEPART에는 Datetime 숫자값을 전달) */
    signup_d = datepart(signup_dt);
    
    /* 2) DATETIME → TIME (TIMEPART에는 Datetime 숫자값을 전달) */
    signup_t = timepart(signup_dt);
    
    /* 3) 연·월·일·요일·분기 추출 (Date 숫자값에서 추출) */
    signup_year  = year(signup_d);
    signup_month = month(signup_d);
    signup_day   = day(signup_d);
    signup_wkday = weekday(signup_d); /* 1:일, 2:월, ..., 7:토 */
    signup_qtr   = qtr(signup_d);
    
    /* 4) DATE → DATETIME (DHMS 함수 활용) */
    d_only = input("2025-01-01", yymmdd10.);
    dt_new = dhms(d_only, 10, 30, 0); /* 2025-01-01 10:30:00 생성 */

    /* 포맷 지정 */
    format signup_dt datetime16. signup_d yymmdd10. signup_t time8. d_only yymmdd10. dt_new datetime16.;
    
    drop _s_str;
run;

/* 결과 출력 확인 */
proc print data=work.users_d (obs=10);
    var signup_d signup_t signup_year signup_month signup_day signup_wkday signup_qtr d_only dt_new;
    title "=== Session 5 날짜/시간 함수 변환 결과 (Top 10) ===";
run;

proc print data=shop.users (obs=5);
    var signup_date;
run;

DATA work.users_arith;
SET work.users_d;
/* 1) 3개월후*/
sub_end = INTNX("month", signup_d, 3);
FORMAT sub_end YYMMDD10.;
/* 2) 1년후같은날*/
anniv = INTNX("year", signup_d, 1, "same");
FORMAT anniv YYMMDD10.;
/* 3) 오늘-가입일= 가입후일수*/
days_since = TODAY() -signup_d;
/* 또는*/
days_v2 = INTCK("day", signup_d, TODAY());
/* 4) 가입후개월수*/
months_since = INTCK("month",
signup_d, TODAY());
/* 5) 가입연도*/
IF YEAR(signup_d) >= 2025 THEN new_user = 1;
ELSE				new_user = 0;
RUN;


proc print data= users_arith(obs=10);
	var signup_d sub_end anniv days_since months_since new_user
;run;
data users_date_prep;
    set shop.users_dirty; /* 실제 날짜 값이 채워져 있는 테이블명으로 지정 */

    /* 1. 데이터 타입 및 값에 따른 signup_d(Date) 변환 */
    if vtype(signup_at) = 'C' then do;
        /* 문자형일 경우: Datetime 변환 후 Date 추출 */
        signup_dt = input(strip(vvalue(signup_at)), anydtdtm25.);
        signup_d  = datepart(signup_dt);
    end;
    else do;
        /* 숫자형일 경우: 값의 크기로 Datetime인지 Date인지 판별 */
        if signup_at > 100000000 then signup_d = datepart(signup_at); /* Datetime 숫자 */
        else signup_d = signup_at;                                   /* Date 숫자 */
    end;

    format signup_d yymmdd10.;

    /* [STEP 1~4] 과제 요구사항 수행 */
    signup_year  = year(signup_d);
    signup_month = month(signup_d);
    signup_day   = day(signup_d);
    signup_wkday = weekday(signup_d);

    signup_3m    = intnx('month', signup_d, 3);
    format signup_3m yymmdd10.;

    days_since_signup = intck('day', signup_d, today());

    drop signup_dt;
run;

/* [STEP 5] PROC FREQ */
proc freq data=users_date_prep;
    tables signup_year signup_month / nocum;
    title "STEP 5 - 가입 연도 및 월별 빈도 분석";
run;

/* 결과 출력 */
proc print data=users_date_prep (obs=10);
    var signup_at signup_d signup_year signup_month signup_day signup_wkday signup_3m days_since_signup;
    title "=== 결과 확인 ===";
run;
proc print data=shop.users (obs=5);
    var signup_at;
run;




/*숙제?*/
/*실습 1*/
dATA work.users_imputed;
SET shop.users;
vip_grade   = coalescec(vip_grade, 'none');
total_spent = coalesce(total_spent, 0);    
IF missing(email) THEN email = 'unknown';  
RUN;
/* 보정 전/후 결측 비교 */
PROC MEANS DATA = shop.users NMISS;
VAR total_spent;
RUN;
PROC MEANS DATA = work.users_imputed NMISS;
VAR total_spent;
RUN;

/*실습2*/
pROC UNIVARIATE DATA = shop.orders NOPRINT;
VAR total_amount;
OUTPUT OUT = work.qstat q1=q1 q3=q3;   
RUN;
DATA work.orders_capped;
IF _N_ = 1 THEN SET work.qstat;
SET shop.orders;
iqr   = q3 - q1;
lower = q1 - 1.5 * iqr;
upper = q3 + 1.5 * iqr;
IF total_amount < lower THEN total_amount = lower; 
ELSE IF total_amount > upper THEN total_amount = upper;  /* upper */
RUN;

/*실습 3*/
dATA work.users_clean;
SET shop.users;
name_clean  = compress(name, ' ');           
email_clean = lowcase(STRIP(email));         
email_clean = tranwrd(email_clean,'gmail.co.kr', 'gmail.com');
city_clean  = TRANWRD(city, '서울특별시', '서울'); 
RUN;
PROC FREQ DATA = work.users_clean;
TABLES city_clean / NOCUM;
RUN;

/*실습4*/
DATA work.users_date;
SET shop.users;
가입년 = year(signup_date);              
가입월 = month(signup_date);              
가입주 = WEEK(signup_date);
경과월 = intck('MONTH', signup_date, TODAY());
다음달 =intnx('MONTH', signup_date, 1);          
FORMAT 다음달 YYMMDD10.;
RUN;
PROC FREQ DATA = work.users_date;
TABLES 가입년 / NOCUM;
RUN;

/*실습5*/
pROC format;                                
VALUE $vip_fmt
'vip'      
= '최우수'
'platinum' = '플래티넘'                  
'gold'     = '골드'
'silver'   = '실버'
'bronze'   = '브론즈';
RUN;
PROC PRINT DATA = shop.users (OBS=20) NOOBS;
FORMAT vip_grade $vip_fmt.;                 
VAR user_id name vip_grade total_spent;
RUN;