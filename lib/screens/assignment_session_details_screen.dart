import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/assignment_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/assignment_export_service.dart';
import 'package:markpro_plus/widgets/assignment_marks_table.dart';
import 'package:markpro_plus/widgets/import_assignment1_dialog.dart';
import 'package:markpro_plus/widgets/import_assignment2_dialog.dart';

class AssignmentSessionDetailsScreen extends StatefulWidget {
  final String sessionId;

  const AssignmentSessionDetailsScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<AssignmentSessionDetailsScreen> createState() => _AssignmentSessionDetailsScreenState();
}

class _AssignmentSessionDetailsScreenState extends State<AssignmentSessionDetailsScreen> with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  final StudentService _studentService = StudentService();
  final AssignmentExportService _exportService = AssignmentExportService();
  
  late TabController _tabController;
  
  AssignmentSession? _session;
  List<StudentModel> _students = [];
  
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final session = await _assignmentService.getAssignmentSession(widget.sessionId);
      
      // Load student data
      final students = <StudentModel>[];
      for (final studentId in session.students) {
        try {
          // Use the branch, year, section from the session we just loaded
          final student = await _studentService.getStudentByRollNo(
            studentId, 
            session.branch, 
            session.year, 
            session.section
          );
          if (student != null) {
            students.add(student);
          } else {
            print('Student $studentId not found');
          }
        } catch (e) {
          print('Error loading student $studentId: $e');
        }
      }
      
      setState(() {
        _session = session;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading session: $e';
        _isLoading = false;
      });
    }
  }
  
  // Refresh data after marks are saved
  Future<void> _refreshData() async {
    // Only fetch the session data without reloading everything
    try {
      final session = await _assignmentService.getAssignmentSession(widget.sessionId);
      
      // Only update the session data, not the students
      setState(() {
        _session = session;
      });
      
    } catch (e) {
      print('Error refreshing session data: $e');
      // In case of error, fallback to full reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error refreshing data, please reload the page'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.subjectName ?? 'Assignment Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignment 1'),
            Tab(text: 'Assignment 2'),
            Tab(text: 'Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              // Use fast physics for immediate response
              physics: const ClampingScrollPhysics(),
              children: [
                _buildAssignment1Tab(),
                _buildAssignment2Tab(),
                _buildSummaryTab(),
              ],
            ),
    );
  }
  
  // Build the Assignment 1 tab
  Widget _buildAssignment1Tab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    return Column(
      children: [
        // Export & Import Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _exportAssignment1Marks,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showImportAssignment1Dialog,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Assignment 1 Marks Table
        Expanded(
          child: AssignmentMarksTable(
            assignmentSession: _session!,
            students: _students,
            assignmentNumber: '1',
            onMarksSaved: _refreshData,
          ),
        ),
      ],
    );
  }
  
  // Build the Assignment 2 tab
  Widget _buildAssignment2Tab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    return Column(
      children: [
        // Export & Import Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _exportAssignment2Marks,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showImportAssignment2Dialog,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Assignment 2 Marks Table
        Expanded(
          child: AssignmentMarksTable(
            assignmentSession: _session!,
            students: _students,
            assignmentNumber: '2',
            onMarksSaved: _refreshData,
          ),
        ),
      ],
    );
  }
  
  // Build the Summary tab showing total assignment marks
  Widget _buildSummaryTab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    
    return Column(
      children: [
        // Export Button
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
          child: ElevatedButton.icon(
            onPressed: _exportAllAssignmentMarks,
            icon: const Icon(Icons.download),
            label: const Text('Export All Assignment Marks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Summary Table
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assignment Marks Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Table
                      Table(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1),    // Student ID
                          1: FlexColumnWidth(3),    // Name
                          2: FlexColumnWidth(1.5),  // Assignment 1
                          3: FlexColumnWidth(1.5),  // Assignment 2
                          4: FlexColumnWidth(1.5),  // Total
                        },
                        children: [
                          // Header Row
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                            ),
                            children: [
                              _buildTableHeader('Student ID'),
                              _buildTableHeader('Name'),
                              _buildTableHeader('Assignment 1'),
                              _buildTableHeader('Assignment 2'),
                              _buildTableHeader('Average (Out of 5)'),
                            ],
                          ),
                          
                          // Data Rows
                          ..._students.map((student) {
                            final studentId = student.rollNo;
                            final marksData = _session!.assignmentMarks[studentId];
                            
                            // Get assignment marks and handle different data formats
                            int assignment1 = 0;
                            int assignment2 = 0;
                            
                            // Extract Assignment 1 marks
                            dynamic assignment1Data = marksData?['assignment1'];
                            if (assignment1Data is int) {
                              assignment1 = assignment1Data;
                            } else if (assignment1Data is Map) {
                              // Try to extract marks from the map structure
                              try {
                                var markValue = assignment1Data['marks'];
                                if (markValue is int) {
                                  assignment1 = markValue;
                                } else if (markValue is double) {
                                  assignment1 = markValue.round();
                                } else if (markValue is String) {
                                  assignment1 = int.tryParse(markValue) ?? 0;
                                }
                              } catch (e) {
                                print('Error extracting Assignment 1 marks: $e');
                              }
                            }
                            
                            // Extract Assignment 2 marks
                            dynamic assignment2Data = marksData?['assignment2'];
                            if (assignment2Data is int) {
                              assignment2 = assignment2Data;
                            } else if (assignment2Data is Map) {
                              // Try to extract marks from the map structure
                              try {
                                var markValue = assignment2Data['marks'];
                                if (markValue is int) {
                                  assignment2 = markValue;
                                } else if (markValue is double) {
                                  assignment2 = markValue.round();
                                } else if (markValue is String) {
                                  assignment2 = int.tryParse(markValue) ?? 0;
                                }
                              } catch (e) {
                                print('Error extracting Assignment 2 marks: $e');
                              }
                            }
                            
                            // Calculate converted marks
                            final converted1 = _assignmentService.convertTo5PointScale(assignment1);
                            final converted2 = _assignmentService.convertTo5PointScale(assignment2);
                            
                            // Calculate average instead of total (max 5 marks instead of 10)
                            final average = (converted1 + converted2) / 2.0;
                            
                            return TableRow(
                              decoration: BoxDecoration(
                                color: average >= 4.0 ? Colors.green[50] : 
                                      average >= 3.0 ? Colors.blue[50] : 
                                      average >= 2.0 ? Colors.amber[50] : 
                                      Colors.red[50],
                              ),
                              children: [
                                _buildTableCell(studentId),
                                _buildTableCell(student.name),
                                _buildTableCell('$converted1'),
                                _buildTableCell('$converted2'),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${average.round()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: average >= 4.0 ? Colors.green[800] : 
                                            average >= 3.0 ? Colors.blue[800] : 
                                            average >= 2.0 ? Colors.orange[800] : 
                                            Colors.red[800],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildScaleItem(String range, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              range,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(' → '),
          Text(
            points,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  // Export methods
  Future<void> _exportAssignment1Marks() async {
    if (_session != null) {
      await _exportService.exportAssignment1Marks(
        assignmentSession: _session!,
        students: _students,
      );
    }
  }
  
  Future<void> _exportAssignment2Marks() async {
    if (_session != null) {
      await _exportService.exportAssignment2Marks(
        assignmentSession: _session!,
        students: _students,
      );
    }
  }
  
  Future<void> _exportAllAssignmentMarks() async {
    if (_session != null) {
      await _exportService.exportAllAssignmentMarks(
        assignmentSession: _session!,
        students: _students,
      );
    }
  }
  
  // Show import dialog for Assignment 1 marks
  void _showImportAssignment1Dialog() {
    if (_session != null) {
      showDialog(
        context: context,
        builder: (context) => ImportAssignment1Dialog(
          assignmentSession: _session!,
          onImportComplete: _refreshData,
        ),
      ).then((_) {
        // Extra refresh when dialog is closed to ensure UI update
        _refreshData();
      });
    }
  }
  
  // Show import dialog for Assignment 2 marks
  void _showImportAssignment2Dialog() {
    if (_session != null) {
      showDialog(
        context: context,
        builder: (context) => ImportAssignment2Dialog(
          assignmentSession: _session!,
          onImportComplete: _refreshData,
        ),
      ).then((_) {
        // Extra refresh when dialog is closed to ensure UI update
        _refreshData();
      });
    }
  }
}
