package Implementation;

import cn.edu.sustech.cs307.database.SQLDataSource;
import cn.edu.sustech.cs307.dto.*;
import cn.edu.sustech.cs307.dto.grade.Grade;
import cn.edu.sustech.cs307.dto.prerequisite.AndPrerequisite;
import cn.edu.sustech.cs307.dto.prerequisite.CoursePrerequisite;
import cn.edu.sustech.cs307.dto.prerequisite.OrPrerequisite;
import cn.edu.sustech.cs307.dto.prerequisite.Prerequisite;
import cn.edu.sustech.cs307.exception.EntityNotFoundException;
import cn.edu.sustech.cs307.exception.IntegrityViolationException;
import cn.edu.sustech.cs307.service.CourseService;

import javax.annotation.Nullable;
import javax.annotation.ParametersAreNonnullByDefault;
import javax.sql.rowset.serial.SerialArray;
import java.sql.*;
import java.sql.Date;
import java.time.DayOfWeek;
import java.util.*;

@ParametersAreNonnullByDefault
public class CourseServiceImplementation implements CourseService {

    final String replace = "X";

    @Override
    public void addCourse(String courseId, String courseName,
                          int credit, int classHour,
                          Course.CourseGrading grading,
                          @Nullable Prerequisite coursePrerequisite) {

        courseId = courseId.replace("-",replace);
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select add_Course(?,?,?,?,?)")//todo prerequisite
        ) {
            stmt.setString(1, courseId);
            stmt.setString(2, courseName);
            stmt.setInt(3, credit);
            stmt.setInt(4, classHour);
            stmt.setString(5, grading.name());
            stmt.execute();
            if(coursePrerequisite != null){
                try (
                        PreparedStatement prerequisite = 
                                connection.prepareStatement("insert into prerequisite (\"courseId\", path, level, \"No\") values (?,text2ltree(?),?,?)")
                ){
                    String path = "Top."+courseId;
                    prerequisite.setString(1,courseId);
                    prerequisite.setString(2,path);
                    prerequisite.setInt(3,2);
                    addPrerequisite(prerequisite,coursePrerequisite,"Top."+courseId,courseId,2,1);
                    prerequisite.executeBatch();
                }
            }

        } catch (SQLException e) {
//            System.out.println(courseId);
//            e.printStackTrace();
            throw new IntegrityViolationException();
        }


    }

    // to do
    public void addPrerequisite(PreparedStatement preparedStatement,Prerequisite prerequisite, String path, String courseId, int level, int no){
        // to do

    }

    // to do
    @Override
    public int addCourseSection(String courseId, int semesterId, String sectionName, int totalCapacity) {

        int result = 0;

        // to do

        return result; //done return courseSectionId


    }

    // to do
    @Override
    public int addCourseSectionClass(int sectionId, int instructorId,
                                     DayOfWeek dayOfWeek, Set<Short> weekList,
                                     short classStart, short classEnd,
                                     String location) {
        int result = 0;

        // to do

        return result;
    }


    // to do
    @Override
    public List<Course> getAllCourses() {

        // to do

        return List.of();
    }

}
