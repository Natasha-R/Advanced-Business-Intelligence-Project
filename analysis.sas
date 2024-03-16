* Create tables for analysis from the fact tables and dimensions;

PROC SQL;
CREATE TABLE Analysis.SLC AS
SELECT *
FROM mdm.ASFTStudyLifecycle as ASFTStudyLifecycle
LEFT JOIN mdm.DimStudent as DimStudent 
ON DimStudent.h_student_hk = ASFTStudyLifecycle.h_student_hk
LEFT JOIN mdm.DimExitReason as DimExitReason 
ON DimExitReason.ExitReas_hk = ASFTStudyLifecycle.ExitReas_hk;
QUIT;
data Analysis.SLC;
set Analysis.SLC;
if UEQ_TYPE not in ("G1", "T3", "O3", "K3", "U1", 
                    "N1", "G3", "L3", "S3", "U3", "A3") then UEQ_Type="OTHER";
run;
data Analysis.SLC;
set Analysis.SLC;
proportion_exams_passed_squared = proportion_exams_passed**2;
run;
data Analysis.SLC;
set Analysis.SLC;
IF EndegrdRead = "Abortion" THEN graduated = 0;
IF EndegrdRead = "Graduation" THEN graduated = 1;
IF EndegrdRead = "Continue" THEN graduated = .;
run;

* Re-running the tests when assuming continue means abort;
data Analysis.SLC;
set Analysis.SLC;
IF EndegrdRead = "Abortion" THEN graduated = 0;
IF EndegrdRead = "Graduation" THEN graduated = 1;
IF EndegrdRead = "Continue" THEN graduated = 0;
run;

PROC SQL;
CREATE TABLE Analysis.ExamStudent AS
SELECT *
FROM mdm.TFTAttemptExam as TFTAttemptExam
LEFT JOIN mdm.DimStudent as DimStudent 
ON DimStudent.h_student_hk = TFTAttemptExam.h_student_hk;
QUIT;
data Analysis.ExamStudent;
set Analysis.ExamStudent;
if UEQ_TYPE not in ("G1", "T3", "O3", "K3", "U1", 
                    "N1", "G3", "L3", "S3", "U3", "A3") then UEQ_Type="OTHER";
run;

* Descriptive analysis;
***********************

* Reporting mean results;
proc freq data=ANALYSIS.SLC order=freq nlevels;
tables graduated;
run;
proc freq data=ANALYSIS.EXAMSTUDENT order=freq nlevels;
tables pass;
run;
proc sql;
select avg(grade) as average
from analysis.examstudent
where pass=1;
quit;

* Rates over time;
proc sgplot data=ANALYSIS.EXAMSTUDENT;
vline semester / response=grade stat=mean;
run;	

* Statistical analysis;
***********************

* Example of one logistic regression model;
proc logistic data=ANALYSIS.EXAMSTUDENT plots
(maxpoints=none);
class gender UEQ_TYPE ProfDegr NationIA / param=glm;
model pass(event='1')=gender UEQ_GPA UEQ_TYPE ProfDegr BirthYr NationIA / 
link=logit technique=fisher;
run;

* Example of one multiple linear regression model (with fit diagnostics);
ods noproctitle;
ods graphics / imagemap=on;
proc glmselect data=ANALYSIS.EXAMSTUDENT 
outdesign(addinputvars)=Work.reg_design;
class gender UEQ_TYPE ProfDegr NationIA / param=glm;
model Grade=gender UEQ_GPA UEQ_TYPE ProfDegr BirthYr NationIA / showpvalues 
selection=none;
run;
proc reg data=Work.reg_design alpha=0.05 plots(only 
maxpoints=none)=(diagnostics residuals observedbypredicted);
where gender is not missing and UEQ_TYPE is not missing and ProfDegr is not 
missing and NationIA is not missing;
ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
model Grade=&_GLSMOD /;
run;
quit;
proc delete data=Work.reg_design;
run;

* Example of Chi-squared test of independence;
proc freq data=ANALYSIS.SLC;
tables  (NationIA) * (graduated) / chisq expected deviation nopercent norow nocol 
nocum plots(only)=(freqplot mosaicplot);
run;

* Example of ANOVA;
proc glm data=ANALYSIS.EXAMSTUDENT plots(maxpoints=none);
class UEQ_Type;
model Grade=UEQ_Type;
means UEQ_Type / hovtest=levene welch plots=none;
lsmeans UEQ_Type / adjust=tukey pdiff alpha=.05;
run;
quit;

* Example of Correlation;
ods noproctitle;
ods graphics / imagemap=on;
proc corr data=ANALYSIS.EXAMSTUDENT pearson nosimple noprob 
plots(maxpoints=none)=scatter(ellipse=none);
var Grade;
with BirthYr;
run;

* Distribution of exit reasons;
DATA only_aborted;
SET ANALYSIS.SLC;
IF EndegrdRead = "Abortion" THEN OUTPUT;
RUN;
proc sgplot data=only_aborted;
vbar exit1 /;
yaxis grid;
run;