libname shop_db'/home/student/shop_db';

%let csv_dir =/home/student/shop_csv;

/* K-Means >> users_clean.csv */

proc python;
submit;

# users_clean >> 'age', 'total_spent','order_count','recency'
import pandas as pd
file_path=SAS.symget('csv_dir')+'/users_clean.csv'
df=pd.read_csv(file_path)

#데이터확인 (50249, 10)
print(df.shape)
print(df.head())

X_cols=['age', 'total_spent','order_count','recency']
X=df[X_cols]
print(X.shape)#(50249, 4)


endsubmit;
quit;