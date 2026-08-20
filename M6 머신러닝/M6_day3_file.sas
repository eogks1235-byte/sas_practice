%let csv_dir = /home/student/shop_csv;

proc python;
	submit;
import pandas as pd

# 1. 경로 가져오기
csv_dir = SAS.symget('csv_dir')

# 2. 데이터 불러오기 및 전처리
users_path = csv_dir + '/users_dirty.csv'
sales_path = csv_dir + '/sales.csv' # (예시) sales 파일 경로

users = pd.read_csv(users_path)
sales = pd.read_csv(sales_path) # (예시) sales 불러오기

if users['user_id'].dtype == 'object':
	users['user_id'] = users['user_id'].str[2:].astype(int)

# ★ 3. users_sales_merged 변수 생성 (이 부분이 to_csv보다 먼저 와야 합니다!)
users_sales_merged = pd.merge(users, sales, on='user_id', how='left')

# 4. 저장하기
save_path = csv_dir + '/users_sales_merged.csv'
users_sales_merged.to_csv(save_path, index=False)

endsubmit;
quit;