package Implementation;

import cn.edu.sustech.cs307.database.SQLDataSource;
import cn.edu.sustech.cs307.dto.*;
import cn.edu.sustech.cs307.dto.grade.Grade;
import cn.edu.sustech.cs307.dto.grade.HundredMarkGrade;
import cn.edu.sustech.cs307.dto.grade.PassOrFailGrade;
import cn.edu.sustech.cs307.exception.EntityNotFoundException;
import cn.edu.sustech.cs307.exception.IntegrityViolationException;
import cn.edu.sustech.cs307.service.StudentService;

import javax.annotation.Nullable;
import javax.annotation.ParametersAreNonnullByDefault;
import java.sql.*;
import java.sql.Date;
import java.time.DayOfWeek;

import java.time.Duration;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@ParametersAreNonnullByDefault
public class StudentServiceImplementation implements StudentService {

    // to do
    @Override
    public void addStudent(int userId, int majorId, String firstName, String lastName, Date enrolledDate) {
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select add_Student(?,?,?,?,?,?)")//todo prerequisite
        ) {
            stmt.setInt(1,userId);
            stmt.setString(2,firstName+" "+lastName);
            stmt.setDate(3,enrolledDate);
            stmt.setInt(4,majorId);
            stmt.setString(5,firstName);
            stmt.setString(6,lastName);
            stmt.executeQuery();
        }catch(Exception e){
            throw new IntegrityViolationException();
        }
    }


    final String replace = "X";
    final String original = "-";
    public Set<CourseSectionClass> getClass(int sectionId,Connection conn){
        try (
             PreparedStatement stmt = conn.prepareStatement("select * from get_ClassOfSection(?)")//todo prerequisite
        ) {
            stmt.setInt(1,sectionId);
            ResultSet res=stmt.executeQuery();
            HashSet<CourseSectionClass> ret=new HashSet<>();
            while(res.next()){
                CourseSectionClass CSC=new CourseSectionClass();
//                for(int i=0;i<res.getMetaData().getColumnCount();i++) {
//                    System.out.println(res.getMetaData().getColumnName(i+1));
//                }

                CSC.instructor=getInstructor(res.getInt("Instructor"),conn);
                CSC.id=res.getInt("id");
                CSC.dayOfWeek=DayOfWeek.valueOf(res.getString("dayOfWeek"));
                //CSC.weekList= new HashSet<Short>(Arrays.stream( ((short[])res.getArray("weekList").getArray())).boxed().toArray( Integer[]::new ));
                HashSet<Short> hs =new HashSet<>();
                for(Short a : (Short[])res.getArray("weekList").getArray()){
                    hs.add(a);
                }
                CSC.weekList=hs;
                CSC.classBegin=res.getShort("classStart");
                CSC.classEnd=res.getShort("classEnd");
            }
        }catch (Exception e){
            e.printStackTrace();
        }
        return null;
    }
    public Course getCourseOfSection(int sectionId,Connection conn){
        try (
             PreparedStatement stmt = conn.prepareStatement("select * from get_CourseOfSection(?)")//todo prerequisite
        ) {
            stmt.setInt(1,sectionId);
            ResultSet res=stmt.executeQuery();
            res.next();
            Course ret=new Course();
            ret.id=res.getString("courseId");
            ret.classHour=res.getInt("classHour");
            ret.name=res.getString("courseName");
            ret.credit=res.getInt("credit");
            ret.grading=res.getString("grading")=="HUNDRED_MARK_SCORE"? Course.CourseGrading.HUNDRED_MARK_SCORE: Course.CourseGrading.PASS_OR_FAIL;
            return ret;
        }catch (Exception e){
            e.printStackTrace();
        }
        return null;
    }
    public Instructor getInstructor(int uid,Connection conn){
        try (
             PreparedStatement stmt = conn.prepareStatement("select * from get_Instructor(?)")//todo prerequisite
        ) {
            stmt.setInt(1,uid);
            ResultSet res=stmt.executeQuery();
            res.next();
            Instructor ret=new Instructor();
            ret.fullName=res.getString("firstName")+res.getString("lastName");
            ret.id=uid;
            return ret;
        }catch (Exception e){
            e.printStackTrace();
        }
        return null;
    }
    public List<String> getConflictCourse(int studentId,int sectionId,Connection conn){
        try (
             PreparedStatement stmt = conn.prepareStatement("select conflict_Course_Name(?,?)")//todo prerequisite
        ) {
            stmt.setInt(1,studentId);
            stmt.setInt(2,sectionId);
            ResultSet res=stmt.executeQuery();
            ArrayList<String> ret=new ArrayList<>();
            while(res.next()){
                ret.add(res.getString("conflict_Course_Name"));
            }
            return ret;
        }catch (Exception e){
            e.printStackTrace();
        }
        return null;
    }
    public CourseSection getSection(int sectionId,Connection conn){
        try (
             PreparedStatement stmt = conn.prepareStatement("select * from \"CourseSection\" where \"sectionId\"=?")//todo prerequisite
        ) {
            stmt.setInt(1,sectionId);
            CourseSection ret=new CourseSection();
            ResultSet res=stmt.executeQuery();
            res.next();
            ret.id=res.getInt("sectionId");
            ret.totalCapacity=res.getInt("totalCapacity");
            ret.leftCapacity=res.getInt("leftCapacity");
            ret.name=res.getString("sectionName");
            return ret;
        }catch (Exception e){
            e.printStackTrace();
        }
        return null;
    }
    public CourseSearchEntry getSectionEntry(int studentId,int sectionId,Connection conn){
//        System.out.print('a');
        CourseSearchEntry ret=new CourseSearchEntry();
        ret.conflictCourseNames=getConflictCourse(studentId, sectionId,conn);
//        System.out.print('b');
        ret.course=getCourseOfSection(sectionId,conn);
//        System.out.print('c');
        ret.sectionClasses=getClass(sectionId,conn);
//        System.out.print('d');
        ret.section=getSection(sectionId,conn);
//        System.out.print('e');
        return ret;
    }





    // to do
    @Override
    public List<CourseSearchEntry> searchCourse(int studentId, int semesterId,
                                                @Nullable String searchCid,
                                                @Nullable String searchName,
                                                @Nullable String searchInstructor,
                                                @Nullable DayOfWeek searchDayOfWeek,
                                                @Nullable Short searchClassTime,
                                                @Nullable List<String> searchClassLocations,
                                                CourseType searchCourseType,
                                                boolean ignoreFull, boolean ignoreConflict,
                                                boolean ignorePassed, boolean ignoreMissingPrerequisites,
                                                int pageSize, int pageIndex) {
//        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
//             PreparedStatement stmt = connection.prepareStatement("select * from search_Section_Student(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
////             PreparedStatement stmt = connection.prepareStatement("select * from \"CourseSection\"");
//        ) {
////            System.out.println("oA ");
//
////            System.out.println("oB ");
//            if(searchCid!=null)searchCid=searchCid.replace(replace,"-");
//            stmt.setInt(1,studentId);
//            stmt.setInt(2,semesterId);
//            stmt.setString(3,searchCid);
//            stmt.setString(4,searchName);
//            stmt.setString(5,searchInstructor);
//            stmt.setString(6,searchDayOfWeek!=null?searchDayOfWeek.toString():"Noday");
//            stmt.setShort(7,searchClassTime!=null?searchClassTime:-1);
//            stmt.setArray(8,searchClassLocations!=null?connection.createArrayOf("varchar",searchClassLocations.toArray()):null);
//            stmt.setString(9,searchCourseType.toString());
//            stmt.setBoolean(10,ignoreFull);
//            stmt.setBoolean(11,ignoreConflict);
//            stmt.setBoolean(12,ignorePassed);
//            stmt.setBoolean(13,ignoreMissingPrerequisites);
//            stmt.setInt(14,pageSize);
//            stmt.setInt(15,pageIndex);
////            System.out.println("oC ");
//            ResultSet res=stmt.executeQuery();
////            System.out.println("oD ");
//            List<CourseSearchEntry> ret=new ArrayList<>();
//            List<Integer> secargs=new ArrayList<>();
//            while(res.next()){
//                int secid=res.getInt("sectionid");
////                System.out.println(secid);
//                secargs.add(secid);
//            }
//            if(secargs.size()!=0)
//                System.out.println(secargs.size());
//            for(int secid:secargs){
////                System.out.println(res.getMetaData().getColumnName(1));
////                System.out.print("oa ");
//
////                System.out.print("ob ");
////                CourseSearchEntry entry=getSectionEntry(studentId,secid,connection);
////                System.out.print("oc ");
////                ret.add(entry);
////                System.out.print("od ");
//            }
////            ret.sort(Comparator.comparing(a -> a.course.name));
//            return ret;
//        }catch(Exception e){
//            System.out.println(e.getMessage());
//        }

        // to do
        return List.of();
    }

    // to do
    @Override
    public EnrollResult enrollCourse(int studentId, int sectionId) {

        EnrollResult result = EnrollResult.UNKNOWN_ERROR;//TODO

        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select enroll_Course(?,?)")//todo prerequisite
        ) {
            stmt.setInt(1,studentId);
            stmt.setInt(2,sectionId);
            ResultSet res=stmt.executeQuery();
            res.next();
            int ret=res.getInt("enroll_Course");
            //System.out.println(ret);
            switch(ret){
                case 0:
                    result=EnrollResult.SUCCESS;
                    break;
                case 1:
                    result=EnrollResult.COURSE_NOT_FOUND;
                    break;
                case 2:
                    result=EnrollResult.ALREADY_ENROLLED;
                    break;
                case 3:
                    result=EnrollResult.ALREADY_PASSED;
                    break;
                case 4:
                    result=EnrollResult.PREREQUISITES_NOT_FULFILLED;
                    break;
                case 5:
                    result=EnrollResult.COURSE_CONFLICT_FOUND;
                    break;
                case 6:
                    result=EnrollResult.COURSE_IS_FULL;
                    break;
                default:
                    result=EnrollResult.UNKNOWN_ERROR;
            }

            //PreparedStatement stmt2 = connection.prepareStatement("select select \"path\",\"level\" from prerequisite where \"courseId\"=?");

        }catch(Exception e){
            System.out.println(e.getMessage());
        }
        //result=EnrollResult.SUCCESS;
        return result;


    }

    // to do
    @Override
    public void dropCourse(int studentId, int sectionId) {
        // to do
        int t=0;
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select drop_Course(?,?)")//todo prerequisite
        ) {
            stmt.setInt(1,studentId);
            stmt.setInt(2,sectionId);
            ResultSet res=stmt.executeQuery();
            res.next();
            t=res.getInt("drop_Course");
        }catch(Exception e){
            throw new IllegalStateException();
        }
        if(t==1) {
            throw new IllegalStateException();
        }
    }

    // to do
    @Override
    public void addEnrolledCourseWithGrade(int studentId, int sectionId, @Nullable Grade grade) {
        // to do
        //System.out.println("Grade");
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select add_Enrolled_Course_With_Grade(?,?,?)")//todo prerequisite
        ) {
            stmt.setInt(1,studentId);
            stmt.setInt(2,sectionId);
            if(grade==null){
                stmt.setString(3,null);
            }
            else {
                String args3 = (grade instanceof HundredMarkGrade) ? Integer.toString(((HundredMarkGrade) grade).mark) : grade.toString();
                //System.out.println(args3);
                stmt.setString(3, args3);
            }
            stmt.executeQuery();
        }catch(Exception e){
            //System.out.println(e.getMessage());
            throw new IntegrityViolationException();
        }
    }

    // to do
    @Override
    public CourseTable getCourseTable(int studentId, Date date) {
        CourseTable ctable=new CourseTable();
        ctable.table=new HashMap<>();
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select * from get_SemFromTime(?)");//todo prerequisite
            PreparedStatement stmt2 = connection.prepareStatement("select * from get_Table_class(?,?)")
        ) {
//            stmt.setDate(1,date);
//            ResultSet ressem=stmt.executeQuery();
//            if(!ressem.next())
//                return ctable;
//            int semid=ressem.getInt("id");
//            Date begin=ressem.getDate("begin");
//            int dayb=(int) ((date.getTime()-begin.getTime()) / (1000 * 60 * 60* 24));
//            short week=(short)(dayb/7+(dayb%7==0?1:0));
//            String day=getDay(date);
            stmt2.setInt(1,studentId);
            stmt2.setDate(2,date);
            ResultSet res=stmt2.executeQuery();

            ctable.table.put(DayOfWeek.MONDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.TUESDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.WEDNESDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.THURSDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.FRIDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.SATURDAY,new HashSet<>());
            ctable.table.put(DayOfWeek.SUNDAY,new HashSet<>());

            while(res.next()){
                String name=res.getString("fullname");
                name=name.replace(replace,original);
                int ins=res.getInt("ins");
                DayOfWeek dayofweek=DayOfWeek.valueOf(res.getString("dayofweek"));
                short classbegin=res.getShort("classbegin");
                short classend=res.getShort("classend");
                String loc=res.getString("loc");
                String insname=res.getString("insname");
                int insid=res.getInt("insid");
                Instructor instructor=new Instructor();
                instructor.id=insid;
                instructor.fullName=insname;
                CourseTable.CourseTableEntry entry=new CourseTable.CourseTableEntry();
                entry.courseFullName=name;
                entry.classBegin=classbegin;
                entry.classEnd=classend;
                entry.instructor=instructor;
                entry.location=loc;
                ctable.table.get(dayofweek).add(entry);
            }
//            System.out.println(semid);
        }catch(Exception e){
            e.printStackTrace();
//            throw new IntegrityViolationException();
        }
        return ctable;


    }
    public String getDay(Date date){
        String[] name={"MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"};
        Calendar cal=Calendar.getInstance();
        int d = cal.get(Calendar.DAY_OF_WEEK) - 1;
        if (d < 0)
            d = 0;
        return name[d];
    }


}
