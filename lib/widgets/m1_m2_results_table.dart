import 'package:flutter/material.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';

class M1M2ResultsTable extends StatelessWidget {
  final LabSession labSession;
  final List<StudentModel> students;

  const M1M2ResultsTable({
    Key? key,
    required this.labSession,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'M1 and M2 marks are out of 30. They are calculated as: '
                    'Average of experiment marks (Component A: 5, Component B: 5, Component C: 10) + '
                    'Internal marks (out of 10).',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildHeader(),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentRow(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    final bool m1Calculated = labSession.m1Marks.isNotEmpty;
    final bool m2Calculated = labSession.m2Marks.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100] ?? Colors.blue),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'M1 Marks',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (m1Calculated)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            )
                          else
                            Icon(
                              Icons.pending,
                              color: Colors.grey,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Out of 30',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'M2 Marks',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (m2Calculated)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            )
                          else
                            Icon(
                              Icons.pending,
                              color: Colors.grey,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Out of 30',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Final Grade',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Average of M1+M2',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentRow(StudentModel student) {
    final studentId = student.rollNo;
    
    // Get M1 and M2 marks
    final m1Mark = labSession.m1Marks[studentId];
    final m2Mark = labSession.m2Marks[studentId];
    
    // Calculate final grade if both M1 and M2 are available
    double? finalGrade;
    String gradeLabel = '-';
    
    if (m1Mark != null && m2Mark != null) {
      finalGrade = (m1Mark + m2Mark) / 2;
      gradeLabel = finalGrade.toStringAsFixed(1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              student.name.isNotEmpty ? student.name : 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: m1Mark != null ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m1Mark != null ? m1Mark.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: m1Mark != null ? Colors.green[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: m2Mark != null ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m2Mark != null ? m2Mark.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: m2Mark != null ? Colors.green[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: finalGrade != null ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gradeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: finalGrade != null ? Colors.blue[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
