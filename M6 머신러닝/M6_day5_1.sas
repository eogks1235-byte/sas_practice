%let snippets=/home/student/snippets;
%let csv_dir=/home/student/shop_csv;
%include "&snippets./macro/matplot.sas";
/* macro show_png 삽입 */
proc python;
submit;
import pandas as pd
import numpy as np
import sys
snippets = SAS.symget('snippets')
csv_dir=SAS.symget('csv_dir')
sys.path.append(snippets + '/python') # snippets 경로 추가
import matplot_kr as kr # matplot_kr.py코드삽입
from scipy import stats
from sklearn.linear_model import LinearRegression

df=pd.read_csv(csv_dir+'/sales.csv')
X=df[['price','qty','discount_pct']]
y=df['total_amount']


model = LinearRegression().fit(X, y)
pred  = model.predict(X)
resid = y - pred

# 2x2 진단 도표 (LINE 4 가정)
fig, axes = kr.plt.subplots(2, 2, figsize=(12, 8))

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

kr.plt.tight_layout()
kr.plt.savefig(csv_dir+'diagnostics.png', dpi=100)
kr.plt.close()
print(f'★ 저장 : {csv_dir}/diagnostics.png')


endsubmit;
quit;
%show_png(diagnostics.png);
/* 스니펫 사용해서 경로 땜빵하기 */










