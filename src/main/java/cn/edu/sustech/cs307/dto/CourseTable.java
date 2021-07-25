package cn.edu.sustech.cs307.dto;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;


public class CourseTable {
    public static class CourseTableEntry {
        /**
         * Course full name: String.format("%s[%s]", course.name, section.name)
         */
        public String courseFullName;
        /**
         * The section class's instructor
         */
        public Instructor instructor;
        /**
         * The class's begin and end time (e.g. 3 and 4).
         */
        public short classBegin, classEnd;
        /**
         * The class location.
         */
        public String location;

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (o == null || getClass() != o.getClass()) {
                return false;
            }
            CourseTableEntry entry = (CourseTableEntry) o;

            boolean res= classBegin == entry.classBegin && classEnd == entry.classEnd && courseFullName
                    .equals(entry.courseFullName)
                    && instructor.equals(entry.instructor) && location.equals(entry.location);
//            if(!res){
//                System.out.printf("Entry not equal %s %s\n",this.courseFullName,entry.courseFullName);
//            }
            return res;
        }

        @Override
        public int hashCode() {
            return Objects.hash(courseFullName, instructor, classBegin, classEnd, location);
        }
    }

    /**
     * Stores all courses(encapsulated by CourseTableEntry) according to DayOfWeek.
     * The key should always be from MONDAY to SUNDAY, if the student has no course for any of the days, put an empty list.
     */
    public Map<DayOfWeek, Set<CourseTableEntry>> table;

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        CourseTable that = (CourseTable) o;
//        if(!table.equals(that.table)){
////            System.out.println("Expeceted");
////            this.printToScreen();
////            System.out.println("Got");
////            that.printToScreen();
//        }
        return table.equals(that.table);
    }
//    public void printToScreen(){
//        for(DayOfWeek day:DayOfWeek.values()){
//            if(table.get(day)==null){
//                System.out.println("NULL FOUND");
//            }
//            for(CourseTableEntry classinday:table.get(day)) {
//                System.out.print(classinday.courseFullName+" ");
//            }
//            System.out.print("\n");
//        }
////        System.out.println("\n");
//    }

    @Override
    public int hashCode() {
        return Objects.hash(table);
    }
}
