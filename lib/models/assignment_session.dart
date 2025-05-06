import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentSession {
  final String id;
  final String subjectName;
  final String branch;
  final String year;
  final String section;
  final List<String> students;
  final Map<String, Map<String, dynamic>> assignmentMarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  AssignmentSession({
    required this.id,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.section,
    required this.students,
    required this.assignmentMarks, 
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Create a copy of this AssignmentSession with updated fields
  AssignmentSession copyWith({
    String? id,
    String? subjectName,
    String? branch,
    String? year,
    String? section,
    List<String>? students,
    Map<String, Map<String, dynamic>>? assignmentMarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return AssignmentSession(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      section: section ?? this.section,
      students: students ?? this.students,
      assignmentMarks: assignmentMarks ?? this.assignmentMarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // Convert AssignmentSession to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'branch': branch,
      'year': year,
      'section': section,
      'students': students,
      'assignmentMarks': assignmentMarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  // Create AssignmentSession from Firestore document
  factory AssignmentSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle the marks data (could be null if new session)
    final assignmentMarks = (data['assignmentMarks'] as Map<String, dynamic>?) ?? {};
    
    // Convert to the correct nested map type
    final typedAssignmentMarks = assignmentMarks.map((key, value) {
      return MapEntry(key, value as Map<String, dynamic>);
    });
    
    return AssignmentSession(
      id: doc.id,
      subjectName: data['subjectName'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? '',
      section: data['section'] ?? '',
      students: List<String>.from(data['students'] ?? []),
      assignmentMarks: typedAssignmentMarks,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  // Create a new AssignmentSession with default values
  factory AssignmentSession.create({
    required String subjectName,
    required String branch,
    required String year,
    required String section,
    required List<String> students,
    required String userId,
  }) {
    final now = DateTime.now();
    final id = FirebaseFirestore.instance.collection('assignmentSessions').doc().id;
    
    return AssignmentSession(
      id: id,
      subjectName: subjectName,
      branch: branch,
      year: year,
      section: section,
      students: students,
      assignmentMarks: {},
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }
}
