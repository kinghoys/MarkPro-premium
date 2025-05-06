import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/services/auth_service.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  // Collection reference
  CollectionReference get _assignmentSessionsCollection => 
      _firestore.collection('assignmentSessions');
  
  // Get all assignment sessions for the current user
  Future<List<AssignmentSession>> getAssignmentSessions() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Use a simpler query approach like MidService, without filtering by userId
    final querySnapshot = await _assignmentSessionsCollection
        .orderBy('updatedAt', descending: true)
        .get();
    
    // Filter by userId in memory after retrieving the data
    return querySnapshot.docs
        .map((doc) => AssignmentSession.fromFirestore(doc))
        .where((session) => session.userId == user.uid)
        .toList();
  }
  
  // Get a specific assignment session by ID
  Future<AssignmentSession> getAssignmentSession(String sessionId) async {
    final doc = await _assignmentSessionsCollection.doc(sessionId).get();
    if (!doc.exists) {
      throw Exception('Assignment session not found');
    }
    
    return AssignmentSession.fromFirestore(doc);
  }
  
  // Create a new assignment session
  Future<AssignmentSession> createAssignmentSession({
    required String subjectName,
    required String branch,
    required String year,
    required String section,
    required List<String> students,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final assignmentSession = AssignmentSession.create(
      subjectName: subjectName,
      branch: branch,
      year: year,
      section: section,
      students: students,
      userId: user.uid,
    );
    
    await _assignmentSessionsCollection
        .doc(assignmentSession.id)
        .set(assignmentSession.toMap());
    
    return assignmentSession;
  }
  
  // Update an existing assignment session
  Future<void> updateAssignmentSession(AssignmentSession assignmentSession) async {
    try {
      // Update with current timestamp
      final updatedSession = assignmentSession.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Convert assignmentMarks to ensure it's in the right format for Firestore
      final Map<String, dynamic> sessionData = updatedSession.toMap();
      
      // Log the update operation
      print('Updating session ${updatedSession.id} with ${sessionData['assignmentMarks'].length} student records');
      
      // Use set with merge option instead of update to handle potential missing fields
      await _assignmentSessionsCollection
          .doc(updatedSession.id)
          .set(sessionData, SetOptions(merge: true));
    } catch (e) {
      print('Error in updateAssignmentSession: $e');
      throw Exception('Failed to update assignment session: $e');
    }
  }
  
  // Delete an assignment session
  Future<void> deleteAssignmentSession(String sessionId) async {
    await _assignmentSessionsCollection.doc(sessionId).delete();
  }
  
  // Calculate converted marks (out of 5) based on original marks (out of 60)
  int convertTo5PointScale(int originalMarks) {
    if (originalMarks >= 36) return 5;       // 36-60 marks => 5/5
    if (originalMarks >= 26) return 4;       // 26-35 marks => 4/5
    if (originalMarks >= 16) return 3;       // 16-25 marks => 3/5
    if (originalMarks >= 6) return 2;        // 6-15 marks => 2/5
    if (originalMarks >= 1) return 1;        // 1-5 marks => 1/5
    return 0;                                // 0 marks => 0/5
  }
  
  // Calculate the average of Assignment 1 and Assignment 2 (out of 5)
  double calculateAssignmentAverage(int assignment1, int assignment2) {
    final converted1 = convertTo5PointScale(assignment1);
    final converted2 = convertTo5PointScale(assignment2);
    
    // Calculate average and round to nearest decimal (e.g., 3.5, 4.0)
    return (converted1 + converted2) / 2;
  }
  
  // Calculate the total assignment marks (rounded to nearest integer out of 10)
  int calculateTotalAssignmentMarks(int assignment1, int assignment2) {
    final converted1 = convertTo5PointScale(assignment1);
    final converted2 = convertTo5PointScale(assignment2);
    
    // Round to nearest integer
    return converted1 + converted2;
  }
  
  // Update Assignment 1 marks for a student
  Future<void> updateAssignment1Marks({
    required String sessionId,
    required String studentId,
    required int marks,
    required int outOf,
  }) async {
    try {
      print('Starting updateAssignment1Marks for student: $studentId, session: $sessionId, marks: $marks');
      
      final assignmentSession = await getAssignmentSession(sessionId);
      print('Retrieved session: ${assignmentSession.id}, student count: ${assignmentSession.students.length}');
      
      // Create updated assignment marks map
      final updatedAssignmentMarks = Map<String, Map<String, dynamic>>.from(assignmentSession.assignmentMarks);
      
      // Get existing marks for the student or create new entry
      final existingMarks = updatedAssignmentMarks[studentId] ?? {};
      print('Existing marks for student $studentId: $existingMarks');
      
      // Get Assignment 2 marks if they exist
      int assignment2 = 0;
      int assignment2OutOf = 0;
      int assignment2Converted = 0;
      
      try {
        assignment2 = existingMarks['assignment2'] is int ? existingMarks['assignment2'] : 0;
        assignment2OutOf = existingMarks['assignment2OutOf'] is int ? existingMarks['assignment2OutOf'] : 0;
        assignment2Converted = existingMarks['assignment2Converted'] is int ? existingMarks['assignment2Converted'] : 0;
      } catch (e) {
        print('Error parsing existing marks: $e, using defaults');
      }
      
      // Calculate converted marks and average
      final convertedMarks = convertTo5PointScale(marks);
      final average = calculateAssignmentAverage(marks, assignment2);
      
      print('Calculated convertedMarks: $convertedMarks, average: $average');
      
      // Update marks for the student
      final Map<String, dynamic> updatedMarks = {
        'assignment1': marks,
        'assignment1OutOf': outOf,
        'assignment1Converted': convertedMarks,
        'assignment2': assignment2,
        'assignment2OutOf': assignment2OutOf,
        'assignment2Converted': assignment2Converted,
        'average': average,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('Updating marks for student $studentId: $updatedMarks');
      updatedAssignmentMarks[studentId] = updatedMarks;
      
      // Update assignment session
      final updatedSession = assignmentSession.copyWith(
        assignmentMarks: updatedAssignmentMarks,
        updatedAt: DateTime.now(),
      );
      
      await updateAssignmentSession(updatedSession);
      print('Successfully updated Assignment 1 marks for student: $studentId');
    } catch (e) {
      print('Error in updateAssignment1Marks: $e');
      throw Exception('Failed to update Assignment 1 marks: $e');
    }
  }
  
  // Update Assignment 2 marks for a student
  Future<void> updateAssignment2Marks({
    required String sessionId,
    required String studentId,
    required int marks,
    required int outOf,
  }) async {
    try {
      print('Starting updateAssignment2Marks for student: $studentId, session: $sessionId, marks: $marks');
      
      final assignmentSession = await getAssignmentSession(sessionId);
      print('Retrieved session: ${assignmentSession.id}, student count: ${assignmentSession.students.length}');
      
      // Create updated assignment marks map
      final updatedAssignmentMarks = Map<String, Map<String, dynamic>>.from(assignmentSession.assignmentMarks);
      
      // Get existing marks for the student or create new entry
      final existingMarks = updatedAssignmentMarks[studentId] ?? {};
      print('Existing marks for student $studentId: $existingMarks');
      
      // Get Assignment 1 marks if they exist
      int assignment1 = 0;
      int assignment1OutOf = 0;
      int assignment1Converted = 0;
      
      try {
        assignment1 = existingMarks['assignment1'] is int ? existingMarks['assignment1'] : 0;
        assignment1OutOf = existingMarks['assignment1OutOf'] is int ? existingMarks['assignment1OutOf'] : 0;
        assignment1Converted = existingMarks['assignment1Converted'] is int ? existingMarks['assignment1Converted'] : 0;
      } catch (e) {
        print('Error parsing existing marks: $e, using defaults');
      }
      
      // Calculate converted marks and average
      final convertedMarks = convertTo5PointScale(marks);
      final average = calculateAssignmentAverage(assignment1, marks);
      
      print('Calculated convertedMarks: $convertedMarks, average: $average');
      
      // Update marks for the student
      final Map<String, dynamic> updatedMarks = {
        'assignment1': assignment1,
        'assignment1OutOf': assignment1OutOf,
        'assignment1Converted': assignment1Converted,
        'assignment2': marks,
        'assignment2OutOf': outOf,
        'assignment2Converted': convertedMarks,
        'average': average,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('Updating marks for student $studentId: $updatedMarks');
      updatedAssignmentMarks[studentId] = updatedMarks;
      
      // Update assignment session
      final updatedSession = assignmentSession.copyWith(
        assignmentMarks: updatedAssignmentMarks,
        updatedAt: DateTime.now(),
      );
      
      await updateAssignmentSession(updatedSession);
      print('Successfully updated Assignment 2 marks for student: $studentId');
    } catch (e) {
      print('Error in updateAssignment2Marks: $e');
      throw Exception('Failed to update Assignment 2 marks: $e');
    }
  }
  
  // Import multiple Assignment 1 marks
  Future<int> importAssignment1Marks({
    required String assignmentSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    try {
      // Get current session data
      final assignmentSession = await getAssignmentSession(assignmentSessionId);
      final updatedAssignmentMarks = Map<String, Map<String, dynamic>>.from(assignmentSession.assignmentMarks);
      int successCount = 0;
      
      // Batch update all marks at once
      for (final mark in marks) {
        try {
          final studentId = mark['studentId'];
          if (studentId == null || studentId.isEmpty) continue;
          
          // Parse the marks value
          final markValue = mark['marks'];
          int markInt = 0;
          
          if (markValue is int) {
            markInt = markValue;
          } else if (markValue is double) {
            markInt = markValue.round();
          } else if (markValue is String) {
            markInt = int.tryParse(markValue) ?? 0;
          }
          
          // Use default outOf value (standard 60)
          final outOf = 60;
          
          // Calculate converted marks
          final convertedMarks = convertTo5PointScale(markInt);
          
          // Get existing marks for this student or create new entry
          final existingMarks = updatedAssignmentMarks[studentId] ?? {};
          
          // Get Assignment 2 marks if they exist
          dynamic assignment2 = existingMarks['assignment2'];
          int assignment2Value = 0;
          if (assignment2 is int) {
            assignment2Value = assignment2;
          } else if (assignment2 is Map<String, dynamic>) {
            assignment2Value = assignment2['marks'] ?? 0;
          } else if (assignment2 != null) {
            // Handle any other type as 0
            print('Assignment 2 marks for student $studentId is of unexpected type: ${assignment2.runtimeType}');
          }
          
          // Calculate average with existing Assignment 2 marks
          final average = calculateAssignmentAverage(markInt, assignment2Value);
          
          // Update marks for the student with new format (Map structure)
          // Use existing assignment2 as is to preserve its structure
          updatedAssignmentMarks[studentId] = {
            'assignment1': {
              'marks': markInt,
              'outOf': outOf,
              'convertedMarks': convertedMarks
            },
            // Keep the existing assignment2 data structure intact to avoid type errors
            'assignment2': existingMarks['assignment2'] ?? 0,
            'average': average,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          };
          
          successCount++;
        } catch (e) {
          print('Error importing Assignment 1 mark for student ${mark['studentId']}: $e');
        }
      }
      
      // Update the session with all marks at once
      final updatedSession = assignmentSession.copyWith(
        assignmentMarks: updatedAssignmentMarks,
        updatedAt: DateTime.now(),
      );
      
      await updateAssignmentSession(updatedSession);
      return successCount;
    } catch (e) {
      throw Exception('Failed to import Assignment 1 marks: $e');
    }
  }

  // Import multiple Assignment 2 marks
  Future<int> importAssignment2Marks({
    required String assignmentSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    try {
      // Get current session data
      final assignmentSession = await getAssignmentSession(assignmentSessionId);
      final updatedAssignmentMarks = Map<String, Map<String, dynamic>>.from(assignmentSession.assignmentMarks);
      int successCount = 0;
      
      // Batch update all marks at once
      for (final mark in marks) {
        try {
          final studentId = mark['studentId'];
          if (studentId == null || studentId.isEmpty) continue;
          
          // Parse the marks value
          final markValue = mark['marks'];
          int markInt = 0;
          
          if (markValue is int) {
            markInt = markValue;
          } else if (markValue is double) {
            markInt = markValue.round();
          } else if (markValue is String) {
            markInt = int.tryParse(markValue) ?? 0;
          }
          
          // Use default outOf value (standard 60)
          final outOf = 60;
          
          // Calculate converted marks
          final convertedMarks = convertTo5PointScale(markInt);
          
          // Get existing marks for this student or create new entry
          final existingMarks = updatedAssignmentMarks[studentId] ?? {};
          
          // Get Assignment 1 marks if they exist
          dynamic assignment1 = existingMarks['assignment1'];
          int assignment1Value = 0;
          if (assignment1 is int) {
            assignment1Value = assignment1;
          } else if (assignment1 is Map<String, dynamic>) {
            assignment1Value = assignment1['marks'] ?? 0;
          } else if (assignment1 != null) {
            // Handle any other type as 0
            print('Assignment 1 marks for student $studentId is of unexpected type: ${assignment1.runtimeType}');
          }
          
          // Calculate average with existing Assignment 1 marks
          final average = calculateAssignmentAverage(assignment1Value, markInt);
          
          // Update marks for the student with new format (Map structure)
          updatedAssignmentMarks[studentId] = {
            'assignment1': existingMarks['assignment1'] ?? 0,
            'assignment2': {
              'marks': markInt,
              'outOf': outOf,
              'convertedMarks': convertedMarks
            },
            'average': average,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          };
          
          successCount++;
        } catch (e) {
          print('Error importing Assignment 2 mark for student ${mark['studentId']}: $e');
        }
      }
      
      // Update the session with all marks at once
      final updatedSession = assignmentSession.copyWith(
        assignmentMarks: updatedAssignmentMarks,
        updatedAt: DateTime.now(),
      );
      
      await updateAssignmentSession(updatedSession);
      return successCount;
    } catch (e) {
      throw Exception('Failed to import Assignment 2 marks: $e');
    }
  }
}
