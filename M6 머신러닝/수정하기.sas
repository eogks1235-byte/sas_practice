proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

df['age']=df['age'].fillna(df['age'].median())
df['total_spent']=df['total_spent'].fillna(0)
df['gender']=df['gender'].fillna(df['gender'].mode()[0])
df=df.dropna(subset=['channel'])
print(df.info())

#이상값처리 > Z-score
from scipy.stats import zscore
df['z_age']=zscore(df['age'])
z_outlier=df[ df['z_age'].abs()>3]

print(f'age Z score : {len(z_outlier)}')

# users_clean.csv 데이터 저장
df.to_csv('/home/student/shop_csv/users_clean.csv',index=False)
endsubmit;
quit;

/*Z-score = 0: 정확히 평균값

Z-score = +1 또는 -1: 평균에서 1 표준편차 거리 내에 있음

Z-score 가 +3 초과 또는 -3 미만:
 평균에서 3 표준편차 이상 떨어진 
상위 0.15% 또는 하위 0.15%의 극단적인 값*/


/* shop.sales 만들기 */

libname shop_db '/home/student/shop_db';
%let csvdir=/home/student/shop_csv;

/* csv to sas macro*/
%macro imp(name=);
	proc import datafile="&csvdir/&name..csv"
	out=shop_db.&name
	dbms=csv replace;
	getnames=yes;
	guessingrows=max;
run;
%put note:=====&name..csv -> shop_db.&name 변환완료=====;
%mend;

%imp(name=categories);

PROC SQL;
   CREATE TABLE shop_db.sales AS
   SELECT
      MONOTONIC()                             AS sale_id      LABEL='거래ID',
      o.user_id                                               LABEL='회원ID',
      o.order_date                             AS sale_date   FORMAT=YYMMDD10.
                                                               LABEL='판매일자',
      p.product_id                                            LABEL='상품ID',
      c.category_name                          AS category    LABEL='카테고리',
      p.price                                                 LABEL='단가(원)',
      oi.quantity                              AS qty         LABEL='수량',
      CASE WHEN oi.quantity * oi.unit_price > 0
           THEN oi.item_discount / (oi.quantity * oi.unit_price) * 100
           ELSE 0 END                          AS discount_pct FORMAT=8.2
                                                               LABEL='할인율(%)',
      oi.line_total                            AS total_amount
                                                               LABEL='최종매출액(원)'
   FROM shop_db.orders            AS o
   INNER JOIN shop_db.order_items AS oi ON o.order_id      = oi.order_id
   INNER JOIN shop_db.products    AS p  ON oi.product_id   = p.product_id
   LEFT  JOIN shop_db.categories  AS c  ON p.category_id   = c.category_id
   WHERE o.order_date IS NOT MISSING
     AND o.status     = 'paid';
QUIT;

PROC SQL;
   SELECT COUNT(*)         AS n_sales,
          MIN(sale_date)   AS date_min,
          MAX(sale_date)   AS date_max,
          MEAN(total_amount) AS avg_amt,
          SUM(total_amount)  AS sum_amt
   FROM shop_db.sales;
QUIT;

proc sql;
	select count(*) from shop_db.sales;
quit;

/* sales.csv 파일로 export*/
proc export data=shop_db.sales outfile='/home/student/shop_csv/sales.csv'
	dbms=csv replace;
run;
proc python;
submit;
import pandas as pd

# 1. 파일 불러오기
users = pd.read_csv('/home/student/shop_csv/users_clean.csv')
sales = pd.read_csv('/home/student/shop_csv/sales.csv')

# 2. total_amount 컬럼의 쉼표(,) 제거 및 숫자(float) 형변환 (★ 에러 해결 핵심)
sales['total_amount'] = sales['total_amount'].astype(str).str.replace(',', '').astype(float)

# 3. 회원별 누적매출, 주문횟수, 평균구매액, 최근구매일 집계
df_agg = sales.groupby('user_id').agg(
    total_amount = ('total_amount', 'sum'),
    order_count = ('sale_id', 'count'),
    avg_amount = ('total_amount', 'mean'),
    last_purchase = ('sale_date', 'max')
).reset_index()

print("--- df_agg 결과 ---")
print(df_agg.head())

# 4. 병합을 위해 user_id 타입을 문자열로 통일
users['user_id'] = users['user_id'].astype(str)
df_agg['user_id'] = df_agg['user_id'].astype(str)

# 5. Left Join 병합
df_merge = users.merge(df_agg, on='user_id', how='left', suffixes=('', '_agg'))

print("\n--- df_merge 결과 ---")
print(df_merge.head())
print(df_merge.info())

print(f'\nusers cnt: {len(users)}, sales cnt: {len(sales)}, df_merge cnt: {len(df_merge)}')
endsubmit;
quit;
/*ww*/