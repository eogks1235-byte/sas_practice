libname shop_db '/home/student/shop_db';


/*카이제곱 0이면 ㄱ같다? ㅇㅇ독립 자유도?  
크레머계수 
빈도는 freq만 사용 
testp 는 비율 
적합도는 1개
독립성(관계) 동질성(분포)은 여러개
카이제곱 = (관측치-기대치)2/기대치
데이터가작으면 fisher

*/
/*독립성*/
proc freq data=shop_db.users;
	tables gender*channel /chisq;
run;/*
p값 	카이제곱	10	9.5240	0.4832
효과크기 크래머의 V	 	0.0098 관계x*/
/*적합도*/
proc freq data=shop_db.orders;
	tables payment_method /chisq testp=(20 20 20 20 20);
run;/*
Pr > ChiSq	<.0001 =균등하지않다 
20은 적합하지않다
*/
/*동질성*/
proc freq data=shop_db.users;
	tables vip_grade*channel /chisq;
run;/*
카이제곱	20	15.2459	0.7622
크래머의 V	 	0.0087	 
칼럼백분율을 확인하면된다
*/

/*fisher*/
data work.trial_demo;
	input drug $ effect$count;
	datalines;
A success 8
A failure 2
B success 3
B failure 12
;
run;

title'[s1.3-@] Fisher -소표본 임상';
proc freq data=work.trial_demo order=data;
	weight count;
	tabels drug*effect /chisq fisher expected;
run;
title;
/*fisher는 카이제곱보는게아니고 
양측 p값 보는거다*/

/*카이제곱과 자유도+임계값을 비교해서
 카이제곱보다 작으면 귀무가설을 기각한다*/

proc freq data=shop_db.users;
	tables gender*channel /chisq expected nopercent nocol norow
	plots = mosaicplot;
run;
/*
카이제곱	10	9.5240	0.4832
크래머의 V	 	0.0098 
미미하다
*/

data work.ad_purchase;
	input ad_view $ purchase $ count;
	datalines;
yes buy 60
yes nobuy 40
no buy 40
no nobuy 60
;
run;

proc freq data=work.ad_purchase;
	weight count;
	table ad_view*purchase /chisq fisher expected
	nopercent nocol norow 
plots=mosaicplot;
run;
/* 
카이제곱	1	8.0000	0.0047
크래머의 V	 	-0.2000

양측 p값 Pr <= P	0.0071

광고 시청 여부(ad_view)와 구매 여부(purchase) 사이에는 
통계적으로 유의미한 관련성이 있다고 결론지을 수 있습니다.

*/
proc sql;
	create table work.uo as
	select u.gender, o.payment_method
from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id
	where u.gender in('M','F') 
	and o.status='paid'
;
quit;

proc freq data=work.uo;
	table gender * payment_method /chisq expected;
run;
/* expected 기대빈도 추가
카이제곱	4	2.1019	0.7170
크래머의 V	 	0.0036	
통계적으로 유의미한 연관성(차이)이 없다
*/

/* 실습독립성검정
	성별 결제수단별 관계를 검정
	1단계: 데이터셋 생성*/
proc sql;
	create table user_order as
	select u.gender, o.payment_method
from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id
	where u.gender in('M','F') 
	and o.status='paid'
;
quit;

/* 2단계: 두 변수간의 독립성 검정*/
proc freq data=user_order;
	table gender * payment_method /chisq expected
nopercent nocol norow
	plots=mosaicplot;
run;


proc sql;
	create table work.uoo as	
	select u.vip_grade, o.channel 
from shop_db.users u inner join shop_db.orders o 
on u.user_id = o.user_id
	where o.status='paid'
and u.vip_grade is not null;
quit;

proc freq data=work.uoo;
	table vip_grade * channel /chisq expected 
nopercent nocol norow
plots=mosaicplot;
run;
/*
카이제곱	16	18.1206	0.316
크래머의 V	 	0.005
관련이없다 
*/


/*데이터셋생성 :광고와 구매의 관계 */
proc sql;
	create table work.camp_agg as
	select channel,
	sum(clicks) as clicks,
	sum(conversions) as conversions
from shop_db.campaigns
group by channel;
quit;

data work.camp_conv;
	set work.camp_agg;
	converted='Y' ; count=conversions; output;
	converted='N' ; count=clicks-conversions; output;
	keep channel converted count;
run;


title '[s2.6]비즈니스 실습 2 - 광고채널 * 구매전환 독립성(광고 ROI)';
title2 'work.camp_conv (shop_db.campaigns 실측 집계) - channel * converted';
proc freq data=work.camp_conv order=data;
	weight count;
	tables channel*converted /
	chisq nopercent nocol norow expected cellchi2 measures
	plots=mosaicplot;
run;
title;
/*
카이제곱	5	6375.1120	<.0001
크래머의 V	 	0.0485	
*/

data work.small_data;
	input treatment $ outcome $ count;
	datalines;
A success 8
A failure 2
B success 3
B failure 12
;run;
/* proc freq fisher*/
proc freq data=work.small_data;
	tables treatment * outcome/
chisq fisher expected;
run;

proc freq data=work.small_data
	order=data;
weight count;
tables treatment * outcome/
chisq fisher expected
;run;

PROC FREQ DATA=work.small_data
ORDER=DATA;
WEIGHT count;
TABLES treatment * outcome /
CHISQ FISHER EXPECTED;
RUN;

/*신약, 위약*/
data work.drug_trial;
	input drug $ effect $ count;
	datalines;
new success 9
new failure 3
placebo success 4
placebo failure 9
;run;

proc freq data=work.drug_trial order=data;
	weight count;
	tables drug * effect / chisq fisher expected;
run;
/* 약 효과가있다*/


data work.ab_test;
	input design $ click $ count;
	datalines;
A click 7
A nclick 13
B click 14
B nclick 6
;
run;

title'[s3.4]비즈니스 실습 3 - A|B테스트 결제 버튼 (n=40)';
title2 "기대빈도 < 5 >> Fisher's Exact 권장";
proc freq data= work.ab_test order=data;
	weight count;
	tables design*click/ chisq expected fisher measures;
run;
title;title2;
/*기대값보다 크면 좋음 */


data work.smoke_cancer;
	input smoking $ cancer $ count;
	datalines;
yes yes 90
yes no 110
no yes 60
no no 740
;
run;

title'[s4.1] OR+ 95% CL -흡연 vs 폐암 (n=1000)';
proc freq data=work.smoke_cancer order=data;
	weight count;
	tables smoking * cancer/ chisq expected relrisk measures;
run;
title;

/* 모바일 앱 사용자와 이탈과의 관계 >> OR */
proc contents data=shop_db.users;
run;

/* 관련 컬럼 >> signup_device, churn*/
/* device 의 종류 확인 */
proc sql; 
select distinct signup_device from shop_db.users;
quit;
/* mobile, pc, tablet*/

/*검정할 데이터 셋 생성 >> users2*/
data work.user2;
	set shop_db.users;
	if signup_device ='mobile' then app_user='Y';
	else app_user ='N';
run;

proc contents data=work.user2;
run;

proc print data=work.user2(obs=5);
run;

/*user의 app_user(mobile app 사용자)와 churn(이탈율)
 관계검정 odds*/
proc freq data=work.user2 order=data;
	tables app_user * churn/
chisq expected relrisk measures
;run; 
/*오즈비 1포함이면 효과가없다 */

/* 마케팅 수신여부와 재구매 관계*/
/* marketing_consent > 1 이면 
push_exposed > 'Y' 아니면 'N'

repurchase 가 order_count보다 1더 크면 'Y' 아니면 'N'*/
data push_users;
	set shop_db.users;
	
	if marketing_consent = 1 then push_exposed ='Y';
	else push_exposed ='N';

	if order_count >1 then repurchase ='Y';
	else repurchase ='N';
run;
proc freq data=push_users;
	tables push_exposed * repurchase/
chisq expected relrisk measures
;run;

/* 적합도 검정 
session 5 */
/* 고객 등급별 관측이 기대치와 같은지 검정*/
proc freq data=shop_db.users;
	tables vip_grade/chisq testp=(20 20 20 20 20);
run;

title'[s5.2]적합도 - 비균등 가설';
proc freq data=shop_db.users;
	tables channel/ chisq testp=(8 34 4 22 12 20);
run;
title;


/* 층화변수 >> gender , 채널과 결제수단 비교 */
proc sql;
	create table uo as
	select u.gender, u.channel, o.payment_method
from shop_db.users u inner join shop_db.orders o
on u.user_id=o.user_id
where o.status='paid'
and gender in('M','F');
quit;


proc freq data=uo;
	table channel*payment_method /chisq measures expected;
run;

proc freq data=uo;
	table gender*channel*payment_method /cmh relrisk;
run;

proc freq data=uo;
	table gender*channel*payment_method /cmh chisq relrisk;
run;

proc freq data=shop_db.orders order =data;
	tables payment_method /testp=(15 20 50 10 5);
run;

proc freq data=shop_db.orders order =data;
	tables payment_method /chisq testp=(15 20 50 10 5);	
	where year(order_date)=2026;
run;


/*마무으리*/
proc freq data=shop_db.users;
	table channel *vip_grade/chisq expected cellchi2 measures;
run;
/*채널과 등급은 관계 없다*/

data work.campaigns;
	input group $ purchase $ count;
	
	datalines;
yes yes 90
yes no 110
no yes 60
no no 740
;
run;

proc freq data=work.campaigns order=data;
	tables group *purchase /chisq fisher;
run;

proc sql ;
	create table uo as 
select o.device as app_user,u.churn
	from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id;
quit;
proc freq data=uo order=data;
	tables app_user * churn / chisq relrisk measures;
run;









































































































