create or replace function add_Course_Section(vsecid int,vinstructorId int,vday varchar,vweek smallint[],vstart smallint,vclassend smallint,vloc varchar)
returns int
as $$
begin
    insert into "CourseSectionClass"(instructor,"dayOfWeek",location,"weekList","sectionId","classStart","classEnd")
    values (vinstructorId,vday,vloc,vweek,vsecid,vstart,vclassend);
    return
        (select id from "CourseSectionClass" where "sectionId"=vsecid
         and "dayOfWeek"=vday and "classEnd"=vclassend and "classStart"=vstart and "weekList"=vweek);
end
$$ LANGUAGE 'plpgsql';

create or replace function add_Section(vcid varchar,vsemid int,vsecname varchar,vtot int)
returns int language plpgsql
as
$$
    begin

    insert into "CourseSection" ("totalCapacity", "leftCapacity", "courseId", "semesterId", "sectionName")
    values (vtot,vtot,vcid,vsemid,vsecname);
    return(
        select "sectionId" from "CourseSection" where "courseId"=vcid and "semesterId"=vsemid and "sectionName"=vsecname and "totalCapacity"=vtot
        );
    end
$$;

--DROP FUNCTION enroll_course(integer,integer);

create or replace function add_Student(vuid int,vfullname varchar,vdate date,vmajorid int,vfirstname varchar,vlastname varchar)
returns void language plpgsql
as
$$
    begin
    insert into "User"(id,"fullName") values (vuid,vfullname);
    insert into "Student"("userId","enrolledDate","majorId","firstName","lastName")
    values (vuid,vdate,vmajorid,vfirstname,vlastname);
    end
$$;

create or replace function enroll_Course(vstuid int,vsecid int)
returns int language plpgsql
as
$$
    declare grad varchar;
            cid varchar;
            rr record;
            semid int;
    begin

        if((select count(*) from "CourseSection" secc where secc."sectionId"=vsecid)=0)
        then return 1;--not found
        end if;

        semid:=(select "semesterId" from "CourseSection" where "sectionId"=vsecid);
        cid:=(select "courseId" from "CourseSection" where "sectionId"=vsecid);

        if((select count(*) from "student_section" join "CourseSection" C on student_section."sectionId" = C."sectionId" where C."sectionId"=vsecid and "studentId"=vstuid)>0)
        then return 2;--already enrolled
        end if;


        if((select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid)>0)
        then grad=(select grade from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid);
            if(grad='PASS' or cast(grad as integer)>=60)
                then return 3;--passed
            end if;
        end if;

--         CREATE TEMP TABLE IF NOT EXISTS prer as (select "path","level" from prerequisite where "courseId"=cid);
--         for rr in (select "path",level from prerequisite where "courseId"=cid)
--         loop
--             if((passed_prerequisites_for_course(vstuid,cid,rr.path,rr.level))=false)
--             then
--                 return 4;--pre not meet
--             end if;
--         end loop;
            if((passed_prerequisites_for_course(vstuid,cid,null,0))=false)
            then
                return 4;--pre not meet
            end if;

        if (
               (with cur as (
                   select *
                   from student_section ssec
                            join "CourseSectionClass" secc
                                 on secc."sectionId" = ssec."sectionId"
                            join "CourseSection" CS2
                                on secc."sectionId" = CS2."sectionId"
                   where ssec."studentId" = vstuid and CS2."semesterId"=semid
               ), toadd as(
                   select * from "CourseSectionClass" join "CourseSection" S on "CourseSectionClass"."sectionId" = S."sectionId"
                   where S."sectionId"=vsecid and "semesterId"=semid
               )
               select count(*)
               from toadd join cur
               on toadd."dayOfWeek" = cur."dayOfWeek"
                 and (toadd."weekList" && cur."weekList")
                 where ((toadd."classStart" between cur."classStart" and cur."classEnd") or
                      (toadd."classEnd" between cur."classStart" and cur."classEnd")
                   or (cur."classStart" between toadd."classStart" and toadd."classEnd") or
                      (cur."classEnd" between toadd."classStart" and toadd."classEnd"))
           )>0)
        then return 5;--conflict
        end if;
        if(
            (select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId"
                where "studentId"=vstuid and CS."courseId"=cid and CS."semesterId"=semid)
            >0)
            then return 5;
        end if;

        if((with sec as(
            select * from "CourseSection" secc
            where secc."sectionId"=vsecid
            )
            select sec."leftCapacity">0 from sec)=false
            )
        then return 6;--full
        end if;
--         if((select count(*) from "student_section" where "sectionId"=vsecid and "studentId"=vstuid)>0)
--         then grad:=(select grade from student_section where "sectionId"=vsecid and "studentId"=vstuid);
--             if(grad is null)
--                 then return 6;
--             end if;
--
--         end if;

        update "CourseSection" set "leftCapacity"="leftCapacity"-1 where "sectionId"=vsecid;
        insert into student_section("studentId", "sectionId") values (vstuid,vsecid);
        return 0;
    end
$$;




create or replace function add_Enrolled_Course_With_Grade(vstuid int,vsecid int,vgrade varchar)
returns void language plpgsql
as
$$
    begin
        if((select count(*) from student_section where "studentId"=vstuid and "sectionId"=vsecid)=0)
            then insert into student_section("studentId", "sectionId", grade) values (vstuid,vsecid,vgrade);
            else
--                 if((select grade from student_section where "studentId"=vstuid and "sectionId"=vsecid)is null)
                update student_section set grade=vgrade where "studentId"=vstuid and "sectionId"=vsecid;
--                 end if;
        end if;


    end;
$$;


create or replace function drop_Course(vstuid int,vsecid int)
returns int language plpgsql
as
$$
    begin
        if((select count(*)from student_section where "studentId"=vstuid and "sectionId"=vsecid)=0)
        then
            return 1;
        end if;
        if((select grade from student_section where "studentId"=vstuid and "sectionId"=vsecid) is not null)
            then return 1;
        end if;
        delete from student_section where "studentId"=vstuid and "sectionId"=vsecid;
        update "CourseSection" set "leftCapacity"="leftCapacity"+1 where "sectionId"=vsecid;
        return 0;
    end;
$$;

create or replace function search_Course(vstuid int,vsemid int,vcid varchar,vcname varchar,vinsname varchar,vday varchar
,vtime smallint,vloc varchar[],vtype varchar,igfull bool,igcon bool,igpass bool,igpre bool,vpgsize int,vpgidx int)
returns table(
    "courseId"   varchar,
    "courseName" varchar,
    credit       integer,
    "classHour"  integer,
    grading      varchar
) language plpgsql
as
$$
    declare
        maj int;
        validc table(
            "courseId"   varchar,
            "courseName" varchar,
            credit       integer,
            "classHour"  integer,
            grading      varchar
        );
    begin
        maj:=(select "majorId" from "Student" where "userId"=vstuid);
        if(vtype='ALL')
        then
            validc=(select * from "Course");
            else if(vtype='MAJOR_COMPULSORY' or vtype='MAJOR_ELECTIVE')
                then validc=(select * from "Course" join "Major_Course" MC on "Course"."courseId" = MC."courseId" where MC."majorId"=maj and MC.property=vtype);
                else if(vtype='MAJOR_ELECTIVE')
                    then validc=(select * from "Course" join "Major_Course" MC on "Course"."courseId" = MC."courseId" where MC."majorId"!=maj);
                    else if(vtype='PUBLIC')
                        then validc=(select * from "Course" left join "Major_Course" MC on "Course"."courseId" = MC."courseId" where "majorId" is null);
                        else raise 'Invalid Search Course Type';
                        end if;
                    end if;
                end if;
        end if;



    with res as(

        select * from student_section SS
            join "CourseSection" CS on SS."sectionId" = CS."sectionId"
            join "CourseSectionClass" CSC on CS."sectionId" = CSC."sectionId"
            join "Course" C on CS."courseId" = C."courseId"
            join "Instructor" Ins on CSC.instructor = Ins."userId"
        where
        vstuid=SS."studentId" and vsemid=CS."sectionId"
        and (vcid is null or vcid=CS."courseId")
        and (vcname is null or C."courseName"=vcname)
        and (vinsname is null or vinsname=Ins."firstName"||Ins."lastName")
        and (vday is null or vday=CSC."dayOfWeek")
        and (vtime is null or vtime between CSC."classStart" and CSC."classEnd")
        and (vloc is null or CSC.location in (vloc) )
        and (igfull or CS."leftCapacity">0)
    )


    end;
$$;
