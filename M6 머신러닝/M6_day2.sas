libname shop_db '/home/student/shop_db';

/*session 1 : 데이터 탐색 */
proc python;
submit;

import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

print(df.head())
print(df.shape)
print(df.info())
print(df.describe())
# 컬럼선택 >> age 컬럼을 선택해서 ages에 저장 
ages=df['age']
print(ages.head())

subset=df[['age','total_spent','churn']]
print(subset.tail())


vip=df[df['vip_grade']==5.0]
print(vip.head())#?
print(df['vip_grade'].head())
young=df.query('age < 30 and total_spent > 100000')

print(young.head())
young_df=df[ (df['age']<30) & (df['total_spent']>100000) ]

print(df['channel'].value_counts())
print(df['vip_grade'].value_counts())
endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

vip=df[df['vip_grade']==5.0]
print(vip.head())

endsubmit;
quit;

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')
#여러개의 값매치 -isin
active=df[df['channel'].isin(['paid_search','social'])]
print(active.head())#2개가없다

print(df['channel'].value_counts())
active1=df[df['channel'].isin(['MOBILE','WEB'])]
print(active1.head())

endsubmit;
quit;
/*다중정렬*/
proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')
sorted_df=df.sort_values(['channel','total_spent'])
print(sorted_df[['channel','total_spent']].head(10))
endsubmit;
quit;
/*정렬*/
proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')
top10=df.sort_values('total_spent',ascending=False).head(10)
print(top10[['user_id','total_spent']])
endsubmit;
quit;
/* 로우와 컬럼 동시 선택 > age >30이상인 행만, 컬럼은
age, channel, total_spent*/
proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')

subset=df.loc[df['age']>30 , ['age','channel','total_spent']]
#행 30살이상 열 은 선택한3개 
print(subset.head())
endsubmit;
quit;

/*-------------------------------------------------------*/

proc python;
submit;
import pandas as pd

df=pd.read_csv('/home/student/shop_csv/users_dirty.csv')


endsubmit;
quit;