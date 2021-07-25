-- create database "dbname you like"
-- with encoding  = 'UTF8'
-- lc_collate = 'en_US.UTF8'



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