import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_markaz/models/lesson_group.dart';

void main() {
  group('LessonGroup Model Tests', () {
    test('Parse API response with populated fields', () {
      final jsonString = '''
      {
        "_id": "692a9aa0d9ce35d4a3a6d2bf",
        "name": "dsdsdsd",
        "teacherId": {
          "_id": "692a928dd9ce35d4a3a6d262",
          "phoneNumber": "+998949998877",
          "name": "DSDSDSD"
        },
        "studentIds": [
          {
            "_id": "692a9368d9ce35d4a3a6d27c",
            "phoneNumber": "+998976545454",
            "name": "SALOM"
          },
          {
            "_id": "6925ac7433e2c093eae0faa2",
            "phoneNumber": "+998999755370",
            "name": "Azizbek"
          }
        ],
        "organizationId": {
          "_id": "69170cde33e2c093eae0f819",
          "name": "Zamon's School"
        },
        "days": [
          "monday",
          "friday"
        ],
        "courseId": {
          "_id": "692a9890d9ce35d4a3a6d29b",
          "name": "MATH",
          "lessonDuration": 90,
          "price": 120000,
          "description": "GHDGHGHDGHDDGH"
        },
        "createdAt": "2025-11-29T07:02:56.641Z",
        "updatedAt": "2025-11-29T07:02:56.641Z",
        "__v": 0
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final lessonGroup = LessonGroup.fromJson(json);

      expect(lessonGroup.id, '692a9aa0d9ce35d4a3a6d2bf');
      expect(lessonGroup.name, 'dsdsdsd');
      
      // Test populated teacher
      expect(lessonGroup.teacherId, '692a928dd9ce35d4a3a6d262');
      expect(lessonGroup.teacherName, 'DSDSDSD');
      expect(lessonGroup.teacherPhone, '+998949998877');
      
      // Test populated students
      expect(lessonGroup.studentIds.length, 2);
      expect(lessonGroup.studentCount, 2);
      expect(lessonGroup.studentIds[0]['_id'], '692a9368d9ce35d4a3a6d27c');
      expect(lessonGroup.studentIds[0]['name'], 'SALOM');
      
      // Test populated organization
      expect(lessonGroup.organizationId, '69170cde33e2c093eae0f819');
      expect(lessonGroup.organizationName, "Zamon's School");
      
      // Test populated course
      expect(lessonGroup.courseId, '692a9890d9ce35d4a3a6d29b');
      expect(lessonGroup.courseName, 'MATH');
      
      // Test days
      expect(lessonGroup.days, ['monday', 'friday']);
      expect(lessonGroup.daysDisplay, 'monday, friday');
      
      // Test status
      expect(lessonGroup.status, 'active');
      expect(lessonGroup.hasTeacher, true);
    });

    test('Parse API response with non-populated fields (string IDs)', () {
      final jsonString = '''
      {
        "_id": "6918dd2833e2c093eae0f956",
        "name": "Friday morning group",
        "teacherId": "692a928dd9ce35d4a3a6d262",
        "studentIds": ["6918dcb633e2c093eae0f92b"],
        "organizationId": "69170cde33e2c093eae0f819",
        "courseId": "692a9890d9ce35d4a3a6d29b",
        "days": ["monday", "tuesday", "wednesday"],
        "createdAt": "2025-11-15T20:06:00.382Z",
        "updatedAt": "2025-11-15T20:06:00.382Z",
        "__v": 0
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final lessonGroup = LessonGroup.fromJson(json);

      expect(lessonGroup.id, '6918dd2833e2c093eae0f956');
      expect(lessonGroup.name, 'Friday morning group');
      
      // Test non-populated fields
      expect(lessonGroup.teacherId, '692a928dd9ce35d4a3a6d262');
      expect(lessonGroup.teacherName, null);
      
      expect(lessonGroup.studentIds.length, 1);
      expect(lessonGroup.studentIds[0]['_id'], '6918dcb633e2c093eae0f92b');
      
      expect(lessonGroup.organizationId, '69170cde33e2c093eae0f819');
      expect(lessonGroup.courseId, '692a9890d9ce35d4a3a6d29b');
      
      expect(lessonGroup.days, ['monday', 'tuesday', 'wednesday']);
    });
  });
}
