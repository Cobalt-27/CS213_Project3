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




    public void addPrerequisite(PreparedStatement preparedStatement,
                                Prerequisite prerequisite,
                                String path,
                                String courseId,
                                int level,
                                int no){
        courseId = courseId.replace("-",replace);
        if (prerequisite == null) return;
        level = level + 1;
        if (prerequisite instanceof AndPrerequisite){
            path += (".and"+no);
            int i = 1;
            try {
                preparedStatement.setString(1,courseId);
                preparedStatement.setString(2,path);
                preparedStatement.setInt(3,level);
                preparedStatement.setInt(4, no);
                preparedStatement.addBatch();
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            for (Prerequisite tmp : ((AndPrerequisite) prerequisite).terms){
                addPrerequisite(preparedStatement,tmp,path,courseId,level,i);
                i++;
            }
        }else if (prerequisite instanceof OrPrerequisite){
            path += (".or"+no);
            int i = 1;
            try {
                preparedStatement.setString(1,courseId);
                preparedStatement.setString(2,path);
                preparedStatement.setInt(3,level);
                preparedStatement.setInt(4, no);
                preparedStatement.addBatch();
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            for (Prerequisite tmp : ((OrPrerequisite) prerequisite).terms){
                addPrerequisite(preparedStatement,tmp,path,courseId,level,i);
                i++;
            }
        }else if (prerequisite instanceof CoursePrerequisite){
            path += ("."+((CoursePrerequisite) prerequisite).courseID);
            try {
                preparedStatement.setString(1,courseId);
                preparedStatement.setString(2,path);
                preparedStatement.setInt(3,level);
                preparedStatement.setInt(4, no);
                preparedStatement.addBatch();
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
        }
    }

    // to do
    @Override
    public int addCourseSection(String courseId, int semesterId, String sectionName, int totalCapacity) {
        courseId = courseId.replace("-",replace);
        int result = 0;

        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select * from add_Section(?,?,?,?)");
        )
        {
            stmt.setString(1,courseId);
            stmt.setInt(2,semesterId);
            stmt.setString(3,sectionName);
            stmt.setInt(4,totalCapacity);
            ResultSet res=stmt.executeQuery();
            res.next();
            result=res.getInt("add_Section");
        }catch(Exception e){
            throw new IntegrityViolationException();
        }
        return result;
    }


    @Override
    public int addCourseSectionClass(int sectionId, int instructorId,
                                     DayOfWeek dayOfWeek, Set<Short> weekList,
                                     short classStart, short classEnd,
                                     String location) {
        int result = 0;
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select * from add_Course_Section(?,?,?,?,?,?,?)");
        ) {
            stmt.setInt(1,sectionId);
            stmt.setInt(2,instructorId);
            stmt.setString(3, dayOfWeek.name());
            stmt.setArray(4,connection.createArrayOf("smallint",weekList.toArray()));
            stmt.setShort(5,classStart);
            stmt.setShort(6,classEnd);
            stmt.setString(7,location);
            ResultSet res=stmt.executeQuery();
            res.next();
            result=res.getInt("add_Course_Section");
        }catch(Exception e){
            throw new IntegrityViolationException();
        }

        return result;
    }


    // to do
    @Override
    public List<Course> getAllCourses() {
        ArrayList<Course> ret=new ArrayList();
        try (Connection connection = SQLDataSource.getInstance().getSQLConnection();
             PreparedStatement stmt = connection.prepareStatement("select * from \"Course\"")
        ) {
            ResultSet res=stmt.executeQuery();
            Course c=new Course();
            while(res.next()){
                c.id=res.getString("courseId");
                c.id = c.id.replace(replace,"-");
                c.classHour=res.getInt("classHour");
                c.grading=res.getString("grading")=="HUNDRED_MARK_SCORE"? Course.CourseGrading.HUNDRED_MARK_SCORE: Course.CourseGrading.PASS_OR_FAIL;
                c.credit=res.getInt("credit");
                c.name=res.getString("courseName");
                ret.add(c);
                //System.out.println(c.name);
            }
        }catch(Exception e){
            throw new EntityNotFoundException();
        }

        return ret;
    }

}
