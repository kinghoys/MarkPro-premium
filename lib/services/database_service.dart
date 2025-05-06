import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Reference to users collection
  CollectionReference get users => _firestore.collection('users');
  
  // Reference to subjects collection
  CollectionReference get subjects => _firestore.collection('subjects');
  
  // Reference to students collection
  CollectionReference get students => _firestore.collection('students');
  
  // Reference to sessions collection
  CollectionReference get sessions => _firestore.collection('sessions');
  
  // Get user data
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await users.doc(uid).get();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      rethrow;
    }
  }
  
  // Create or update user data
  Future<void> setUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await users.doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user data: $e');
      }
      rethrow;
    }
  }
  
  // Get all subjects for a professor
  Future<QuerySnapshot> getProfessorSubjects(String professorId) async {
    try {
      return await subjects.where('professorId', isEqualTo: professorId).get();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subjects: $e');
      }
      rethrow;
    }
  }
  
  // Create a new subject
  Future<DocumentReference> createSubject(Map<String, dynamic> subjectData) async {
    try {
      return await subjects.add(subjectData);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating subject: $e');
      }
      rethrow;
    }
  }
  
  // Get students for a specific branch/year/section
  Future<QuerySnapshot> getStudents({
    required String branch,
    required int year,
    String? section,
  }) async {
    try {
      Query query = students.where('branch', isEqualTo: branch)
                          .where('year', isEqualTo: year);
      
      if (section != null) {
        query = query.where('section', isEqualTo: section);
      }
      
      return await query.get();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting students: $e');
      }
      rethrow;
    }
  }
  
  // Create a session
  Future<DocumentReference> createSession(Map<String, dynamic> sessionData) async {
    try {
      return await sessions.add(sessionData);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating session: $e');
      }
      rethrow;
    }
  }
  
  // Get sessions for a subject
  Future<QuerySnapshot> getSubjectSessions(String subjectId) async {
    try {
      return await sessions.where('subjectId', isEqualTo: subjectId).get();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sessions: $e');
      }
      rethrow;
    }
  }
  
  // Update session marks
  Future<void> updateSessionMarks(
    String sessionId, 
    Map<String, dynamic> marksData
  ) async {
    try {
      await sessions.doc(sessionId).update({
        'marks': FieldValue.arrayUnion([marksData])
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating session marks: $e');
      }
      rethrow;
    }
  }
  
  // Add student
  Future<DocumentReference> addStudent(Map<String, dynamic> studentData) async {
    try {
      return await students.add(studentData);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding student: $e');
      }
      rethrow;
    }
  }
  
  // Bulk add students
  Future<List<DocumentReference>> bulkAddStudents(
    List<Map<String, dynamic>> studentsData
  ) async {
    try {
      List<DocumentReference> refs = [];
      
      // Use a batch write for better performance
      WriteBatch batch = _firestore.batch();
      
      for (var studentData in studentsData) {
        DocumentReference docRef = students.doc();
        batch.set(docRef, studentData);
        refs.add(docRef);
      }
      
      await batch.commit();
      return refs;
    } catch (e) {
      if (kDebugMode) {
        print('Error bulk adding students: $e');
      }
      rethrow;
    }
  }
}
