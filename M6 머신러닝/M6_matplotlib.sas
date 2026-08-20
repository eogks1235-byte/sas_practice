
%let snippets=/home/student/snippets;
%include '&snippets/macro/matplot.sas';
%show_png(users_kmeans.png, title=K-Means 4그룹 군집화 결과);