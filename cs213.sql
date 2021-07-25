create database project3
with encoding = 'UTF8';
-- lc_collate = 'en_US.UTF8';



create extension if not exists ltree;

create table "Department"
(
    "departmentId" serial  not null
        constraint department_pk
            primary key,
    name           varchar not null
);

alter table "Department"
    owner to postgres;

create unique index department_departmentid_uindex
    on "Department" ("departmentId");

create unique index department_name_uindex
    on "Department" (name);

create table "Course"
(
    "courseId"   varchar not null
        constraint course_pk
            primary key,
    "courseName" varchar,
    credit       integer,
    "classHour"  integer,
    grading      varchar
);

alter table "Course"
    owner to postgres;

create table "User"
(
    id         integer not null
        constraint user_pk
            primary key,
    "fullName" varchar
);

alter table "User"
    owner to postgres;

create table "Instructor"
(
    "userId"    integer not null
        constraint instructor_pk
            primary key
        constraint instructor_user_id_fk
            references "User"
            on delete cascade,
    "firstName" varchar,
    "lastName"  varchar
);

alter table "Instructor"
    owner to postgres;

create table "Major"
(
    id             serial not null
        constraint major_pk
            primary key,
    name           varchar,
    "departmentId" integer
        constraint major_department_departmentid_fk
            references "Department"
            on delete cascade
);

alter table "Major"
    owner to postgres;

create table "Student"
(
    "enrolledDate" date,
    "majorId"      integer
        constraint student_major_id_fk
            references "Major"
            on delete cascade,
    "userId"       integer not null
        constraint student_pk
            primary key
        constraint student_user_id_fk
            references "User"
            on delete cascade,
    "firstName"    varchar,
    "lastName"     varchar
);

alter table "Student"
    owner to postgres;

create table "Semester"
(
    id    serial not null
        constraint semester_pk
            primary key,
    name  varchar,
    begin date,
    "end" date
);

alter table "Semester"
    owner to postgres;

create table "CourseSection"
(
    "sectionId"     serial not null
        constraint coursesection_pk
            primary key,
    "totalCapacity" integer,
    "leftCapacity"  integer,
    "courseId"      varchar
        constraint coursesection_course_courseid_fk
            references "Course"
            on delete cascade,
    "semesterId"    integer
        constraint coursesection_semester_id_fk
            references "Semester"
            on delete cascade,
    "sectionName"   varchar
);

alter table "CourseSection"
    owner to postgres;

create table "CourseSectionClass"
(
    id           serial not null
        constraint coursesectionclass_pk
            primary key,
    instructor   integer
        constraint coursesectionclass_instructor_userid_fk
            references "Instructor"
            on delete cascade,
    "dayOfWeek"  varchar,
    location     varchar,
    "weekList"   smallint[],
    "sectionId"  integer
        constraint coursesectionclass_coursesection_sectionid_fk_2
            references "CourseSection"
            on delete cascade,
    "classStart" smallint,
    "classEnd"   smallint
);

alter table "CourseSectionClass"
    owner to postgres;

create table "Major_Course"
(
    "majorId"  integer
        constraint major_course_major_id_fk
            references "Major"
            on delete cascade,
    "courseId" varchar
        constraint major_course_course_courseid_fk
            references "Course"
            on delete cascade,
    property   varchar,
    id         serial not null
        constraint major_course_pk
            primary key
);

alter table "Major_Course"
    owner to postgres;

create unique index major_course_majorid_uindex
    on "Major_Course" ("majorId", "courseId");


--alter table prerequisite
    --owner to postgres;

create table student_section
(
    "studentId" integer
        constraint student_section_student_userid_fk
            references "Student"
            on delete cascade,
    "sectionId" integer
        constraint student_section_coursesection_sectionid_fk
            references "CourseSection"
            on delete cascade,
    grade       varchar
);

alter table student_section
    owner to postgres;



create or replace function add_Department(nameIn varchar) returns integer
    language plpgsql
as
$$
BEGIN
    insert into "Department" (name) values (nameIn);
    RETURN (select "departmentId" from "Department" where name = nameIn);
END
$$;



CREATE OR REPLACE FUNCTION remove_Department(departmentId int)
    returns void
as
$$
BEGIN
    IF ((select count(*) from "Department" where "departmentId" = departmentId) = 0) THEN
        RAISE EXCEPTION '';
    end if;
    DELETE
    FROM "Department"
    WHERE "departmentId" = departmentId;
END
$$
    LANGUAGE plpgsql;


CREATE OR REPLACE function getAllDepartments()
    RETURNS TABLE
            (
                departmentId_out integer,
                name_out         varchar
            )
AS
$$
BEGIN
    RETURN QUERY
        select "departmentId" as departmentId_out, "Department".name as name_out from "Department";
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function getDepartment(department int)
    RETURNS TABLE
            (
                departmentId_out integer,
                name_out         varchar
            )
AS
$$
BEGIN
    IF ((select count(*) from "Department" where "departmentId" = department) = 0) THEN
        RAISE EXCEPTION '';
    END IF;
    RETURN QUERY
        select "departmentId", "Department".name from "Department" where "departmentId" = department;
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function add_Major(nameIn varchar, departmentId int)
    RETURNS integer
AS
$$
BEGIN
    insert into "Major" (name, "departmentId") VALUES (nameIn, departmentId);
    RETURN (select id from "Major" where name = nameIn and "departmentId" = departmentId);
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION remove_Major(majorId int)
    RETURNS VOID
    language plpgsql
AS
$$
BEGIN
    if ((select count(*) from "Major" where id = majorId) = 0) then
        raise exception '' ;
    end if;

    DELETE
    FROM "Major"
    WHERE id = majorId;
end
$$;



CREATE OR REPLACE function get_all_Majors()
    RETURNS TABLE
            (
                id              integer,
                major_name      varchar,
                department_id   integer,
                department_name varchar
            )
AS
$$
BEGIN
    RETURN QUERY
        select "Major".id,
               "Major".name           as Major_name,
               "Major"."departmentId" as department_Id,
               "Department".name      as Department_Name
        from "Major"
                 left join "Department" on "Major"."departmentId" = "Department"."departmentId";
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function get_Major(majorId int)
    RETURNS table
            (
                id              integer,
                major_name      varchar,
                department_id   integer,
                department_name varchar
            )
AS
$$
BEGIN
    if ((select count(*) from "Major" where id = majorId) = 0) then
        RAISE EXCEPTION '';
    end if;
    RETURN QUERY
        select "Major".id,
               "Major".name           as Major_name,
               "Major"."departmentId" as department_Id,
               "Department".name      as Department_Name
        from "Major"
                 left join "Department" on "Major"."departmentId" = "Department"."departmentId"
        where "Major".id = majorId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function add_Major_Compulsory_Course(majorId int, courseId varchar) --Compulsory
    returns void
    LANGUAGE SQL
as
$$
insert into "Major_Course" ("majorId", "courseId", property)
VALUES (majorId, courseId, 'MAJOR_COMPULSORY');
$$;



CREATE OR REPLACE FUNCTION add_Major_Elective_Course(majorId int, courseId varchar) --Elective
    returns void
    LANGUAGE SQL
as
$$
insert into "Major_Course" ("majorId", "courseId", property)
VALUES (majorId, courseId, 'MAJOR_ELECTIVE');
$$;


CREATE OR REPLACE FUNCTION remove_Semester(semesterId int)
    returns void
    LANGUAGE plpgsql
as
$$
begin
    if ((select count(*) from "Semester" where id = semesterId) = 0) then
        raise exception '';
    end if;

    DELETE
    FROM "Semester"
    WHERE id = semesterId;
end
$$;

CREATE OR REPLACE function add_Semester(nameIn varchar, beginIn date, end_In date)
    RETURNS integer
AS
$$
BEGIN
    insert into "Semester" (name, begin, "end") VALUES (nameIn, beginIn, end_In);
    RETURN (select id from "Semester" where name = nameIn and begin = beginIn and "end" = end_In);
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function get_all_Semester()
    RETURNS TABLE
            (
                id_out        integer,
                semester_name varchar,
                begin_        date,
                end_          date
            )
AS
$$
BEGIN
    RETURN QUERY
        select "Semester".id as id_out, name as semester_name, begin as begin_, "end" as end_
        from "Semester";
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function get_Semester(semesterId int)
    RETURNS TABLE
            (
                id_out        integer,
                semester_name varchar,
                begin_        date,
                end_          date
            )
AS
$$
BEGIN
    if ((select count(*) from "Semester" where "Semester".id = semesterId) = 0) then
        raise exception '';
    end if;
    RETURN QUERY
        select "Semester".id, name, begin, "end"
        from "Semester"
        where "Semester".id = semesterId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION remove_User(userId int)
    RETURNS VOID
    language plpgsql
AS
$$
BEGIN
    if ((select count(*) from "User" where id = userId) = 0) then
        raise exception '' ;
    end if;

    DELETE
    FROM "User"
    WHERE id = userId;
end
$$;



create or replace function get_all_users()
    returns TABLE
            (
                userId          integer,
                fullName        varchar,
                enrolledDate    date,
                department_name varchar,
                MajorId         integer,
                major_name      varchar,
                department_id   integer
            )
    language plpgsql
as
$$
BEGIN
    RETURN QUERY
        select "User".id, "fullName", "enrolledDate", department_name, "majorId", major_name, "Major"."departmentId"
        from "User"
                 left join "Student" on "User".id = "Student"."userId"
                 left join "Instructor" on "User".id = "Instructor"."userId"
                 left join "Major" on "Student"."majorId" = "Major".id
                 left join "Department" on "Major"."departmentId" = "Department"."departmentId";
END
$$;


create or replace function get_User(userIdIn integer)
    returns TABLE
            (
                userId          integer,
                fullName        varchar,
                enrolledDate    date,
                department_name varchar,
                MajorId         integer,
                major_name      varchar,
                department_id   integer
            )
    language plpgsql
as
$$
BEGIN
    if ((select count(*) from "User" where id = userIdIn) = 0) then
        raise exception '';
    end if;
    RETURN QUERY
        select "User".id, "fullName", "enrolledDate", "Department".name, "majorId", "Major".name, "Major"."departmentId"
        from "User"
                 left join "Student" on "User".id = "Student"."userId"
                 left join "Instructor" on "User".id = "Instructor"."userId"
                 left join "Major" on "Student"."majorId" = "Major".id
                 left join "Department" on "Major"."departmentId" = "Department"."departmentId"
        where "User".id = userIdIn;
END
$$;


CREATE OR REPLACE function add_Instructor(userId int, firstName varchar, lastName varchar, fullname_in varchar)
    RETURNS integer
AS
$$
BEGIN
            insert into "User" (id, "fullName") VALUES (userId, fullname_in);
    insert into "Instructor" ("userId", "firstName", "lastName") VALUES (userId, firstName, lastName);
    RETURN userId;
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function get_Instructed_CourseSections(instructorIdIn int, semesterIdIn int)
    RETURNS TABLE
            (
                courseSectionIdOut   int,
                courseSectionNameOut varchar,
                leftCapacityOut      int,
                totalCapacityOut     int
            )
AS
$$
BEGIN

    if ((select count(*) from "Instructor" where "userId" = instructorIdIn) = 0) then raise exception ''; end if;
    if ((select count(*) from "Semester" where id = semesterIdIn) = 0) then raise exception ''; end if;

    RETURN QUERY
        select "CourseSection"."sectionId", "sectionName", "leftCapacity", "totalCapacity"
        from "CourseSectionClass"
                 left join "CourseSection" on "CourseSectionClass"."sectionId" = "CourseSection"."sectionId"
        where instructor = instructorIdIn
          and "semesterId" = semesterIdIn;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function add_Course(courseId varchar, courseName varchar, credit int, classHour int, grading varchar)
    returns void
AS
$$
BEGIN
    insert into "Course" ("courseId", "courseName", credit, "classHour", grading)
    VALUES (courseId, courseName, credit, classHour, grading);
END;
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function remove_Coures(courseId varchar)
    returns void
AS
$$
BEGIN
    if ((select count(*) from "Course" where "courseId" = courseId) = 0) then raise exception ''; end if;

    delete from "Course" where "courseId" = courseId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function remove_Coures_Section(sectionId int)
    returns void
AS
$$
BEGIN
    if ((select count(*) from "CourseSection" where "sectionId" = sectionId) = 0) then raise exception ''; end if;

    delete from "CourseSection" where "sectionId" = sectionId;
END
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE function remove_Coures_Section_Class(classId int)
    returns void
AS
$$
BEGIN
    if ((select count(*) from "CourseSectionClass" where id = classId) = 0) then raise exception ''; end if;

    delete from "CourseSectionClass" where id = classId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function get_Course_Sections_In_Semester(courseId varchar, semesterId int)
    RETURNS TABLE
            (
                idOut         integer,
                nameOut       varchar,
                leftCapacity  integer,
                totalCapacity integer
            )
AS
$$
BEGIN

    if ((select count(*) from "Course" where "courseId" = courseId) = 0) then raise exception ''; end if;

    if ((select count(*) from "Semester" where id = semesterId) = 0) then raise exception ''; end if;

    RETURN QUERY
        select "sectionId", "sectionName", "leftCapacity", "totalCapacity"
        from "CourseSection"
        where "courseId" = courseId
          and "semesterId" = semesterId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function get_Course_By_Section(sectionId int)
    RETURNS TABLE
            (
                id         varchar,
                name       varchar,
                creditOut  integer,
                classHour  integer,
                gradingOut varchar
            )
AS
$$
BEGIN

    if ((select count(*) from "CourseSection" where "sectionId" = sectionId) = 0) then raise exception ''; end if;

    RETURN QUERY
        select "Course"."courseId", "courseName", credit, "classHour", grading
        from "CourseSection"
                 left join "Course" on "CourseSection"."courseId" = "Course"."courseId"
        where "sectionId" = sectionId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function get_Course_Section_Classes(sectionIdIn int)
    RETURNS TABLE
            (
                idOut               int,
                dayOfWeek           varchar,
                weekList            smallint[],
                classBegin          smallint,
                classEnd            smallint,
                locationOut         varchar,
                instructor_fullName varchar,
                instructor_idOut    integer
            )
AS
$$
BEGIN
    if ((select count(*) from "CourseSection" where "sectionId" = sectionIdIn) = 0) then raise exception ''; end if;

    RETURN QUERY
        select "CourseSectionClass".id,
               "dayOfWeek",
               "weekList",
               "classStart",
               "classEnd",
               location,
               "fullName",
               instructor
        from "CourseSectionClass"
                 left join "Instructor" on "CourseSectionClass".instructor = "Instructor"."userId"
                 left join "User" on "Instructor"."userId" = "User".id
        where "CourseSectionClass"."sectionId" = sectionIdIn;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE function get_Course_Section_By_Class(classId int)
    RETURNS TABLE
            (
                sectionId     integer,
                nameOut       varchar,
                leftCapacity  integer,
                totalCapacity integer
            )
AS
$$
BEGIN

    if ((select count(*) from "CourseSectionClass" where id = classId) = 0) then raise exception ''; end if;

    RETURN QUERY
        select "CourseSection"."sectionId", "sectionName", "leftCapacity", "totalCapacity"
        from "CourseSectionClass"
                 left join "CourseSection" on "CourseSectionClass"."sectionId" = "CourseSection"."sectionId"
        where id = classId;
END
$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION remove_course_trigger_function()
    returns trigger
as
$$
declare
begin
    update "CourseSection" set "leftCapacity" = "leftCapacity" + 1 where "sectionId" = old."sectionId";
    return new;
end

$$ language plpgsql;

CREATE TRIGGER remove_course_trigger
    AFTER delete
    on student_section
    for each row
execute procedure remove_course_trigger_function();



CREATE OR REPLACE function get_Enrolled_Students_In_Semester(courseId varchar, semesterId int)
    returns TABLE
            (
                studentId         integer,
                fullNameOut       varchar,
                enrolledDateOut   date,
                majorIdOut        int,
                majorNameOut      varchar,
                departmentIdOut   integer,
                departmentNameOut varchar
            )
AS
$$
BEGIN
    if ((select count(*) from "Course" where "courseId" = courseId) = 0) then raise exception ''; end if;

    if ((select count(*) from "Semester" where id = semesterId) = 0) then raise exception ''; end if;

    return query
        select "userId",
               "fullName",
               "enrolledDate",
               "majorId",
               "Major".name,
               "Department"."departmentId",
               "Department".name
        from "Student"
                 left join "User" on "Student"."userId" = "User".id
                 left join "Major" on "Student"."majorId" = "Major".id
                 left join "Department" on "Major"."departmentId" = "Department"."departmentId";
END
$$ LANGUAGE 'plpgsql';



create index name1 on student_section("studentId");
create index name2 on student_section("sectionId");



  create table public.prerequisite
  (
      "courseId" varchar
          constraint prerequisite_course_courseid_fk
              references public."Course"
              on delete cascade,
      path       ltree,
      level      integer,
      "No"       integer
  );


  CREATE OR REPLACE function passed_Prerequisites_For_Course(studentIdIn integer, courseIdIn varchar, pathIn ltree,
                                                             levelIn integer)
      RETURNS bool
  AS
  $$
  declare
      root     varchar;
      andFlag  bool;
      orFlag   bool;
      cnt      int;
      totalCnt int;
      subPath  ltree;
  BEGIN
      if (pathIn is null) then
          if ((select count(*) from prerequisite where text2ltree('Top.'||courseIdIn) @> path) = 0) then return true; end if;
          root = 'Top.' || courseIdIn;
          subpath = (select path from prerequisite where text2ltree(root) @> path and level = 3);
          return passed_Prerequisites_For_Course(studentIdIn, courseIdIn, subPath, 3);
      end if;

      root = (select split_part(ltree2text(pathIn), '.', levelIn));
      --done test
      if (root not like 'and%' and root not like 'or%') then --todo
          if (
                  root in (select "courseId"
                           from student_section
                                    left join "CourseSection" CS on CS."sectionId" = student_section."sectionId"
                           where "studentId" = studentIdIn
                             and case
                                     when (grade ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$') then
                                         cast(grade as int) between 60 and 100
                                     else grade = 'PASS'
                               end)
              ) then
              return true;
          else
              return false;
          end if;
      end if;
      totalCnt = (select count(*) from prerequisite where pathIn @> path and level = levelIn + 1); --done test
      cnt = 1;
      if (root like 'and%') then
          while cnt <= totalCnt
              loop
                  subPath =
                          (select path from prerequisite where pathIn @> path and level = levelIn + 1 and "No" = cnt);
                  if ((passed_Prerequisites_For_Course(studentIdIn, courseIdIn, subPath, levelIn + 1)) = false)
                  then
                      return false;
                  end if;
                  cnt = cnt + 1;
              end loop;
          return true;
      end if;


      if (root like 'or%') then
          while cnt <= totalCnt
              loop
                  subPath =
                          (select path from prerequisite where pathIn @> path and level = levelIn + 1 and "No" = cnt);
                  if ((passed_Prerequisites_For_Course(studentIdIn, courseIdIn, subPath, levelIn + 1)))
                  then
                      return true;
                  end if;
                  cnt = cnt + 1;
              end loop;
          return false;
      end if;

      return false; --todo
  END
  $$ LANGUAGE 'plpgsql';


  -- my code
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


--         if((select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid)>0)
--         then grad=(select grade from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid);
--             if(grad='PASS' or cast(grad as integer)>=60)
--                 then return 3;--passed
--             end if;
--         end if;
        if(pass_Or_Not(vstuid,vsecid))
            then return 3;--passed
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
--                (with cur as (
--                    select *
--                    from student_section ssec
--                             join "CourseSectionClass" secc
--                                  on secc."sectionId" = ssec."sectionId"
--                             join "CourseSection" CS2
--                                 on secc."sectionId" = CS2."sectionId"
--                    where ssec."studentId" = vstuid and CS2."semesterId"=semid
--                ), toadd as(
--                    select * from "CourseSectionClass" join "CourseSection" S on "CourseSectionClass"."sectionId" = S."sectionId"
--                    where S."sectionId"=vsecid and "semesterId"=semid
--                )
--                select count(*)
--                from toadd join cur
--                on toadd."dayOfWeek" = cur."dayOfWeek"
--                  and (toadd."weekList" && cur."weekList")
--                  where ((toadd."classStart" between cur."classStart" and cur."classEnd") or
--                       (toadd."classEnd" between cur."classStart" and cur."classEnd")
--                    or (cur."classStart" between toadd."classStart" and toadd."classEnd") or
--                       (cur."classEnd" between toadd."classStart" and toadd."classEnd"))
--            )
               (select count(*) from conflict_Course_Name(vstuid,vsecid) )   >0)
        then return 5;--conflict
        end if;
        if(
            (select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId"
                where "studentId"=vstuid and CS."courseId"=cid and CS."semesterId"=semid)
            >0)
            then return 5;--conflict
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
        if((select grading from "Course" join "CourseSection" CS on "Course"."courseId" = CS."courseId"
            where CS."sectionId"=vsecid)
            ='HUNDRED_MARK_SCORE')
        then
            if(vgrade is not null and vgrade !~'^([0-9]+[.]?[0-9]*|[.][0-9]+)$')
                then
                return;
            end if;
        else
            if(vgrade is not null and vgrade!='PASS' and vgrade !='FAIL')
                then
                return;
            end if;
        end if;
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

-- sec stuid in conflict class out
create or replace function conflict_Course_Name(vstuid int,vsecid int)
returns table(
    name varchar
             ) language plpgsql
as
$$
declare
    cid varchar;
    semid int;
begin
    semid:=(select "semesterId" from "CourseSection" where "sectionId"=vsecid);
    cid:=(select "courseId" from "CourseSection" where "sectionId"=vsecid);
    return query(with cur as (
                   select *
                   from student_section ssec
                            join "CourseSectionClass" secc
                                 on secc."sectionId" = ssec."sectionId"
                            join "CourseSection" CS2
                                on secc."sectionId" = CS2."sectionId"
                            join "Course" C on CS2."courseId" = C."courseId"
                   where ssec."studentId" = vstuid and CS2."semesterId"=semid
               ), toadd as(
                   select * from "CourseSectionClass" join "CourseSection" S on "CourseSectionClass"."sectionId" = S."sectionId"
                   where S."sectionId"=vsecid and "semesterId"=semid
               )
               select (cur."courseName"||'['|| cur."sectionName" ||']')::varchar as name
--             select section_Fullname(cur."sectionId") as name
               from toadd join cur
               on toadd."dayOfWeek" = cur."dayOfWeek"
                 and (toadd."weekList" && cur."weekList")
                 where ((toadd."classStart" between cur."classStart" and cur."classEnd") or
                      (toadd."classEnd" between cur."classStart" and cur."classEnd")
                   or (cur."classStart" between toadd."classStart" and toadd."classEnd") or
                      (cur."classEnd" between toadd."classStart" and toadd."classEnd"))
           );

end

$$;

-- sec stu in; pass out
create or replace function pass_Or_Not(vstuid int,vsecid int)
returns bool language plpgsql
as $$
    declare grad varchar;
            cid varchar;
begin
     cid:=(select "courseId" from "CourseSection" where "sectionId"=vsecid);
    if((select count(*) from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid)>0)
        then grad=(select grade from student_section ssec join "CourseSection" CS on ssec."sectionId" = CS."sectionId" where ssec."studentId"=vstuid and "courseId"=cid);
            if(grad='PASS' )
                then return true;
            else if((grad ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$'))
                then if(cast(grad as integer)>=60) then return true; end if;

            end if;
            end if;
        end if;
    return false;
end
$$;

create or replace function section_Fullname(vsecid int)
returns varchar language plpgsql
as $$
begin
   return  cast((select ("courseName"||'['|| "sectionName" ||']')
   from "CourseSection" join "Course" C on "CourseSection"."courseId" = C."courseId"
   where "sectionId"=vsecid) as varchar);

end

$$;


create or replace function search_Section_Student(vstuid int,vsemid int,vcid varchar,vcname varchar,vinsname varchar,vday varchar
,vtime smallint,vloc varchar[],vtype varchar,igfull bool,igcon bool,igpass bool,igpre bool,vpgsize int,vpgidx int)
returns table(
    sectionid   int
) language plpgsql
as
$$
    declare
        maj int;
    begin
--     return query(select "sectionId" from student_section);
        maj:=(select "majorId" from "Student" where "userId"=vstuid);
--         if(vtype='ALL')
--         then
--             validc=(select * from "Course");
--             else if(vtype='MAJOR_COMPULSORY' or vtype='MAJOR_ELECTIVE')
--                 then validc=(select * from "Course" join "Major_Course" MC on "Course"."courseId" = MC."courseId" where MC."majorId"=maj and MC.property=vtype);
--                 else if(vtype='MAJOR_ELECTIVE')
--                     then validc=(select * from "Course" join "Major_Course" MC on "Course"."courseId" = MC."courseId" where MC."majorId"!=maj);
--                     else if(vtype='PUBLIC')
--                         then validc=(select * from "Course" left join "Major_Course" MC on "Course"."courseId" = MC."courseId" where "majorId" is null);
--                         else raise 'Invalid Search Course Type';
--                         end if;
--                     end if;
--                 end if;
--         end if;
    return query(
    with res as(
        select CS."sectionId",CS."courseId", section_Fullname(CS."sectionId") as name from "CourseSection" CS
            left join student_section SS on CS."sectionId" = ss."sectionId"
            left join "CourseSectionClass" CSC on CS."sectionId" = CSC."sectionId"
                                                 and (vcid is null or vcid=CS."courseId")
                                           and (igfull or CS."leftCapacity">0)
                                           and (vcname is null or section_Fullname(CS."sectionId")=vcname)
                                            and CS."semesterId"=vsemid

                                                 and (vday is null or vday=CSC."dayOfWeek")
                                                 and (vtime is null or vtime between CSC."classStart"and CSC."classEnd")
                                                and (vloc is null or (CSC.location=any (vloc)) )

            left join "Instructor" Ins on CSC.instructor = Ins."userId"
                         and (vinsname is null or (Ins."firstName"||' '||Ins."lastName")=vcname or Ins."firstName"=vcname or Ins."lastName"=vcname or (Ins."firstName"||Ins."lastName")=vcname)


        where (igpre or passed_prerequisites_for_course(vstuid,CS."courseId",null,0))

        and (igcon or (select count(*) from conflict_Course_Name(vstuid,SS."sectionId"))=0)
        and (igpass or pass_Or_Not(vstuid,SS."sectionId"))

    ) select res."sectionId" as sectionid from res
    order by res."courseId",res.name
--     limit vpgsize offset vpgsize*vpgidx
        );

    end
$$;



create or replace function get_CourseOfSection(vsecid int)
returns setof "Course" language plpgsql
as $$
    declare cid varchar;
begin
    cid:=(select "courseId" from "CourseSection" where "sectionId"=vsecid);

   return query(
       with sec as (select * from "CourseSection" where "sectionId"=vsecid)
       select * from "Course"
       where "courseId"=cid
   );
end
$$;

--drop function get_CourseOfSection(vsecid int);
-- secid in secclass out
create or replace function get_ClassOfSection(vsecid int)
returns setof "CourseSectionClass" language  plpgsql
as $$
begin
   return query(
       select *
       from "CourseSectionClass" CSC
       where CSC."sectionId"=vsecid
   );
end
$$;

create or replace function get_Instructor(vinsid int)
returns setof "Instructor" language plpgsql
as $$
begin
    return query(select  * from "Instructor" where "userId"=vinsid);
end;
$$;

create or replace function get_SemFromTime(vdate date)
returns setof "Semester" language  plpgsql
as $$
    begin
    return query(select * from "Semester" S where vdate between  S.begin and S."end");
    end
$$;

-- drop function get_table_class(vstuid integer, vdate date);


create or replace function get_Table_class(vstuid int,vdate date)
returns table(
    fullname varchar,
    ins int,
    dayofweek varchar,
    classbegin smallint,
    classend smallint,
    loc varchar,
    insfirstname varchar,
    inslastname varchar,
    insid int
)language plpgsql
as $$
    declare
        semid int;
        sembegin date;
        week smallint;
begin
    semid=(select S.id from "Semester" S where vdate between  S.begin and S."end");
    sembegin=(select S.begin from "Semester" S where vdate between  S.begin and S."end");
    week=(((vdate-sembegin)/7)+1)::smallint;
--     if((vdate-sembegin)%7!=0)
--     then week=week+1;
--     end if;

    return query(
      select section_fullname(SC."sectionId")::varchar,CSC.instructor,CSC."dayOfWeek",CSC."classStart",CSC."classEnd",CSC.location,I."firstName",I."lastName",I."userId" from student_section SC
        join "CourseSection" CS on SC."sectionId"=CS."sectionId"
        join "CourseSectionClass" CSC on SC."sectionId"=CSC."sectionId"
        join "Instructor" I on CSC.instructor = I."userId"
        where SC."studentId"=vstuid and week=any(CSC."weekList")
        and semid=CS."semesterId"
    );
end
$$;
