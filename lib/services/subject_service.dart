import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:markpro_plus/models/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Constants
  static const String kSubjectsCollection = 'subjects';
  static const String kNameKey = 'name';

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get reference to user's subjects collection
  CollectionReference<Map<String, dynamic>> get _subjectsRef => 
      _firestore.collection('users')
               .doc(currentUserId)
               .collection(kSubjectsCollection);

  // Fetch all subjects for current user
  Future<List<SubjectModel>> getSubjects() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final snapshot = await _subjectsRef.get();
    
    return snapshot.docs.map((doc) => 
      SubjectModel.fromMap(
        {
          'name': doc.data()['name'] ?? '',
          'code': doc.data()['code'] ?? '',
          'professorId': doc.data()['professorId'] ?? currentUserId,
          'branch': doc.data()['branch'] ?? '',
          'year': doc.data()['year'] ?? 1,
          'section': doc.data()['section'],
          'semester': doc.data()['semester'] ?? 1,
          'academicYear': doc.data()['academicYear'] ?? '',
        }, 
        doc.id
      )
    ).toList();
  }

  // Add a new subject
  Future<DocumentReference> addSubject(String name) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Create a simplified subject document with just the name
    return await _subjectsRef.add({
      kNameKey: name,
    });
  }

  // Update an existing subject
  Future<void> updateSubject(String id, String name) async {
    await _subjectsRef.doc(id).update({
      kNameKey: name,
    });
  }

  // Delete a subject
  Future<void> deleteSubject(String id) async {
    await _subjectsRef.doc(id).delete();
  }

  // Add subjects from Excel
  Future<List<String>> addSubjectsFromExcel(List<String> subjectNames) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final batch = _firestore.batch();
    final addedSubjects = <String>[];
    
    // Get existing subjects to avoid duplicates
    final existingSubjects = await getSubjects();
    final existingNames = existingSubjects.map((s) => s.name.toLowerCase()).toSet();
    
    // Add each non-duplicate subject
    for (final name in subjectNames) {
      // Skip if already exists
      if (existingNames.contains(name.toLowerCase())) {
        continue;
      }
      
      // Create new document reference
      final docRef = _subjectsRef.doc();
      
      // Set just the name field
      batch.set(docRef, {
        kNameKey: name,
      });
      
      // Add to list of added subjects
      addedSubjects.add(name);
      
      // Add to existing set to prevent duplicates in the same batch
      existingNames.add(name.toLowerCase());
    }
    
    // Commit the batch
    await batch.commit();
    
    return addedSubjects;
  }
}
