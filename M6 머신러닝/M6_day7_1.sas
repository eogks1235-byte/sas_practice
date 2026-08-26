%let userid=&SYSUSERID; /*student*/
libname shop_db "/home/&userid/shop_db";
%let csv_dir=/home/&SYSUSERID/shop_csv;
%include "/home/&userid/snippets/macro/matplot.sas";


/* session 1: EDA + logistic */

PROC PYTHON;
   SUBMIT;
import pandas as pd
from sklearn.linear_model    import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing   import StandardScaler
from sklearn.metrics         import roc_auc_score

csv_path = SAS.symget('CSV_PATH')

# (1) 데이터 로드 + 진단
df = pd.read_csv(csv_path+'/users.csv')
print(f'★ shape        : {df.shape}')
print()
print('── dtype ──')
print(df.dtypes)
print()
print('── 결측률(%) 상위 ──')
print((df.isnull().mean()*100).sort_values(ascending=False).round(2).head())
print()

if 'churn' in df.columns:
    print(f'── churn 분포 ──')
    print(df['churn'].value_counts(normalize=True).round(3))
    print()

print('── 기초 통계 ──')
print(df.describe().round(1))

# (2) 베이스라인 - Logistic
df = df.dropna()
X_cols = [c for c in ['age','total_spent','order_count','recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

sc = StandardScaler().fit(X_tr)
X_trs, X_tes = sc.transform(X_tr), sc.transform(X_te)

baseline = LogisticRegression(max_iter=1000, random_state=42).fit(X_trs, y_tr)
auc = roc_auc_score(y_te, baseline.predict_proba(X_tes)[:, 1])
print()
print(f'★★★ 베이스라인 (Logistic) AUC = {auc:.3f} ★★★')
print('★ 목표 - Optuna+XGB 로 +5%↑ (0.85+)')
>>>
# ★ shape        : (50000, 9)
# ── dtype ──
# user_id        object
# age             int64
# gender         object
# channel        object
# vip_grade       int64
# total_spent     int64
# order_count     int64
# recency         int64
# churn           int64
# dtype: object
# ── 결측률(%) 상위 ──
# user_id      0.0
# age          0.0
# gender       0.0
# channel      0.0
# vip_grade    0.0
# dtype: float64
# ── churn 분포 ──
# churn
# 0    0.8
# 1    0.2
# Name: proportion, dtype: float64
# ── 기초 통계 ──
#            age  vip_grade  total_spent  order_count  recency    churn
# count  50000.0    50000.0      50000.0      50000.0  50000.0  50000.0
# mean      35.9        1.1     617339.7          8.2     39.0      0.2
# std       10.3        1.3     481592.5          5.5     44.9      0.4
# min       20.0        0.0          0.0          0.0      0.0      0.0
# 25%       28.0        0.0     264371.5          4.0      4.0      0.0
# 50%       36.0        1.0     511121.5          7.0     26.0      0.0
# 75%       43.0        2.0     858275.0         11.0     57.0      0.0
# max       65.0        5.0    5190286.0         42.0    365.0      1.0
# ★★★ 베이스라인 (Logistic) AUC = 0.757 ★★★
# ★ 목표 - Optuna+XGB 로 +5%↑ (0.85+)
# >>> 
   ENDSUBMIT;
QUIT;


