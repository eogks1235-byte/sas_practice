PROC PYTHON;
SUBMIT;
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
df = pd.read_csv('/home/student/shop_csv/users_dirty.csv').dropna()
X = df.drop(columns=['churn'])
y = df['churn']
# (1) 변수 분리
num_cols = ['age', 'total_spent', 'order_count', 'recency']
cat_cols = ['gender', 'channel', 'vip_grade']
# (2) ColumnTransformer - 컬럼별 다른 처리
preprocessor = ColumnTransformer([
('num', StandardScaler(), num_cols),
('cat', OneHotEncoder(drop='first'), cat_cols)      
])

X_transformed = preprocessor.fit_transform(X)

print(f'데이터 타입: {X_transformed.dtype}')

print(f'변환후 shape:{X_transformed.shape}')
print(preprocessor.get_feature_names_out())
feature_names=preprocessor.get_feature_names_out()

# numpy array X_transformed >> dataframe으로 
X_df=pd.DataFrame(X_transformed, columns=feature_names)
print(X_df.head())
endsubmit;

quit;