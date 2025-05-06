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
  final int? initialTabIndex;
  
  const AssignmentSessionDetailsScreen({
    Key? key, 
    required this.sessionId,
    this.initialTabIndex,
  }) : super(key: key);

  @override
  State<AssignmentSessionDetailsScreen> createState() => _AssignmentSessionDetailsScreenState();
}

class _AssignmentSessionDetailsScreenState extends State<AssignmentSessionDetailsScreen> with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  final StudentService _studentService = StudentService();
  final AssignmentExportService _exportService = AssignmentExportService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;
  AssignmentSession? _session;
  List<StudentModel> _students = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.initialTabIndex != null) {
      _tabController.index = widget.initialTabIndex!;
    }
    
    _fetchData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Fetch session data and students
  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Fetch assignment session
      final session = await _assignmentService.getAssignmentSession(widget.sessionId);
      
      // Fetch students for this session
      final students = await _studentService.getStudentsByRollNumbers(session.students);
      
      // Sort students by roll number
      students.sort((a, b) => a.rollNo.compareTo(b.rollNo));
      
      setState(() {
        _session = session;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  // Refresh data (used after marking changes)
  Future<void> _refreshData() async {
    try {
      final session = await _assignmentService.getAssignmentSession(widget.sessionId);
      
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
      );
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
      );
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
                    onPressed: _fetchData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
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
        
        // Summary Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Explanation Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assignment Marks Scale',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildScaleItem('36-60 marks', '5 points'),
                          _buildScaleItem('26-35 marks', '4 points'),
                          _buildScaleItem('16-25 marks', '3 points'),
                          _buildScaleItem('6-15 marks', '2 points'),
                          _buildScaleItem('1-5 marks', '1 point'),
                          _buildScaleItem('0 marks', '0 points'),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Assignment Summary. Each assignment is converted to a 5-point scale, with a total out of 10.',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Summary Table
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSummaryTable(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to build the summary table
  Widget _buildSummaryTable() {
    return Table(
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
        // Data Rows - generate for each student
        for (final student in _students)
          _buildStudentSummaryRow(student),
      ],
    );
  }
  
  // Helper method to build each student's summary row
  TableRow _buildStudentSummaryRow(StudentModel student) {
    final studentId = student.rollNo;
    final marks = _session!.assignmentMarks[studentId] ?? {};
    
    final assignment1Data = marks['assignment1'] as Map<String, dynamic>? ?? {};
    final assignment2Data = marks['assignment2'] as Map<String, dynamic>? ?? {};
    
    final assignment1Mark = assignment1Data['convertedMarks'] as double? ?? 0.0;
    final assignment2Mark = assignment2Data['convertedMarks'] as double? ?? 0.0;
    final totalMark = assignment1Mark + assignment2Mark;
    
    return TableRow(
      children: [
        _buildTableCell(student.rollNo),
        _buildTableCell(student.name),
        _buildTableCell(assignment1Mark.toString()),
        _buildTableCell(assignment2Mark.toString()),
        _buildTableCell(totalMark.toString()),
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
}
