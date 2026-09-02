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


/* 2일차 */

*3.3 Formatting Columns;
* Format : 컬럼의 값에 옷을 입히는 것.
 컬럼의 값이 변하는 것이 아니고, 컬럼의 값을 표시하는 방식을 지정하는 것(출력 형식);

proc print data=pg1.class_birthdate;
	format height weight 3. birthdate date9.;
run;

proc print data=pg1.class_birthdate;
	format height weight 3. birthdate yymmdd10.;
run;

* 2026-09-01 : yymmdd(d)10.  d가 생략decimal;
* 2026/09/01 : yymmdds10. ;
* 2026.09.01 : yymmddp10. ;
* 20260901   : yymmddn8.  ;
* 2026년 09월 01일 : nldate. ;


*3.4 ;
proc sort data = pg1.class_test2 out=work.class_test2;
	by name /* 정렬기준 */;
run;

* 이름별, 시험 점수(TestScore);
proc sort data =pg1.class_test2 out=work.class_test3;
	by name TestScore;
run;

* 시험 과목별로 가장 시험을 잘 본 학생이 누구인지 확인 ;
proc sort data=work.class_test3;
	by subject descending testscore name;
run;

* descending 은 바로 뒤에 오는 컬럼에만 영향 있음;

* 중복 제거;
proc sort data= pg1.class_test3 out=work.test_clean
	nodupkey
	dupout=work.test_dup;
	by _all_;
run; *NOTE: 중복 키값을 가지고 있는 1개의 관측값이 삭제되었습니다.;


* Lesson 4. Preparing Date;
* 4.1;

data work.myclass; /* output (저장위치)*/
	set sashelp.class; /* input file */
	where age >=15; /* 행필터링 */
/* drop(버리기) 과 keep(유지)*/
	keep name age height; /* 컬럼 필터링 */
run;

/* format 
data step에서의 format : 영구적인 format. data step에서 format적용 시,
컬럼의 속성 정보로서 format이 적용됨. 따라서 해당 데이터셋 자체에 format이 입혀짐.
데이터셋 자체에 format이 적용되어, 별도의 format을 적용하지 않아도, 데이터 셋에 적용된 format 기준으로 값이 출력됨;

proc step에서의 format : 일시적인 format. proc step에서 format 적용 시,
해당 proc step에 의해 출력되는 report만 한시적으로 그 format이 적용됨.
해당 proc step이 종료되면, 더 이상 format은 적용되지 않음.
입력 데이터 셋에 이미 영구적인 format이 있는 경우에도 proc step에서 새로운 format을 적용하면
proc step의 format이 우선 적용된다
*/

proc contents data=work.myclass varnum;
run;

data work.myclass; /* output (저장위치)*/
	set sashelp.class; /* input file */
	where age >=15; /* 행필터링 */
/* drop(버리기) 과 keep(유지)*/
	keep name age height; /* 컬럼 필터링 */
	format height 3.;
run;


proc contents data=work.myclass varnum;
run;

proc print data=work.myclass;
run;

*4.2;
data work.cars_new;
	set sashelp.cars;
	where origin ^=/*=ne*/ "USA";
	keep make model msrp invoice profit source;
	drop make;
	profit =msrp - invoice; /* 파생변수는 keep에 있어야 출력된다*/
	source="Non-US Cars";
	format profit dollar10.;
run;


/*PDV(Program Data Vector)
인풋과 아웃풋 사이 테이블이 만들어지는 공간 
초기에 초기화하고 시작 
두번째행부터는 새로운컬럼에 대해서만 재초기화 진행 RETAIN (값 유지 명령어)
(Iteration)
*/
data work.cars_new;
	set sashelp.cars;
	where origin ^=/*=ne*/ "USA";
	keep make model msrp invoice profit source;
	drop make;
	profit =msrp - invoice; /* 파생변수는 keep에 있어야 출력된다*/
	source="Non-US Cars";
	if profit>=3000;
	format profit dollar10.;
run;

/*데이터생성시 where 조건이 있는데 신규컬럼에도 조건을 주고 싶을떄 if 를 사용하면 된다*/

/* 컬럼여러개 계산 ex)mean(of x1-x100) of 필수
컬럼명이 다를경우 (of x1--q2) --두개 */


data work.test;
	t=today();
	m=mdy(09,01,2026);
	format t m yymmdd10.;
run;

/* mdy(1,15,1960)
15-1=14 */

/* input : sashelp.csrs; 
	output : work.cars2;
	
조건 : msrp가 60000마만이면, cartype이라는 칼럼을 생성하요 basic이라는 문자열을 할당
msrp가 60000 이상이면, cartype 칼럼에 luxury문자열 할당

칼럼선택 :make model msrp cartype
	*/	
	
data work.cars2;
	set sashelp.cars;
	length cartype $10;
	cartype= ' ';/*변수지정안해도 된다*/
	if msrp <60000 then cartype='basic';
	else if msrp >=60000 then cartype='luxury';
keep make model msrp cartype;
run;
/* length 문장은 작성하는 위치가 중요한 문장! 길이를 변경하고자 하는 컬럼이 생성되기 전까지 선언되어야 함 
	컬럼 속성 정보가 결정되면, 변경할 수 없다. 
	새로운 컬럼을 생성할 때, length 문장을 함께 선언해 주는 것이 좋은 습관 */


data work.under40 work.over40;
	set sashelp.cars;
	keep make model msrp cost_group;
	if msrp <20000 then do;
		cost_group =1 ;
		output work.under40;
	end;
	else if msrp <40000 then do;
		cost_group =2 ;
		output work.under40;
	end;	
	else do;
		cost_group =3 ;
		output work.over40;
	end;	
run;

/* lesson 5. Analyzing and reporting on data
	5.1*/
proc print data = sashelp.cars(obs=10) label;/*label보고싶으면 label 적어야함*/
	var make msrp mpg_highway;
	label msrp ='소비자 가격' mpg_highway='고속도로 주행 연비';
run;

/* label : 컬럼명에 옷을 입히는 것 물리적인 칼럼명이 변경되는 것은 아님
칼럼에 대한 설명을 입히는 것.*/

/* proc step의 label은 임시적 label, data step의 label은 영구정 label임 */


proc print data = sashelp.cars(obs=10) label split=' ';/*label보고싶으면 label 적어야함*/
	var make msrp mpg_highway;/*split = 스플릿에 할당된 것을 만나면 줄바꿈해준다*/
	label msrp ='소비자 가격' mpg_highway='고속도로 주행 연비';
run;

/* data step에서 적용한 라벨이 있다고 하더라도, proc step에서 라벨을 새로 적용하면,
리포트는 proc step의 라벨을 출력함 -- 시험출제!!*/

* 5.2;
proc freq data=pg1.storm_final order=freq nlevels;
	tables basinname startdate / nocum;
	format startdate monname.; /*지린다*/
run;


proc freq data=sashelp.heart;
	tables bp_status*chol_status / norow nocol nopercent;
run;


/* 5.3 */
proc means data=pg1.storm_final maxdec=0 min q1 median q3 max sum std mean ;
	var maxwindMPH; /* 분석변수 */
	class basinname stormtype; /*group by 분류 변수 */
	ways 0; /*분석변수 분류변수 조화 */
	/* 0 1 2 분류변수x 전체토탈, var1 class1, var1 class2 변수조합*/
run;

/* lesson 6. Exporting result */
proc export data=sashelp.cars outfile='/home/u64579251/pg1/cars.xlsx'
	dbms=xlsx replace;
run;


/* 6.2
 리포트 내보내기 */
ods pdf file='/home/u64579251/pg1/mydata.pdf';
ods excel file='/home/u64579251/pg1/mydata.xlsx';
ods powerpoint file='/home/u64579251/pg1/mydata.pptx';
proc means data=pg1.storm_final maxdec=0 min q1 median q3 max sum std mean ;
	var maxwindMPH; /* 분석변수 */
	class basinname stormtype; /*group by 분류 변수 */
	ways 0; /*분석변수 분류변수 조화 */
	/* 0 1 2 분류변수x 전체토탈, var1 class1, var1 class2 변수조합*/
run;
ods powerpoint close;
ods excel close;
ods pdf close;




