%let root = /home/student;

libname shop '/home/student/shop_db';
libname shop '&root/shop_db';
/*shop.users 가져와서 user_copy로*/

data user_copy;
	set shop.users;
run;

proc sql outobbs=20;
	select user_id, name, age, gender, city, channel
from user_copy;
quit;

/* proc print 로 변경*/
title 'users를 복사한 user_copy 의 정보';
proc print data=user_copy(obs=5);
	var user_id name age gender city channel;
/*var는 컬럼사이 콤마(,)사용안함
 =keep or drop*/
run;
title; /*초기화해주기*/

/* 중간 결과는 work 에 tax=total_spent * 0.1 */
data users;
	set shop.users;
	tax=total_spent*0.1;
run;
/*데이터셋 WORK.USERS에 50000개의 관측값과
 16개의 변수가 있습니다.
변수추가과정*/

data shop.users_tax;
	set users;
run;
/*work에 저장되는게 아닌 shop에 고정 저장 되는과정
quit; 까지해주어야 탐색기에 뜬다*/

proc print data=shop.users_tax;
run;
quit;

/* shop.users 에서 user_id name age channel 컬럼만 추출*/
data users_kept;
	set shop.users;
	keep user_id name age channel;
run;
/*데이터셋 WORK.USERS_KEPT에 50000개의 관측값과
 4개의 변수가 있습니다.*/

/* total_spent order_count churn marketing_consent 컬럼 제외*/
data users_dropped;
	set shop.users;
	drop total_spent order_count churn marketing_consent;
run;
/* 데이터셋 WORK.USERS_DROPPED에 50000개의 관측값과
 11개의 변수가 있습니다.*/

title '[s1.3] keep 결과 - 4 컬럼';
proc print data=work.users_kept(obs=5) noobs; run;
/*noobs란 인덱스 번호? 행개수? 안보이게하는것 */

title '[s1.3] drop 결과 - 4 컬럼 제거';
proc print data=work.users_dropped(obs=5) noobs;
	var user_id name age city channel vip_grade;
run;
title;

title 'users_kept과 users_dropped ->union all';
data users_2025;
	set shop.users;
	where signup_date between '01JAN2025'd and '31DEC2025'd;
run;

data users_2026;
	set shop.users;
	where signup_date between '01JAN2026'd and '31DEC2026'd;
run;

data users_all;
set users_2025
users_2026;
run;

data users_tagged;
	set users_2025 (in=y25)
	users_2026(in=y26);
if y25 then src = '2025';
else if y26 then src='2026';
run;

proc sort data=users_tagged nodupkey;
by user_id;
run;
/*nodupkey중복값 제거*/

proc print data=shop.orders(obs=5) noobs;
	var user_id order_id order_date;
run;

PROC IMPORT DATAFILE="/home/student/shop_csv/orders.csv"
	OUT = shop.orders 	/*shop라이브러리에 orders만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

/* csv to sas macro*/
%let CSVDIR=/home/student/shop_csv;
%macro imp(name=);
	proc import datafile='&CSVDIR/&name..csv'
				out=shop.&name
				dbms=csv
				replace;
		getnames=yes;
		guessingrows=max;
	run;
%put note: ===== &name..csv -> shop.&name 변환 완료 =====;
%mend;

%imp(name=orders);
%imp(name=categories);

data orders_2025;
	set shop.orders;
	where order_date between '01JAN2025'd and '31DEC2025'd;
run;

data orders_2026;
	set shop.orders;
	where order_date between '01JAN2026'd and '31DEC2026'd;
run;

/* session 2 */
data work.users_safe;
	length email $50;
	set shop.users;

	/*1. missing 함수*/
	if missing(age) then age=0;
	if missing(email) then email='no-email';

	/*2. coalesce - 첫 비결측*/
	age_safe =coalesce(age,0);
	email_safe= coalesce(email,'unknown');

	/*3. 행내 결측 개수*/
	missing_cnt =nmiss(age,email,email_safe);

	/*4. 결측 행 자체를 제외*/
	if missing(age) then delete;
run;

data work.users_calc;
	set shop.users;
	age_dec =floor(age/10)*10;
	spent_won_k =round(total_amount/1000,1);
	age_next =age+1;
	keep user_id name age age_dec age_next total_amount
	spent_won_k;
run;
title '[s2.1] 새 변수 - 연령대 천원 매출';
proc print data=work.users_calc(obs=8) noobs; run;
title;

/*결측치 처리*/
data work.users_filled;
	set shop.users;
	if missing(last_login_date) then do;
	last_login_flag=1;
end;
	else last_login_flag=0;

if missing(city) then city ='미상';
if missing(age) then age=0;
keep user_id name age city last_login_date last_login_flag;
run;

title'[s2.2] 결측 보정 - last_login 미접속 플래그';
proc freq data=work.users_filled;
	tables last_login_flag /nocum;
run;
title;

/*문자열자르는거책에서찾아보기*/

/* session 3*/
data user_grp;
	length age_grade $20;
	set shop.users;
	if missing(age)  then age=0;
	if age < 20 then age_grade= '10대';
	else if age < 30 then age_grade= '20대';
	else if age < 40 then age_grade= '30대';
	else if age < 50 then age_grade= '40대';
	else age_grade = '40대+';
	if age >=30;
	
keep user_id name age age_grade;
run;
 
title'[s3.1] if/then/else -4단계 연령 분류';
proc print data=user_grp(obs=5);
run;
proc freq data=user_grp;
	table age_grade /nocum
;run;
title;

/* and or not notin 하기*/

/* 조건 분기 select ~ when ~ end*/
data work.users_cohort;
	length cohort $20;
	set shop.users;
	select;
	when (age<=25) cohort ='z세대';
	when (age<=35) cohort ='밀레니얼';
	when (age<=50) cohort ='x세대';
	otherwise cohort ='베이비붐'
;end;
keep user_id name age cohort;
run;

/*세대별 인원수, 비율*/
proc freq data=users_cohort;
	tables cohort ;
run;

/*실습 3*/
data user_grp;
/* 	length age_grade $20; */ /*40대+ 안나옴*/
	set shop.users;
	if missing(age)  then age=0;
	if age < 20 then age_grade= '10대';
	else if age < 30 then age_grade= '20대';
	else if age < 40 then age_grade= '30대';
	else if age < 50 then age_grade= '40대';
	else age_grade = '40대+';
	if age >=30;
	
keep user_id name age age_grade;
run;

data user_grp;
	length age_grade $20;  /*40대+ 안나옴*/
	set shop.users;
	if missing(age)  then age=0;
	if age < 20 then age_grade= '10대';
	else if age < 30 then age_grade= '20대';
	else if age < 40 then age_grade= '30대';
	else if age < 50 then age_grade= '40대';
	else age_grade = '40대+';
	if age >=30;
	
keep user_id name age age_grade;
run;

data user_grp;
	length age_grade $20;
	set shop.users;
	if missing(age) then age=0;
	select ;
	when (age<20) age_grade='10대';
	when (age<30) age_grade='20대';
	when (age<40) age_grade='30대';
	when (age<50) age_grade='40대';
	otherwise	age_grade= '40대+';
end;

keep user_id name age age_grade;
run;

data work.users_good;
	length age_grade $20 metro $10;
	set shop.users;
	if age < 20 then age_grade ='10대';
	else if age <30 then age_grade ='20대';
	else if age <40 then age_grade ='30대';
	else if age <50 then age_grade ='40대';
else age_grade='40대+';

select ;
when(city in('서울','경기','인천')) metro='수도권';
	otherwise metro ='기타';
end;
keep user_id name age age_grade metro;
run;

/*session 4*/
title '[s4.1] obs=5 -users 첫 5행만';
proc print data=shop.users (obs=5) noobs;
run;
title;
title '[s4.2] var -4컬럼만';
proc print data=shop.users(obs=10) noobs;
	var user_id name age channel;
run;
title;
title '[s4.3] where -30대+ 여성 + 서울';
proc print data =shop.users(obs=10) noobs;
	where gender ='F' and age>=30 and city='서울';
	var user_id name age channel vip_grade total_spent;
run;
title;
title '[s4.4] sum- vip 사용자 매출 합계';
proc print data=shop.users (obs=20) noobs;
	where vip_grade in('platinum', 'vip');
	var user_id name vip_grade total_spent order_count;
	sum total_spent order_count;
run;
title;

/*1) 전체 합계*/
data work.orders;
	set shop.orders;
run;

proc print data =work.orders(obs=10);
	var order_id user_id total_amount;
	sum total_amount;
run;

proc sort data=work.orders;
by statuts;
run;

proc print data=work.orders;
by status;
var order_id total_amount;
sum total_amount;
sumby status;
run;/*sumby 최종 마미막줄에 합계표시 */

title "[s5.1] where like '김%' -김씨 사용자";
proc print data=shop.users (obs=10) noobs;
where name like '김%';
var user_id name age city channel;
run;
title;

title '[s5.2] between + in 조합';
proc print data= shop.users(obs=10) noobs label;
	where age between 30 and 39
	and channel in('organic', 'paid_search','email');
	ID user_id;
var  name age city channel total_spent;
sum total_spent;
run;
title;

/* 한글 헤더로*/
title '[s5.3] 한글 label로';
proc print data= shop.users(obs=10) noobs label;
/* 	length user_id $10 name $20; */
	where age between 30 and 39
	and channel in('organic', 'paid_search','email');
	ID user_id;
var  name age city channel total_spent;
/* sum total_spent; */
label user_id ='고객ID' name='고객명' age='나이'
	city='도시' channel='채널' total_spent='누적매출'
;run;
title;

/* title, title2 ... title10
	footnote, ... ,footnote10*/
title 'organic 채널 30대+ 사용자';
title '데이터: shop_users';
footnote '분석:2026-05-26 / 데이터팀';
proc print data= shop.users(obs=10) noobs label;
/* 	length user_id $10 name $20; */
var name channel age city;

label user_id ='고객ID' name='고객명' age='나이'
	city='도시' channel='채널' total_spent='누적매출'
;run;

/* 보고서 pdf 저장 file명 :M4D1_report&TODAY..pdf" style=journal*/
%let TODAY = %system(today(),yymmddn8.);
ods pdf file='/home/student/m4d1_report&TODAY..pdf' style=journal;
title'[s5.5] PDF 자동 출력 -VIP보고서';
proc print data=shop.users noobs label;
	where vip_grade in('platinum','vip');
var user_id name age vip_grade total_spent order_count;
label user_id ='고객ID' name='고객명' age='나이'
	city='도시' channel='채널' total_spent='누적매출'

;sum total_spent order_count;
run;
ods pdf close;
title;

/* 실습5: 고객 id , 이름, email, totla_spent, gender 컬럼 출력
	email= naver.com, 30~50대 사이, 여성만,
	지역은 서울 경기 이외의 지역에 있는 고객정보만
	excel 파일로 저장 -> users_city.excel 파일로 저장
	title -> 수도권 이외의 지역에 사는 여성 고객 정보 
	footnote -> 2026.07.31 작성 
	헤더는 고객id, 이름, 연령, 지역, 성별, 누적매출
	총매출도 출력 */

ods excel file='/home/student/m4d1_report&TODAY..excel' style=journal;
title'[최종] 수도권 이외의 지역에 사는 여성 고객 정보';
footnote '2026.07.31 작성';
proc print data=shop.users noobs label;

where city not in('서울','경기')and email like '%@naver.com' 
and age between 30 and 50 and gender='F';
var user_id name age vip_grade total_spent order_count gender;
label user_id ='고객ID' name='고객명' age='나이'
	city='도시' channel='채널' total_spent='누적매출' gender='성별';
sum total_spent;
run;
ods excel close;
title;