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


%let userid=&SYSUSERID; /*student*/
libname shop_db "/home/&userid/shop_db";
%let csv_dir=/home/&SYSUSERID/shop_csv;
%include "/home/&userid/snippets/macro/matplot.sas";


/* session 4: xgb + optuna */
proc python;
submit;

import gc
import pandas as pd
import numpy as np
import pickle
import warnings
warnings.filterwarnings('ignore')
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics         import (roc_auc_score, accuracy_score, precision_score,
                                      recall_score, f1_score, confusion_matrix, roc_curve)
csv_path = SAS.symget('CSV_PATH')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os
_font_path = '/home/student/font/malgun.ttf'
if os.path.exists(_font_path):
    font_manager.fontManager.addfont(_font_path)
    plt.rcParams['font.family'] = 'Malgun Gothic'
plt.rcParams['axes.unicode_minus'] = False
try:
    df = pd.read_csv(f'{csv_path}/users_fe.csv')
except FileNotFoundError:
    df = pd.read_csv(csv_path+'/users.csv').dropna()
drop_cols = [c for c in ['user_id', 'churn'] if c in df.columns]
X = df.drop(columns=drop_cols).select_dtypes(include='number')
y = df['churn']
X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)
del df
gc.collect()
try:
    import optuna
    import xgboost as xgb
    optuna.logging.set_verbosity(optuna.logging.WARNING)
    def objective(trial):
        params = {
            'n_estimators'    : trial.suggest_int('n_estimators', 100, 500),
            'max_depth'       : trial.suggest_int('max_depth', 3, 10),
            'learning_rate'   : trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'subsample'       : trial.suggest_float('subsample', 0.6, 1.0),
            'random_state'    : 42,
            'eval_metric'     : 'auc',
            'use_label_encoder': False,
            'n_jobs'          : 1,
        }
        score = cross_val_score(xgb.XGBClassifier(**params), X_tr, y_tr,
                                 cv=3, scoring='roc_auc').mean()
        gc.collect()
        return score
    study = optuna.create_study(direction='maximize',
                                 sampler=optuna.samplers.TPESampler(seed=42))
    study.optimize(objective, n_trials=30, show_progress_bar=False )
    print(f'★ 최적 파라미터 : {study.best_params}')
    print(f'★ CV AUC       : {study.best_value:.4f}')
    final = xgb.XGBClassifier(**study.best_params, random_state=42,
                               eval_metric='auc', use_label_encoder=False)
    final.fit(X_tr, y_tr)
    pred = final.predict(X_te)
    prob = final.predict_proba(X_te)[:, 1]
    print()
    print('── S4 · 5 평가지표 (Test) ──')
    print(f'  Accuracy  = {accuracy_score(y_te, pred):.3f}')
    print(f'  Precision = {precision_score(y_te, pred):.3f}')
    print(f'  Recall    = {recall_score(y_te, pred):.3f}  ★ 이탈 놓침 최소')
    print(f'  F1        = {f1_score(y_te, pred):.3f}')
    print(f'  AUC       = {roc_auc_score(y_te, prob):.3f}')
    cm = confusion_matrix(y_te, pred)
    print()
    print('── Confusion Matrix ──')
    print(f'              예측 잔류    예측 이탈')
    print(f'  실제 잔류 : {cm[0,0]:>8}     {cm[0,1]:>8}')
    print(f'  실제 이탈 : {cm[1,0]:>8}     {cm[1,1]:>8}')
    fpr, tpr, _ = roc_curve(y_te, prob)
    plt.figure(figsize=(7, 6))
    plt.plot(fpr, tpr, linewidth=2,
             label=f'XGB+Optuna · AUC={roc_auc_score(y_te, prob):.3f}')
    plt.plot([0, 1], [0, 1], '--', color='gray', label='Random')
    plt.xlabel('FPR'); plt.ylabel('TPR = Recall')
    plt.title('Capstone 최종 모형 · ROC Curve')
    plt.legend(loc='lower right')
    plt.tight_layout()
    plt.savefig(f'{csv_path}/s4_roc.png', dpi=100)
    plt.close()
    with open(f'{csv_path}/s4_final_model.pkl', 'wb') as f:
        pickle.dump({'model': final, 'X_tr': X_tr, 'X_te': X_te,
                      'y_tr': y_tr, 'y_te': y_te,
                      'cols': X.columns.tolist(),
                      'best_params': study.best_params}, f)
    print()
    print('★ s4_final_model.pkl 저장 (S5 SHAP 재사용)')
except ImportError:
    print('⚠ optuna/xgboost 미설치 · 튜닝 스킵')

# >>>
# ★ 최적 파라미터 : {'n_estimators': 497, 'max_depth': 3, 'learning_rate': 0.013958212325617057, 'subsample': 
# 0.631040847490091}
# ★ CV AUC       : 0.7795
# ── S4 · 5 평가지표 (Test) ──
#   Accuracy  = 0.814
#   Precision = 0.604
#   Recall    = 0.206  ★ 이탈 놓침 최소
#   F1        = 0.307
#   AUC       = 0.766
# ── Confusion Matrix ──
#               예측 잔류    예측 이탈
#   실제 잔류 :    11595          405
#   실제 이탈 :     2382          618

endsubmit;
quit;

%show_png(s4_roc.png, title=%STR(S4 · Capstone 최종 모형 ROC));


%let userid=&SYSUSERID; /*student*/
libname shop_db "/home/&userid/shop_db";
%let csv_dir=/home/&SYSUSERID/shop_csv;
%include "/home/&userid/snippets/macro/matplot.sas";


/* session 5: XAI SHAP */
proc python;
submit;
import pandas as pd
import numpy as np
import pickle
import warnings
warnings.filterwarnings('ignore')

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

try:
    import shap

    # S4 모형 로드
    with open(f'{csv_path}/s4_final_model.pkl', 'rb') as f:
        s = pickle.load(f)

    final = s['model']
    X_te  = s['X_te']

    # 성능 위해 500 샘플만
    sample = X_te.sample(min(500, len(X_te)), random_state=42)

    # (1) TreeExplainer (XGB 는 매우 빠름)
    explainer = shap.TreeExplainer(final)
    shap_values = explainer.shap_values(sample)

    # (2) 글로벌 summary plot (dot)
    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, sample, show=False)
    plt.tight_layout()
    plt.savefig(f'{csv_path}/shap_summary.png', dpi=100, bbox_inches='tight')
    plt.close()
    print('★ shap_summary.png 저장')

    # (3) 변수 중요도 bar
    plt.figure(figsize=(8, 5))
    shap.summary_plot(shap_values, sample, plot_type='bar', show=False)
    plt.tight_layout()
    plt.savefig(f'{csv_path}/shap_bar.png', dpi=100, bbox_inches='tight')
    plt.close()
    print('★ shap_bar.png 저장')

    # (4) 의존성 plot (recency)
    if 'recency' in sample.columns:
        plt.figure(figsize=(8, 5))
        shap.dependence_plot('recency', shap_values, sample, show=False)
        plt.tight_layout()
        plt.savefig(f'{csv_path}/shap_dep_recency.png', dpi=100, bbox_inches='tight')
        plt.close()
        print('★ shap_dep_recency.png 저장 (recency 의존성)')

    # (5) 개별 회원 해석 (mean|shap| Top 5 텍스트)
    print()
    print('── 변수 중요도 순위 (mean|SHAP|) ──')
    imp = np.abs(shap_values).mean(0)
    for var, val in sorted(zip(sample.columns, imp),
                             key=lambda x: -x[1])[:6]:
        print(f'  {var:<20} {val:>8.4f}')

except ImportError:
    print('⚠ shap 미설치 : pip install shap · 스킵')
except FileNotFoundError:
    print('⚠ s4_final_model.pkl 없음 · S4 먼저 실행')
# ── 변수 중요도 순위 (mean|SHAP|) ──
#   order_count            0.6174
#   recency                0.5771
#   age                    0.2689
#   total_spent            0.0649
#   avg_order              0.0222
#   is_recent              0.0000
# >>> 
   ENDSUBMIT;
QUIT;

%show_png(shap_summary.png, title=%STR(S5 · SHAP 글로벌 summary));
%show_png(shap_bar.png,     title=%STR(S5 · SHAP 변수 중요도 (mean|SHAP|)));



