libname shop_db'/home/student/shop_db';

%let csv_dir =/home/student/shop_csv;

/* K-Means >> users_clean.csv */

proc python;
submit;

# users_clean >> 'age', 'total_spent','order_count','recency'
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

file_path=SAS.symget('csv_dir')+'/users_clean.csv'
df=pd.read_csv(file_path)

#데이터확인 (50249, 10)
print(df.shape)
print(df.head())

X_cols=['age', 'total_spent','order_count','recency']
X=df[X_cols]
print(X.shape) #(50249, 4)

#스케일링 - 필수
scaler=StandardScaler()
X_s=scaler.fit_transform(X)

# KMeans 학습 - 4그룹
kmeans= KMeans(
	n_clusters=4,
	init= 'k-means++',
	n_init=10,
	max_iter=300,
	random_state=42)
df['cluster']=kmeans.fit_predict(X_s)
print(f'k=4,n={len(df)} ')
print(df['cluster'].head())
print(f' wcss(inertia_) ={kmeans.inertia_:,.0f}')

#WCSS (Within-Cluster Sum of Squares): 각 군집의 중심점(Centroid)과 군집 내
# 데이터 점들 사이의 거리를 제곱해서 싹 더한 값(군집 내 오차제곱합)입니다.
#해석 방법:
#이 값이 작을수록 군집끼리 아주 빽빽하게 잘 뭉쳐있다는 뜻입니다.

print(kmeans.labels_)

#그룹별 회원수
print('--- 그룹별 회원수 분류 ---')
print(df['cluster'].value_counts().sort_index())

#그룹별 평균값 
summary= df.groupby('cluster')[X_cols].mean().round(1)
print(f'그룹별 평균값 : {summary}')


# 그래프 그리기 위한 라이브러리 import
import matplotlib.pyplot as plt
from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False

# 시각화 PCA 2D - 4그룹의 색을 다르게 구분 
from sklearn.decomposition import PCA
X_pca=PCA(n_components=2).fit_transform(X_s)
# 가로는 PC1 세로는 PC2

plt.figure(figsize=(10,6))
plt.scatter(X_pca[:,0], X_pca[:,1], c=df['cluster'], cmap='viridis',
		alpha=0.5, s=20)
plt.xlabel('PC1')
plt.ylabel('PC2')
plt.title('users K-Means 4그룹 ')
plt.colorbar(label='Cluster')
plt.tight_layout()
plt.savefig(SAS.symget('csv_dir')+'/users_kmeans.png')

df.to_csv(SAS.symget('csv_dir')+'/users_kmeas.csv')
endsubmit;
quit;

%let csv_path=/home/student/shop_csv;

%MACRO show_png(fname, title=matplotlib);
   ODS ESCAPECHAR='^';
   PROC ODSTEXT;
      P "&title"
        / STYLE=[FONTWEIGHT=BOLD FONTSIZE=13PT COLOR=CX1F3864
                 JUST=CENTER MARGINBOTTOM=6PT];
      P " "
        / STYLE=[PREIMAGE="&CSV_PATH/&fname" JUST=CENTER
                 BORDERCOLOR=CXDDDDDD BORDERWIDTH=1PT PADDING=4PT];
   RUN;
%MEND show_png;

%let snippets=/home/student/snippets;
%include '&snippets/macro/matplot.sas';
%show_png(users_kmeans.png, title=K-Means 4그룹 군집화 결과);