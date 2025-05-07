import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markpro_plus/models/mid_session.dart';

class MidService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _midSessionsCollection => 
      _firestore.collection('midSessions');
  
  // Create a new mid session
  Future<String> createMidSession(MidSession midSession) async {
    try {
      final docRef = await _midSessionsCollection.add(midSession.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create mid session: $e');
    }
  }
  
  // Get all mid sessions
  Future<List<MidSession>> getMidSessions() async {
    try {
      final snapshot = await _midSessionsCollection
          .orderBy('updatedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return MidSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get mid sessions: $e');
    }
  }
  
  // Get a single mid session by ID
  Future<MidSession> getMidSession(String id) async {
    try {
      final doc = await _midSessionsCollection.doc(id).get();
      
      if (!doc.exists) {
        throw Exception('Mid session not found');
      }
      
      return MidSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get mid session: $e');
    }
  }
  
  // Update a mid session
  Future<void> updateMidSession(MidSession midSession) async {
    try {
      await _midSessionsCollection
          .doc(midSession.id)
          .update(midSession.toMap());
    } catch (e) {
      throw Exception('Failed to update mid session: $e');
    }
  }
  
  // Delete a mid session
  Future<void> deleteMidSession(String id) async {
    try {
      await _midSessionsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete mid session: $e');
    }
  }
  
  // Update mid1 marks for a student
  Future<void> updateMid1Marks({
    required String midSessionId,
    required String studentId,
    required double descriptive,
    required double objective,
  }) async {
    try {
      final midSession = await getMidSession(midSessionId);
      
      // Create updated mid1 marks map
      final updatedMid1Marks = Map<String, Map<String, dynamic>>.from(midSession.mid1Marks);
      
      // Calculate total (descriptive + objective)
      final total = descriptive + objective;
      
      updatedMid1Marks[studentId] = {
        'descriptive': descriptive,
        'objective': objective,
        'total': total,
      };
      
      // Update mid session
      final updatedMidSession = midSession.copyWith(
        mid1Marks: updatedMid1Marks,
        updatedAt: DateTime.now(),
      );
      
      await updateMidSession(updatedMidSession);
    } catch (e) {
      throw Exception('Failed to update Mid 1 marks: $e');
    }
  }
  
  // Update mid2 marks for a student
  Future<void> updateMid2Marks({
    required String midSessionId,
    required String studentId,
    required double descriptive,
    required double objective,
  }) async {
    try {
      final midSession = await getMidSession(midSessionId);
      
      // Create updated mid2 marks map
      final updatedMid2Marks = Map<String, Map<String, dynamic>>.from(midSession.mid2Marks);
      
      // Calculate total (descriptive + objective)
      final total = descriptive + objective;
      
      updatedMid2Marks[studentId] = {
        'descriptive': descriptive,
        'objective': objective,
        'total': total,
      };
      
      // Update mid session
      final updatedMidSession = midSession.copyWith(
        mid2Marks: updatedMid2Marks,
        updatedAt: DateTime.now(),
      );
      
      await updateMidSession(updatedMidSession);
    } catch (e) {
      throw Exception('Failed to update Mid 2 marks: $e');
    }
  }
  
  // Calculate and save final mid marks
  Future<void> calculateAndSaveFinalMidMarks(String midSessionId) async {
    try {
      final midSession = await getMidSession(midSessionId);
      final updatedFinalMidMarks = <String, double>{};
      
      // For each student, calculate the average of mid1 and mid2 totals
      for (final studentId in midSession.students) {
        final mid1Total = midSession.mid1Marks[studentId]?['total'] as double? ?? 0;
        final mid2Total = midSession.mid2Marks[studentId]?['total'] as double? ?? 0;
        
        // Calculate average and round up
        final average = (mid1Total + mid2Total) / 2;
        final finalMark = average.ceil().toDouble();
        
        updatedFinalMidMarks[studentId] = finalMark;
      }
      
      // Update mid session
      final updatedMidSession = midSession.copyWith(
        finalMidMarks: updatedFinalMidMarks,
        updatedAt: DateTime.now(),
      );
      
      await updateMidSession(updatedMidSession);
    } catch (e) {
      throw Exception('Failed to calculate final mid marks: $e');
    }
  }
}
