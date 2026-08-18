
proc python ;
	submit;
import pandas as pd
from sklearn.model_selection import train_test_split

df = pd.read_csv("/home/student/shop_csv/users.csv")


X = df.drop(columns=['churn', 'user_id'])
y = df['churn']

print(df.head())
print(X.head())
print(y.head())

# 60:40 train:test 분리
X_tr, X_te, y_tr, y_te = train_test_split(
    X, y, random_state=42, stratify=y, train_size=0.6
)

print(f'train:{len(X_tr):,}행 churn 비율{y_tr.mean():.3f}')
print(f'test:{len(X_te):,}행 churn 비율{y_te.mean():.3f}')
endsubmit;
quit;


proc python;