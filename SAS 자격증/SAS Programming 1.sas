/* ------------------ */
/* 작성일자 2026-08-31 */
/* ------------------ */
data test;
	x=1;
	y='Test';
run;

/* 정렬 숫자는 오른쪽 */
/* 문자는 왼쪽 */
/* proc print data=test; */
/* run; */

proc means data=test;
run;

/* Ctrl + Shift + U */
/* Ctrl + Shift + l */
/* Ctrl + / */
/* Ctrl + Shift +  */

/* session 2: Descriptor Portion 확인 */
proc contents data= '/home/u64579251/pg1/class_birthdate.sas7bdat';
run;
/*  */
/* 변수와 속성 리스트(오름차순) */
/* #	변수	유형	길이 */
/* 3	Age	숫자	8 */
/* 6	Birthdate	숫자	8 */
/* 4	Height	숫자	8 */
/* 1	Name	문자	8 */
/* 2	Sex	문자	1 */
/* 5	Weight	숫자	8 */
proc contents data= '/home/u64579251/pg1/class_birthdate.sas7bdat' varnum;
run;
/* 변수(생성 순서) */
/* #	변수	유형	길이 */
/* 1	Name	문자	8 */
/* 2	Sex	문자	1 */
/* 3	Age	숫자	8 */
/* 4	Height	숫자	8 */
/* 5	Weight	숫자	8 */
/* 6	Birthdate	숫자	8 */


* 사용자 정의의 라이브러리 생성;
libname pg1 v9 '/home/u64579251/pg1';
/* v9? 엔진명 디폴트라서 생략가능 */
libname pg1 base '/home/u64579251/pg1';
/* v9 = base = 생략  택1 가능 */

proc contents data=pg1.class_birthdate varnum;
run; 	/* 확장자명 없어도 가능 라이브러리에 들어가면 경로 따옴표없어도가능*/

proc contents data=pg1._all_ nods;
run;	/*라이브러리 전체 뽑기 nods= 특정라이브러리 내의 테이블 리스트 추출*/


libname xlclass xlsx'/home/u64579251/pg1/class.xlsx';

proc contents data=xlclass.class_birthdate varnum;
run;

libname xlclass clear; /*라이브러리해지*/

* option validvarname = any ;
/* 컬럼명에 특수문자, 한글 포함가능하게 하는 방법 */


/* Name,Sex,Age,Height,Weight,Birthdate */
/* Alfred,M,14,69,112.5,10/26/2004 */
/* Alice,F,13,56.5,84,11/16/2005 */
proc import datafile='/home/u64579251/pg1/class_birthdate.csv'
	dbms=csv /*파일유형*/
	out=work.class_b
	replace;/*같은이름있으면 덮어쓰기*/
	guessingrows=max;/*테이터타입추측 max는 모든행보고*/
	getnames=yes;/*첫행(레코드)컬럼 이름으로 지정*/
run;


/* excel 파일 읽어오기 - by import */
proc import datafile='/home/u64579251/pg1/class.xlsx'
	dbms=xlsx out=work.class replace;
	sheet = class_test; /*원하는 시트 가져오기*/
run;


*===================================================;
/* Lesson 3. Exploring and Validating */

/* Data Portion */

proc print data=sashelp.cars (obs=10);
	var make model type msrp /* 컬럼선택 및 컬럼이 출력되는 순서를 지정 */
;run;


/* 요약 통계량 산출 */
proc means data=sashelp.cars;
	var horsepower enginesize msrp;
run;


/* 분포 분석 */
proc univariate data=sashelp.cars;
	var mpg_highway;
	histogram mpg_highway;
run;


/* 빈도 분석 */
proc freq data=sashelp.cars;
	tables origin type drivetrain
;run;


*3.2;
*input : sashelp.cars;
*컬럼선택 : Make Model Type;
*행선텍 : Type이 Wagon이거나 SUV이고 MSRP가 30000이상인 경우;

proc print data=sashelp.cars;
	var make model type msrp;
	where (type='Wagon' or type='SUV') and msrp>=30000;
	
run;

/* where age = . */
/* where name = ' ' (blank)*/

/* where age between 20 and 39  */
/* where 20 <= age <= 39 (더보편적)*/
/* where 20 < age < 39 */
/* where name between A and B */


/* Contains : 문자 컬럼에 특정 문자열을 포함하고 있는지 여부 확인, 문자열 위치는 중요하지 않다
like 상위 호환 인거같음*/
/* like : 문자 컬럼에 특정 문자패턴을 포함하고 있는지 여부 확인
			ㅁㄴㅇ			
문자 패턴은 _, %로 정의 된다
한글은 2byte __ 이런식*/

/* step 1 : 매크로 변수 생성 */
%let CarType= Sedan;

/* step 2 : 매크로 변수 사용 */

proc print data= sashelp.cars;
	where type="&CarType";
run;

proc means data= sashelp.cars;
	where type="&CarType";
run;

proc freq data= sashelp.cars;
	where type="&CarType";
run;


