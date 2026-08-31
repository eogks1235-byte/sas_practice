/***********************************************************
  2. Accessing Data  (데이터 접근 - C:\educprog1_v2\data)
      1) SAS Table 
          국제 폭풍 데이터들이 SAS Table로 존재합니다. 
          해당 SAS Table 들을 사용하기 전에 library를 할당합니다.
          (라이브러리 참조 이름 : pg1)
      2) Excel Sheet data
          국제 폭풍 데이터가 storm.xlsx 워크시트 파일에 있습니다.
          xlsx 엔진을 사용하여 엑셀 스프레드 시트를 직접 읽을 수 있도록
          library를 할당합니다. (라이브러리 참조 이름 : xlstorm) 
          2.1)  해당 엑셀파일에 몇 개의 워크시트가 있나요?8개
***********************************************************/


libname pg1 v9 '/home/u64579251/pg1';

libname xlstorm xlsx '/home/u64579251/pg1/storm.xlsx';


/***********************************************************
   3. Exploring Data (데이터 탐색)
       - pg1.storm_summary 테이블 탐색
      1) 처음 10건 중 폭풍 이름에 결측값이 존재하나요? 네
      2) 폭풍의 최대 풍속/최저기압이 측정된 폭풍수는? 평균은?
      변수	N	 평균	
MaxWindMPH  3095 79.3179321
MinPressure 2922 961.8545517
      3) 폭풍의 최대풍속 극소/극대값 5개씩 각 값은?
	극 관측값
최소		최대
값	관측값	값	관측값
6	2659	184	702
17	1960	184	1477
23	2757	184	2164
23	1366	190	6
23	1103	213	3017
      4) 폭풍이 발생한 유역(basin), 유형(type), 시기(season)별
         고유값이 각 건수는?
변수 레벨 수
변수	레벨
Basin	7
Type	5
Season	37
------------------------------------------------------------
      5) 아래 조건을 만족하는 폭풍에 대한 
           5.1) 리스트 (칼럼 : 유역, 이름, 시작일, 종료일, 최대 풍속)
           5.2) 최대풍속/최저기압의 기본 통계량 리포트
        [조건] 최대풍속(MaxWindMPH)이 156 이상이고 
                  발생유역(basin)dl NA 이고
                  발생일(StartDate)가 2000년1월1일 이후 발생한 폭풍
***********************************************************/
%let dl =NA;
%let nal =01Jan2000;

proc print data=pg1.storm_summary;
	var Name Basin MaxWindMPH StartDate EndDate;
	where MaxWindMPH>=156 and basin="&dl" and startdate>="&nal"d;
run;

proc means data=pg1.storm_summary;
	var MaxWindMPH MinPressure;
	where MaxWindMPH>=156 and basin="&dl" and startdate>="&nal"d;
run;

proc print data=pg1.storm_summary (obs=10);
run;

proc means data=pg1.storm_summary;
	var MaxWindMPH	MinPressure
;run;

proc univariate data=pg1.storm_summary;
    var MaxWindMPH;
run;

proc freq data=pg1.storm_summary nlevels;
    tables Basin Type Season;
run;
 


