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

