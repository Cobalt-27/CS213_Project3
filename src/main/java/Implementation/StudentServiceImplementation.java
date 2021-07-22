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
            stmt.setString(2,firstName+lastName);
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
        System.out.print('a');
        CourseSearchEntry ret=new CourseSearchEntry();
        ret.conflictCourseNames=getConflictCourse(studentId, sectionId,conn);
        System.out.print('b');
        ret.course=getCourseOfSection(sectionId,conn);
        System.out.print('c');
        ret.sectionClasses=getClass(sectionId,conn);
        System.out.print('d');
        ret.section=getSection(sectionId,conn);
        System.out.print('e');
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
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();

        ) {
            System.out.println("oA ");
            PreparedStatement stmt = connection.prepareStatement("select search_Section_Student(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
            System.out.println("oB ");
            stmt.setObject(1,studentId);
            stmt.setObject(2,semesterId);
            stmt.setObject(3,searchCid);
            stmt.setObject(4,searchName);
            stmt.setObject(5,searchInstructor);
            stmt.setObject(6,searchDayOfWeek!=null?searchDayOfWeek.toString():null);
            stmt.setObject(7,searchClassTime);
            stmt.setObject(8,searchClassLocations!=null?connection.createArrayOf("varchar",searchClassLocations.toArray()):null);
            stmt.setObject(9,searchCourseType!=null?searchCourseType.toString():null);
            stmt.setObject(10,ignoreFull);
            stmt.setObject(11,ignoreConflict);
            stmt.setObject(12,ignorePassed);
            stmt.setObject(13,ignoreMissingPrerequisites);
            stmt.setInt(14,pageSize);
            stmt.setInt(15,pageIndex);
            System.out.println("oC ");
            ResultSet res=stmt.executeQuery();
            System.out.println("oD ");
            List<CourseSearchEntry> ret=new ArrayList<>();
            List<Integer> secargs=new ArrayList<>();
            while(res.next()){
                int secid=res.getInt("search_section_student");
                secargs.add(secid);
            }
            System.out.println("oE ");
            for(int secid:secargs){
                //System.out.println(res.getMetaData().getColumnName(1));
//                System.out.print("oa ");

                System.out.print("ob ");
                //CourseSearchEntry entry=getSectionEntry(studentId,secid,connection);
                System.out.print("oc ");
                //ret.add(entry);
                System.out.print("od ");
            }
            return ret;
        }catch(Exception e){
            System.out.println(e.getMessage());
        }

        // to do
        return null;
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

        ResultSet resultSet;
        CourseTable courseTable =  new CourseTable();
        courseTable.table = new HashMap<>();
        // to do
        return courseTable;


    }

}
