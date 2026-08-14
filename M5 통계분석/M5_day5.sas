libname shop_db'/home/student/shop_db';

proc contents data=shop_db.users;
run;

/*
	실측결과요약(8시나리오)
	1. 남녀 매출 t-test
	2. pre/post_promo_spent Paired
	3. vip_graded ANOVA
	4. 채널 * 등급 X^2
	5. budget-revenue Pearson
	6. churn Logistic
	7. gender * churn Fisher
	8. 남녀 매출 Wilcoxon
*/ 

/* 1. 남녀 매출은 같다. >> 2. sample ttest : p-value cohen's d*/
title' 2-sample t-test : 남녀매출';
proc ttest data=shop_db.users;
	class gender;
	var total_spent;
	where gender in ('M','F');
run;
title;
/*
Equality of Variances
Method		Num DF	Den DF	F Value	 Pr > F
Folded F	24401	24117	1.01	 0.5934

Method			Variances	DF			t Value		Pr > |t|
Pooled			Equal		48518		0.56		0.5747
Satterthwaite	Unequal		48515		0.56		0.5747
t-value와 Pr>F 를 보면된다
*/

/* 2. pre/post_promo_spent Paired 매출: ttest > Paired */
title 'Paired t-test : 프로모션 전후 매출 ';
proc ttest data=shop_db.users;
	paired post_promo_spent * pre_promo_spent;
run;
title;
/*
DF		t Value		Pr > |t|
49999	212.26		<.0001
*/

/* 3. vip_grade 별 매출 : anova >> gle */
title'[One-Way ANOVA : VIP 등급별 매출]';
proc glm data=shop_db.users;
	class vip_grade;
	model total_spent = vip_grade;
run;
title;
/*
R-Square
0.751848
Source		DF	Type I SS		Mean Square		F Value		Pr > F
vip_grade	4	2.0044201E17	5.0110501E16	37868.6		<.0001
Source		DF	Type III SS		Mean Square		F Value		Pr > F
vip_grade	4	2.0044201E17	5.0110501E16	37868.6		<.0001
*/

/* 4. 채널 * 등급 >> 카이제곱 검정, 빈도 변수:FREQ*/
title '채널과 등급간의 차이';
proc freq data= shop_db.users;
	tables channel * vip_grade /chisq;
run;
title;
/*
칼럼백분율 행백분율 확인 
통계량	자유도	값		Prob
카이제곱	20		15.2459	0.7622
크래머의 V	 	0.0087	
*/
DATA work.ads;
   SET shop_db.campaigns;
   IF clicks      > 0 THEN cpc = budget / clicks;         ELSE cpc = .;
   IF conversions > 0 THEN cpa = budget / conversions;    ELSE cpa = .;
   IF budget      > 0 THEN roi = (revenue - budget) / budget; ELSE roi = .;
   month = MONTH(start_date);
   IF      month IN (3,4,5)  THEN season = 1;   /* 봄 */
   ELSE IF month IN (6,7,8)  THEN season = 2;   /* 여름 */
   ELSE IF month IN (9,10,11) THEN season = 3;  /* 가을 */
   ELSE                            season = 4;  /* 겨울 */
   LABEL cpc    = '클릭당비용(CPC)'
         cpa    = '전환당비용(CPA)'
         roi    = '광고ROI'
         season = '시즌(1봄 2여름 3가을 4겨울)';
RUN;

/* 5 광고비와 매출간의 상관관계 */
title 'Pearson r >> 광고비 매출';
proc corr data= work.ads;
	var budget revenue;
run;
title;
/*
피어슨 상관 계수, N = 50
H0: Rho=0 가정하에서 Prob > |r|
 		budget	revenue
budget	
		1.00000
 
				-0.02183
				0.8804
revenue	
		-0.02183
		 0.8804
				1.0000
*/
/*"예산(budget)과 수익(revenue) 사이에는 
통계적으로 유의미한 상관관계가 전혀 없다."*/
/* 5-1 전환과 매출간의 상관관계*/
title 'Pearson >> 전환 매출';
proc corr data=work.ads;
	var conversions revenue;
run;
title;
/*
피어슨 상관 계수, N = 50
H0: Rho=0 가정하에서 Prob > |r|
 			conversions	revenue
conversions	
			1.00000
				 
					0.86877
					<.0001
revenue	
			0.86877
			<.0001
					1.00000
*/

/*이탈 예측 >> logiscit 이진 분류 */
proc logistic data= shop_db.users;
	class gender (param=ref ref='M');
	model churn (event='1')= age total_spent gender;
run;
/*
Testing Global Null Hypothesis: BETA=0
Test				Chi-Square	DF	Pr > ChiSq
Likelihood Ratio	2.6965		4	0.6098
Score				2.6784		4	0.6130
Wald				1.0704		4	0.8989
*/
/*
Analysis of Maximum Likelihood Estimates
Parameter	 	DF	Estimate	Standard
								Error		Wald
											Chi-Square	Pr > ChiSq
Intercept	 	1	1.6392		0.0449		1331.1546	<.0001
age	 			1	0.000392	0.00114		0.1173		0.7319
total_spent	 	1	6.777E-9	5.365E-9	1.5962		0.2064
gender	F		1	0.0136		0.0249		0.2967		0.5860
gender	U		1	0.0665		0.0749		0.7893		0.3743
*/
/*
Odds Ratio Estimates
Effect		Point Estimate	95% Wald
						Confidence Limits
age				1.000	0.998	1.003
total_spent		1.000	1.000	1.000
gender F vs M	1.014	0.965	1.064
gender U vs M	1.069	0.923	1.238
*/

/*소 표본 분할 >> gender, churn >> fisher*/
proc freq data=shop_db.users;
	tables gender * churn /fisher;
	where gender in('M','F');
run;
/*
카이제곱	1		0.2978	0.5853
크래머의 V	 	-0.0025	

	Fisher의 정확 검정
(1,1) 셀 빈도(F)		3829
하단측 p값 Pr <= F	0.2969
상단측 p값 Pr >= F	0.7116
 	 
테이블 확률 (P)		0.0086
양측 p값 Pr <= P		0.5923
*/

/*8.비정규 그룹 >> npar1way*/
proc npar1way data=shop_db.users wilcoxon;
	class gender;
	var total_spent;
	where gender in ('M','F');
run;

title' 2-sample t-test : 남녀매출';
proc ttest data=shop_db.users;
	class gender;
	var total_spent;
	where gender in ('M','F');
run;
title;

/*연속 정규 ttest anova logistic

*/



































































































