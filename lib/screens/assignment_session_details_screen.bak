import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/assignment_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/widgets/assignment_marks_table.dart';

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
  
  late TabController _tabController;
  
  AssignmentSession? _session;
  List<StudentModel> _students = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Controllers for the text fields
  final Map<String, TextEditingController> _assignment1Controllers = {};
  final Map<String, TextEditingController> _assignment2Controllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    
    // Dispose of text controllers
    for (final controller in _assignment1Controllers.values) {
      controller.dispose();
    }
    for (final controller in _assignment2Controllers.values) {
      controller.dispose();
    }
    
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
      
      // Initialize controllers
      for (final student in students) {
        final studentId = student.rollNo;
        
        // Get existing marks if available
        final marks = session.assignmentMarks[studentId];
        final assignment1 = marks?['assignment1'] as int? ?? 0;
        final assignment2 = marks?['assignment2'] as int? ?? 0;
        
        // Create controllers with initial values
        _assignment1Controllers[studentId] = TextEditingController(
          text: assignment1 > 0 ? assignment1.toString() : '',
        );
        _assignment2Controllers[studentId] = TextEditingController(
          text: assignment2 > 0 ? assignment2.toString() : '',
        );
      }
      
      setState(() {
        _session = session;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading data: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  Future<void> _saveAssignment1Marks(String studentId) async {
    final text = _assignment1Controllers[studentId]?.text ?? '';
    if (text.isEmpty) return;
    
    try {
      final marks = int.parse(text);
      
      // Validate marks range
      if (marks < 0 || marks > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment marks must be between 0 and 60')),
        );
        return;
      }
      
      await _assignmentService.updateAssignment1Marks(
        sessionId: widget.sessionId,
        studentId: studentId,
        marks: marks,
      );
      
      // Refresh data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment 1 marks saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    }
  }
  
  Future<void> _saveAssignment2Marks(String studentId) async {
    final text = _assignment2Controllers[studentId]?.text ?? '';
    if (text.isEmpty) return;
    
    try {
      final marks = int.parse(text);
      
      // Validate marks range
      if (marks < 0 || marks > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment marks must be between 0 and 60')),
        );
        return;
      }
      
      await _assignmentService.updateAssignment2Marks(
        sessionId: widget.sessionId,
        studentId: studentId,
        marks: marks,
      );
      
      // Refresh data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment 2 marks saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    }
  }
  
  Future<void> _saveAllMarks() async {
    int savedCount = 0;
    
    for (final student in _students) {
      final studentId = student.rollNo;
      
      // Save Assignment 1 marks
      final assignment1Text = _assignment1Controllers[studentId]?.text ?? '';
      if (assignment1Text.isNotEmpty) {
        try {
          final marks = int.parse(assignment1Text);
          
          // Validate marks range
          if (marks < 0 || marks > 60) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.name}: Assignment 1 marks must be between 0 and 60')),
              );
            }
            continue;
          }
          
          await _assignmentService.updateAssignment1Marks(
            sessionId: widget.sessionId,
            studentId: studentId,
            marks: marks,
          );
          
          savedCount++;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving Assignment 1 marks for ${student.name}: $e')),
            );
          }
        }
      }
      
      // Save Assignment 2 marks
      final assignment2Text = _assignment2Controllers[studentId]?.text ?? '';
      if (assignment2Text.isNotEmpty) {
        try {
          final marks = int.parse(assignment2Text);
          
          // Validate marks range
          if (marks < 0 || marks > 60) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.name}: Assignment 2 marks must be between 0 and 60')),
              );
            }
            continue;
          }
          
          await _assignmentService.updateAssignment2Marks(
            sessionId: widget.sessionId,
            studentId: studentId,
            marks: marks,
          );
          
          savedCount++;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving Assignment 2 marks for ${student.name}: $e')),
            );
          }
        }
      }
    }
    
    // Refresh data
    await _loadData();
    
    if (mounted && savedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved marks for $savedCount students')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Details'),
        ),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Details'),
        ),
        body: const Center(
          child: Text('Session not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${_session!.subjectName} - Assignment'),
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
            icon: const Icon(Icons.save),
            onPressed: _saveAllMarks,
            tooltip: 'Save All Marks',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignment1Tab(),
          _buildAssignment2Tab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }
  
  // Refresh data after marks are saved
  Future<void> _refreshData() async {
    await _loadData();
  }

  // Build the Assignment 1 tab
  Widget _buildAssignment1Tab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    return AssignmentMarksTable(
      assignmentSession: _session!,
      students: _students,
      assignmentNumber: '1',
      onMarksSaved: _refreshData,
    );
  }
  
  Widget _buildAssignment2Tab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    return AssignmentMarksTable(
      assignmentSession: _session!,
      students: _students,
      assignmentNumber: '2',
      onMarksSaved: _refreshData,
    );
  }
  
  Widget _buildSummaryTab() {
    if (_session == null) {
      return const Center(child: Text('No session data available'));
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.assessment, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Assignment Summary. Each assignment is converted to a 5-point scale, with a total out of 10. '
                    'The scale is: 36-60→5, 26-35→4, 16-25→3, 6-15→2, 1-5→1, 0→0.',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey[300] ?? Colors.grey,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                      ),
                      children: [
                        _buildTableHeader('Roll No'),
                        _buildTableHeader('Name'),
                        _buildTableHeader('Assign. 1 (0-5)'),
                        _buildTableHeader('Assign. 2 (0-5)'),
                        _buildTableHeader('Total (0-10)'),
                      ],
                    ),
                    // Data Rows
                    ..._students.map((student) {
                      final studentId = student.rollNo;
                      final marks = _session!.assignmentMarks[studentId] ?? {};
                      
                      final assignment1 = marks['assignment1'] as int? ?? 0;
                      final assignment2 = marks['assignment2'] as int? ?? 0;
                      
                      final converted1 = _assignmentService.convertTo5PointScale(assignment1);
                      final converted2 = _assignmentService.convertTo5PointScale(assignment2);
                      final total = converted1 + converted2;
                      
                      return TableRow(
                        decoration: BoxDecoration(
                          color: total >= 8 ? Colors.green[50] : 
                                total >= 6 ? Colors.blue[50] : 
                                total >= 4 ? Colors.amber[50] : 
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
                              '$total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: total >= 8 ? Colors.green[800] : 
                                      total >= 6 ? Colors.blue[800] : 
                                      total >= 4 ? Colors.orange[800] : 
                                      Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
  
  // Helper method for table headers and cells
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assignment Summary. Each assignment is converted to a 5-point scale, with a total out of 10. '
                  'The scale is: 36-60→5, 26-35→4, 16-25→3, 6-15→2, 1-5→1, 0→0.',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey[300] ?? Colors.grey,
                  width: 1,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                    ),
                    children: [
                      _buildTableHeader('Roll No'),
                      _buildTableHeader('Name'),
                      _buildTableHeader('Assign. 1 (0-5)'),
                      _buildTableHeader('Assign. 2 (0-5)'),
                      _buildTableHeader('Total (0-10)'),
                    ],
                  ),
                  // Data Rows
                  ..._students.map((student) {
                    final studentId = student.rollNo;
                    final marks = _session!.assignmentMarks[studentId] ?? {};
                    
                    final assignment1 = marks['assignment1'] as int? ?? 0;
                    final assignment2 = marks['assignment2'] as int? ?? 0;
                    
                    final converted1 = _assignmentService.convertTo5PointScale(assignment1);
                    final converted2 = _assignmentService.convertTo5PointScale(assignment2);
                    final total = converted1 + converted2;
                    
                    return TableRow(
                      decoration: BoxDecoration(
                        color: total >= 8 ? Colors.green[50] : 
                              total >= 6 ? Colors.blue[50] : 
                              total >= 4 ? Colors.amber[50] : 
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
                            '$total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: total >= 8 ? Colors.green[800] : 
                                    total >= 6 ? Colors.blue[800] : 
                                    total >= 4 ? Colors.orange[800] : 
                                    Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
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
          Container(
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
}
