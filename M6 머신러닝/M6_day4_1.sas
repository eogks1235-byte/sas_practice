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














