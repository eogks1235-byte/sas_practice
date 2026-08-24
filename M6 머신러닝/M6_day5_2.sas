libname shop_db '/home/student/shop_db';

%let snippets=/home/student/snippets;
%let csv_dir=/home/student/shop_csv;
%include "&snippets./macro/matplot.sas";

/*  users >> users_ml 로 복사 후 이진 분류 시작 */
/*  */
/* data shop_db.users_ml; */
/* 	set shop_db.users; */
/* run; */
/* 	 */
/* python에서 sas data users_ml을 read 해서 데이터 타입과 */
/* 데이터 정보 데이터 shape, churn -> 이탈율 출력 */
/*  */
/* proc freq data=shop_db.users_ml; */
/* 	tables churn /nocum nopercent */
/* ;run; */
/*
이탈율 : churn
0.0    40000
1.0    10000
*/
proc python ;
	submit;
import pandas as pd
csv_path=SAS.symget('csv_dir')
df=SAS.sd2df('shop_db.users_ml')
#df= pd.read_csv('/home/student/shop_db/users.sas7bdat')
print(df.head())
print(f'shop_db.users_ml : {df.shape}')

# churn 분포(이진 분류 타겟)
print(f"데이터분포(churn) : {df['churn'].value_counts()}")
#이탈율 : churn (0.0    40000) (1.0    10000)
print(f"이탈율 : {df['churn'].mean():.2f}")
#이탈율 : 0.20

#logistic regression
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, roc_auc_score

X_cols=['age','total_spent','order_count','recency']
X=df[X_cols]
y=df['churn']

#train /test 분리
X_tr,X_te ,y_tr,y_te=train_test_split(X,y,test_size=0.3,stratify=y,random_state=42)

#스케일링
sc=StandardScaler().fit(X_tr)
X_trs,X_tes = sc.transform(X_tr),sc.transform(X_te)

#모델 생성
model=LogisticRegression(max_iter=1000, random_state=42)
model.fit(X_trs,y_tr)

#예측 
pred=model.predict(X_tes) #테스트 데이터로
prob=model.predict_proba(X_tes)[:,1]#모든행에서 이탈율찾기


print(f'Accuracy: {accuracy_score(y_te, pred):.3f}')
print(f'AUC : {roc_auc_score(y_te, prob):.3f}')

# Accuracy: 0.813
# AUC : 0.757

endsubmit;
quit;





