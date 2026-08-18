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











































































































