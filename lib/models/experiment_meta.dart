import 'package:cloud_firestore/cloud_firestore.dart';

class ExperimentMeta {
  final DateTime dateOfExperiment;
  final DateTime dueDate;
  
  ExperimentMeta({
    required this.dateOfExperiment,
    DateTime? dueDate,
  }) : this.dueDate = dueDate ?? dateOfExperiment.add(Duration(days: 10));
  
  factory ExperimentMeta.fromMap(Map<String, dynamic> map) {
    return ExperimentMeta(
      dateOfExperiment: (map['dateOfExperiment'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'dateOfExperiment': Timestamp.fromDate(dateOfExperiment),
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }
  
  bool isAfterDueDate() {
    final now = DateTime.now();
    return now.isAfter(dueDate);
  }
}
