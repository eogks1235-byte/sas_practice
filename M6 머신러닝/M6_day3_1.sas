
proc python;
submit;

import pandas as pd
import numpy as np

df = pd.read_csv("/home/student/shop_csv/users_sales_merged (1).csv")
print(df.columns)
print(df['last_purchase'].dtype)
print()

df['last_purchase'] = pd.to_datetime(df['last_purchase'])
print(df['last_purchase'].dtype)
endsubmit;
quit;
/* session 6 : 파생변수 생성 */
proc python;
submit;

import pandas as pd
import numpy as np

df = pd.read_csv("/home/student/shop_csv/users_sales_merged (1).csv")
print(df.columns)
print(df['last_purchase'].dtype)
print()

# last_purchase 를 날짜타입으로 수정
df['last_purchase'] = pd.to_datetime(df['last_purchase'])
print(df['last_purchase'].dtype)

# 비율변수 - 거래당 평균 매출
df['order_count'] = df['order_count_x']
df['avg_order_amount'] = df['total_amount'] /df['order_count'].clip(lower=1)


# 날짜 변환 -> month, weekday 
df['purchase_month'] = df['last_purchase'].dt.month
df['purchase_weekday'] = df['last_purchase'].dt.weekday

print(df.head())
print()

# binning - age 그룹화 
df['age_group'] = pd.cut(df['age'], bins=[0, 30, 50, 99], labels=['청년', '장년','노년'])
print(df[['age_group', 'age']].head())

# 시간차 - 마지막 구매 ~  오늘
today = pd.Timestamp('2026-08-20')
df['days_since_purchase'] = (today - df['last_purchase']).dt.days
print(df[['days_since_purchase','last_purchase' ]].head())

# 로그 변환 - 매출의 왜도 줄이기 
df['log_total_amount'] = np.log1p(df['total_amount']).clip(lower=0)
print(df[['log_total_amount','total_amount' ]].head())

# 상호작용 - VIP * 주문수
df['vip_x_orders'] = (df['vip_grade'] == 5) * df['order_count']
print(df[['vip_x_orders','order_count', 'vip_grade' ]].head())
print(df[df['vip_grade'] == 5][['vip_x_orders','order_count', 'vip_grade' ]].head())

print(df.columns)
fe_cols = [ 'avg_order_amount', 'purchase_month', 'purchase_weekday', 'age_group',
       'days_since_purchase', 'log_total_amount', 'vip_x_orders']
users_fe = df[fe_cols]
print(users_fe.head())

# 새로 생성된 데이터를 저장 
users_fe.to_csv("/home/student/shop_csv/users_fe.csv", index=False)

endsubmit;
quit;


PROC PYTHON;
   SUBMIT;
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
users = pd.read_csv('/home/student/shop_csv/users_dirty.csv')

# 결측값 
users['age'] = users['age'].fillna(users['age'].median())
users['gender'] = users['gender'].fillna(users['gender'].mode()[0])
users['total_spent'] = users['total_spent'].fillna(0)
users = users.dropna(subset=['churn'])   

# 이상치 
Q1, Q3 = users['total_spent'].quantile([0.25, 0.75])
IQR = Q3 - Q1
lo, hi = Q1 - 1.5*IQR, Q3 + 1.5*IQR
users = users[(users['total_spent'] >= lo) & (users['total_spent'] <= hi)]

# sales.csv load  
sales = pd.read_csv('/home/student/shop_csv/sales.csv', parse_dates=['sale_date'])
agg = sales.groupby('user_id').agg(
    total_amount = ('total_amount', 'sum'),
    order_count  = ('sale_id',      'count'),
    avg_amount   = ('total_amount', 'mean'),
).reset_index()

users = users.drop(columns=['order_count']) # agg 의 order_count와 겹침 
df = users.merge(agg, on='user_id', how='left')

# 매출 : total_amount, order_count, avg_amount Nan인경우
for c in['total_amount','order_count','avg_amount']:
	if c in df.columns: df[c]=df[c].fillna(0)

df['log_amount'] =np.log1p(df['total_amount'].clip(lower=0))
df['avg_order_amount']=df['total_amount']/df['order_count'].clip(lower=1)
df['age_group']=pd.cut(df['age'],bins=[0,30,50,99],
	labels=[0,1,2]).astype(float)

#스케일링, 인코딩
num_cols=['age','total_amount','order_count','avg_order_amount','log_amount','age_group']
cat_cols=['gender','channel','vip_grade']
scaler=StandardScaler()
df[num_cols]=scaler.fit_transform(df[num_cols].fillna(0))
df=pd.get_dummies(df,columns=cat_cols,drop_first=True)

#날짜형 컬럼 제거
date_cols = df.select_dtypes(include=['datetime64[ns]']).columns.tolist()
if date_cols:
	df=df.drop(columns=date_cols)

#ID / 미사용 컬럼 제거
id_cols=[c for c in ['email','name','city','signup_date','last_login_date','signup_device','signup_at']
if c in df.columns]
if id_cols:
	df=df.drop(columns=id_cols)

print(df.columns)
df.to_csv('/home/student/shop_csv/users_ml_ready.csv')

endsubmit;
quit;