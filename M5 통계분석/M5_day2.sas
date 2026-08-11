libname shop_db '/home/student/shop_db';


/* 케이스별 검정 매칭
	1 남 vs 여 평균매출 2-samples t*/
proc ttest data=shop_db.users alpha=0.05 plots(only)=summary;
	where gender in('M','F');
	class gender;
	var total_spent;
run;

/* 2 프로모션 전 후 paired t*/
data work.users_demo;
	set shop_db.users(keep=user_id total_spent);
	where total_spent is not null
	and total_spent>0; /*구매회원만*/
	before_spent=total_spent*0.6;
	after_spent=total_spent*0.4+rand('normal',5000,2000);
run;

proc ttest data=users_demo;
	paired after_spent*before_spent;
run;


/* one- way anova*/
proc glm data=shop_db.users;
	where vip_grade is not null;
	class vip_grade;
	model total_spent =vip_grade;
run;
quit;

/*비모수 2그룹 >> wilcoxon*/
proc npar1way data=shop_db.users wilcoxon;
	class channel; var total_spent;
run;

/* session 2 2-sample t검정 */
proc ttest data=shop_db.users alpha=0.05;
	where channel in('organic','paid_search');
	class channel;
	var age;
run;

/* "유기적 검색(organic)과 유료 검색(paid_search) 
유입 고객의 평균 나이에는 통계적으로 유의미한 차이가 없다" */

/*성별 매출차이 분석*/
/* 1 데이터 정제 >> user_id, gender, total_amount*/
/* 2 데이터 분포 사각화 
	3 정규성 검증 >> univariate normal 
	4 2-sample ttest 
	5 비모수 검정 >> npar1way wilcoxon*/
proc sql ;
	create table uo as 
select o.payment_method, u.user_id, u.gender, o.total_amount, u.vip_grade, u.channel
	from shop_db.users u inner join shop_db.orders o
on u.user_id = o.user_id
	where o.status ='paid'
;quit;

proc sgplot data=uo;
	vbox total_amount / category=gender;
run;


proc sgplot data=uo;
	vbox total_amount / category=vip_grade;
run;

proc univariate data=uo normal;
	where gender in('M','F');
	class gender;
	var total_amount;
	histogram  total_amount /normal(color=red) kernel;
run;

proc univariate data=uo normal;
	where vip_grade in('platinum','vip');
	class vip_grade;
	var total_amount;
	histogram  total_amount /normal(color=red) kernel;
run;
proc ttest data=uo;
	where gender in('M','F');
	class gender;
	var total_amount;
run;

proc ttest data=uo;
	where vip_grade in('platinum','vip');
	class vip_grade;
	var total_amount;
run;
proc npar1way data=uo wilcoxon;
	where gender in ('M','F');
	class gender;
	var total_amount;
run;

proc npar1way data=uo wilcoxon;
	where vip_grade in ('platinum','vip');
	class vip_grade;
	var total_amount;
run;

/*session 3: 같은 그룹에 대해 매출 비교
	: ttest -paired*/
/*사용자별 6월 7월 매출 집계*/
proc sql;
	create table work.before_after as	
	select user_id,
		sum(case when month(order_date)=6
			then total_amount else 0 end)
		as jun_amt,
		sum(case when month(order_date)=7
			then total_amount else 0 end)
		as jul_amt
	from shop_db.orders
	where status='paid' and year(order_date)=2025
	group by user_id
	having jun_amt >0
	and jul_amt>0;
quit;
	
/*h0: 사용자별로 6월과 7월 의 구매금액이 차이가없다*/
/*paired t-test*/
proc ttest data=work.before_after;
	paired jun_amt * jul_amt;
run;

/* 표본이 너무 작아 검증이 안됨 >> q1, q2 변경분*/
proc sql;
	create table work.before_after as	
	select user_id,
		sum(case when qtr(order_date)=1
			then total_amount else 0 end)
		as q1_amt,
		sum(case when qtr(order_date)=2
			then total_amount else 0 end)
		as q2_amt
	from shop_db.orders
	where status='paid' and year(order_date)=2025
	group by user_id
	having q1_amt >0
	and q2_amt>0;
quit;

proc ttest data=work.before_after;
	paired q1_amt * q2_amt;
run;

proc univariate data=work.before_after normal;
	var q1_amt q2_amt;
run;


/* session 4 : anova 분석 >> 그룹이 3개지요 */
proc glm data=work.uo;
	class channel;
	model total_amount = channel;
	means channel /tukey
			hovtest=levene	
			alpha=0.05;
run;
quit;
/*0.5보다크면 등분산 아니면 웰치스
	채널별 0이들어갈가능성있어서 차이가없다 */

proc glm data=work.uo;
	class payment_method;
model total_amount =payment_method;
means payment_method / tukey hovtest=levene alpha=0.05;
run;
quit;

proc glm data=work.uo plots=none;/*plots none 그래프그리지않겠다*/
	class channel;
	model total_amount= channel;
	means channel/tukey hovtest=levene
;run;
quit;


으악
;
proc sgplot data=shop_db.users;
	where vip_grade is not null;
	vbox total_spent / category=vip_grade;
run;

proc glm data=shop_db.users;
	where vip_grade is not null; /*널값제외 */
	class vip_grade;
	model total_spent = vip_grade; /*grade로spent를 설명 (회귀)*/
	means vip_grade /tukey hovtest=levene
;run;/*ANOVA 결과가 유의할 때 어느 등급끼리 차이가 나는지 다중비교 보정*/
quit;/*ANOVA의 전제 조건인 등분산성 가정(그룹 간 분산이 같은지)을*/
/*R-Square
0.751848*/

proc npar1way data=shop_db.users wilcoxon dscf;
	where vip_grade is not null;
	class vip_grade;
	var total_spent;
run;
/*Pr > ChiSq
0.1794*/
/*Pr > DSCF
$0.05$보다 작으면 두 등급 간 나이 차이가 존재, 크면 차이가 없음*/

proc glm data=shop_db.users;
	class vip_grade;
	where vip_grade in('gold','bronze','vip');
	model total_spent =vip_grade;
	means vip_grade /tukey hovtest=levene;
run;
quit;/*R-Square
0.73
df는 자유도 n-1
anova  ttest 이상치많다 ==dscf로확인 */

/*보페로니 알파를 쌍의 수로 나눈다 */

/*tukey*/
proc glm data= shop_db.users;
	where vip_grade is not null;
	class vip_grade;
	model total_spent =vip_grade;
	means vip_grade/ tukey;
run;
quit;
/*

*/
/*bonferroni*/
proc glm data= shop_db.users;
	where vip_grade is not null;
	class vip_grade;
	model total_spent =vip_grade;
	means vip_grade/ bon;
run;
quit;
/*

*/
/*알파 인플레이션계산*/
data work.alpha;
	k=5;
	n_pairs =k*(k-1)/2;
	alpha=0.05;
	prob_err=1-(1-alpha)**n_pairs;
	alpha_bon=alpha/n_pairs; /*0.005*/
run;

/* session 6: 비모수검증 >> npar1way /wilcoxon*/
/* wilcoxon rank-sum*/
proc npar1way data=work.uo wilcoxon;
	where channel in('organic','paid_search');
	class channel;
	var total_amount;
run;

/* kruskal-wallis */
proc npar1way data=work.uo wilcoxon;
	class channel;
	var total_amount;
run;

/* dscf */
proc npar1way data=shop_db.users wilcoxon dscf;
	where vip_grade is not null;
	class vip_grade;
	var total_spent;
run;


PROC TTEST DATA = shop_db.users ALPHA = 0.05;
	CLASS channel;
	where channel in('organic','paid_search');
	VAR total_spent;
RUN;

proc ttest data=work.users_demo alpha =0.05;
	paired after_spent * before_spent;
run;

proc glm data=shop_db.users ;
	class vip_grade;
	model total_spent =vip_grade;
	means vip_grade /hovtest=levene;
run;
quit;

proc glm data= shop_db.users;
	class vip_grade;
	model total_spent =vip_grade;
	means vip_grade /tukey alpha=0.05;
run;
quit;














