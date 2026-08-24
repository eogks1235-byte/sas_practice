libname shop_db '/home/student/shop_db';

%let snippets=/home/student/snippets;
%let csv_dir=/home/student/shop_csv;
%include "&snippets./macro/matplot.sas";

/* %let snippets=/home/student/snippets; */
/* %include "&snippets/macro/matplot.sas"; */
/*  */
/* %show_png(diagnostics.png); */

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

/*DecisionTree*/
proc python;
	submit;
import pandas as pd
import sys
import os

from sklearn.tree import DecisionTreeClassifier, plot_tree
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, roc_auc_score

# 1. 경로 설정 및 한글 폰트 모듈 로드
snippets = SAS.symget('snippets')
csv_dir = SAS.symget('csv_dir')
sys.path.append(os.path.join(snippets, 'python'))
import matplot_kr as kr

# 2. 데이터 로드
csv_path = os.path.join(csv_dir, 'users.csv')
df = pd.read_csv(csv_path)

X_cols = ['age', 'total_spent', 'order_count', 'recency']
X = df[X_cols]
y = df['churn']

# 3. Train / Test 분리 및 스케일링
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)
sc = StandardScaler().fit(X_tr)
X_trs, X_tes = sc.transform(X_tr), sc.transform(X_te)

# 4. 의사결정나무 모델 학습
model = DecisionTreeClassifier(max_depth=5, random_state=42, min_samples_leaf=50, criterion='gini')
model.fit(X_trs, y_tr)

# 5. 성능 평가 출력
pred = model.predict(X_tes)
prob = model.predict_proba(X_tes)[:, 1]
print(f'Accuracy: {accuracy_score(y_te, pred):.3f}')
print(f'AUC : {roc_auc_score(y_te, prob):.3f}')

# 6. 트리 시각화 생성 및 이미지 저장
fig = kr.plt.figure(figsize=(20, 10))

# [수정 1] X.columns 뒤에 .tolist() 추가
plot_tree(model, feature_names=X.columns.tolist(), class_names=['잔류', '이탈'], filled=True, fontsize=10)

# 저장 경로 조합
save_path = os.path.join(csv_dir, 'tree.png')

# 파일 저장 및 캔버스 닫기
kr.plt.savefig(save_path, dpi=100, bbox_inches='tight')
kr.plt.close(fig)

print(f"이미지 저장 성공: {os.path.exists(save_path)}")

# Accuracy: 0.810
# AUC : 0.753
endsubmit;
quit;


%show_png(tree.png);



/* Random Forest 변수 중요도 */
proc python;
	submit;
import pandas as pd
import sys
import os

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from sklearn.metrics import accuracy_score, roc_auc_score

# 1. 경로 설정 및 한글 폰트 모듈 로드
snippets = SAS.symget('snippets')
csv_dir = SAS.symget('csv_dir')
sys.path.append(os.path.join(snippets, 'python'))
import matplot_kr as kr

# 2. 데이터 로드
csv_path = os.path.join(csv_dir, 'users.csv')
df = pd.read_csv(csv_path)

X_cols = ['age', 'total_spent', 'order_count', 'recency']
X = df[X_cols]
y = df['churn']

# 3. Train / Test 분리 및 스케일링
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)

# 4. 의사결정나무 모델 학습
model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
model.fit(X_tr, y_tr)

# 변수 중요도
importance=pd.Series(model.feature_importances_,index=X.columns)
print(importance.sort_values(ascending=False))

#recency        0.413281
#total_spent    0.232799
#order_count    0.208707
#age            0.145213
pred=model.predict(X_te)
prob=model.predict_proba(X_te)[:,1]

print(f'Accuracy:{accuracy_score(y_te,pred):.3f}')
print(f'AUC:{roc_auc_score(y_te,prob):.3f}')
#Accuracy:0.814
#AUC:0.760
#recency        0.413281
#total_spent    0.232799
#order_count    0.208707
#age            0.145213

importance=pd.Series(model.feature_importances_,index=X_cols)
print(importance.sort_values(ascending=False))

snippets=SAS.symget('snippets')
sys.path.append(snippets+'/python')
import matplot_kr as kr

kr.plt.figure(figsize=(8,4))
importance.plot(kind='barh',color='steelblue')
kr.plt.xlabel('중요도')
kr.plt.title('shop.users_ml 이탈예측 변수중요도')
kr.plt.tight_layout()
kr.plt.savefig(csv_dir+'/rf_importance.png',dpi=100)
kr.plt.close()

endsubmit;
quit;
%show_png(rf_importance.png);


libname shop_db '/home/student/shop_db';

/* logistic */
proc logistic data= shop_db.users descending;
	model churn = age total_spent order_count recency / ctable pprob=0.5;
run;
/*
Classification Table
Prob
Level	Correct	Incorrect	Percentages
		Event	Non-
				Event	Event	Non-
								Event	Correct	Sensi-
												tivity	Speci-
														ficity		Pos
																	Pred	Neg
																			Pred
0.500	1919	38844	1156	8081	81.5	19.2	97.1		62.4	82.8
*/

proc hpforest data=shop_db.users maxtrees=100 vars_to_try=2;
	target churn /level=binary ;
	input age total_spent order_count recency / level =interval;
run;

/*
Loss Reduction Variable Importance
Variable	Number
			of Rules	Gini	OOB
								Gini		Margin		OOB
														Margin
order_count	55165	0.032385	0.00028		0.064770	0.033359
age			93486	0.040853	-0.03058	0.081706	0.011404
recency		166997	0.079226	-0.03087	0.158452	0.052064
total_spent	218921	0.093074	-0.08278	0.186148	0.008443
*/
proc python;
submit;
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
for name, m in[('Logistic', LogisticRegression(max_iter=1000)),
		('RandomForest',RandomForestClassifier(n_estimators=100, random_state=42))]:

	m.fit(X_tr,y_tr)
	prob=m.predict_proba(X_te)[:,1]
	print(f'{name}AUC={roc_auc_score(y_te,prob):.3f}')

endsubmit;
quit;

libname shop_db '/home/student/shop_db';

%let snippets=/home/student/snippets;
%let csv_dir=/home/student/shop_csv;
%include "&snippets./macro/matplot.sas";

proc python;
	submit;
import pandas as pd
import sys
import os

from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, classification_report, roc_auc_score, roc_curve
)

# 1. 경로 설정 및 한글 폰트 모듈 로드
snippets = SAS.symget('snippets')
csv_dir = SAS.symget('csv_dir')
sys.path.append(os.path.join(snippets, 'python'))
import matplot_kr as kr

# 2. 데이터 로드 및 전처리
csv_path = os.path.join(csv_dir, 'users.csv')
df = pd.read_csv(csv_path)

X_cols = ['age', 'total_spent', 'order_count', 'recency']
X = df[X_cols]
y = df['churn']

# Train / Test 분리
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)

# 스케일링 (로지스틱 회귀용)
sc = StandardScaler().fit(X_tr)
X_trs, X_tes = sc.transform(X_tr), sc.transform(X_te)

# 3. Random Forest 모델 학습 및 지표 출력
rf = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
rf.fit(X_tr, y_tr)

pred = rf.predict(X_te)
prob = rf.predict_proba(X_te)[:, 1]

print("=== Random Forest 평가 지표 ===")
print(f'Accuracy  = {accuracy_score(y_te, pred):.3f}')
print(f'Precision = {precision_score(y_te, pred):.3f}')
print(f'Recall    = {recall_score(y_te, pred):.3f}')
print(f'F1        = {f1_score(y_te, pred):.3f}')
print(f'AUC       = {roc_auc_score(y_te, prob):.3f}')

print("\n=== Confusion Matrix ===")
print(confusion_matrix(y_te, pred))

#=== Random Forest 평가 지표 ===
#Accuracy  = 0.814
#Precision = 0.605
#Recall    = 0.202
#F1        = 0.303
#AUC       = 0.760
#=== Confusion Matrix ===
#[[11605   395]
# [ 2394   606]]

# 4. Logistic Regression 모델 학습 및 ROC 비교 시각화
lr = LogisticRegression(max_iter=1000, random_state=42)
lr.fit(X_trs, y_tr)
prob_lr = lr.predict_proba(X_tes)[:, 1]

fpr_rf, tpr_rf, _ = roc_curve(y_te, prob)
fpr_lr, tpr_lr, _ = roc_curve(y_te, prob_lr)

fig = kr.plt.figure(figsize=(8, 6))
kr.plt.plot(fpr_rf, tpr_rf, label=f'RandomForest (AUC = {roc_auc_score(y_te, prob):.3f})', color='blue')
kr.plt.plot(fpr_lr, tpr_lr, label=f'Logistic (AUC = {roc_auc_score(y_te, prob_lr):.3f})', color='green', linestyle='--')
kr.plt.plot([0, 1], [0, 1], 'k--', color='gray', label='Random Guess')

kr.plt.xlabel('FPR (1 - Specificity)')
kr.plt.ylabel('TPR (Recall)')
kr.plt.title('ROC Curve Comparison')
kr.plt.legend()

# 이미지 저장
save_path = os.path.join(csv_dir, 'roc.png')
kr.plt.savefig(save_path, dpi=100, bbox_inches='tight')
kr.plt.close(fig)

print(f"이미지 저장 성공: {os.path.exists(save_path)}")

endsubmit;
quit;

/* 5. 저장된 ROC 곡선 이미지 출력 */
%show_png(roc.png);




