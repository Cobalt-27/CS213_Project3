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
        // to do
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
        // to do
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
