* Creating the hubs;
*******************;

proc sql;
create table dv.h_Student as
select distinct MatrNo_SID
from raw.students;
quit;
DATA dv.h_Student;
SET dv.h_Student;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "students";
h_student_hk = hashing("md5", MatrNo_SID || ltds || "students");
RUN;

proc sql;
create table dv.h_ExamWithRegulationVer as
select distinct Pordnr
from raw.exams;
quit;
DATA dv.h_ExamWithRegulationVer;
SET dv.h_ExamWithRegulationVer;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "exams";
h_ExamWithRegulationVer_hk = hashing("md5", Pordnr || ltds || "exams");
RUN;

proc sql;
create table dv.h_Exam as
select distinct Pnr
from raw.exams;
quit;
DATA dv.h_Exam;
SET dv.h_Exam;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "exams";
h_Exam_hk = hashing("md5", Pnr || ltds || "exams");
RUN;

proc sql;
create table dv.h_ExamRegulation as
select distinct examregv
from raw.exams;
quit;
DATA dv.h_ExamRegulation;
SET dv.h_ExamRegulation;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "exams";
h_ExamRegulation_hk = hashing("md5", examregv || ltds || "exams");
RUN;

proc sql;
create table dv.h_Semester as
select distinct semester
from raw.semesters;
quit;
DATA dv.h_Semester;
SET dv.h_Semester;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "semesters";
h_Semester_hk = hashing("md5", semester || ltds || "semesters");
RUN;

proc sql;
create table dv.h_StudyProgramme as
select distinct study_programme
from raw.semesters;
quit;
DATA dv.h_StudyProgramme;
FORMAT study_programme $8. ltds DDMMYY10. record_src $32.;
set dv.h_StudyProgramme;
ltds = MDY(12,06,23);
record_src = "semesters";
h_StudyProgramme_hk = hashing("md5", study_programme || ltds || "semesters");
RUN;

proc sql;
create table dv.h_Cohort as
select distinct semester, study_programme
from raw.semesters;
quit;
DATA dv.h_Cohort (drop=semester study_programme);
SET dv.h_Cohort;
FORMAT Cohort $20. ltds DDMMYY10. record_src $32.;
Cohort = semester || study_programme;
ltds = MDY(12,06,23);
record_src = "semesters";
h_Cohort_hk = hashing("md5", Cohort || ltds || "semesters");
RUN;

* Creating the links;
********************;

DATA dv.l_ExamRegistration (keep=Labnr ltds record_src l_ExamRegistration_hk 
h_Student_hk h_Semester_hk h_ExamWithRegulationVer_hk);
set raw.exam_attempts;
FORMAT Labnr 8. ltds DDMMYY10. record_src $32.;
WHERE Pstatus="AN";
ltds = MDY(12,06,23);
record_src = "exam_attempts";
h_Student_hk = hashing("md5", MatrNo_SID || ltds || "students");
h_Semester_hk = hashing("md5", Semester || ltds || "semesters");
h_ExamWithRegulationVer_hk = hashing("md5", pordnr || ltds || "exams");
l_ExamRegistration_hk = hashing("md5", Labnr || ltds || "exam_attempts");
RUN;

DATA dv.l_ExamAttempt (keep=Labnr ltds record_src l_ExamAttempt_hk 
h_Student_hk h_Semester_hk h_ExamWithRegulationVer_hk);
set raw.exam_attempts;
FORMAT Labnr 8. ltds DDMMYY10. record_src $32.; 
WHERE Pstatus~="AN";
ltds = MDY(12,06,23);
record_src = "exam_attempts";
h_Student_hk = hashing("md5", MatrNo_SID || ltds || "students");
h_Semester_hk = hashing("md5", Semester || ltds || "semesters");
h_ExamWithRegulationVer_hk = hashing("md5", pordnr || ltds || "exams");
l_ExamAttempt_hk = hashing("md5", Labnr || ltds || "exam_attempts");
RUN;

DATA dv.l_Exam (keep=Exam ltds record_src l_Exam_hk 
h_Exam_hk h_ExamWithRegulationVer_hk h_ExamRegulation_hk);
set raw.exams;
FORMAT Exam 8. ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "exams";
Exam = _n_;
l_Exam_hk = hashing("md5", Exam || ltds || "exams");
h_Exam_hk = hashing("md5", Pnr || ltds || "exams");
h_ExamWithRegulationVer_hk = hashing("md5", Pordnr || ltds || "exams");
h_ExamRegulation_hk = hashing("md5", examregv || ltds || "exams");
RUN;

DATA dv.l_StudentSemester (keep=StudentSemester ltds record_src l_StudentSemester_hk 
h_student_hk h_semester_hk);
set raw.semesters;
FORMAT StudentSemester 8. ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "semesters";
StudentSemester = _n_;
l_StudentSemester_hk = hashing("md5", StudentSemester || ltds || "semesters");
h_student_hk = hashing("md5", MatrNo_SID || ltds || "students");
h_semester_hk = hashing("md5", semester || ltds || "semesters");
RUN;

DATA dv.l_StudentStudyProgramme (keep=StudentStudyProgramme ltds record_src 
l_StudentStudyProgramme_hk h_student_hk h_StudyProgramme_hk);
set raw.semesters;
FORMAT StudentStudyProgramme 8. ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "semesters";
l_StudentStudyProgramme_hk = hashing("md5", StudentStudyProgramme || ltds || "semesters");
h_Student_hk = hashing("md5", MatrNo_SID || ltds || "students");
h_StudyProgramme_hk = hashing("md5", study_programme || ltds || "semesters");
RUN;
PROC SORT data=dv.l_StudentStudyProgramme out=dv.l_StudentStudyProgramme nodupkey;
by _all_;
RUN;
DATA dv.l_StudentStudyProgramme;
SET dv.l_StudentStudyProgramme;
StudentStudyProgramme = _n_;
RUN;

DATA dv.l_StudentCohort (keep=StudentCohort ltds record_src 
l_StudentCohort_hk h_student_hk h_Cohort_hk h_Semester_hk);
set raw.semesters;
FORMAT StudentCohort 8. ltds DDMMYY10. record_src $32.;
where semester_status = "first" or semester_status = "first and last";
StudentCohort = _n_;
ltds = MDY(12,06,23);
record_src = "semesters";
l_StudentCohort_hk = hashing("md5", StudentCohort || ltds || "semesters");
h_Student_hk = hashing("md5", MatrNo_SID || ltds || "students");
h_Cohort_hk = hashing("md5", semester || study_programme || ltds || "semesters");
h_Semester_hk = hashing("md5", semester || ltds || "semesters");
RUN;

* Creating the satellites;
*************************;

data dv.s_Student (drop= ueq_type_descriptor);
set raw.students;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "students";
h_Student_hk = hashing("md5", MatrNo_SID || ltds || "students");
hashdiff = hashing("md5", MatrNo_SID||gender||ueq_type||ueq_year||ueq_ia
||ueq_gpa||ProfDegr||BirthYr||NationIA);
run;

proc sql;
create table dv.s_StudyProgramme as
select distinct grad, program, spec, study_programme
from raw.semesters;
quit;
data dv.s_StudyProgramme;
set dv.s_StudyProgramme;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "semesters";
h_StudyProgramme_hk = hashing("md5", study_programme || ltds || "semesters");
hashdiff = hashing("md5", grad||program||spec||study_programme);
run;

data dv.s_StudentSemester (keep=StudentSemester prgsem semester_status ExitReas 
ltds record_src l_StudentSemester_hk hashdiff);
set raw.semesters;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src= "semesters";
StudentSemester = _n_;
l_StudentSemester_hk = hashing("md5", StudentSemester || ltds || "semesters");
hashdiff = hashing("md5", StudentSemester||prgsem||semester_status||ExitReas);
run;

proc sql;
create table dv.s_Semester as
select distinct semester, semester_year, semester_season
from raw.semesters;
quit;
data dv.s_Semester;
set dv.s_Semester;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "semesters";
h_Semester_hk = hashing("md5", semester || ltds || "semesters");
hashdiff = hashing("md5", semester||semester_year||semester_season);
run;

data dv.s_Exam (keep = Exam No_Sem ECTS mandatory ExamType
ltds record_src l_Exam_hk hashdiff);
set raw.exams;
FORMAT ltds DDMMYY10. record_src $32.;
ltds = MDY(12,06,23);
record_src = "exams";
Exam = _n_;
l_Exam_hk = hashing("md5", Exam || ltds || "exams");
hashdiff = hashing("md5", Exam||No_Sem||ECTS||mandatory||ExamType);
run;

data dv.s_ExamRegistration (keep=Labnr attempt Withdrawl Ptermin
ltds record_src l_ExamRegistration_hk hashdiff);
set raw.exam_attempts;
FORMAT ltds DDMMYY10. record_src $32.;
WHERE Pstatus="AN";
ltds = MDY(12,06,23);
record_src = "exam_attempts";
l_ExamRegistration_hk = hashing("md5", Labnr || ltds || "exam_attempts");
hashdiff = hashing("md5", Labnr||attempt||Withdrawl||Ptermin);
run;

data dv.s_ExamAttempt (keep=Labnr attempt Withdrawl Ptermin panerk
ECTS grade Pstatus ltds record_src l_ExamAttempt_hk hashdiff);
set raw.exam_attempts;
FORMAT ltds DDMMYY10. record_src $32.;
WHERE Pstatus~="AN";
ltds = MDY(12,06,23);
record_src = "exam_attempts";
l_ExamAttempt_hk = hashing("md5", Labnr || ltds || "exam_attempts");
hashdiff = hashing("md5", Labnr||attempt||Withdrawl||Ptermin||panerk||ECTS||grade||Pstatus);
run;

* Creating the reference tables;
*******************************;

data dv.r_pstatus;
set raw.pstatus_descriptor;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "pstatus_descriptor";
run;

data dv.r_UEQType;
set raw.ueqtype_descriptor;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "ueqtype_descriptor";
run;

data dv.r_Panerk;
set raw.panerk_descriptor;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "panerk_descriptor";
run;

data dv.r_Mandatory;
set raw.mandatory_descriptor;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "mandatory_descriptor";
run;

data dv.r_ExamType;
set raw.examtype_descriptor;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "ExamType_descriptor";
run;

data dv.r_ExitReason (keep=ExitReas etxt Exit1 EndegrdRead
ltds record_src);
set raw.ending_reason;
FORMAT ltds DDMMYY10.;
ltds = MDY(12,06,23);
record_src = "ExamType_descriptor";
run;