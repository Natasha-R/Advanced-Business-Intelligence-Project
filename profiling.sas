* Full table profiling;
**********************;
* Attributes;
PROC datasets;
contents data=raw.ending_reason order=collate;
QUIT;

* Check for duplicates;
PROC SQL;
SELECT *, COUNT(*) AS Count
FROM raw.ending_reason  
GROUP BY ExitReas, ltxt, etxt, exit1, EndegrdRead
HAVING COUNT(*) > 1;
RUN;

* Single variable profiling;
***************************;
* Number of unique values and missing values;
proc freq data=raw.ENDING_REASON order=freq nlevels;
tables ExitReas ltxt etxt astat exit1 EndegrdRead / missing;
run;

* Frequency distribution;
proc sgplot data=raw.ENDING_REASON;
title height=12pt "Frequency of Unique Values in Variable Exit1";
vbar exit1 / fillattrs=(color=CX40c5c5) categoryorder=respdesc datalabel;
yaxis grid;
run;

* Set some categories as other, to reduce the size of bar charts;
data work.examtype_figure;
set raw.exam_attempts;
if ExamType not in ('MO' 'TN' 'CP' 'TM') then Exam_Type = 'Other';
else Exam_Type = ExamType;
run;

* Histogram;
proc sgplot data=raw.exam_attempts;
title height=12pt "Distribution of Semester Years";
histogram semester_year / fillattrs=(color=CX40c5c5) scale=count;
yaxis grid;
run;

* Minimum, maximum and average string lengths;
PROC SQL; 
select min(length(examtype_descriptor)) as min_length, 
max(length(examtype_descriptor)) as max_length, 
avg(length(examtype_descriptor)) as mean_length
from raw.exam_attempts; 
QUIT;

* Minimum, maximum and average value of numeric types;
PROC SQL; 
select min(grade) as min, max(grade) as max, avg(grade) as mean
from raw.exam_attempts; 
QUIT;

* Inter-variable profiling;
***************************;
* Which exam regulation versions cover which years;
proc sort data=RAW.SEMESTERS out=_HistogramTaskData;
by examregv;
run;
proc sgplot data=_HistogramTaskData;
histogram semester_year / group=examregv scale=count;
label examregv="Regulations version";
run;

* Which semester is each student's first semester (any transfers);
PROC SQL; 
create table first_semester as
select min(prgsem) as first_semester, MatrNo_SID
from raw.semesters
group by MATRNO_SID;
QUIT;
proc freq data=first_semester order=data nlevels;
tables first_semester / missing;
run;
proc sgplot data=first_semester;
title height=12pt "The first semester number for students";
vbar first_semester / fillattrs=(color=CX40c5c5) datalabel;
yaxis grid;
run;

* How many pordnr are associated with each pnr;
proc sql;
create table raw.pordnr_in_pnr as
SELECT Pnr, COUNT(*) as pordnr_in_pnr
FROM raw.exams
GROUP BY pnr;
quit;
proc sgplot data=raw.pordnr_in_pnr;
title height=12pt "Number of 'Pordnr' associated with each 'Pnr' 
(Number of different versions for each exam)";
vbar pordnr_in_pnr / fillattrs=(color=CX40c5c5) datalabel;
yaxis grid;
run;