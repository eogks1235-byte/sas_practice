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
%imp(name=orders);
%imp(name=order_items);
%imp(name=products);
%imp(name=campaigns);


