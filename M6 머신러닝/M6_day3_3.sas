proc python;
submit;
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

# 그래프 설정
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os

_font_path = '/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path)
plt.rcParams['font.family'] = 'Malgun Gothic'
plt.rcParams['axes.unicode_minus'] = False

csv_path = SAS.symget('csv_dir')

df = pd.read_csv(csv_path + '/users.csv').dropna()
X_cols = ['age', 'total_spent', 'order_count', 'recency']
X = df[X_cols]

# 스케일링
scaler = StandardScaler()
X_s = scaler.fit_transform(X)

# Silhouette 계산용 샘플링
sample_size = min(5000, len(df))
sample_idx = np.random.RandomState(42).choice(len(df), size=sample_size, replace=False)
X_sample = X_s[sample_idx]

# K 후보값 찾기 (k: 2 ~ 10)
wcss, sil = [], []
k_list = list(range(2, 11))

for k in k_list:
	# 1. Elbow (전체 데이터 기준)
	km = KMeans(n_clusters=k, random_state=42, n_init=10)
	km.fit(X_s)
	wcss.append(km.inertia_)
	
	# 2. Silhouette (샘플링 데이터 기준)
	km_s = KMeans(n_clusters=k, random_state=42, n_init=10)
	sample_labels = km_s.fit_predict(X_sample)
	sil_score = silhouette_score(X_sample, sample_labels)
	sil.append(sil_score)

	print(f'k={k:2d} | WCSS={km.inertia_:10.0f} | Silhouette={sil_score:.3f}')

# 최적의 k 구하기
best_k = k_list[sil.index(max(sil))]
print(f'최적 k = {best_k} | Silhouette = {max(sil):.3f}')

# 그래프로 확인 - Elbow, Silhouette (오타 수정 파트)
fig, ax = plt.subplots(1, 2, figsize=(9.5, 4)) # subplot -> subplots

# 1. Elbow Plot
ax[0].plot(k_list, wcss, 'o-', linewidth=2) # linewith -> linewidth
ax[0].set_xlabel('K')
ax[0].set_ylabel('WCSS')
ax[0].set_title('Elbow Method') # title -> set_title
ax[0].axvline(best_k, color='r', linestyle='--', label=f'Best K={best_k}')
ax[0].legend()

# 2. Silhouette Plot
ax[1].plot(k_list, sil, 'o-', linewidth=2, color='green') # color='green' 문자열 수정
ax[1].set_xlabel('K')
ax[1].set_ylabel('Silhouette Score')
ax[1].set_title('Silhouette Score') # title -> set_title
ax[1].axvline(best_k, color='r', linestyle='--', label=f'Best K={best_k}')
ax[1].legend()

plt.tight_layout()
plt.savefig(f'{csv_path}/k_selection.png', dpi=100)
plt.close()

endsubmit;
quit;

/* SAS 리포트에 저장된 이미지 출력 */
%show_png(k_selection.png, title=K-Means 최적 K값 탐색 결과);