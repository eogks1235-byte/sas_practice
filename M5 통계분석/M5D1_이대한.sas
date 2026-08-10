libname shop_db '/home/student/shop_db';

/* ods graphics off; */
libname shop_db '/home/student/shop_db';

ods graphics off; 

%LET TODAY = %SYSFUNC(TODAY(), YYMMDDN8.);

ODS PDF FILE="/home/student/report/&TODAY..pdf" STYLE=journal;

TITLE "평균 주문금액 검정 - APA";

PROC TTEST DATA=shop_db.orders H0=50000;
    VAR total_amount;
    WHERE status='paid';
RUN;

PROC SQL;
    SELECT (MEAN(total_amount) - 50000) / STD(total_amount) AS d FORMAT=8.3
    FROM shop_db.orders
    WHERE status='paid';
QUIT;

ODS PDF CLOSE;
/*"귀무가설을 기각(Reject)함에 따라,
 95% 신뢰구간[67.6만 원 ~ 68.6만 원]이 
기준선인 5만 원을 크게 상회하는 것으로 나타나 
쿠폰 정책의 객단가 상승 효과가 확실함을 입증함" */

/*중위수 17.9만원 */
proc univariate data=shop_db.orders normal;
var total_amount;
run;

proc univariate data=shop_db.orders mu0=50000;
	var total_amount;
run;
title;