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

proc contents daata=ads;
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



























































































































































































































































































