* Kimball's error event schema;
******************************;

* Screen dimension;
DATA raw.screen_dimension;
INPUT rule $40.;
CARDS;
"identifier structure violation"
"inconsistent grade length"
"date ordering violation"
"inclusion dependency violation"
"failing grade but not failed exam"
"missing ECTS but not failed exam"
"inconsistent ECTS between tables"
"exam attempt year outside of semesters"
;
RUN;

* Error event fact table;
DATA raw.error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.ending_reason;
IF PRXMATCH(PRXPARSE("/\w{2}/"), ExitReas) = 0 THEN DO;
rule = "identifier structure violation";
dataset = "ending_reason";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.students;
IF PRXMATCH(PRXPARSE("/M\d{5}/"), MatrNo_SID) = 0 THEN DO;
rule = "identifier structure violation";
dataset = "students";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.exam_attempts;
IF PRXMATCH(PRXPARSE("/M\d{5}/"), MatrNo_SID) = 0 THEN DO;
rule = "identifier structure violation";
dataset = "exam_attempts";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.semesters;
IF PRXMATCH(PRXPARSE("/M\d{5}/"), MatrNo_SID) = 0 THEN DO;
rule = "identifier structure violation";
dataset = "semesters";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.students;
IF UEQ_GPA < 100 THEN DO;
rule = "inconsistent grade length";
dataset = "students";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.exam_attempts;
IF PRXMATCH(PRXPARSE("/(\d{3}|\s+)/"), grade) = 0 THEN DO;
rule = "inconsistent grade length";
dataset = "exam_attempts";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.students;
IF BirthYr > UEQ_YEAR THEN DO;
rule = "date ordering violation";
dataset = "students";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
proc sql;
create table temp_error_event_fact as
SELECT ExitReas
FROM raw.semesters as t1
WHERE t1.ExitReas NOT IN (SELECT t2.ExitReas
FROM raw.ending_reason as t2);
run;
data temp_error_event_fact (drop=ExitReas);
set temp_error_event_fact;
FORMAT date ddmmyy8. rule $40. dataset $30.;
rule = "inclusion dependency violation";
dataset = "semesters";
date = today();
run;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.exam_attempts;
IF Grade>400 and pstatus_descriptor = "passed" THEN DO;
rule = "failing grade but not failed exam";
dataset = "exam_attempts";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.exam_attempts;
IF ECTS=. and pstatus_descriptor ^= "not passed" 
and pstatus_descriptor ^= "finally failed" THEN DO;
rule = "missing ECTS but not failed exam";
dataset = "exam_attempts";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
proc sql;
create table temp as
SELECT t1.*, t2.pordnr, t2.ects as exams_table_ects
FROM raw.exam_attempts as t1
LEFT JOIN raw.exams as t2
ON t1.pordnr = t2.pordnr;
run;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET temp;
IF ECTS ^= exams_table_ects THEN DO;
rule = "inconsistent ECTS values";
dataset = "exam_attempts and exams";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
DATA temp_error_event_fact (KEEP=rule dataset date);
FORMAT date ddmmyy8. rule $40. dataset $30.;
SET raw.exam_attempts;
IF semester_year>2018 THEN DO;
rule = "exam attempt year outside of semester";
dataset = "exam_attempts";
date = today();
END;
IF cmiss(OF date) THEN delete;
RUN;
proc append base=raw.error_event_fact data=temp_error_event_fact;
RUN;
PROC SORT data=raw.error_event_fact out=raw.error_event_fact nodupkey;
by _all_;
RUN;

* Error event detail table;
DATA raw.error_event_detail (KEEP=record variable table_name rule);
SET raw.semesters;
FORMAT record 8. variable $30. table_name $30. rule $40.;
IF exitReas = "E2" THEN DO;
record = _n_;
variable = "ExitReas";
table_name = "Semesters";
rule = "inclusion dependency violation";
END;
IF cmiss(OF variable) THEN delete;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.ending_reason;
FORMAT record 8. variable $30. table_name $30. rule $40.;
IF PRXMATCH(PRXPARSE("/\w{2}/"), ExitReas) = 0 THEN DO;
record = _n_;
variable = "Exitreas";
table_name = "ending_reason";
rule = "identifier structure violation";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.students;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF BirthYr > UEQ_YEAR THEN DO;
record = _n_;
variable = "BirthYr and UEQ_Year";
table_name = "students";
rule = "date ordering violation";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.exam_attempts;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF semester_year>2018 THEN DO;
record = _n_;
variable = "Semester_Year";
table_name = "exam_attempts";
rule = "exam attempt year outside of semester";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.exam_attempts;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF Grade>400 and pstatus_descriptor = "passed" THEN DO;
record = _n_;
variable = "Grade and Pstatus";
table_name = "exam_attempts";
rule = "failing grade but not failed exam";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.exam_attempts;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF ECTS=. and pstatus_descriptor ^= "not passed" 
and pstatus_descriptor ^= "finally failed" THEN DO;
record = _n_;
variable = "ECTS and Pstatus";
table_name = "exam_attempts";
rule = "missing ECTS but not failed exam";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;
proc sql;
create table temp as
SELECT t1.*, t2.pordnr, t2.ects as exams_table_ects
FROM raw.exam_attempts as t1
LEFT JOIN raw.exams as t2
ON t1.pordnr = t2.pordnr;
run;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET temp;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF ECTS ^= exams_table_ects THEN DO;
record = _n_;
variable = "ECTS";
table_name = "exam_attempts and exams";
rule = "inconsistent ECTS values";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
DATA temp_error_event_detail (KEEP=record variable table_name rule);
SET raw.students;
FORMAT record 8. variable $30. table_name $30. rule $40.; 
IF UEQ_GPA < 100 THEN DO;
record = _n_;
variable = "Grade";
table_name = "students";
rule = "inconsistent grade length";
END;
IF cmiss(OF variable) THEN delete;
proc append base=raw.error_event_detail data=temp_error_event_detail;
RUN;

* Checking inclusion dependencies;
proc sql;
create table temp as
SELECT MatrNo_SID
FROM raw.semesters as t1
WHERE t1.MatrNo_SID NOT IN (SELECT t2.MatrNo_SID
FROM raw.students as t2);
run;

* Exams with both a registration and a result;
proc sql;
create table register_and_attempt as
select matrno_sid, pordnr, SUM(pstatus="AN") as num_registered,
COUNT(*)-SUM(pstatus="AN") as num_other
from raw.exam_attempts
group by matrno_sid, pordnr;
run;
data register_and_attempt;
set register_and_attempt;
if num_registered ~= 0 and num_other ~= 0 then both = "registration and result";
else both = "only one recorded";
run;
proc sgplot data=register_and_attempt;
title height=12pt "Number of exam attempts with both a registration and a result";
vbar both / fillattrs=(color=CX40c5c5) categoryorder=respdesc datalabel;
yaxis grid;
run;

* Is a student's first semester consistently marked;
proc sql;
create table first_semester_status as
SELECT 
rawsemesters.MatrNo_SID,
rawsemesters.status,
rawsemesters.prgsem
FROM raw.semesters as rawsemesters
INNER JOIN 
( 
SELECT MatrNo_SID, MIN(prgsem) as first_sem
FROM raw.semesters 
GROUP BY MatrNo_SID  ) t
ON rawsemesters.MatrNo_SID = t.MatrNo_SID
AND rawsemesters.prgsem = t.first_sem;
run;
proc freq data=first_semester_status order=freq nlevels;
tables status / missing;
run;

* How many ECTS does each student have?;
* Is it no greater than 180 or 240?;
proc sql;
create table student_ects as
select MatrNo_SID, SUM(ects) as ects_gained
from raw.exam_attempts
group by matrno_SID;
run;
proc freq data=student_ects order=freq nlevels;
tables ects_gained / missing;
run;
proc sql;

* Are all failing grades associated with failed exams?;
data failing_grades;
set raw.exam_attempts;
if Grade>400 and pstatus_descriptor="passed" then output;
run;
proc freq data=failing_grades order=data;
tables Pstatus_descriptor / missing;
run;

* Data quality handling;
***********************;

* Split up semester into its component parts;
DATA raw.semesters;
SET raw.semesters;
semester_year=int(substr(put(semester,5.),1,4));
semester_season=int(substr(put(semester,5.),5));
run;

* Add in the text descriptors;
proc sql;
create table raw.exam_attempts as
SELECT *
FROM raw.exam_attempts as t1
LEFT JOIN raw.mandatory_descriptor as t2
ON t1.mandatory = t2.mandatory;
run;

* Changing the missing exit reason to continue;
data raw.ending_reason;
set raw.ending_reason end=last;
if not last then output;
run;
data raw.ending_reason;
set raw.ending_reason end=eof;
output;
if eof then do;
ExitReas='C1';
ltxt="Continue";
etxt="Continue";
astat=9;
exit1="C";
EndegrdRead="Continue";
output;
end;
run;
* Appending the new reason to semesters; 
data raw.semesters;
set raw.semesters;
if ExitReas= ' ' then ExitReas="C1";
run;


* Convert ProfDegr to 1/0, and replace missing with 0;
data raw.students;
set raw.students;
if ProfDegr= 'J' then ProfDegr=1;
else if ProfDegr= 'N' then ProfDegr=0;
else ProfDegr=0;
run;

* Creating a combined code for a study programme;
data raw.semesters;
set raw.semesters;
study_programme = grad||program||spec;
run;

* Correcting inconsistent GPAs;
DATA raw.students;
SET raw.students;
IF UEQ_GPA = 2 THEN UEQ_GPA=200;
RUN;

* Setting missing exam ECTS to 0;
data raw.exams;
set raw.exams;
if ECTS=. then ECTS=0;
run;

* Correcting the missing ECTS in exam attempts;
DATA raw.exam_attempts;
SET raw.exam_attempts;
IF Pstatus="AN" THEN ECTS=0;
IF Pstatus="NB" THEN ECTS=0;
IF Pstatus="EN" THEN ECTS=0;
RUN;

* Changing the incorrect exit reason code;
DATA raw.semesters;
SET raw.semesters;
IF ExitReas="E2" THEN ExitReas="E1";
RUN;

* Fixing the numeric type of Grade;
data raw.exam_attempts;
set raw.exam_attempts;
Grade = input(Grade, 8.);
run;

* Replace 0 grade with missing;
data raw.exam_attempts;
set raw.exam_attempts;
if Grade=0 then Grade=.;
run;

* Add an indicator for the students first and last semesters;
proc sql;
create table raw.semesters as
select semesters.*, min(semester) as first_sem_date, max(semester) as last_sem_date
from raw.semesters as semesters
group by MatrNo_SID;
run;
data raw.semesters (drop=first_sem_date last_sem_date);
set raw.semesters;
IF first_sem_date = last_sem_date AND first_sem_date = semester THEN semester_status = "first and last";
ELSE IF semester = first_sem_date THEN semester_status = "first";
ELSE IF semester = last_sem_date THEN semester_status = "last";
ELSE semester_status = "regular";
run;

* Adding exam types to the exams table;
proc sql;
create table pordnr_examtype as
select distinct pordnr, examtype
from raw.exam_attempts;
run;
proc sql;
create table raw.exams as
SELECT *
FROM raw.exams as t1
LEFT JOIN pordnr_examtype as t2
ON t1.pordnr = t2.pordnr;
run;