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

        if((select count(*) from "student_section" join "CourseSection" C on student_section."sectionId" = C."sectionId" where C."sectionId"=vsecid and "studentId"=vstuid and C."semesterId"=semid)>0)
        then return 2;--already enrolled
        end if;


        if((select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid)>0)
        then grad=(select grade from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid);
            if( grad='PASS' or cast(grad as integer)>=60)
                then return 3;--passed
            end if;
        end if;

--         CREATE TEMP TABLE IF NOT EXISTS prer as (select "path","level" from prerequisite where "courseId"=cid);
        for rr in (select "path",level from prerequisite where "courseId"=cid)
        loop
            if((passed_prerequisites_for_course(vstuid,cid,rr.path,rr.level))=false)
            then
                return 4;--pre not meet
            end if;
        end loop;
--         drop table prer;

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
            then perform enroll_Course(vstuid,vsecid);
        end if;
        update student_section set grade=vgrade where "studentId"=vstuid and "sectionId"=vsecid;


    end;
$$
