/* 회귀 */

libname shop_db '/home/student/shop_db';

proc reg data=shop_db.sales
	plots = fit(stats=NONE);
	model total_amount =qty;
run;
/*p-value 설명가능 r-square 가 낮아서 설명력이 많이떨어짐*/

proc python;
submit;

import pandas as pd
from sklearn.linear_model import LinearRegression

df=pd.read_csv('/home/student/shop_csv/sales.csv')

X=df[['qty']]
y=df['total_amount']

model=LinearRegression().fit(X,y)

print(f':{model.intercept_:,.1f}')

print(f':{model.coef_[0]:,.1f}')
print(f':{model.score(X,y):,.1f}')

for q in [1,3,5]:
    pred = model.intercept_ + model.coef_[0] * q
    print(f'  qty={q} → 예측 매출 {pred:,.0f}원')
	
endsubmit;
quit;

PROC PYTHON;
   SUBMIT;
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False

df = pd.read_csv('/home/student/shop_csv/sales.csv')
X = df[['qty']]
y = df['total_amount']
model = LinearRegression().fit(X, y)

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# (1) 산점도 + 회귀선
axes[0].scatter(df['qty'], df['total_amount'], alpha=0.3, s=20)
x_line = np.linspace(df['qty'].min(), df['qty'].max(), 100)
y_line = model.intercept_ + model.coef_[0] * x_line
axes[0].plot(x_line, y_line, 'r-', linewidth=2)
axes[0].set_xlabel('qty'); axes[0].set_ylabel('total_amount')
axes[0].set_title('산점도 + 회귀선')

# (2) 잔차도
y_pred = model.predict(X)
resid  = y - y_pred
axes[1].scatter(y_pred, resid, alpha=0.3, s=20)
axes[1].axhline(y=0, color='r', linestyle='--')
axes[1].set_xlabel('예측값'); axes[1].set_ylabel('잔차')
axes[1].set_title('잔차 도표 - 무작위 분포여야 정상')

plt.tight_layout()
plt.savefig('/home/student/shop_csv/reg_plot.png', dpi=100)
plt.close()
print('★ 저장 : /home/student/shop_csv/reg_plot.png')
   ENDSUBMIT;
QUIT;

/* 다중회귀 */

proc reg data=shop_db.sales;

	model total_amount = qty price discount_pct;
run;

proc python;
submit;
#R² = 0.836
import pandas as pd
from sklearn.linear_model import LinearRegression
		
df=pd.read_csv('/home/student/shop_csv/sales.csv')

X=df[['price','qty','discount_pct']]
y=df['total_amount']

model=LinearRegression().fit(X,y)

print(f'R² = {model.score(X, y):.3f}')
print()
print('── 회귀 계수 ──')
print(f'{"절편(β₀)":<15} {model.intercept_:>15,.2f}')
for var, c in zip(X.columns, model.coef_):
    print(f'{var:<15} {c:>15,.2f}')

# 신규 거래 예측
new_sale = [[50000, 3, 10]]   # price=50K · qty=3 · disc=10%
print()
print(f'★ 신규 거래 예측 (price=50K qty=3 disc=10%) : {model.predict(new_sale)[0]:,.0f} 원')

endsubmit;
quit;



PROC PYTHON;
   SUBMIT;
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler

df = pd.read_csv('/home/student/shop_csv/sales.csv')
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False
X = df[['price', 'qty', 'discount_pct']]
y = df['total_amount']

# 표준화 → 계수 비교 가능
X_s = StandardScaler().fit_transform(X)
model_s = LinearRegression().fit(X_s, y)

# 절대값 정렬 + 막대
coefs = np.abs(model_s.coef_)
idx   = np.argsort(coefs)[::-1]

print('── 변수 중요도 (표준화 계수 절대값) ──')
for i in idx:
    print(f'  {X.columns[i]:<15} {coefs[i]:>12,.2f}')

plt.figure(figsize=(8, 4))
plt.barh(np.array(X.columns)[idx], coefs[idx], color='steelblue')
plt.xlabel('표준화 계수 (절대값)')
plt.title('변수 중요도 - shop.sales 매출 예측')
plt.tight_layout()
plt.savefig('/home/student/shop_csv/feat_imp.png', dpi=100)
plt.close()

endsubmit;
quit;

%let snippets=/home/student/snippets;
%include "&snippets/macro/matplot.sas";

%show_png(feat_imp.png);

/* 중요변수 선택 >price qty*/
proc python;
submit;
import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler

df = pd.read_csv('/home/student/shop_csv/sales.csv')
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False
df=pd.read_csv('/home/student/shop_csv/sales.csv')

X = df[['qty', 'discount_pct']]
y = df['total_amount']

# 표준화 → 계수 비교 가능
X_s = StandardScaler().fit_transform(X)
model_s = LinearRegression().fit(X_s, y)

# 절대값 정렬 + 막대
coefs = np.abs(model_s.coef_)
idx   = np.argsort(coefs)[::-1]

print('── 변수 중요도 (표준화 계수 절대값) ──')
for i in idx:
    print(f'  {X.columns[i]:<15} {coefs[i]:>12,.2f}')

print('── 변수 중요도 (표준화 계수 절대값) ──')
for i in idx:
    print(f'  {X.columns[i]:<15} {coefs[i]:>12,.2f}')

plt.figure(figsize=(8, 4))
plt.barh(np.array(X.columns)[idx], coefs[idx], color='steelblue')
plt.xlabel('표준화 계수 (절대값)')
plt.title('변수 중요도 - shop.sales 매출 예측')
plt.tight_layout()
plt.savefig('/home/student/shop_csv/feat_imp1.png', dpi=100)
plt.close()

endsubmit;
quit;

%let snippets=/home/student/snippets;
%include "&snippets/macro/matplot.sas";
%show_png(feat_imp.png);
%show_png(feat_imp1.png);


/* 다중 회귀 분석 진단 :
	LINE*/

proc reg data=shop_db.sales
	plots(MAXPOINTS=NONE)=(diagnostics residuals);
	model total_amount = price qty discount_pct /DW;
	output out=diag p=pred r=resid;
run;
quit;/*메모리할당된걸끝냄*/
/*Durbin-Watson D	2.014  2에가까울수록 좋음 */

/* python으로 LINE 진단*/
proc python;
submit;
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False


from scipy import stats
from sklearn.linear_model import LinearRegression

df=pd.read_csv('/home/student/shop_csv/sales.csv')
X=df[['price','qty','discount_pct']]
y=df['total_amount']


model = LinearRegression().fit(X, y)
pred  = model.predict(X)
resid = y - pred

# 2x2 진단 도표 (LINE 4 가정)
fig, axes = plt.subplots(2, 2, figsize=(12, 8))

# (1) 잔차 vs 예측값 - 등분산성 (E)
axes[0, 0].scatter(pred, resid, alpha=0.3, s=15)
axes[0, 0].axhline(0, color='r', linestyle='--')
axes[0, 0].set_xlabel('예측값'); axes[0, 0].set_ylabel('잔차')
axes[0, 0].set_title('(E) 잔차 vs 예측값 · 등분산성')

# (2) Q-Q plot - 정규성 (N)
stats.probplot(resid, dist='norm', plot=axes[0, 1])
axes[0, 1].set_title('(N) Q-Q plot · 정규성')

# (3) 잔차 히스토그램 - 정규성 시각
axes[1, 0].hist(resid, bins=40, edgecolor='black')
axes[1, 0].set_title('(N) 잔차 분포 히스토그램')

# (4) Scale-Location - 등분산성 추가 확인
axes[1, 1].scatter(pred, np.sqrt(np.abs(resid)), alpha=0.3, s=15)
axes[1, 1].set_xlabel('예측값'); axes[1, 1].set_ylabel('√|잔차|')
axes[1, 1].set_title('(E) Scale-Location')

plt.tight_layout()
plt.savefig('/home/student/shop_csv/diagnostics.png', dpi=100)
plt.close()
print('★ 저장 : /home/student/shop_csv/diagnostics.png')


endsubmit;
quit;

%let snippets=/home/student/snippets;
%include "&snippets/macro/matplot.sas";

%show_png(diagnostics.png);

/* L1> Lasso L2> Ridge ElasticNet 
	session 4 > 정규화 linearregression lasso ridge*/
proc python;
submit;
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LinearRegression, Lasso, Ridge
from sklearn.model_selection import train_test_split

df=pd.read_csv('/home/student/shop_csv/sales.csv')
X=df[['price','qty','discount_pct']]
y=df['total_amount']

#테스트와 트레인 분리
X_train,X_test,y_train,y_test=train_test_split(X,y, train_size=0.7, random_state=42)

#스케일링 X_train
sc=StandardScaler().fit(X_train)
X_tr=sc.transform(X_train) #분석대상
X_te=sc.transform(X_test) #예측대상

print('모델 출력') 
for M_name, func in[['OLS',LinearRegression()],
				['Ridge',Ridge(alpha=1.0)],
				['Lasso',Lasso(alpha=1.0, max_iter=10000)]]:
	func.fit(X_tr,y_train)
	tr_score=func.score(X_tr,y_train)
	te_score=func.score(X_te,y_test)
	print(f'{M_name:<8} {tr_score:<10.3f} {te_score:<10.3f}')
				
#모델 출력
#OLS      0.836      0.837     
#Ridge    0.836      0.837     
#Lasso    0.836      0.837

endsubmit;
quit;

proc python;
submit;
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import Lasso
from sklearn.model_selection import train_test_split, GridSearchCV

# 1. 데이터 로드
df = pd.read_csv('/home/student/shop_csv/sales.csv')
X = df[['price', 'qty', 'discount_pct']]
y = df['total_amount']

# 2. Train / Test 분리
X_train, X_test, y_train, y_test = train_test_split(X, y, train_size=0.7, random_state=42)

# 3. 스케일링
sc = StandardScaler().fit(X_train)
X_tr = sc.transform(X_train)
X_te = sc.transform(X_test)

# 4. Alpha 범위를 20개로 줄이고 안전하게 생성
alphas = np.logspace(-3, 3, 20)

# 5. GridSearchCV (핵심: n_jobs=1로 설정하여 메모리 265 에러 방지)
grid = GridSearchCV(
    Lasso(max_iter=10000, random_state=42),
    param_grid={'alpha': alphas}, 
    cv=5, 
    scoring='r2', 
    n_jobs=1  # <- 핵심! 메모리 튕김 방지
)
grid.fit(X_tr, y_train)

# 6. 결과 출력
best_alpha = grid.best_params_["alpha"]
best_score = grid.best_score_

print('── GridSearchCV 최적화 결과 ──')
print(f'최적 Alpha  : {best_alpha:.4f}')
print(f'최적 CV R²  : {best_score:.4f}\n')

# 변수 선택 및 제거 결과
best_model = grid.best_estimator_
selected = [col for col, coef in zip(X.columns, best_model.coef_) if coef != 0]
removed  = [col for col, coef in zip(X.columns, best_model.coef_) if coef == 0]

print('── 변수 선택 결과 ──')
print(f'선택된 변수 (Selected) : {selected}')
print(f'제거된 변수 (Removed)  : {removed}\n')

print('── Lasso 회귀계수 ──')
for col, coef in zip(X.columns, best_model.coef_):
    print(f'  {col:<15} {coef:>12,.2f}')
#── GridSearchCV 최적화 결과 ──
#최적 Alpha  : 26.3665
#최적 CV R²  : 0.8360
#── 변수 선택 결과 ──
#선택된 변수 (Selected) : ['price', 'qty', 'discount_pct']
#제거된 변수 (Removed)  : []

endsubmit;
quit;


proc python;
submit;
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import (mean_squared_error, mean_absolute_error,r2_score,mean_absolute_percentage_error)
# 1. 데이터 로드
df = pd.read_csv('/home/student/shop_csv/sales.csv')
X = df[['price', 'qty', 'discount_pct']]
y = df['total_amount']

# 2. Train / Test 분리
X_tr, X_te, y_tr, y_te = train_test_split(X, y, train_size=0.7, random_state=42)

# 3. 스케일링
sc = StandardScaler().fit(X_tr)
X_trs = sc.transform(X_tr)
X_tes = sc.transform(X_te)

model=LinearRegression().fit(X_trs,y_tr)
y_pred=model.predict(X_tes)

rmse   = np.sqrt(mean_squared_error(y_te, y_pred))
mae    = mean_absolute_error(y_te, y_pred)
r2     = r2_score(y_te, y_pred)
mape   = mean_absolute_percentage_error(y_te, y_pred) * 100
adj_r2 = 1 - (1-r2)*(len(y_te)-1)/(len(y_te)-X_te.shape[1]-1)

print('── S5 · 5 종 회귀 평가지표 ──')
print(f'  RMSE   : {rmse:>12,.0f} 원')
print(f'  MAE    : {mae:>12,.0f} 원')
print(f'  R²     : {r2:>12.4f}')
print(f'  MAPE   : {mape:>12.2f} %')
print(f'  Adj-R² : {adj_r2:>12.4f}')
#── S5 · 5 종 회귀 평가지표 ──
#  RMSE   :      279,551 원
#  MAE    :      155,059 원
#  R²     :       0.8365
#  MAPE   :       616.54 %
#  Adj-R² :       0.8365

import matplotlib.pyplot as plt
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False
fig, axes = plt.subplots(2, 2, figsize=(12, 8))

# (1) 예측 vs 실제 - y=x 위에 모일수록 좋음
axes[0, 0].scatter(y_te, y_pred, alpha=0.4, s=15)
axes[0, 0].plot([y_te.min(), y_te.max()], [y_te.min(), y_te.max()], 'r--')
axes[0, 0].set_xlabel('실제'); axes[0, 0].set_ylabel('예측')
axes[0, 0].set_title(f'예측 vs 실제 (R²={r2:.3f})')

# (2) 잔차 히스토그램
axes[0, 1].hist(y_te - y_pred, bins=40, edgecolor='black')
axes[0, 1].set_title('잔차 분포')

# (3) 잔차 vs 예측값
axes[1, 0].scatter(y_pred, y_te - y_pred, alpha=0.3, s=15)
axes[1, 0].axhline(0, color='r', linestyle='--')
axes[1, 0].set_title('잔차 vs 예측값')

# (4) 오차율 누적 분포
err_pct = np.abs((y_te - y_pred) / y_te.replace(0, np.nan)) * 100
err_pct = err_pct.dropna()
axes[1, 1].hist(err_pct, bins=40, cumulative=True, density=True)
axes[1, 1].set_xlabel('오차율(%)'); axes[1, 1].set_ylabel('누적비율')
axes[1, 1].set_title('오차율 누적 분포')

plt.tight_layout()
plt.savefig('/home/student/shop_csv/eval_plots.png', dpi=100)
plt.close()
print('★ 저장 : /home/student/shop_csv/eval_plots.png')


endsubmit;
quit;

%let snippets=/home/student/snippets;
%include "&snippets/macro/matplot.sas";

%show_png(eval_plots.png);


/* 다항회귀 + 더미변수 */
/*미친 비선형인 그래프를 선형효과로 바꿔주려면 
제곱을 했을떄 선형효과처럼 보인다고 설명하심*/

/* session 6: 비선형 회귀 > 변수 변환을 통해 > 선형으로*/

proc python;
submit;
import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

df=pd.read_csv('/home/student/shop_csv/sales.csv')
# 더미변수 생성 >> category
df=pd.get_dummies(df,columns=['category'],drop_first=True)
print(df.head())
#결과가 좋지않아서 더미변수 빼는게좋아보인다
# 다항 변수 - qty>>qty^2
df['pty_sq']=df['qty']**2

# 단가 >> 왜도 보정하기 위한 log()사용
df['log_price']=np.log1p(df['price'])

# 분석에 필요한 X컬럼과 Y컬럼을 추출
drop_cols=['total_amount','sale_id','sale_date','product_id','price','qty']
X = df.drop(columns=drop_cols)
y=df['total_amount']

model=LinearRegression().fit(X,y)
print(model.score(X,y))#0.6066828207647683
endsubmit;
quit;


PROC PYTHON;
   SUBMIT;
import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split

df = pd.read_csv('/home/student/shop_csv/sales.csv')
y = df['total_amount']

X_base = df[['price', 'qty', 'discount_pct']].copy()
X_poly = X_base.assign(qty_sq=df['qty']**2, price_sq=df['price']**2)
X_log  = X_base.assign(log_price=np.log1p(df['price']))

drop_cols = [c for c in ['total_amount','sale_id','sale_date','product_id']
             if c in df.columns]
X_full = pd.get_dummies(df.drop(columns=drop_cols), drop_first=True)

print(f'{"변환":<15} {"Test R²":>10} {"변수 수":>10}')
print('─' * 40)
for name, X in [('원본       ', X_base),
                ('+ 다항    ', X_poly),
                ('+ 로그    ', X_log),
                ('+ 더미(전체)', X_full)]:
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.3, random_state=42)
    m = LinearRegression().fit(Xtr, ytr)
    print(f'{name:<15} {m.score(Xte, yte):>10.4f} {X.shape[1]:>10}')
#변환                 Test R²       변수 수
#────────────────────────────────────────
#원본                  0.8365          3
#+ 다항                0.8365          5
#+ 로그                0.8365          4
#+ 더미(전체)            0.8365         45
   ENDSUBMIT;
QUIT;









