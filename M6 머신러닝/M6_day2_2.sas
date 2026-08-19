proc python;
submit;

import pandas as pd

df=pd.read_sas("/home/student/shop_db/users.sas7bdat")
print(df.info())
print(df.head())

endsubmit;
quit;

proc python;
submit;

import pandas as pd
import sqlite3
#df=pd.read_sas("/home/student/shop_db/users.sas7bdat")


# (1) CSV 읽기- 가장 일반적
df_csv = pd.read_csv('/home/student/shop_csv/users_dirty.csv',
					encoding='utf-8',
					parse_dates=['signup_date'])  # 날짜 자동 변환
print(df_csv.head())
# (2) SAS sas7bdat 직접 읽기
df_sas = pd.read_sas('/home/student/shop_db/users_dirty.sas7bdat',
encoding='utf-8')
# (3) SQL 쿼리 (예시- sqlite)
conn = sqlite3.connect('/tmp/shop.db')
conn.close()


df_sql = pd.read_sql('SELECT * FROM users WHERE vip_grade="VIP"', conn)
print(f'CSV {df_csv.shape} / SAS {df_sas.shape} / SQL {df_sql.shape}')
ENDSUBMIT; QUIT
endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

#원본의 행과 열의 수
print(f'월본 (결측포함): {df.shape}')

missing_pct=df.isnull().sum() /len(df)*100
print(missing_pct)
print(missing_pct[missing_pct>0])

#결측처리 age 컬럼의 nan을 age의 중앙값으로 변경
print(df['age'].head(10))
df['age']=df['age'].fillna(df['age'].median())
print(df['age'].head(10))

# toal_spent >nan을 0으로
print(df['total_spent'].iloc[210:220])
df['total_spent']=df['total_spent'].fillna(0)
print(df['total_spent'].iloc[210:220])

# vip_grade 컬럼의 nan 값 
df['vip_grade'] = df['vip_grade'].fillna(df['vip_grade'].mode()[0])

# channel이 nan인 행을제거
df=df.dropna(subset=['channel'])
print(f'결측처리후{df.shape}')
endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

null_indices = []

# index와 값(value)을 동시에 순회
for idx, val in enumerate(df['total_spent']):
    if pd.isna(val):  # 값이 결측치(NaN/None)인지 확인
        null_indices.append(idx)

print("널값 인덱스 목록:", null_indices)

endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

#이상치 제거 >> q1, q3, iqr >> lo, hi

q1,q3=df['total_spent'].quantile([0.25,0.75])
iqr=q3-q1
lo,hi=q1-iqr*1.5, q3+iqr*1.5
df=df[ (df['total_spent'] >=lo) & (df['total_spent']<=hi)]
print(f'이상치 처리후 : {df.shape}')
endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')


endsubmit;
quit;