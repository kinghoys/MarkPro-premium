import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:markpro_plus/models/experiment_meta.dart';
import 'package:markpro_plus/models/lab_session.dart';

class LabService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Constants
  static const String kLabsCollection = 'labs';
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get reference to user's labs collection
  CollectionReference<Map<String, dynamic>> get _labsRef => 
      _firestore.collection('users')
               .doc(currentUserId)
               .collection(kLabsCollection);
  
  // Create a new lab session
  Future<DocumentReference> createLabSession(LabSession labSession) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    return await _labsRef.add(labSession.toMap());
  }
  
  // Get all lab sessions for the current user
  Future<List<LabSession>> getLabSessions() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final snapshot = await _labsRef.get();
    return snapshot.docs.map((doc) => LabSession.fromMap(doc.data(), doc.id)).toList();
  }
  
  // Get a specific lab session
  Future<LabSession?> getLabSession(String labSessionId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final doc = await _labsRef.doc(labSessionId).get();
    if (!doc.exists) return null;
    
    return LabSession.fromMap(doc.data()!, doc.id);
  }
  
  // Update a lab session
  Future<void> updateLabSession(LabSession labSession) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    await _labsRef.doc(labSession.id).update(
      labSession.copyWith(updatedAt: DateTime.now()).toMap()
    );
  }
  
  // Delete a lab session
  Future<void> deleteLabSession(String labSessionId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    await _labsRef.doc(labSessionId).delete();
  }
  
  // Get lab sessions by subject
  Future<List<LabSession>> getLabSessionsBySubject(String subjectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final snapshot = await _labsRef.where('subjectId', isEqualTo: subjectId).get();
    return snapshot.docs.map((doc) => LabSession.fromMap(doc.data(), doc.id)).toList();
  }
  
  // Get lab sessions by branch, year, section
  Future<List<LabSession>> getLabSessionsByClass(String branch, String year, String section) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final snapshot = await _labsRef
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();
    
    return snapshot.docs.map((doc) => LabSession.fromMap(doc.data(), doc.id)).toList();
  }
  
  // Save experiment marks for a student
  Future<void> saveExperimentMarks({
    required String labSessionId,
    required String studentId,
    required String experimentNumber,
    required int markA,
    required int markB,
    required int markC,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Calculate total
    final total = markA + markB + markC;
    
    // Create the marks map
    final marksMap = {
      'A': markA,
      'B': markB,
      'C': markC,
      'total': total,
    };
    
    // Update the marks in Firestore
    await _labsRef.doc(labSessionId).update({
      'experimentMarks.$studentId.$experimentNumber': marksMap,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Save internal marks for a student
  Future<void> saveInternalMarks({
    required String labSessionId,
    required String studentId,
    required String internalNumber, // "1" or "2"
    required int mark,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Update the internal mark in Firestore
    await _labsRef.doc(labSessionId).update({
      'internalMarks.$studentId.$internalNumber': mark,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Set experiment date
  Future<void> setExperimentDate({
    required String labSessionId,
    required String experimentNumber,
    required DateTime dateOfExperiment,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final meta = ExperimentMeta(dateOfExperiment: dateOfExperiment);
    
    await _labsRef.doc(labSessionId).update({
      'experimentMeta.$experimentNumber': meta.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Calculate and save M1 marks
  Future<void> calculateAndSaveM1Marks({
    required String labSessionId,
    required int lastExperiment,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the lab session
    final labSession = await getLabSession(labSessionId);
    if (labSession == null) {
      throw Exception('Lab session not found');
    }
    
    // Calculate M1 marks
    final m1Marks = labSession.calculateM1Marks(lastExperiment);
    
    // Update Firestore
    await _labsRef.doc(labSessionId).update({
      'm1Marks': m1Marks,
      'm1LastExperiment': lastExperiment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Calculate and save M2 marks
  Future<void> calculateAndSaveM2Marks({
    required String labSessionId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the lab session
    final labSession = await getLabSession(labSessionId);
    if (labSession == null) {
      throw Exception('Lab session not found');
    }
    
    // Verify that M1 has been calculated
    if (labSession.m1LastExperiment == null) {
      throw Exception('M1 must be calculated before calculating M2');
    }
    
    // Calculate M2 marks (starting from experiment after m1LastExperiment)
    final m2Marks = labSession.calculateM2Marks(labSession.m1LastExperiment! + 1);
    
    // Update Firestore
    await _labsRef.doc(labSessionId).update({
      'm2Marks': m2Marks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Save viva marks for a student
  Future<void> saveVivaMark({
    required String labSessionId,
    required String studentId,
    required int mark,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Validate mark range (0-10)
    if (mark < 0 || mark > 10) {
      throw Exception('Viva mark must be between 0 and 10');
    }
    
    // Update the viva mark in Firestore
    await _labsRef.doc(labSessionId).update({
      'vivaMarks.$studentId': mark,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Calculate and save final lab marks
  Future<void> calculateAndSaveFinalLabMarks({
    required String labSessionId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the lab session
    final labSession = await getLabSession(labSessionId);
    if (labSession == null) {
      throw Exception('Lab session not found');
    }
    
    // Verify that M1, M2 have been calculated
    if (labSession.m1Marks.isEmpty || labSession.m2Marks.isEmpty) {
      throw Exception('M1 and M2 must be calculated before calculating final lab marks');
    }
    
    // Calculate final lab marks
    final finalLabMarks = labSession.calculateFinalLabMarks();
    
    // Update Firestore
    await _labsRef.doc(labSessionId).update({
      'finalLabMarks': finalLabMarks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Save individual viva marks and calculate final lab grade
  Future<void> saveVivaMarkAndCalculateFinal({
    required String labSessionId,
    required String studentId,
    required int vivaMark,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the lab session
    final labSession = await getLabSession(labSessionId);
    if (labSession == null) {
      throw Exception('Lab session not found');
    }
    
    // Validate that M1 and M2 are available for this student
    if (!labSession.m1Marks.containsKey(studentId) || !labSession.m2Marks.containsKey(studentId)) {
      throw Exception('M1 and M2 marks must be calculated before saving viva mark');
    }
    
    // Save viva mark
    await saveVivaMark(labSessionId: labSessionId, studentId: studentId, mark: vivaMark);
    
    // Get the updated lab session
    final updatedLabSession = await getLabSession(labSessionId);
    if (updatedLabSession == null) {
      throw Exception('Lab session not found after updating viva mark');
    }
    
    // Calculate final grade for this student
    final m1Mark = updatedLabSession.m1Marks[studentId]!;
    final m2Mark = updatedLabSession.m2Marks[studentId]!;
    final modelScore = m1Mark > m2Mark ? m1Mark : m2Mark;
    final finalScore = (modelScore * 0.75) + vivaMark.toDouble();
    
    // Update the final lab mark in Firestore
    await _labsRef.doc(labSessionId).update({
      'finalLabMarks.$studentId': finalScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Calculate final lab grades for all students at once
  Future<Map<String, String>> calculateAllFinalLabGrades({
    required String labSessionId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get the lab session
    final labSession = await getLabSession(labSessionId);
    if (labSession == null) {
      throw Exception('Lab session not found');
    }
    
    // Track processed students and errors
    final processedStudents = <String>[];
    final errors = <String, String>{};
    final finalLabMarks = <String, double>{};
    
    // Process each student
    for (final studentId in labSession.students) {
      // Check if student has both M1 and M2 marks
      if (!labSession.m1Marks.containsKey(studentId) || !labSession.m2Marks.containsKey(studentId)) {
        errors[studentId] = 'Missing M1 or M2 marks';
        continue;
      }
      
      // Check if student has viva marks
      if (!labSession.vivaMarks.containsKey(studentId)) {
        errors[studentId] = 'Missing viva marks';
        continue;
      }
      
      // Calculate final grade
      final m1Mark = labSession.m1Marks[studentId]!;
      final m2Mark = labSession.m2Marks[studentId]!;
      final vivaMark = labSession.vivaMarks[studentId]!;
      
      // Select the better score between M1 and M2
      final modelScore = m1Mark > m2Mark ? m1Mark : m2Mark;
      
      // Final lab mark = 75% of model score (max 30) + viva mark (max 10)
      final finalScore = (modelScore * 0.75) + vivaMark.toDouble();
      
      finalLabMarks[studentId] = finalScore;
      processedStudents.add(studentId);
    }
    
    // Update all final lab marks in Firestore
    if (finalLabMarks.isNotEmpty) {
      await _labsRef.doc(labSessionId).update({
        'finalLabMarks': finalLabMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    return errors;
  }
  
  // Save M1/M2 marks (for import functionality)
  Future<void> saveM1M2Marks({
    required String labSessionId,
    required String studentId,
    required double m1Mark,
    required double m2Mark,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Update M1 marks
    await _labsRef.doc(labSessionId).update({
      'm1Marks.$studentId': m1Mark,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update M2 marks
    await _labsRef.doc(labSessionId).update({
      'm2Marks.$studentId': m2Mark,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Save viva marks (for import functionality)
  Future<void> saveVivaMarks({
    required String labSessionId,
    required String studentId,
    required int vivaMarks,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Update viva marks
    await _labsRef.doc(labSessionId).update({
      'vivaMarks.$studentId': vivaMarks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Save final lab marks (for import functionality)
  Future<void> saveFinalLabMarks({
    required String labSessionId,
    required String studentId,
    required double finalLabMarks,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Update final lab marks
    await _labsRef.doc(labSessionId).update({
      'finalLabMarks.$studentId': finalLabMarks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
