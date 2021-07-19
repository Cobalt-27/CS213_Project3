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

        // to do
        return List.of();
    }

    // to do
    @Override
    public EnrollResult enrollCourse(int studentId, int sectionId) {

        EnrollResult result = EnrollResult.UNKNOWN_ERROR;//TODO
        //1 not found
        //2 time conflict
        //3 enrolled
        //4 passed
        //5 pre not meet
        //6 full
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
        return result;


    }

    // to do
    @Override
    public void dropCourse(int studentId, int sectionId) {
        // to do
    }

    // to do
    @Override
    public void addEnrolledCourseWithGrade(int studentId, int sectionId, @Nullable Grade grade) {
        // to do
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
            System.out.println(e.getMessage());
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
