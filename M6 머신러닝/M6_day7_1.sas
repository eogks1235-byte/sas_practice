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


%let userid=&SYSUSERID; /*student*/
libname shop_db "/home/&userid/shop_db";
%let csv_dir=/home/&SYSUSERID/shop_csv;
%include "/home/&userid/snippets/macro/matplot.sas";


/* session 2: EDA + Feature Engineering */

PROC PYTHON;
   SUBMIT;
import pandas as pd
import numpy as np
from sklearn.linear_model    import LogisticRegression
from sklearn.preprocessing   import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics         import roc_auc_score

csv_path = SAS.symget('CSV_PATH')

# ★ matplotlib 한글 폰트 설정 (인라인)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os
_font_path = '/home/student/fonts/malgun.ttf'
if os.path.exists(_font_path):
    font_manager.fontManager.addfont(_font_path)
    plt.rcParams['font.family'] = 'Malgun Gothic'
plt.rcParams['axes.unicode_minus'] = False

df = pd.read_csv(csv_path+'/users.csv').dropna()

# (1) EDA - 상관 (churn 기준)
num = df.select_dtypes(include='number')
if 'churn' in num.columns:
    corr = num.corr()['churn'].sort_values()
    print('── churn 과 상관 (하위→상위) ──')
    print(corr.round(3))

# (2) 파생 변수 4종
if 'order_count' in df.columns and 'total_spent' in df.columns:
    df['avg_order'] = df['total_spent'] / df['order_count'].clip(lower=1)
if 'recency' in df.columns:
    df['is_recent'] = (df['recency'] < 30).astype(int)
if 'age' in df.columns:
    df['age_group'] = pd.cut(df['age'], bins=[0,30,50,99],
                              labels=[0,1,2]).astype(float)
if 'total_spent' in df.columns:
    df['log_spent'] = np.log1p(df['total_spent'].clip(lower=0))

print()
print(f'★ 파생 후 shape : {df.shape}')

# (3) OneHot 인코딩 (범주형)
cat_cols = [c for c in ['channel', 'vip_grade', 'gender'] if c in df.columns]
if cat_cols:
    df = pd.get_dummies(df, columns=cat_cols, drop_first=True)

# (4) 모형 재학습 · AUC 비교
drop_cols = [c for c in ['user_id', 'churn'] if c in df.columns]
X = df.drop(columns=drop_cols).select_dtypes(include='number')
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

sc = StandardScaler().fit(X_tr)
X_trs, X_tes = sc.transform(X_tr), sc.transform(X_te)

lr = LogisticRegression(max_iter=1000, random_state=42).fit(X_trs, y_tr)
auc = roc_auc_score(y_te, lr.predict_proba(X_tes)[:, 1])
print()
print(f'★ FE 후 AUC = {auc:.3f}  (베이스라인 대비 +향상)')

# 저장 (다음 세션 재사용)
df.to_csv(f'{csv_path}/users_fe.csv', index=False)

# EDA 히스토그램 저장
df.select_dtypes(include='number').hist(figsize=(12, 8))
plt.tight_layout()
plt.savefig(f'{csv_path}/eda_hist.png', dpi=100)
plt.close()

>>>
# ── churn 과 상관 (하위→상위) ──
# vip_grade     -0.277
# order_count   -0.252
# total_spent   -0.217
# age           -0.090
# recency        0.300
# churn          1.000
# Name: churn, dtype: float64
# ★ 파생 후 shape : (50000, 13)
# ★ FE 후 AUC = 0.757  (베이스라인 대비 +향상)
# >>>
   ENDSUBMIT;
QUIT;

%show_png(eda_hist.png, title=%STR(S2 · EDA 히스토그램 (파생 후)));


%let userid=&SYSUSERID; /*student*/
libname shop_db "/home/&userid/shop_db";
%let csv_dir=/home/&SYSUSERID/shop_csv;
%include "/home/&userid/snippets/macro/matplot.sas";


/* session 3: */
proc python;
submit;
import pandas as pd
import numpy as np
import time

from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import (RandomForestClassifier, GradientBoostingClassifier)
from sklearn.svm import SVC
from sklearn.neural_network  import MLPClassifier
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.preprocessing import StandardScaler
import xgboost as xgb, lightgbm as lgb


csv_path = SAS.symget('CSV_PATH')

# FE 데이터 사용 (없으면 원본)
try:
    df = pd.read_csv(f'{csv_path}/users_fe.csv')
except FileNotFoundError:
    df = pd.read_csv(csv_path+'/users.csv').dropna()

drop_cols = [c for c in ['user_id', 'churn'] if c in df.columns]
X = df.drop(columns=drop_cols).select_dtypes(include='number')
y = df['churn']

X_s = StandardScaler().fit_transform(X)
cv  = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

# 모형 정의 (scale=True → 스케일링 데이터 사용)
models = [
    ('Logistic', LogisticRegression(max_iter=1000, random_state=42),           True),
    ('Tree',     DecisionTreeClassifier(max_depth=5, random_state=42),         False),
    ('RF',       RandomForestClassifier(n_estimators=100, random_state=42),   False),
    ('GBM',      GradientBoostingClassifier(n_estimators=100, random_state=42),False),
    ('NN',       MLPClassifier(hidden_layer_sizes=(8,4), max_iter=500, random_state=42), True),
]

# XGB/LGB 추가 (있으면)
try:
    import xgboost as xgb
    models.append(('XGB',
                    xgb.XGBClassifier(n_estimators=100, random_state=42,  eval_metric='auc', use_label_encoder=False),
                    False))
except ImportError:
    pass
try:
    import lightgbm as lgb
    models.append(('LGB',
                    lgb.LGBMClassifier(n_estimators=100, random_state=42,  verbosity=-1),
                    False))
except ImportError:
    pass

# SVM - 큰 데이터 느려서 5000 샘플로만 (참고 표시)
print(f'{"모델":<12} {"CV AUC 평균":>12} {"±std":>8} {"시간(s)":>10}')
print('─' * 46)
results = []
for name, m, scale in models:
    Xi = X_s if scale else X.values
    t0 = time.time()
    scores = cross_val_score(m, Xi, y, cv=cv, scoring='roc_auc')
    dt = time.time() - t0
    print(f'{name:<12} {scores.mean():>12.4f} {scores.std():>8.4f} {dt:>10.2f}')
    results.append((name, scores.mean(), scores.std(), dt))

# Top 3 저장 (S4 튜닝 대상) 
#람다해석 result튜플안에서 [1]인 mean을 뽑아서 정렬
top3 = sorted(results, key=lambda r: r[1], reverse=True)[:3]
print()
print('★★★ Top 3 (S4 Optuna 튜닝 대상) ★★★')
for i, r in enumerate(top3, 1):
    print(f'  {i}. {r[0]:<10} AUC {r[1]:.4f} ± {r[2]:.4f}')

# 결과 저장
pd.DataFrame(results, columns=['model','auc_mean','auc_std','time_s'])\
    .sort_values('auc_mean', ascending=False)\
    .to_csv(f'{csv_path}/s3_model_comparison.csv', index=False)

# >>>
# 모델              CV AUC 평균     ±std      시간(s)
# ────────────────────────────────────────────
# ──
# Logistic           0.7666   0.0045       0.29
# Tree               0.7621   0.0031       0.58
# RF                 0.7295   0.0036      30.46
# GBM                0.7741   0.0036      34.20
# NN                 0.7719   0.0036      23.34
# XGB                0.7545   0.0016       3.04
# LGB                0.7703   0.0035       0.84
# ★★★ Top 3 (S4 Optuna 튜닝 대상) ★★★
#   1. GBM        AUC 0.7741 ± 0.0036
#   2. NN         AUC 0.7719 ± 0.0036
#   3. LGB        AUC 0.7703 ± 0.0035
# >>>
endsubmit;
quit;


