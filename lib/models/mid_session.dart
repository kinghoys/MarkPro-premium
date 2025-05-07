import 'package:cloud_firestore/cloud_firestore.dart';

class MidSession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String section;
  final List<String> students;
  Map<String, Map<String, dynamic>> mid1Marks; // studentId -> {descriptive, objective, total}
  Map<String, Map<String, dynamic>> mid2Marks; // studentId -> {descriptive, objective, total}
  Map<String, double> finalMidMarks; // studentId -> total (average of mid1 and mid2)
  final DateTime createdAt;
  final DateTime updatedAt;

  MidSession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.section,
    required this.students,
    Map<String, Map<String, dynamic>>? mid1Marks,
    Map<String, Map<String, dynamic>>? mid2Marks,
    Map<String, double>? finalMidMarks,
    required this.createdAt,
    required this.updatedAt,
  }) : 
    this.mid1Marks = mid1Marks ?? {},
    this.mid2Marks = mid2Marks ?? {},
    this.finalMidMarks = finalMidMarks ?? {};

  factory MidSession.create({
    required String subjectId,
    required String subjectName,
    required String branch,
    required String year,
    required String section,
    required List<String> students,
  }) {
    return MidSession(
      id: '',
      subjectId: subjectId,
      subjectName: subjectName,
      branch: branch,
      year: year,
      section: section,
      students: students,
      mid1Marks: {},
      mid2Marks: {},
      finalMidMarks: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory MidSession.fromMap(Map<String, dynamic> map, String id) {
    // Convert mid1 marks
    final mid1MarksMap = <String, Map<String, dynamic>>{};
    if (map['mid1Marks'] != null) {
      final rawMarks = map['mid1Marks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, marks) {
        mid1MarksMap[studentId] = Map<String, dynamic>.from(marks);
      });
    }
    
    // Convert mid2 marks
    final mid2MarksMap = <String, Map<String, dynamic>>{};
    if (map['mid2Marks'] != null) {
      final rawMarks = map['mid2Marks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, marks) {
        mid2MarksMap[studentId] = Map<String, dynamic>.from(marks);
      });
    }
    
    // Convert final mid marks
    final finalMidMarksMap = <String, double>{};
    if (map['finalMidMarks'] != null) {
      final rawMarks = map['finalMidMarks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, mark) {
        finalMidMarksMap[studentId] = (mark as num).toDouble();
      });
    }

    return MidSession(
      id: id,
      subjectId: map['subjectId'],
      subjectName: map['subjectName'],
      branch: map['branch'],
      year: map['year'],
      section: map['section'],
      students: List<String>.from(map['students'] ?? []),
      mid1Marks: mid1MarksMap,
      mid2Marks: mid2MarksMap,
      finalMidMarks: finalMidMarksMap,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'branch': branch,
      'year': year,
      'section': section,
      'students': students,
      'mid1Marks': mid1Marks,
      'mid2Marks': mid2Marks,
      'finalMidMarks': finalMidMarks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  MidSession copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? branch,
    String? year,
    String? section,
    List<String>? students,
    Map<String, Map<String, dynamic>>? mid1Marks,
    Map<String, Map<String, dynamic>>? mid2Marks,
    Map<String, double>? finalMidMarks,
    DateTime? updatedAt,
  }) {
    return MidSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      section: section ?? this.section,
      students: students ?? this.students,
      mid1Marks: mid1Marks ?? this.mid1Marks,
      mid2Marks: mid2Marks ?? this.mid2Marks,
      finalMidMarks: finalMidMarks ?? this.finalMidMarks,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  Map<String, dynamic>? getMid1Marks(String studentId) {
    return mid1Marks[studentId];
  }
  
  Map<String, dynamic>? getMid2Marks(String studentId) {
    return mid2Marks[studentId];
  }
  
  double? getFinalMidMark(String studentId) {
    return finalMidMarks[studentId];
  }
}
