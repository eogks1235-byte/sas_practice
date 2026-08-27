PROC PYTHON;
    SUBMIT;
import sys
import site

# 사용자 패키지 설치 경로를 sys.path에 추가 (필수)
user_site = site.getusersitepackages()
if user_site not in sys.path:
    sys.path.append(user_site)

# 패키지 임포트
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

optuna.logging.set_verbosity(optuna.logging.WARNING)

study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=5)

print(f"   ✔ Optuna 최적화 완료! (Best Accuracy: {study.best_value:.4f})")

# ---------------------------------------------------------
# [테스트 2] SHAP 값 계산 및 시각화 테스트
# ---------------------------------------------------------
print("▶ [SHAP] 변수 중요도(SHAP) 계산 테스트 중...")
best_model = XGBClassifier(**study.best_params, random_state=42)
best_model.fit(X_tr, y_tr)

explainer = shap.TreeExplainer(best_model)
shap_values = explainer(pd.DataFrame(X_te, columns=data.feature_names))

print("   ✔ SHAP 값 계산 완료!")
print(f"   ✔ SHAP Matrix Shape: {shap_values.values.shape}")
print("\n🎉 Optuna와 SHAP 모두 SAS PROC PYTHON 환경에서 정상 작동합니다!")
# Python 버전 : 3.11.5
# Optuna 버전 : 4.9.0
# SHAP 버전   : 0.51.0 
   ENDSUBMIT;
QUIT;