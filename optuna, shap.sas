%let userid = &SYSUSERID;
%include "/home/&userid/snippets/macro/matplot.sas";

/* =========================================================
   1단계: Optuna 및 SHAP 라이브러리 설치 (최초 1회 실행)
   * 이미 설치되어 있다면 이 블록은 주석 처리하시거나 
     설치가 안 되었을 때만 실행하셔도 됩니다.
   ========================================================= */
PROC PYTHON;
    SUBMIT;
import sys
import subprocess

# 설치할 패키지 리스트
packages = ['optuna', 'shap']

for pkg in packages:
    try:
        __import__(pkg)
        print(f"✔ [{pkg}] 이미 설치되어 있습니다.")
    except ImportError:
        print(f"⚙ [{pkg}] 설치를 진행합니다...")
        # 현재 SAS 파이썬 환경의 pip를 사용하여 패키지 설치
        subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])
        print(f"✔ [{pkg}] 설치 완료!")
    ENDSUBMIT;
QUIT;


/* =========================================================
   2단계: 설치 버전 확인 및 간단 작동 테스트
   ========================================================= */
PROC PYTHON;
    SUBMIT;
import sys
import optuna
import shap
import pandas as pd
import numpy as np
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

print("\n" + "="*50)
print(f" Python 버전 : {sys.version.split()[0]}")
print(f" Optuna 버전 : {optuna.__version__}")
print(f" SHAP 버전   : {shap.__version__}")
print("="*50 + "\n")

# ---------------------------------------------------------
# [테스트 1] Optuna 튜닝 작동 테스트
# ---------------------------------------------------------
print("▶ [Optuna] 하이퍼파라미터 최적화 테스트 중...")
data = load_breast_cancer()
X_tr, X_te, y_tr, y_te = train_test_split(data.data, data.target, test_size=0.2, random_state=42)

def objective(trial):
    params = {
        'n_estimators': trial.suggest_int('n_estimators', 10, 50),
        'max_depth': trial.suggest_int('max_depth', 2, 5),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1),
        'random_state': 42
    }
    model = XGBClassifier(**params)
    model.fit(X_tr, y_tr)
    return model.score(X_te, y_te)

# Optuna 출력이 너무 길어지지 않도록 로그 레벨 설정 (WARNING 이상만 출력)
optuna.logging.set_verbosity(optuna.logging.WARNING)

study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=5)

print(f"  ✔ Optuna 최적화 완료! (Best Accuracy: {study.best_value:.4f})")


# ---------------------------------------------------------
# [테스트 2] SHAP 값 계산 및 시각화 테스트
# ---------------------------------------------------------
print("▶ [SHAP] 변수 중요도(SHAP) 계산 테스트 중...")
best_model = XGBClassifier(**study.best_params, random_state=42)
best_model.fit(X_tr, y_tr)

# SHAP Explainer 생성 및 값 계산
explainer = shap.TreeExplainer(best_model)
shap_values = explainer(pd.DataFrame(X_te, columns=data.feature_names))

print("  ✔ SHAP 값 계산 완료!")
print(f"  ✔ SHAP Matrix Shape: {shap_values.values.shape}")
print("\n🎉 Optuna와 SHAP 모두 SAS PROC PYTHON 환경에서 정상 작동합니다!")

#  Python 버전 : 3.11.5
#  Optuna 버전 : 4.9.0
#  SHAP 버전   : 0.51.0
    ENDSUBMIT;
QUIT;
