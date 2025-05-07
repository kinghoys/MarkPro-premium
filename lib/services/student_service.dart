import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'dart:developer' as developer;

// Define the keys used in Firestore documents
const String kStudentsKey = 'students';
const String kBranchKey = 'branch';
const String kYearKey = 'year';
const String kSectionKey = 'section';
const String kUpdatedAtKey = 'updatedAt';
const String kCreatedAtKey = 'createdAt';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get document reference for a specific branch/year/section
  DocumentReference _getStudentDocument(String branch, String year, String section) {
    return _firestore.collection('students').doc('${branch}_${year}_${section}');
  }

  // Add students from Excel
  Future<void> addStudentsFromExcel(
    List<StudentModel> students,
    String branch,
    String year,
    String section,
  ) async {
    // Log the operation
    developer.log('Adding ${students.length} students to Firestore', name: 'StudentService');
    for (var student in students) {
      developer.log('Student data: ${student.toMap()}', name: 'StudentService');
    }

    // Get document reference
    final docRef = _getStudentDocument(branch, year, section);
    
    // Get current document data
    final docSnapshot = await docRef.get();
    List<Map<String, dynamic>> currentStudentList = [];
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data[kStudentsKey] != null) {
        // Convert to list of maps
        currentStudentList = List<Map<String, dynamic>>.from(
          (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item as Map))
        );
      }
    }
    
    // Check for duplicate IDs
    final existingIds = currentStudentList.map((s) => s['rollNo'] as String).toSet();
    final duplicateIds = <String>[];
    
    // Filter valid students
    final validStudents = students.where((student) {
      if (existingIds.contains(student.rollNo)) {
        duplicateIds.add(student.rollNo);
        return false;
      }
      return true;
    }).toList();

    if (duplicateIds.isNotEmpty) {
      throw Exception('Duplicate student IDs found: ${duplicateIds.join(", ")}');
    }

    // Prepare student data for storage
    final List<Map<String, dynamic>> newStudentData = validStudents.map((student) {
      final Map<String, dynamic> studentData = student.toMap();
      
      // Ensure all fields are properly set
      if (studentData['name'] == null) studentData['name'] = 'Student';
      if (studentData['rollNo'] == null) return <String, dynamic>{}; // Skip if no roll number
      if (studentData['branch'] == null) studentData['branch'] = branch;
      if (studentData['year'] == null) studentData['year'] = _parseIntSafely(year);
      if (studentData['section'] == null) studentData['section'] = section;
      
      // Use DateTime.now() instead of server timestamps for array items
      // as FieldValue.serverTimestamp() is not supported inside arrays
      final now = DateTime.now().toIso8601String();
      studentData[kCreatedAtKey] = now;
      studentData[kUpdatedAtKey] = now;
      
      return studentData;
    }).where((data) => data.isNotEmpty).toList();

    // Combine with existing students
    currentStudentList.addAll(newStudentData);
    
    // Update document with combined student list
    await docRef.set({
      kStudentsKey: currentStudentList,
      kBranchKey: branch.toLowerCase(),
      kYearKey: _parseIntSafely(year),
      kSectionKey: section.toUpperCase(),
      kUpdatedAtKey: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    developer.log('${newStudentData.length} students added successfully', name: 'StudentService');
  }

  // Get a single student by roll number
  Future<StudentModel?> getStudent(String rollNo) async {
    try {
      // Search in all collections
      final collections = await _firestore.collection('students').get();
      
      for (var doc in collections.docs) {
        final data = doc.data();
        
        if (data[kStudentsKey] != null) {
          final studentsList = List<Map<String, dynamic>>.from(
            (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item as Map))
          );
          
          // Find the student with matching roll number
          final studentData = studentsList.firstWhere(
            (student) => student['rollNo'] == rollNo,
            orElse: () => <String, dynamic>{},
          );
          
          if (studentData.isNotEmpty) {
            return StudentModel.fromMap(studentData, studentData['rollNo'] ?? '');
          }
        }
      }
      
      return null;
    } catch (e) {
      developer.log('Error finding student: $e', name: 'StudentService', error: e);
      return null;
    }
  }
  
  // Get students by branch/year/section (non-streaming version)
  Future<List<StudentModel>> getStudents(String branch, String year, String section) async {
    final docRef = _getStudentDocument(branch, year, section);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      return [];
    }
    
    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data[kStudentsKey] == null) {
      return [];
    }
    
    try {
      final studentsList = List<Map<String, dynamic>>.from(
        (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item as Map))
      );
      
      return studentsList.map((studentData) => 
        StudentModel.fromMap(studentData, studentData['rollNo'] ?? '')
      ).toList();
    } catch (e) {
      developer.log('Error parsing students: $e', name: 'StudentService', error: e);
      return [];
    }
  }
  
  // Stream students by branch/year/section - for real-time updates
  Stream<List<StudentModel>> streamStudents(String branch, String year, String section) {
    return _getStudentDocument(branch, year, section).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return <StudentModel>[];
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      if (data[kStudentsKey] == null) {
        return <StudentModel>[];
      }
      
      try {
        final studentsList = List<Map<String, dynamic>>.from(
          (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item))
        );
        
        return studentsList.map((studentData) => 
          StudentModel.fromMap(studentData, studentData['rollNo'] ?? '')
        ).toList();
      } catch (e) {
        developer.log('Error parsing students stream: $e', name: 'StudentService', error: e);
        return <StudentModel>[];
      }
    });
  }

  // Get a specific student by roll number
  Future<StudentModel?> getStudentByRollNo(String rollNo, String branch, String year, String section) async {
    try {
      final students = await getStudents(branch, year, section);
      final matchingStudents = students.where((student) => student.rollNo == rollNo).toList();
      if (matchingStudents.isNotEmpty) {
        return matchingStudents.first;
      }
      return null;
    } catch (e) {
      developer.log('Error getting student by rollNo: $e', name: 'StudentService');
      return null;
    }
  }

  // Delete a single student
  Future<void> deleteStudent(String rollNo, String branch, String year, String section) async {
    final docRef = _getStudentDocument(branch, year, section);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw Exception('No students found for this branch/year/section');
    }
    
    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data[kStudentsKey] == null) {
      throw Exception('No students found in this document');
    }
    
    // Convert to list of maps
    final studentsList = List<Map<String, dynamic>>.from(
      (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item))
    );
    
    // Remove student with matching rollNo
    final initialCount = studentsList.length;
    studentsList.removeWhere((student) => student['rollNo'] == rollNo);
    
    if (initialCount == studentsList.length) {
      throw Exception('Student with ID $rollNo not found');
    }
    
    // Update document with modified student list
    await docRef.update({
      kStudentsKey: studentsList,
      kUpdatedAtKey: FieldValue.serverTimestamp(),
    });
    
    developer.log('Student $rollNo deleted successfully', name: 'StudentService');
  }
  
  // Update an existing student
  Future<void> updateStudent(
    StudentModel student,
    String branch,
    String year,
    String section,
  ) async {
    final docRef = _getStudentDocument(branch, year, section);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw Exception('No students found for this branch/year/section');
    }
    
    final data = docSnapshot.data() as Map<String, dynamic>;
    if (data[kStudentsKey] == null) {
      throw Exception('No students found in this document');
    }
    
    // Convert to list of maps
    final studentsList = List<Map<String, dynamic>>.from(
      (data[kStudentsKey] as List).map((item) => Map<String, dynamic>.from(item))
    );
    
    // Find student index
    final studentIndex = studentsList.indexWhere((s) => s['rollNo'] == student.rollNo);
    if (studentIndex < 0) {
      throw Exception('Student with ID ${student.rollNo} not found');
    }
    
    // Prepare updated student data
    final Map<String, dynamic> studentData = student.toMap();
    
    // Ensure all fields are properly set
    if (studentData['name'] == null) studentData['name'] = 'Student';
    if (studentData['rollNo'] == null) return; // Cannot update without roll number
    if (studentData['branch'] == null) studentData['branch'] = branch;
    if (studentData['year'] == null) studentData['year'] = _parseIntSafely(year);
    if (studentData['semester'] == null) studentData['semester'] = 1;
    if (studentData['section'] == null) studentData['section'] = section;
    if (studentData['academicYear'] == null) {
      studentData['academicYear'] = '${DateTime.now().year}-${DateTime.now().year + 1}';
    }
    
    // Preserve creation timestamp
    if (studentsList[studentIndex][kCreatedAtKey] != null) {
      studentData[kCreatedAtKey] = studentsList[studentIndex][kCreatedAtKey];
    } else {
      studentData[kCreatedAtKey] = DateTime.now().toIso8601String();
    }
    
    // Update timestamp
    studentData[kUpdatedAtKey] = DateTime.now().toIso8601String();
    
    // Update student in the list
    studentsList[studentIndex] = studentData;
    
    // Update document with modified student list
    developer.log('Updating student ${student.rollNo}', name: 'StudentService');
    await docRef.update({
      kStudentsKey: studentsList,
      kUpdatedAtKey: FieldValue.serverTimestamp(),
    });
    
    developer.log('Student update completed successfully', name: 'StudentService');
  }

  // Delete all students in a section
  Future<void> deleteAllStudents(String branch, String year, String section) async {
    final docRef = _getStudentDocument(branch, year, section);
    
    // Update document with empty student list
    await docRef.update({
      kStudentsKey: [],
      kUpdatedAtKey: FieldValue.serverTimestamp(),
    });
    
    developer.log('All students deleted for $branch/$year/$section', name: 'StudentService');
  }
  
  // Helper method to safely parse integer values
  int _parseIntSafely(String value) {
    if (value.isEmpty) return 1;
    // First, try to parse as-is
    int? result = int.tryParse(value);
    if (result != null) return result;
    
    // If that fails, try extracting only numeric characters
    final numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isNotEmpty) {
      result = int.tryParse(numericOnly);
      if (result != null) return result;
    }
    
    // Default fallback
    return 1;
  }
}
