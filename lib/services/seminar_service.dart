import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markpro_plus/models/seminar_session.dart';

class SeminarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _seminarSessions => 
      _firestore.collection('seminarSessions');
      
  // Get all seminar sessions
  Future<List<SeminarSession>> getSeminarSessions() async {
    final QuerySnapshot snapshot = await _seminarSessions.get();
    return snapshot.docs
        .map((doc) => SeminarSession.fromFirestore(doc))
        .toList();
  }
  
  // Get a single seminar session by ID
  Future<SeminarSession?> getSeminarSession(String sessionId) async {
    final DocumentSnapshot doc = await _seminarSessions.doc(sessionId).get();
    if (doc.exists) {
      return SeminarSession.fromFirestore(doc);
    }
    return null;
  }
  
  // Create a new seminar session
  Future<SeminarSession> createSeminarSession(SeminarSession session) async {
    final docRef = await _seminarSessions.add(session.toFirestore());
    final newSession = session.copyWith(id: docRef.id);
    
    // Update the document with the ID
    await docRef.update({'id': docRef.id});
    
    return newSession;
  }
  
  // Update an existing seminar session
  Future<void> updateSeminarSession(SeminarSession session) async {
    await _seminarSessions.doc(session.id).update(session.toFirestore());
  }
  
  // Delete a seminar session
  Future<void> deleteSeminarSession(String sessionId) async {
    await _seminarSessions.doc(sessionId).delete();
  }
  
  // Update presentation marks for a student
  Future<void> updatePresentationMarks({
    required String sessionId,
    required String studentId,
    double content = 0,
    double delivery = 0,
    double qa = 0,
    double? seminarMark,
  }) async {
    try {
      // Get the current session
      final session = await getSeminarSession(sessionId);
      if (session == null) {
        throw Exception('Seminar session not found');
      }
      
      // Calculate total
      final total = seminarMark ?? (content + delivery + qa);
      
      // Update marks in the session
      final updatedMarks = session.presentationMarks;
      updatedMarks[studentId] = {
        'content': content,
        'delivery': delivery,
        'qa': qa,
        'total': total,
      };
      
      // Recalculate final marks
      final updatedSession = session.copyWith(
        presentationMarks: updatedMarks,
        updatedAt: DateTime.now(),
      );
      updatedSession.calculateFinalMarks();
      
      // Update in Firestore
      await _seminarSessions.doc(sessionId).update({
        'presentationMarks': updatedMarks,
        'finalSeminarMarks': updatedSession.finalSeminarMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating presentation marks: $e');
      throw Exception('Failed to update presentation marks: $e');
    }
  }
  
  // Update report marks for a student
  Future<void> updateReportMarks({
    required String sessionId,
    required String studentId,
    required double content,
    required double format,
    required double references,
  }) async {
    try {
      // Get the current session
      final session = await getSeminarSession(sessionId);
      if (session == null) {
        throw Exception('Seminar session not found');
      }
      
      // Calculate total
      final total = content + format + references;
      
      // Update marks in the session
      final updatedMarks = session.reportMarks;
      updatedMarks[studentId] = {
        'content': content,
        'format': format,
        'references': references,
        'total': total,
      };
      
      // Recalculate final marks
      final updatedSession = session.copyWith(
        reportMarks: updatedMarks,
        updatedAt: DateTime.now(),
      );
      updatedSession.calculateFinalMarks();
      
      // Update in Firestore
      await _seminarSessions.doc(sessionId).update({
        'reportMarks': updatedMarks,
        'finalSeminarMarks': updatedSession.finalSeminarMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating report marks: $e');
      throw Exception('Failed to update report marks: $e');
    }
  }
  
  // Calculate and update final seminar marks
  Future<void> calculateAndUpdateFinalMarks(String sessionId) async {
    try {
      // Get the current session
      final session = await getSeminarSession(sessionId);
      if (session == null) {
        throw Exception('Seminar session not found');
      }
      
      // Calculate final marks
      session.calculateFinalMarks();
      
      // Update in Firestore
      await _seminarSessions.doc(sessionId).update({
        'finalSeminarMarks': session.finalSeminarMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error calculating final marks: $e');
      throw Exception('Failed to calculate final marks: $e');
    }
  }
}
