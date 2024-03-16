* Creating the dimensions;
*************************;

PROC SQL;
CREATE TABLE mdm.dimExam AS
SELECT 
l_Exam.l_Exam_hk,
h_EWRV.pordnr,
h_Exam.pnr,
h_ExamRegulation.Examregv,
s_Exam.No_Sem,
s_Exam.ECTS,
s_Exam.Mandatory,
s_Exam.ExamType
FROM dv.l_exam as l_Exam
LEFT JOIN dv.h_ExamWithRegulationVer as h_EWRV 
ON h_EWRV.h_ExamWithRegulationVer_hk = l_Exam.h_ExamWithRegulationVer_hk
LEFT JOIN dv.h_Exam as h_Exam ON h_Exam.h_Exam_hk = l_Exam.h_Exam_hk
LEFT JOIN dv.h_ExamRegulation as h_ExamRegulation ON 
h_ExamRegulation.h_ExamRegulation_hk = l_Exam.h_ExamRegulation_hk
LEFT JOIN dv.s_Exam as s_Exam ON s_Exam.l_Exam_hk = l_Exam.l_Exam_hk;
QUIT;

PROC SQL;
CREATE TABLE mdm.dimSemester AS
SELECT 
h_Semester.Semester,
s_Semester.Semester_Year,
s_Semester.Semester_Season
FROM dv.h_Semester as h_Semester
LEFT JOIN dv.s_Semester as s_Semester on s_Semester.h_Semester_hk = h_Semester.h_Semester_hk;
QUIT;
DATA mdm.dimSemester;
SET mdm.dimSemester END=eof;
OUTPUT;
IF eof THEN DO;
Semester=.;
Semester_Year=.;
Semester_Season=.;
OUTPUT;
END;
RUN;

PROC SQL;
CREATE TABLE mdm.dimStudent AS
SELECT 
h_Student.h_Student_hk,
h_Student.MatrNo_SID,
s_Student.Gender,
s_Student.UEQ_Type,
s_Student.UEQ_GPA,
s_Student.ProfDegr,
s_Student.BirthYr,
s_Student.NationIA
FROM dv.h_Student as h_Student
LEFT JOIN dv.s_Student as s_Student ON s_Student.h_Student_hk = h_Student.h_Student_hk;
QUIT;

PROC SQL;
CREATE TABLE mdm.dimStudyProgramme AS
SELECT  
h_StudyProgramme.h_StudyProgramme_hk,
h_StudyProgramme.study_programme,
s_StudyProgramme.grad,
s_StudyProgramme.program,
s_StudyProgramme.spec
FROM dv.h_StudyProgramme as h_StudyProgramme
LEFT JOIN dv.s_StudyProgramme as s_StudyProgramme ON 
s_StudyProgramme.h_StudyProgramme_hk = h_StudyProgramme.h_StudyProgramme_hk;
QUIT;

DATA mdm.dimExitReason (keep=ExitReas etxt EndegrdRead exit1 ExitReas_hk);
SET dv.r_exitreason;
ExitReas_hk = hashing("md5", ExitReas);
RUN;

* Creating the TFTs;
*******************;

PROC SQL;
CREATE TABLE mdm.TFTRegisterExam AS
SELECT
l_examregistration.l_Examregistration_hk,
l_examregistration.h_Student_hk,
l_Exam.l_Exam_hk,
s_Semester.semester,
s_ExamRegistration.Attempt as Attempt_No
FROM dv.l_examregistration as l_examregistration
LEFT JOIN dv.l_Exam as l_Exam 
ON l_Exam.h_ExamWithRegulationVer_hk = l_examregistration.h_ExamWithRegulationVer_hk
LEFT JOIN dv.s_Semester as s_Semester 
ON s_Semester.h_Semester_hk = l_examregistration.h_Semester_hk
LEFT JOIN dv.s_ExamRegistration as s_Registration 
ON s_Registration.l_ExamRegistration_hk = l_ExamRegistration.l_ExamRegistration_hk;
QUIT;
DATA mdm.TFTRegisterExam;
SET mdm.TFTRegisterExam;
register_exam = 1;
RUN;

PROC SQL;
CREATE TABLE mdm.TFTAttemptExam AS
SELECT
l_ExamAttempt.l_ExamAttempt_hk,
l_ExamAttempt.h_Student_hk,
l_Exam.l_Exam_hk,
s_Semester.semester,
s_ExamAttempt.Grade,
s_ExamAttempt.Attempt as Attempt_No,
s_ExamAttempt.PStatus
FROM dv.l_ExamAttempt as l_ExamAttempt
LEFT JOIN dv.l_Exam as l_Exam 
ON l_Exam.h_ExamWithRegulationVer_hk = l_ExamAttempt.h_ExamWithRegulationVer_hk
LEFT JOIN dv.s_Semester as s_Semester 
ON s_Semester.h_Semester_hk = l_ExamAttempt.h_Semester_hk
LEFT JOIN dv.s_ExamAttempt as s_ExamAttempt 
ON s_ExamAttempt.l_ExamAttempt_hk = l_ExamAttempt.l_ExamAttempt_hk;
QUIT;
DATA mdm.TFTAttemptExam;
SET mdm.TFTAttemptExam;
IF PStatus="BE" THEN pass=1;
IF Pstatus = "NB" or Pstatus = "EN" THEN pass=0;
IF PStatus = "BE" or PStatus="NB" or Pstatus = "EN" THEN OUTPUT;
RUN;
DATA mdm.TFTAttemptExam (drop=Pstatus);
SET mdm.TFTAttemptExam;
attempt_exam = 1;
RUN;

PROC SQL;
CREATE TABLE mdm.TFTRegisterSemester AS
SELECT 
l_StudentSemester.l_StudentSemester_hk,
l_StudentSemester.h_Student_hk,
s_Semester.semester,
s_StudentSemester.prgsem,
s_StudentSemester.semester_status,
l_StudentStudyProgramme.h_StudyProgramme_hk
FROM dv.l_StudentSemester as l_StudentSemester
LEFT JOIN dv.s_StudentSemester as s_StudentSemester 
ON s_StudentSemester.l_StudentSemester_hk = l_StudentSemester.l_StudentSemester_hk
LEFT JOIN dv.s_Semester as s_Semester 
ON s_Semester.h_Semester_hk = l_StudentSemester.h_Semester_hk
LEFT JOIN dv.l_StudentStudyProgramme as l_StudentStudyProgramme ON 
l_StudentStudyProgramme.h_student_hk = l_StudentSemester.h_student_hk;
QUIT;
DATA mdm.TFTRegisterSemester;
SET mdm.TFTRegisterSemester;
IF semester_status = "first" or semester_status = "first and last" THEN first_semester = 1;
IF semester_status = "regular" THEN first_semester = 0;
IF semester_status ~= "last" THEN OUTPUT;
RUN;
DATA mdm.TFTRegisterSemester (drop=semester_status);
SET mdm.TFTRegisterSemester;
register_semester = 1;
RUN;

PROC SQL;
CREATE TABLE mdm.TFTEndStudy AS
SELECT 
l_StudentSemester.l_StudentSemester_hk,
l_StudentSemester.h_Student_hk,
s_Semester.semester,
s_StudentSemester.prgsem,
s_StudentSemester.semester_status,
s_StudentSemester.ExitReas,
l_StudentStudyProgramme.h_StudyProgramme_hk
FROM dv.l_StudentSemester as l_StudentSemester
LEFT JOIN dv.s_StudentSemester as s_StudentSemester 
ON s_StudentSemester.l_StudentSemester_hk = l_StudentSemester.l_StudentSemester_hk
LEFT JOIN dv.s_Semester as s_Semester 
ON s_Semester.h_Semester_hk = l_StudentSemester.h_Semester_hk
LEFT JOIN dv.l_StudentStudyProgramme as l_StudentStudyProgramme 
ON l_StudentStudyProgramme.h_student_hk = l_StudentSemester.h_student_hk;
QUIT;
DATA mdm.TFTEndStudy;
SET mdm.TFTEndStudy;
ExitReas_hk = hashing("md5", ExitReas);
IF semester_status = "last" or semester_status = "first and last" THEN OUTPUT;
RUN;
DATA mdm.TFTEndStudy (drop=semester_status ExitReas);
SET mdm.TFTEndStudy;
end_study = 1;
RUN;

* Creating the PSFTs;
********************;

proc sql;
create table mdm.PSFTRegisterExam as 
select
l_Exam_hk,
semester,
h_Student_hk,
sum(register_exam) as register_exam
from mdm.TFTRegisterExam
group by l_Exam_hk, semester, h_Student_hk;
quit;

proc sql;
create table mdm.PSFTPassExam as 
select
l_Exam_hk,
semester,
h_Student_hk,
sum(attempt_exam) as pass_exam
from mdm.TFTAttemptExam
where pass = 1
group by h_Student_hk, l_Exam_hk, semester;
quit;

proc sql;
create table mdm.PSFTFailExam as 
select
l_Exam_hk,
semester,
h_Student_hk,
sum(attempt_exam) as fail_exam
from mdm.TFTAttemptExam
where pass = 0
group by l_Exam_hk, semester, h_Student_hk;
quit;

proc sql;
create table mdm.PSFTRegisterFirstSemester as 
select
h_StudyProgramme_hk,
semester,
sum(register_semester) as register_semester
from mdm.TFTRegisterSemester
where first_semester = 1
group by h_StudyProgramme_hk, semester;
quit;

proc sql;
create table mdm.PSFTRegisterNextSemester as 
select
h_StudyProgramme_hk,
semester,
sum(register_semester) as register_semester
from mdm.TFTRegisterSemester
where first_semester = 0
group by h_StudyProgramme_hk, semester;
quit;

proc sql;
create table mdm.PSFTGraduate as
select
TFTEndStudy.semester,
TFTEndStudy.h_StudyProgramme_hk,
TFTEndStudy.end_study,
dimExitReason.EndegrdRead
from mdm.TFTEndStudy as TFTEndStudy
LEFT JOIN mdm.dimExitReason as dimExitReason 
ON dimExitReason.ExitReas_hk = TFTEndStudy.ExitReas_hk;
quit;
proc sql;
create table mdm.PSFTGraduate as
select
semester,
h_StudyProgramme_hk,
sum(end_study) as graduate
from mdm.PSFTGraduate
WHERE EndegrdRead = "Graduation"
group by semester, h_StudyProgramme_hk;
quit;

proc sql;
create table mdm.PSFTAbortStudy as
select
TFTEndStudy.semester,
TFTEndStudy.h_StudyProgramme_hk,
TFTEndStudy.end_study,
dimExitReason.EndegrdRead
from mdm.TFTEndStudy as TFTEndStudy
LEFT JOIN mdm.dimExitReason as dimExitReason 
ON dimExitReason.ExitReas_hk = TFTEndStudy.ExitReas_hk;
quit;
proc sql;
create table mdm.PSFTAbortStudy as
select
semester,
h_StudyProgramme_hk,
sum(end_study) as abort_study
from mdm.AbortStudy
WHERE EndegrdRead = "Abortion"
group by semester, h_StudyProgramme_hk;
quit;

* Creating the ASFT;
*******************;

proc sql;
create table mdm.ASFTStudyLifecycle as
select 
min(h_semester.semester) as semester_start, 
max(h_semester.semester) as semester_end,
l_studentsemester.h_student_hk
from dv.l_studentsemester as l_studentsemester
LEFT JOIN dv.h_semester as h_semester 
ON h_semester.h_semester_hk = l_studentsemester.h_semester_hk
group by l_studentsemester.h_student_hk;
quit;
proc sql;
create table mdm.ASFTStudyLifecycle as
select * 
from dv.l_studentsemester as l_studentsemester
LEFT JOIN mdm.ASFTStudyLifecycle as ASFTStudyLifecycle 
ON ASFTStudyLifecycle.h_student_hk = l_studentsemester.h_student_hk
LEFT JOIN dv.s_StudentSemester as s_StudentSemester 
ON s_StudentSemester.l_StudentSemester_hk = l_StudentSemester.l_StudentSemester_hk
LEFT JOIN dv.s_Semester as s_Semester 
ON s_Semester.h_Semester_hk = l_StudentSemester.h_Semester_hk
LEFT JOIN dv.l_StudentStudyProgramme as l_StudentStudyProgramme 
ON l_StudentStudyProgramme.h_student_hk = l_StudentSemester.h_student_hk;
quit;
DATA mdm.ASFTStudyLifecycle;
SET mdm.ASFTStudyLifecycle;
start_year=int(substr(put(semester_start,5.),1,4));
start_season=int(substr(put(semester_start,5.),5));
end_year=int(substr(put(semester_end,5.),1,4));
end_season=int(substr(put(semester_end,5.),5));
duration = ((end_year - start_year) * 2) + (end_season - start_season) + 1;
RUN;
DATA mdm.ASFTStudyLifecycle;
SET mdm.ASFTStudyLifecycle;
IF semester_end = semester THEN OUTPUT;
RUN;
DATA mdm.ASFTStudyLifecycle (keep=ExitReas_hk duration semester_start semester_end 
h_Student_hk h_StudyProgramme_hk);
SET mdm.ASFTStudyLifecycle;
if ExitReas = "C1" THEN semester_end = .;
ExitReas_hk = hashing("md5", ExitReas);
RUN;
proc sql;
create table pass_by_student as 
select
h_Student_hk,
sum(pass_exam) as num_exams_passed
from mdm.PSFTPassExam
group by h_Student_hk;
quit;
proc sql;
create table fail_by_student as 
select
h_Student_hk,
sum(fail_exam) as num_exams_failed
from mdm.PSFTFailExam
group by h_Student_hk;
quit;
proc sql;
create table register_by_student as 
select
h_Student_hk,
sum(register_exam) as num_exams_registered
from mdm.PSFTRegisterExam
group by h_Student_hk;
quit;
proc sql;
create table num_ects_by_student as
select 
h_student_hk,
sum(ects) as num_ects_completed
from mdm.PSFTPassExam as PSFTPassExam
LEFT JOIN dv.s_Exam as s_Exam on s_Exam.l_exam_hk = PSFTPassExam.l_exam_hk
group by PSFTPassExam.h_student_hk;
QUIT;
proc sql;
create table avg_grade_by_student as
select 
h_student_hk,
AVG(Grade) as average_grade
from mdm.TFTAttemptExam as TFTAttemptExam
group by TFTAttemptExam.h_student_hk;
QUIT;
proc sql;
create table avg_weighted_grade_by_student as
select 
h_student_hk,
sum(Grade * ECTS) / sum(ECTS) as average_weighted_grade
from mdm.TFTAttemptExam as TFTAttemptExam
LEFT JOIN dv.s_Exam as s_Exam on s_Exam.l_exam_hk = TFTAttemptExam.l_exam_hk
group by TFTAttemptExam.h_student_hk;
QUIT;
proc sql;
create table mdm.ASFTStudyLifecycle as
select *
from mdm.ASFTStudyLifecycle as ASFTStudyLifecycle
LEFT JOIN pass_by_student 
ON pass_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk
LEFT JOIN fail_by_student 
ON fail_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk
LEFT JOIN register_by_student 
ON register_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk
LEFT JOIN avg_grade_by_student 
ON avg_grade_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk
LEFT JOIN avg_weighted_grade_by_student 
ON avg_weighted_grade_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk
LEFT JOIN num_ects_by_student 
ON num_ects_by_student.h_Student_hk = ASFTStudyLifecycle.h_Student_hk;
quit;
DATA mdm.ASFTStudyLifecycle;
SET mdm.ASFTStudyLifecycle;
IF num_exams_passed = . THEN num_exams_passed = 0;
IF num_exams_failed = . THEN num_exams_failed = 0;
IF num_exams_registered = . THEN num_exams_registered = 0;
IF num_ects_completed = . THEN num_ects_completed = 0;
RUN;
DATA mdm.ASFTStudyLifecycle;
SET mdm.ASFTStudylifecycle;
StudyLifecycle = _n_;
num_exams_attempted = num_exams_passed + num_exams_failed;
proportion_exams_passed = num_exams_passed / num_exams_attempted;
RUN;