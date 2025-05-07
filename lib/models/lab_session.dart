import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markpro_plus/models/experiment_meta.dart';

class LabSession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String section;
  final int numberOfExperiments;
  final List<String> students;
  final Map<String, Map<String, Map<String, dynamic>>> experimentMarks; // studentId -> experimentNum -> {A, B, C, total}
  final Map<String, Map<String, int>> internalMarks; // studentId -> {1: score, 2: score}
  final Map<String, double> m1Marks; // studentId -> M1 score (out of 30)
  final Map<String, double> m2Marks; // studentId -> M2 score (out of 30)
  final Map<String, int> vivaMarks; // studentId -> viva score (out of 10)
  final Map<String, double> finalLabMarks; // studentId -> final lab score (out of 40)
  final int? m1LastExperiment; // Last experiment number included in M1
  final Map<String, ExperimentMeta> experimentMeta; // experimentNum -> ExperimentMeta
  final DateTime createdAt;
  final DateTime updatedAt;

  LabSession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.section,
    required this.numberOfExperiments,
    required this.students,
    required this.experimentMarks,
    required this.internalMarks,
    required this.m1Marks,
    required this.m2Marks,
    required this.vivaMarks,
    required this.finalLabMarks,
    this.m1LastExperiment,
    required this.experimentMeta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LabSession.create({
    required String subjectId,
    required String subjectName,
    required String branch,
    required String year,
    required String section,
    required int numberOfExperiments,
    required List<String> students,
    Map<String, int> vivaMarks = const {},
    Map<String, double> finalLabMarks = const {},
  }) {
    return LabSession(
      id: '',
      subjectId: subjectId,
      subjectName: subjectName,
      branch: branch,
      year: year,
      section: section,
      numberOfExperiments: numberOfExperiments,
      students: students,
      experimentMarks: {},
      internalMarks: {},
      m1Marks: {},
      m2Marks: {},
      vivaMarks: vivaMarks,
      finalLabMarks: finalLabMarks,
      m1LastExperiment: null,
      experimentMeta: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory LabSession.fromMap(Map<String, dynamic> map, String id) {
    // Convert experiment meta data
    final experimentMetaMap = <String, ExperimentMeta>{};
    if (map['experimentMeta'] != null) {
      final metaData = map['experimentMeta'] as Map<String, dynamic>;
      metaData.forEach((key, value) {
        experimentMetaMap[key] = ExperimentMeta.fromMap(value);
      });
    }

    // Convert experiment marks
    final experimentMarksMap = <String, Map<String, Map<String, dynamic>>>{};
    if (map['experimentMarks'] != null) {
      final rawMarks = map['experimentMarks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, experiments) {
        experimentMarksMap[studentId] = {};
        final experimentMap = experiments as Map<String, dynamic>;
        experimentMap.forEach((experimentNum, marks) {
          experimentMarksMap[studentId]![experimentNum] = Map<String, dynamic>.from(marks);
        });
      });
    }

    // Convert internal marks
    final internalMarksMap = <String, Map<String, int>>{};
    if (map['internalMarks'] != null) {
      final rawMarks = map['internalMarks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, marks) {
        internalMarksMap[studentId] = {};
        final internalMap = marks as Map<String, dynamic>;
        internalMap.forEach((internalNum, mark) {
          internalMarksMap[studentId]![internalNum] = mark as int;
        });
      });
    }

    // Convert M1 and M2 marks
    final m1MarksMap = <String, double>{};
    if (map['m1Marks'] != null) {
      final rawMarks = map['m1Marks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, mark) {
        m1MarksMap[studentId] = (mark as num).toDouble();
      });
    }

    final m2MarksMap = <String, double>{};
    if (map['m2Marks'] != null) {
      final rawMarks = map['m2Marks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, mark) {
        m2MarksMap[studentId] = (mark as num).toDouble();
      });
    }
    
    // Convert viva marks
    final vivaMarksMap = <String, int>{};
    if (map['vivaMarks'] != null) {
      final rawMarks = map['vivaMarks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, mark) {
        vivaMarksMap[studentId] = mark as int;
      });
    }
    
    // Convert final lab marks
    final finalLabMarksMap = <String, double>{};
    if (map['finalLabMarks'] != null) {
      final rawMarks = map['finalLabMarks'] as Map<String, dynamic>;
      rawMarks.forEach((studentId, mark) {
        finalLabMarksMap[studentId] = (mark as num).toDouble();
      });
    }

    return LabSession(
      id: id,
      subjectId: map['subjectId'] as String,
      subjectName: map['subjectName'] as String,
      branch: map['branch'] as String,
      year: map['year'] as String,
      section: map['section'] as String,
      numberOfExperiments: map['numberOfExperiments'] as int,
      students: List<String>.from(map['students']),
      experimentMarks: experimentMarksMap,
      internalMarks: internalMarksMap,
      m1Marks: m1MarksMap,
      m2Marks: m2MarksMap,
      vivaMarks: vivaMarksMap,
      finalLabMarks: finalLabMarksMap,
      m1LastExperiment: map['m1LastExperiment'] as int?,
      experimentMeta: experimentMetaMap,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convert experiment meta to map
    final experimentMetaMap = <String, dynamic>{};
    experimentMeta.forEach((key, value) {
      experimentMetaMap[key] = value.toMap();
    });
    
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'branch': branch,
      'year': year,
      'section': section,
      'numberOfExperiments': numberOfExperiments,
      'students': students,
      'experimentMarks': experimentMarks,
      'internalMarks': internalMarks,
      'm1Marks': m1Marks,
      'm2Marks': m2Marks,
      'vivaMarks': vivaMarks,
      'finalLabMarks': finalLabMarks,
      'm1LastExperiment': m1LastExperiment,
      'experimentMeta': experimentMetaMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LabSession copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? branch,
    String? year,
    String? section,
    int? numberOfExperiments,
    List<String>? students,
    Map<String, Map<String, Map<String, dynamic>>>? experimentMarks,
    Map<String, Map<String, int>>? internalMarks,
    Map<String, double>? m1Marks,
    Map<String, double>? m2Marks,
    Map<String, int>? vivaMarks,
    Map<String, double>? finalLabMarks,
    int? m1LastExperiment,
    Map<String, ExperimentMeta>? experimentMeta,
    DateTime? updatedAt,
  }) {
    return LabSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      section: section ?? this.section,
      numberOfExperiments: numberOfExperiments ?? this.numberOfExperiments,
      students: students ?? this.students,
      experimentMarks: experimentMarks ?? this.experimentMarks,
      internalMarks: internalMarks ?? this.internalMarks,
      m1Marks: m1Marks ?? this.m1Marks,
      m2Marks: m2Marks ?? this.m2Marks,
      vivaMarks: vivaMarks ?? this.vivaMarks,
      finalLabMarks: finalLabMarks ?? this.finalLabMarks,
      m1LastExperiment: m1LastExperiment ?? this.m1LastExperiment,
      experimentMeta: experimentMeta ?? this.experimentMeta,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods

  // Get experiment marks for a student
  Map<String, dynamic>? getExperimentMarks(String studentId, String experimentNumber) {
    return experimentMarks[studentId]?[experimentNumber];
  }

  // Get internal marks for a student
  int? getInternalMark(String studentId, String internalNumber) {
    return internalMarks[studentId]?[internalNumber];
  }

  // Check if experiment date is set
  bool isExperimentDateSet(String experimentNumber) {
    return experimentMeta.containsKey(experimentNumber);
  }

  // Check if experiment is past due date
  bool isExperimentPastDueDate(String experimentNumber) {
    final meta = experimentMeta[experimentNumber];
    if (meta == null) return false;
    return meta.isAfterDueDate();
  }

  // Calculate M1 marks
  Map<String, double> calculateM1Marks(int lastExperiment) {
    final result = <String, double>{};
    
    for (final studentId in students) {
      double experimentSum = 0;
      int experimentCount = 0;
      
      // Sum experiment marks
      for (int i = 1; i <= lastExperiment; i++) {
        final marks = getExperimentMarks(studentId, i.toString());
        if (marks != null && marks['total'] != null) {
          experimentSum += (marks['total'] as num).toDouble();
          experimentCount++;
        }
      }
      
      // Calculate experiment average (out of 20)
      double experimentAverage = experimentCount > 0 ? experimentSum / experimentCount : 0;
      
      // Get internal mark (out of 10)
      final internalMark = getInternalMark(studentId, '1') ?? 0;
      
      // M1 = experiment average + internal mark (out of 30)
      result[studentId] = experimentAverage + internalMark;
    }
    
    return result;
  }

  // Calculate M2 marks
  Map<String, double> calculateM2Marks(int startExperiment) {
    final result = <String, double>{};
    
    for (final studentId in students) {
      double experimentSum = 0;
      int experimentCount = 0;
      
      // Sum experiment marks
      for (int i = startExperiment; i <= numberOfExperiments; i++) {
        final marks = getExperimentMarks(studentId, i.toString());
        if (marks != null && marks['total'] != null) {
          experimentSum += (marks['total'] as num).toDouble();
          experimentCount++;
        }
      }
      
      // Calculate experiment average (out of 20)
      double experimentAverage = experimentCount > 0 ? experimentSum / experimentCount : 0;
      
      // Get internal mark (out of 10)
      final internalMark = getInternalMark(studentId, '2') ?? 0;
      
      // M2 = experiment average + internal mark (out of 30)
      result[studentId] = experimentAverage + internalMark;
    }
    
    return result;
  }
  
  // Get viva mark for a student
  int? getVivaMark(String studentId) {
    return vivaMarks[studentId];
  }
  
  // Calculate final lab marks
  Map<String, double> calculateFinalLabMarks() {
    final result = <String, double>{};
    
    for (final studentId in students) {
      final m1Mark = m1Marks[studentId];
      final m2Mark = m2Marks[studentId];
      final vivaMark = vivaMarks[studentId];
      
      // Skip if any required component is missing
      if (m1Mark == null || m2Mark == null || vivaMark == null) {
        continue;
      }
      
      // Select the better score between M1 and M2
      final modelScore = m1Mark > m2Mark ? m1Mark : m2Mark;
      
      // Final lab mark = 75% of model score (max 30) + viva mark (max 10)
      final finalScore = (modelScore * 0.75) + vivaMark.toDouble();
      
      result[studentId] = finalScore;
    }
    
    return result;
  }
}
