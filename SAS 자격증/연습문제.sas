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
      6) 발생 유역(basin)별 최대 풍속(MaxWindMPH)별로 데이터를 정렬하세요
		(최대 풍속은 내림차순 정렬하여 발생 유역별 최대 풍속 확인)
	  7) StartDate mmddyy 형태로 리포트에 표시하세요
***********************************************************/
proc print data=pg1.storm_summary ;
	format startdate mmddyy10.
	;
run;

proc sort data=pg1.storm_summary out=work.storm_summary;
	by basin descending MaxWindMPH;
run;

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
 


/***********************************************************
   4. Preparing Data (데이터 준비)
     - pg1.storm_summary ==> work.storm_new 생성
      1) 최대 풍속의 단위 변경 (MaxWindKM) - maxWindMPH*1.60934
      2) 폭풍기간(storm_days) - 종료일과 발생일의 차이 
      3) 발생유역(basin) 칼럼의 값 클린징 - 모든 대문자 변경
      4) 폭풍이름(name) 칼럼의 값 클린징 - 단어기준 대소문자 적절하게
      5) 발생지역칼럼 생성 (EWNS) - Hem_NS, Hem_EW 문자열 연결
      6) 발생대양 생성(Ocean) - Basin의 두번째 위치 값 추출
      7) 폭풍발생월(Month) - 발생일(startDate)에서 월정보 추출
      8) 칼럼 제거  : Hem_NS, Hem_EW, Lat, Lon

     - pg1.storm_summary ==> work.storm_new2 생성 
      1) 최저기압(MinPressure)의 범주화 칼럼 생성  (각 숫자,문자로 생성)
          Grp_MP_N - 결측값이 경우 : .       , 920 이하인 경우 : 1     , 920 초과 : 2
          Grp_MP_C - 결측값이 경우 :'NaN' , 920 이하인 경우 : 'Low', 920 초과 : 'High'
         
***********************************************************/
proc print data=pg1.storm_summary (obs=10);
run;
data work.storm_new;
	set pg1.storm_summary;
	MaxWindKM=maxWindMPH*1.60934;
	format StartDate EndDate yymmdd8.;
	/*format은 껍데기 input으로 문자를 >> 숫자로 변경해야한다
	real_date = input(char_date, yymmdd10.);*/
	storm_days=EndDate -StartDate;
	basin=upcase(basin);
	name=upcase(substr(name,1,1));/*propcase()*/
	ewms=Hem_NS||Hem_EW;/*cats()로해야 공백도 삭제된다*/
	ocean=substr(basin,2,1);
	month=month(startdate);
	drop Hem_NS Hem_EW Lat Lon;
run;

data work.storm_new2;
    set pg1.storm_summary;
    length grp_mp_c $5;

    
    if missing(minpressure) then grp_mp_n = .;
    else if minpressure <= 920 then grp_mp_n = 1;
    else grp_mp_n = 2; 
    
    if missing(minpressure) then grp_mp_c = 'NaN';
    else if minpressure <= 920 then grp_mp_c = 'Low';
    else grp_mp_c = 'High';
run;



/***********************************************************
   5. Analyzing and Reporting on Data (요약 리포트 생성)
     1) 폭풍 이름으로 가장 많이 사용된 이름은?
     2) 발생유역(basin)과 폭풍유형(type)에 대한 교차 빈도표 작성
     3) 발생유역(basin)별 최대풍속의 
          요약통계량 ( 건수, 평균, 중위수, 최대, 최소값) 생성
     4) 발생유역(basin)별 최대풍속의 평균/중위수에 차이가 가장 큰 유역은?
***********************************************************/

































