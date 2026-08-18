/*sas 안에 python있지만 
우리는 sas에서 python을 사용하는방법을 이용*/

libname shop_db '/home/student/shop_db';

%let csvdir=/home/student/shop_csv;

/* csv to sas macro*/
%macro imp(name=);
	proc import datafile="&csvdir/&name..csv"
	out=shop_db.&name
	dbms=csv replace;
	getnames=yes;
	guessingrows=max;
run;
%put note:=====&name..csv -> shop_db.&name 변환완료=====;
%mend;

%imp(name=users);
%imp(name=users1);
%imp(name=users_dirty);
%imp(name=users_dirty1);



/*churn 데이터 분포 확인*/
proc contents data=shop_db.users
	varnum;
run;

proc freq data=shop_db.users;
	tables churn / nocum;
run;
/*The FREQ Procedure

churn	빈도	백분율
0		2400	80.00
1		600	20.00
*/

/*users >> churn 기준으로 sort*/
proc sort data=shop_db.users
	out=users_sorted;
	by churn;
run;

/* train 6: test 4*/
proc surveyselect data=work.users_sorted
	out=work.split
	samprate=0.60
	seed=42
	outall;/*전체출력*/
strata churn;
run;

/*train >> selected 1, 0이면 test*/
data train test;
	set split;
	if selected=1 then output train;
	else output test;
run;

/*데이터 검증*/
proc freq data=train;
	tables churn / nocum;
run;
/*The FREQ Procedure

churn	빈도	백분율
0		1440	80.00
1		360	20.00
*/

proc freq data=test;
	tables churn / nocum;
run;
/*

churn	빈도	백분율
0		960		80.00
1		240		20.00
*/

proc export data =shop_db.users
	outfile = '/home/student/shop_db/users_copy.csv'
	dbms=csv replace;
run;
/*shop_db폴더안에 users_copy.csv생성*/

proc python;
submit;
print('Hello from sas Python !!')
print('머신러닝 start')
a=100
b=200
print(f'{a}+{b}={a+b}')
endsubmit;
quit;

proc python;
submit;

#users.csv file read
#데이터 관측
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users.csv')
print(f'행수 : {df.shape[0]},컬럼수:{df.shape[1]},컬럼목룍:{list(df.columns)}')
print()
#첫 5행보기
print(df.head())
endsubmit;
quit;

proc python;
submit;
import sys
import pandas as pd
import numpy as np
import sklearn 

print('-'*50)
print(f'Python 버전 : {sys.version.split()[0]}')
print(f'pandas       : {pd.__version__}')
print(f'numpy        : {np.__version__}')
print(f'scikit-learn : {sklearn.__version__}')
print('-'*50)

endsubmit;
quit;


/*sas에서 임계값정리*/
%let vip_threshold=100000;
%let min_age=18;

/*python에서 매크로 변수사용*/

proc python;
submit;
import pandas as pd

vip_threshold=float(SAS.symget('vip_threshold'))
min_age=int(SAS.symget('min_age'))


df=pd.read_csv('/home/student/shop_csv/users.csv')
vip=df[(df.age>=min_age)&(df.total_spent>=vip_threshold)]
vip_count=len(vip)
vip_pct=vip_count/len(df)*100

SAS.symput('vip_count',str(vip_count))
SAS.symput('vip_pct',f'{vip_pct:.2f}')
endsubmit;
quit;
%PUT VIP 고객 수: &vip_count;
%PUT VIP 비율: &vip_pct%;
/*sas는 대문자로 sys아니고 sym이다 */

/*뭐여 print문이없어서 결과창이안보였었음*/

proc export data=shop_db.users(keep= user_id channel age total_spent churn)
	outfile='/home/student/shop_csv/user_churn.csv'
dbms=csv replace;
run;

proc python ;
submit;
import pandas as pd
df=pd.read_csv('/home/student/shop_csv/user_churn.csv')

stats=df.groupby('channel').agg(
	n_users=('user_id','count'),
	avg_spent=('total_spent','mean'),
	churn_rate=('churn','mean')
).round(2)
#/*컬럼명 (들어갈값 을 어던걸로계산해서넣을지)*/
print(stats)
stats.to_csv('/home/student/shop_csv/channel_stats.csv')

endsubmit;
quit;

proc import datafile='/home/student/shop_csv/channel_stats.csv'
	out=stats dbms=csv replace;
run;

proc print data=stats;
run;

/*
1. 데이터셋로드
2. 데이터구조확인
3. 통계정보확인
4. vip회원식별 macro=기준 만들기
	total_spent 200000이상 order_count 10이상*/

/*let은 하드코딩  비교연산사불가*/
%let vip_spent = 200000;
%let vip_count = 10;

proc python;
submit;
import pandas as pd

vip_spent = float(SAS.symget('vip_spent'))
vip_count = int(SAS.symget('vip_count'))

df = pd.read_csv('/home/student/shop_csv/users.csv')

# --- 디버그: 실제 컬럼명과 데이터 형태부터 확인 ---
print('컬럼목록:', df.columns.tolist())
print('행수:', len(df))
print(df.dtypes)

if 'order_count' not in df.columns:
    print('경고: order_count 컬럼이 없어서 전부 0으로 대체됨 -> VIP 조건이 항상 거짓이 될 수 있음')
    df['order_count'] = 0

# total_spent가 문자열로 읽혔을 가능성 대비 - 숫자 강제 변환
df['total_spent'] = pd.to_numeric(df['total_spent'], errors='coerce')
df['order_count'] = pd.to_numeric(df['order_count'], errors='coerce')

vip = df[(df['total_spent'] >= vip_spent) & (df['order_count'] >= vip_count)]

print(f'전체 회원수: {len(df)}')
print(f'VIP 회원수: {len(vip)} / 비율: {len(vip)/len(df) if len(df)>0 else 0:.4f}')

SAS.symput('vip_n', str(len(vip)))
SAS.symput('vip_rate', str(len(vip)/len(df)) if len(df)>0 else '0')
endsubmit;
run;

%put NOTE: vip회원수 = &vip_n;
%put NOTE: vip비율 = &vip_rate;

PROC PYTHON;
SUBMIT;
import pandas as pd
df = pd.read_csv('/home/student/shop_csv/users.csv')
# [1] 데이터 크기
print(f'행 수: {df.shape[0]:,} / 컬럼 수: {df.shape[1]}')
# [2] 결측치 확인
print('결측치 비율:')
print(df.isnull().mean().sort_values(ascending=False).head())
# [3] 수치 변수 요약
print(df[['age', 'total_spent', 'order_count', 'recency']].describe())
# [4] 범주 변수 분포
print('채널별 분포:')
print(df.channel.value_counts(normalize=True).round(3))
# [5] 이탈률 (타겟 변수)
print(f'이탈률: {df.churn.mean():.2%}')
# [6] 이상치 진단- IQR
Q1, Q3 = df.total_spent.quantile([0.25, 0.75])
upper = Q3 + 1.5 * (Q3 - Q1)
outliers = df[df.total_spent > upper]
print(f'이상치: {len(outliers):,} ({len(outliers)/len(df):.1%})')

ENDSUBMIT;
QUIT;


/*AI활용 프롬프트*/
proc python;
submit;
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, roc_auc_score

# 1. 데이터 로드
file_path = '/home/student/shop_csv/users.csv'
df = pd.read_csv(file_path)

# 2. 독립변수(X) 및 종속변수(y) 설정
features = ['age', 'total_spent', 'order_count', 'recency']
target = 'churn'

X = df[features]
y = df[target]

# 3. 데이터 분할 (Train 7: Test 3, random_state=42)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

# 4. 이진분류 모델 생성 및 학습 (Random Forest)
model = RandomForestClassifier(random_state=42)
model.fit(X_train, y_train)

# 5. 예측 및 평가
y_pred = model.predict(X_test)
y_pred_proba = model.predict_proba(X_test)[:, 1]

accuracy = accuracy_score(y_test, y_pred)
auc = roc_auc_score(y_test, y_pred_proba)

# 6. 결과 출력
print("=== 모델 평가 결과 ===")
print(f"정확도 (Accuracy) : {accuracy:.4f}")
print(f"ROC AUC Score     : {auc:.4f}")

endsubmit;
run;




