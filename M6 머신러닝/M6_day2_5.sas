PROC PYTHON;
SUBMIT;
import pandas as pd

df = pd.read_csv('/home/student/shop_csv/users_dirty.csv')

# (1) 기본 pivot - 채널(행) × 성별(열) 평균 지출액
p1 = df.pivot_table(
    index='channel',            
    columns='gender',          
    values='total_spent',
    aggfunc='mean'
)             
print("--- (1) 채널 x 성별 평균 지출액 ---")
print(p1)

# (2) 단일 컬럼 다중 집계 - 채널별 합계, 평균, 개수, 표준편차
p2 = df.pivot_table(
    index='channel',
    values='total_spent',
    aggfunc=['sum', 'mean', 'count', 'std']
)
print("\n--- (2) 채널별 지출액 다중 집계 ---")
print(p2)

# (3) 다중 컬럼 각각 다른 함수 적용 - VIP 등급별 집계
p3 = df.pivot_table(
    index='vip_grade',
    values=['total_spent', 'age', 'order_count'],
    aggfunc={
        'total_spent': 'sum',
        'age': 'mean',
        'order_count': 'max'
    }
)
print("\n--- (3) VIP 등급별 컬럼 맞춤 집계 ---")
print(p3)

# (4) margins=True - Total(전체 합계/평균) 행과 열 추가
p4 = df.pivot_table(
    index='channel', 
    values='total_spent',
    aggfunc='sum', 
    margins=True
)
print("\n--- (4) 합계 행(Total) 포함 ---")
print(p4)

ENDSUBMIT; 
QUIT;