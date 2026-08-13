libname shop_db '/home/student/shop_db';



/* ── [사전 준비] 강의용 분석 뷰 3 개 생성 (모든 세션 재사용) ──────── */

/* (A) work.ads : shop.campaigns 확장 
        · budget · revenue · impressions · clicks · conversions (원본)
        · cpc / cpa / roi / month / season (파생)                       */
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

/* (B) work.uo_sum : shop.users + shop.orders JOIN (Session 2~6 재사용)
       · tenure_days       = TODAY - signup_date (원 강의 tenure 대체)
       · marketing_consent = 0/1 (원 강의 app_user 대체)                 */
PROC SQL;
   CREATE TABLE work.uo_sum AS
   SELECT u.user_id,
          u.age,
          u.gender,
          u.city,
          u.channel,
          u.vip_grade,
          u.marketing_consent                                LABEL='마케팅수신동의',
          u.total_spent,
          u.order_count                                      LABEL='총주문건',
          u.churn,
          INTCK('DAY', u.signup_date, TODAY())    AS tenure_days
                                                             LABEL='가입경과일',
          COUNT(o.order_id)                        AS n_orders
                                                             LABEL='결제주문수',
          SUM(o.total_amount)                      AS spent
                                                             LABEL='실결제총액',
          MEAN(o.total_amount)                     AS avg_price
                                                             LABEL='평균결제액',
          CASE WHEN u.total_spent >= 1500000 THEN 1 ELSE 0 END
                                                    AS is_vip
                                                             LABEL='VIP여부'
   FROM shop_db.users  AS u
   INNER JOIN shop_db.orders AS o
           ON u.user_id = o.user_id
   WHERE o.status = 'paid'
   GROUP BY u.user_id, u.age, u.gender, u.city, u.channel, u.vip_grade,
            u.marketing_consent, u.total_spent, u.order_count, u.churn,
            u.signup_date;
QUIT;

/* (C) work.prod_sales : shop.products + shop.order_items JOIN
       · products.monthly_sales 가 없으므로 order_items 실판매수량 집계
       · sold_qty      = 총 판매 수량 (모든 주문)
       · sold_revenue  = 총 판매 매출 (line_total 합)
       · Session 7 종합 1 - price × sold_qty 상관 분석에 사용            */
PROC SQL;
   CREATE TABLE work.prod_sales AS
   SELECT p.product_id,
          p.product_name,
          p.brand,
          p.category_id,
          p.price,
          p.cost,
          p.stock,
          p.rating_avg,
          p.review_count,
          COALESCE(SUM(oi.quantity), 0)   AS sold_qty
                                                LABEL='총판매수량',
          COALESCE(SUM(oi.line_total), 0) AS sold_revenue
                                                LABEL='총판매매출',
          COUNT(oi.item_id)               AS n_items
                                                LABEL='주문라인수'
   FROM shop_db.products AS p
   LEFT JOIN shop_db.order_items AS oi
          ON p.product_id = oi.product_id
   GROUP BY p.product_id, p.product_name, p.brand, p.category_id,
            p.price, p.cost, p.stock, p.rating_avg, p.review_count;
QUIT;


/*---s1.1 [slide 11] 실습 1 - 광고비 * 매출 * 트래픽 상관 ---*/
title'[s1.1] 실습 1 -budget * revenue * clicks 상관(shop_db.campaigns)';
proc corr data=work.ads	
	pearson spearman
	plots=matrix(histogram);
var budget revenue clicks;
run;
title;


/*편상관*/
proc corr data=work.uo_sum;
	var spent n_orders;
	partial age;
run;

proc corr data=work.uo_sum;
	var spent n_orders;
run;

title'[s2.2] 편상관 - 시즌 통제 후 budget * revenue';
proc corr data =work.ads;
	var budget revenue;
	partial season month; /*시즌 월 통제*/
run; /*budget과 revenue 간 season과 month로 영향을 주었는지 파악가능*/
title;

/*r 잔차 clb신뢰도 stb표준화계수 출력*/

/*session 2 : 단순 선형회귀분석 > proc reg*/
/*proc reg - 풀세트*/
title'[s3.1] : 단순선형회귀분석 >porc reg';
proc reg data=work.uo_sum
	plots=none;
	model spent=age /clb stb;
	output out=work.pred
	predicted =yhat
	residual=resid;
run;quit;
title;
/*
Pr > F
0.0947
*/

title'[s3.2] 실습3 : budget >> revenue 단순회귀';
proc reg data=work.ads	
plots=(fit residuals);
	model revenue= budget;
	output out=work.pred_rev
	predicted =pred_revenue
	residual=residual;
run; quit;
title;
/*
Parameter Estimates
Variable	DF	Parameter
				Estimate	Standard
								Error	t Value	Pr > |t|
Intercept	1	274023264	102223732	2.68	0.0100
budget		1	-0.28102	1.85759		-0.15	0.8804
*/

proc contents data=ads;
run;
proc reg data=work.ads	
plots=(fit residuals);
	model revenue= clicks;
	output out=work.pred_rev_cc
	predicted =pred_revenue
	residual=residual;
run; quit;
/*
Parameter Estimates
Variable	DF	Parameter
				Estimate	Standard
								Error	t Value	Pr > |t|
Intercept	1	12957639	50795191	0.26	0.7997
clicks		1	4577.17672	658.91751	6.95	<.0001
*/


/* session4 : 다중회귀분석 */
title'[s4.2-@] step2 - 다중 회귀 진단';
proc reg data=work.uo_sum
	plots=none;
	model spent=age n_orders avg_price
/ r clb stb vif tol dw;
output out=work.diag
	predicted=yhat
	residual=resid;
run;quit;
title;
/*dw = durbin-watson -잔차독립성*/
/*
Standardized
Estimate*/


/* 2단계 : 잔차 정규성 : i=univariate normal*/
title'[s4.2-@] 잔차 정규성 - proc nuivariate qqplot';
proc univariate data=work.diag normal;
	var resid;
	qqplot resid / normal (mu=est sigma=est);
run;
title;

/* 잔차 vs 예측 - 등분산 >> 패턴확인 */
proc sgplot data=diag;
	scatter x=yhat y=resid;
refine 0 / axis=y;
run;


/*변수 선택 >> stepwise + VIF */
proc reg data=ads
	plots=(fit residuals);
	model revenue = budget cpc impressions clicks conversions season /
		selection =stepwise /*다중공선성에서 안전한것이 확보된 애들을 찾아줌*/
	slentry =0.15/*진입*/
	slstay=0.15/*제거*/
vif stb;
run;


/*session 5: logistic 회귀분석 >> sigmoid, logictic*/
title'[s5.1]proc rogistic 풀세트 (clodds / ctable / rsq / roc)';
proc logistic data=work.uo_sum
	plots(only)=roc;
/*의미: 기본으로 출력되는 수많은 그래프(잔차, 영향력 진단 플롯 등)를 모두 끄고,
 오직 ROC 커브 하나만 출력하라는 뜻입니다.*/
	class gender (ref='F');
	model is_vip(event='1') = age gender spent
/*내가 예측하려는 사건(VIP=1)이 바로 이 값이다!"라고 확실하게 타깃을 지정*/
/ clodds = wald	
/*오즈비(Odds Ratio)의 $95\%$
 신뢰구간(Confidence Limit)을 구할 때 Wald 검정 통계량 */
ctable rsq stb;
/*ctable =confusion matrix
rsq = r square*/
run;
title;


/*고객 이탈률 */
proc logistic data=shop_db.users descending;
	class gender (param=ref ref ='M');
/* ref ='M' 더미변수 
ref='M'의 역할: '남성(M)'을 기준점($0$)으로 삼겠다
범주형변수를 알아보기위해서*/
	model churn = age total_spent gender order_count
		/clparm=wald;
	output out=work.score
		predicted = p_churn;
run;


/*실제 스키마 반영 -work.uo_sum 사용(tenure_days , marketing_convesion,
 order_count 실컴럼활용 */
title'[s5.2] 실습 5 - 고객 이탈 예측 로지스틱(work.uo_sum)';
proc logistic data=work.uo_sum descending;
	class gender (param=ref ref='M')
		marketing_consent (param=ref ref='0');
	model churn = age total_spent order_count tenure_days 
	gender marketing_consent
/	clparm = wald ctable rsq stb;
	output out=work.score
	predicted = p_churn;
run;
title;

proc print data=score(obs=10);
	var churn p_churn;
run;


/*session 6: 이상치를 처리하는 방법: robusreg */
title'[s6.1-1]robust 회귀 -M-estimation';

proc robustreg data = work.uo_sum
	method=M
plots=(ddplot rdplot);

	model spent= age n_orders;
	output out=work.robust
	r=resid_r
	outlier=outlier
	leverage=leverage;
run;

title'[s6.1_2]OLS -robust 비교용';
proc reg data=work.uo_sum;
	model spent =age n_orders;
	run; quit;
title;

proc corr data=shop_db.products
	pearson spearman;
var price launch_date;
run;

proc reg data =shop_db.products;

	model price= cost;
run;quit;

proc reg data=shop_db.products;
	model price = rating_avg review_count cost/
vif stb;
	plot regidual.*predicted.;
run; quit;

proc logistic data = shop_db.users descending;
class gender (ref='M');
	model churn = age last_login_date gender/
	clparm= wald;
output out = work.score predicted =p_churn;
run;

































































































































































































