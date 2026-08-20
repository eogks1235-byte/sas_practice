libname shop_db '/home/student/shop_db';


data work.users_clean;
	set shop_db.users;
	if nmiss(of _numeric_)=0;
	if total_spent <10000000;
run;

proc sql;
	select count(*) from shop_db.users;
	select count(*) from work.users_clean;

PROC FASTCLUS DATA=work.users_clean
              MAXCLUSTERS=4
              MAXITER=20
              OUT=work.sas_result
              SUMMARY;
   VAR age total_spent order_count;
   TITLE2 "S5-A · PROC FASTCLUS K=4";
RUN;

/* (3) SAS 결과 - 군집 비율 확인 */
PROC FREQ DATA=work.sas_result;
   TABLES CLUSTER / NOCUM NOPERCENT;
   TITLE2 "S5-A · SAS 군집 분포";
RUN;


/* ── [실습 S5-B] Python sklearn 비교 · [PPT slide 32~33] ───── */
PROC PYTHON;
   SUBMIT;
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

csv_path = SAS.symget('CSV_PATH')

df = pd.read_csv('/home/student/shop_csv/users.csv').dropna()
X_cols = [c for c in ['age', 'total_spent', 'order_count', 'recency'] if c in df.columns]
X = df[X_cols]
X_s = StandardScaler().fit_transform(X)

km = KMeans(n_clusters=4, random_state=42, n_init=10)
df['cluster_py'] = km.fit_predict(X_s)

print('── Python sklearn 군집 분포 ──')
print(df['cluster_py'].value_counts().sort_index())
print()
print('★ SAS PROC FASTCLUS ↔ Python sklearn : 군집 비율 거의 동일 · 라벨 번호만 다름')

df[['user_id','cluster_py']].to_csv(f'{csv_path}/users_py_cluster.csv', index=False)
   ENDSUBMIT;
QUIT;
