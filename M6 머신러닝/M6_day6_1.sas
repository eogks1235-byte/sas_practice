%let csv_dir = /home/student/shop_csv;
%include '/home/student/snippets/macro/matplot.sas';


proc python;
submit;

import pandas as pd
from sklearn.ensemble import (RandomForestClassifier,GradientBoostingClassifier,
			StackingClassifier)
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score

csv_dir=SAS.symget('csv_dir')

df=pd.read_csv(csv_dir+'/users.csv').dropna()
#print(df.head())
#X_cols=['age','total_spent','order_count','recency']
#X=df[X_cols]
X=df[['age','total_spent','order_count','recency']]
y=df['churn']

X_tr,X_te,y_tr,y_te=train_test_split(X,y,test_size=0.3,random_state=42,stratify=y)

#Stacking의 기본정의
base=[('lr',LogisticRegression(max_iter=1000)),
		('tree',DecisionTreeClassifier(max_depth=5,random_state=42)),
	('rf',RandomForestClassifier(n_estimators=100,random_state=42))]

model=[
	('Bagging-RF',RandomForestClassifier(n_estimators=100,random_state=42)),
	('Boosting-GBM',GradientBoostingClassifier(n_estimators=100,random_state=42)),
	('Stacking',StackingClassifier(estimators=base,final_estimator=LogisticRegression(max_iter=1000)))]

for name,m in model:
	m.fit(X_tr,y_tr)
	auc=roc_auc_score(y_te,m.predict_proba(X_te)[:,1])
	print(f'모델명: {name:<15} AUC={auc:.3f}')

#모델명: Bagging-RF      AUC=0.721 병렬
#모델명: Boosting-GBM    AUC=0.766 가중치
#모델명: Stacking        AUC=0.757 혼합
endsubmit;
quit;


%let csv_dir = /home/student/shop_csv;
%include '/home/student/snippets/macro/matplot.sas';

/* session 2: XGBoost LightGBM */

proc python;
submit;

import pandas as pd
import time  # time 모듈 추가
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score

# 1. SAS 변수 가져오기 및 데이터 로드
csv_dir = SAS.symget('csv_dir')
df = pd.read_csv(csv_dir + '/users.csv').dropna()

X = df[['age', 'total_spent', 'order_count', 'recency']]
y = df['churn']

# 2. Train / Test Split 
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)

# 3. XGBoost 학습 및 평가
try:
    import xgboost as xgb
    t0 = time.time()
    xgb_model = xgb.XGBClassifier(
        n_estimators=500, learning_rate=0.05, max_depth=6, random_state=42, eval_metric='auc'
    )
    xgb_model.fit(X_tr, y_tr, eval_set=[(X_te, y_te)], verbose=True, early_stopping_rounds=20)
#verbose=True하면 n_estimators의 개수만큼 로그에 출력
#[498]validation_0-auc:0.75409
#[499]validation_0-auc:0.75408
#early_stopping_round하면 중간에 멈춤 
#[70]validation_0-auc:0.76271
#[71]validation_0-auc:0.76262
    auc = roc_auc_score(y_te, xgb_model.predict_proba(X_te)[:, 1])
    print(f'XGBoost  AUC = {auc:.3f} · {time.time()-t0:.2f}s')
except ImportError:
    print('xgboost 미설치')

# 4. LightGBM 학습 및 평가
try:
    import lightgbm as lgb
    t0 = time.time()
    lgb_model = lgb.LGBMClassifier(
        n_estimators=500, learning_rate=0.05, max_depth=6,
        random_state=42, n_jobs=-1, verbosity=-1
    )
    lgb_model.fit(X_tr, y_tr)
    
    auc = roc_auc_score(y_te, lgb_model.predict_proba(X_te)[:, 1])
    print(f'LightGBM AUC = {auc:.3f} · {time.time()-t0:.2f}s')
except ImportError:
    print('lightgbm 미설치')

#XGBoost  AUC = 0.754 · 4.93s
#LightGBM AUC = 0.757 · 5.58s
endsubmit;
quit;


/*3, 4, 5 날아감*/
PROC PYTHON;
   SUBMIT;
import pandas as pd
from sklearn.neural_network  import MLPClassifier
from sklearn.preprocessing   import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics         import roc_auc_score

df = pd.read_csv('/home/student/m6_data/users.csv').dropna()
X_cols = [c for c in ['age','total_spent','order_count','recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

sc = StandardScaler().fit(X_tr)
X_trs = sc.transform(X_tr)
X_tes = sc.transform(X_te)

mlp = MLPClassifier(
    hidden_layer_sizes=(8, 4),
    activation='relu',
    solver='adam',
    max_iter=500,
    learning_rate_init=0.001,
    random_state=42,
).fit(X_trs, y_tr)

print(f'MLP AUC = {roc_auc_score(y_te, mlp.predict_proba(X_tes)[:, 1]):.3f}')
print(f'학습 손실 : {mlp.loss_:.4f}')
print(f'에포크    : {mlp.n_iter_}')
   ENDSUBMIT;
QUIT;

PROC PYTHON;
   SUBMIT;
import pandas as pd
import warnings
warnings.filterwarnings('ignore')
from sklearn.neural_network  import MLPClassifier
from sklearn.preprocessing   import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics         import roc_auc_score

df = pd.read_csv('/home/student/m6_data/users.csv').dropna()
X_cols = [c for c in ['age','total_spent','order_count','recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

sc = StandardScaler().fit(X_tr)
X_trs = sc.transform(X_tr)
X_tes = sc.transform(X_te)

for act in ['logistic', 'tanh', 'relu', 'identity']:
    m = MLPClassifier(hidden_layer_sizes=(8, 4), activation=act,
                      solver='adam', max_iter=500, random_state=42).fit(X_trs, y_tr)
    auc = roc_auc_score(y_te, m.predict_proba(X_tes)[:, 1])
    print(f'{act:<12} AUC={auc:.3f} 에포크={m.n_iter_}')

for opt in ['sgd', 'adam', 'lbfgs']:
    m = MLPClassifier(hidden_layer_sizes=(8, 4), activation='relu',
                      solver=opt, max_iter=500, random_state=42).fit(X_trs, y_tr)
    auc = roc_auc_score(y_te, m.predict_proba(X_tes)[:, 1])
    print(f'{opt:<12} AUC={auc:.3f}')
   ENDSUBMIT;
QUIT;

PROC PYTHON;
   SUBMIT;
import pandas as pd
from sklearn.svm             import SVC
from sklearn.preprocessing   import StandardScaler
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics         import roc_auc_score

df = pd.read_csv('/home/student/m6_data/users.csv').dropna()
X_cols = [c for c in ['age','total_spent','order_count','recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

sc = StandardScaler().fit(X_tr)
X_trs = sc.transform(X_tr)
X_tes = sc.transform(X_te)

n_sample = min(5000, len(y_tr))
idx = pd.Series(range(len(y_tr))).sample(n_sample, random_state=42).values
X_sample = X_trs[idx]
y_sample = y_tr.iloc[idx]

for k in ['linear', 'rbf', 'poly']:
    m = SVC(kernel=k, C=1.0, probability=True, random_state=42).fit(X_sample, y_sample)
    print(f'{k:<10} AUC={roc_auc_score(y_te, m.predict_proba(X_tes)[:, 1]):.3f}')

params = {'C': [0.1, 1, 10], 'gamma': ['scale', 0.01, 0.1]}
grid = GridSearchCV(SVC(kernel='rbf', probability=True, random_state=42),
                    params, cv=3, scoring='roc_auc', n_jobs=-1).fit(X_sample, y_sample)
print(f'최적 : {grid.best_params_} · CV AUC = {grid.best_score_:.3f}')
   ENDSUBMIT;
QUIT;

PROC PYTHON;
   SUBMIT;
import pandas as pd
import warnings
warnings.filterwarnings('ignore')
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics         import roc_auc_score

csv_path = SAS.symget('CSV_PATH')
df = pd.read_csv(csv_path+'/users.csv').dropna()
X_cols = [c for c in ['age','total_spent','order_count','recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42)

try:
    import optuna
    import xgboost as xgb

    optuna.logging.set_verbosity(optuna.logging.WARNING)   # 로그 최소화

    # (1) 목적 함수 정의
    def objective(trial):
        params = {
            'n_estimators'    : trial.suggest_int('n_estimators', 50, 500),
            'max_depth'       : trial.suggest_int('max_depth', 3, 10),
            'learning_rate'   : trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'subsample'       : trial.suggest_float('subsample', 0.6, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
            'random_state'    : 42,
            'eval_metric'     : 'auc',
            'use_label_encoder': False,
        }
        m = xgb.XGBClassifier(**params)
        return cross_val_score(m, X_tr, y_tr, cv=3, scoring='roc_auc').mean()

    # (2) 최적화 실행 (30 회 · 시연용 · 실무는 100~300)
    study = optuna.create_study(direction='maximize',
                                 sampler=optuna.samplers.TPESampler(seed=42))
    study.optimize(objective, n_trials=30, show_progress_bar=False)

    # (3) 결과
    print(f'★ 최적 AUC (CV)    : {study.best_value:.4f}')
    print(f'★ 최적 파라미터     : {study.best_params}')

    # (4) 최적 모형 Test 평가
    best = xgb.XGBClassifier(**study.best_params, random_state=42,
                              eval_metric='auc', use_label_encoder=False)
    best.fit(X_tr, y_tr)
    prob = best.predict_proba(X_te)[:, 1]
    print(f'★ Test AUC          : {roc_auc_score(y_te, prob):.4f}')

    # (5) 상위 5 trial
    print()
    print('── Top 5 trials ──')
    df_trials = study.trials_dataframe().sort_values('value', ascending=False).head(5)
    print(df_trials[['number', 'value']].to_string(index=False))

except ImportError as e:
    print(f'⚠ 라이브러리 미설치 ({e.name}) : pip install optuna xgboost')
# >>>
# ★ 최적 AUC (CV)    : 0.7792
# ★ 최적 파라미터     : {'n_estimators': 182, 'max_depth': 3, 'learning_rate': 0.0338365368731356, 'subsample': 
# 0.6465355151101959, 'colsample_bytree': 0.9403349375437392}
# ★ Test AUC          : 0.7664
# ── Top 5 trials ──
#  number    value
#      22 0.779233
#      14 0.779171
#      19 0.779108
#      16 0.779067
#      27 0.778994
   ENDSUBMIT;
QUIT;


/* session 6: Optuna 파라미터 자동 선택 (통합 코드) */

proc python;
submit;
import sys
import os
import site
import subprocess

# ==========================================
# 1. 패키지 자동 설치 및 경로 설정 (최우선 실행)
# ==========================================
try:
    import optuna
except ModuleNotFoundError:
    print("Optuna 라이브러리가 없어 자동 설치를 진행합니다...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "optuna"])

# 설치된 사용자 패키지 경로를 sys.path에 등록 (ModuleNotFoundError 방지)
user_site = site.getusersitepackages()
if user_site not in sys.path:
    sys.path.append(user_site)

local_site = '/home/student/.local/lib/python3.11/site-packages'
if os.path.exists(local_site) and local_site not in sys.path:
    sys.path.append(local_site)

# 패키지 로드
import optuna
import pandas as pd
import warnings
warnings.filterwarnings('ignore')

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import roc_auc_score

print(f"Optuna 버전을 성공적으로 불러왔습니다: v{optuna.__version__}")

# ==========================================
# 2. 데이터 로드 및 전처리
# ==========================================
csv_dir = SAS.symget('csv_dir')
df = pd.read_csv(csv_dir + '/users.csv').dropna()

X_cols = [c for c in ['age', 'total_spent', 'order_count', 'recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42
)

# ==========================================
# 3. Optuna 최적화 실행
# ==========================================
try:
    import xgboost as xgb
    optuna.logging.set_verbosity(optuna.logging.WARNING)

    def objective(trial):
        # 메모리 폭증 방지를 위해 max_depth 및 n_estimators 범위를 안정적인 값으로 설정
        params = {
            'n_estimators'    : trial.suggest_int('n_estimators', 50, 300),
            'max_depth'       : trial.suggest_int('max_depth', 3, 7),
            'learning_rate'   : trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'subsample'       : trial.suggest_float('subsample', 0.6, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
            'random_state'    : 42,
            'eval_metric'     : 'auc',
            'n_jobs'          : 1  # 프로세스 복제 억제
        }
        m = xgb.XGBClassifier(**params)
        
        # [핵심] n_jobs=1 로 설정하여 메모리 킬(SIGKILL -9) 방지
        return cross_val_score(m, X_tr, y_tr, cv=3, scoring='roc_auc', n_jobs=1).mean()

    study = optuna.create_study(
        direction='maximize',
        sampler=optuna.samplers.TPESampler(seed=42)
    )
    
    print("Optuna 하이퍼파라미터 최적화 시작 (30회)...")
    study.optimize(objective, n_trials=30, show_progress_bar=False)

    print("\n================ [최종 결과] ================")
    print(f'최적 AUC (CV) : {study.best_value:.4f}')
    print(f'최적 파라미터 : {study.best_params}')
    print("=============================================")

except ImportError as e:
    print(f'라이브러리 미설치 오류: {e.name}')

#
#최적 AUC(CV) : 0.7791
#최적 파라미터 : {'n_estimators': 203, 'max_depth': 3, 'learning_rate': 0.027010527749605478, 'subsample': 0.7465447373174767, 
#'colsample_bytree': 0.7824279936868144}


endsubmit;
quit;

%let csv_dir = /home/student/shop_csv;
%include '/home/student/snippets/macro/matplot.sas';

/* session 7: Optuna 하이퍼파라미터 자동 최적화 */

proc python;
submit;
import sys
import os
import site
import pandas as pd
import warnings
warnings.filterwarnings('ignore')

# 1. Optuna 및 사용자 설치 패키지 경로 추가
user_site = site.getusersitepackages()
if user_site not in sys.path:
    sys.path.append(user_site)

local_site = '/home/student/.local/lib/python3.11/site-packages'
if os.path.exists(local_site) and local_site not in sys.path:
    sys.path.append(local_site)

import optuna
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import roc_auc_score
import xgboost as xgb

print(f"Optuna(v{optuna.__version__})를 사용해 최적화를 시작합니다.")

# 2. 데이터 로드 및 전처리
csv_dir = SAS.symget('csv_dir')
df = pd.read_csv(csv_dir + '/users.csv').dropna()

X_cols = [c for c in ['age', 'total_spent', 'order_count', 'recency'] if c in df.columns]
X = df[X_cols]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, test_size=0.3, stratify=y, random_state=42
)

# 3. Optuna 목적 함수 (Objective) 정의
optuna.logging.set_verbosity(optuna.logging.WARNING)

def objective(trial):
    params = {
        'n_estimators'    : trial.suggest_int('n_estimators', 50, 300),
        'max_depth'       : trial.suggest_int('max_depth', 3, 8),
        'learning_rate'   : trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
        'subsample'       : trial.suggest_float('subsample', 0.6, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
        'random_state'    : 42,
        'eval_metric'     : 'auc',
        'n_jobs'          : 1  # 멈춤/메모리 폭증 방지
    }
    
    model = xgb.XGBClassifier(**params)
    # 3-Fold 교차 검증의 평균 AUC 측정
    return cross_val_score(model, X_tr, y_tr, cv=3, scoring='roc_auc', n_jobs=1).mean()

# 4. Optuna Study 실행 (30회 자동 탐색)
study = optuna.create_study(
    direction='maximize',
    sampler=optuna.samplers.TPESampler(seed=42)
)

print("하이퍼파라미터 탐색 중 (30회)...")
study.optimize(objective, n_trials=30, show_progress_bar=False)

# 5. 최적 파라미터로 최종 평가
best_params = study.best_params
print("\n================ [Optuna 결과] ================")
print(f'최적 교차검증 AUC (CV): {study.best_value:.4f}')
print(f'최적 파라미터 조합    : {best_params}')

# 최적 모델을 전체 학습 데이터로 재학습 후 최종 테스트 데이터 평가
best_model = xgb.XGBClassifier(**best_params, random_state=42, eval_metric='auc')
best_model.fit(X_tr, y_tr)

final_test_auc = roc_auc_score(y_te, best_model.predict_proba(X_te)[:, 1])
print(f'최종 Test Set AUC     : {final_test_auc:.4f}')
print("===============================================")
#================ [Optuna 결과] ================
#최적 교차검증 AUC (CV): 0.7792
#최적 파라미터 조합    : {'n_estimators': 193, 'max_depth': 3, 'learning_rate': 0.0415193760925758, 'subsample': 
#0.6312132172453417, 'colsample_bytree': 0.9873257039026792}
#최종 Test Set AUC     : 0.7663
#===============================================
endsubmit;
quit;


%let csv_dir = /home/student/shop_csv;
%include '/home/student/snippets/macro/matplot.sas';

/* session 7: 실 사례 이탈 예측 (Top 500 타겟팅) */
proc python;
submit;
import pandas as pd, xgboost as xgb
from sklearn.model_selection import train_test_split

# (1) SAS 경로 변수 불러오기 + 데이터 로드 및 분할
csv_dir = SAS.symget('csv_dir')
df = pd.read_csv(csv_dir + '/users.csv').dropna()

X = df[['age', 'total_spent', 'order_count', 'recency']]
y = df['churn']

X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)

# (2) XGBoost 학습 + 전체 회원 대상 확률 예측
model = xgb.XGBClassifier(n_estimators=200, learning_rate=0.05, max_depth=6, random_state=42)
model.fit(X_tr, y_tr)
df['prob_churn'] = model.predict_proba(X)[:, 1] 

# (3) 위험도별 타겟팅 (TOP 500명 추출)
top500 = df.nlargest(500, 'prob_churn')

top500['risk_grade'] = pd.cut(
    top500['prob_churn'],
    bins=[0, 0.5, 0.7, 0.9, 1.0],
    labels=['LOW', 'MID', 'HIGH', 'VERY_HIGH']
)

# (4) 위험도별 액션 (예산 분배)
print("========== [TOP 500 이탈 위험군 캠페인 예산 분배] ==========")
for grade, n in top500['risk_grade'].value_counts().items():
    cost = n * (5000 if grade == 'VERY_HIGH' else 1500 if grade == 'HIGH' else 500)
    print(f'{grade:10s} {n:3d}명 → 캠페인 비용: {cost:10,}원')
print("============================================================")

#>>>
#========== [TOP 500 이탈 위험군 캠페인 예산 분배] ==========
#HIGH       363명 → 캠페인 비용:    544,500원
#VERY_HIGH  137명 → 캠페인 비용:    685,000원
#LOW          0명 → 캠페인 비용:          0원
#MID          0명 → 캠페인 비용:          0원
#============================================================
#>>>
endsubmit;
quit;










