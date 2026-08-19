/* session 4:데이터 수치와 범주형 변환*/

proc python;
submit;
import pandas as pd
from sklearn.preprocessing import StandardScaler

df= pd.read_csv('/home/student/shop_csv/users_dirty.csv')
print(df.info())

#수치형변수 >> age, total_spent, order_count, recency
num_cols=['age','total_spent','order_count','recency']
#범주형변수 >> gender, channel, vip_grade, churn
cat_cols=['gender', 'channel', 'vip_grade', 'churn']

#수치형 변수를 평균0 표준편차를 1로 스케일링
scaler =StandardScaler()
df[num_cols]=scaler.fit_transform(df[num_cols])
#범주형 변수를 onehotencodeing으로 스케일링
print(f'컬럼원형 :{df.columns}')
df=pd.get_dummies(df, columns = cat_cols, drop_first=True)
print(f'범주형 onehotencoding 후 컬럼 : {df.columns}')
print(df[num_cols].head())

# 모든 컬럼의 데이터 타입 확인
print(df.dtypes.value_counts())

print(df.head())

# 전처리 실행한 데이터 저장
df.to_csv('/home/student/shop_csv/users_ml.csv',index=False)
# 이렇게하면 맨앞에 인덱스포함 파일생성 그래서 index=False
endsubmit;
quit;
/*결측치 이상치 스케일러 수치형 범주형 */
/*df 를 df1에 넣으면 df1을 수정하면 df가 수정되는게 맞아? ㅇㅇ*/
















