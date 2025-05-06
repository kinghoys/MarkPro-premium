import 'package:flutter/material.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/seminar_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/export_service_fixed.dart';
import 'package:markpro_plus/widgets/seminar_marks_table.dart';
import 'package:markpro_plus/widgets/import_seminar_marks_dialog.dart';

class SeminarSessionDetailsScreen extends StatefulWidget {
  final SeminarSession seminarSession;
  final int? initialTabIndex;
  
  const SeminarSessionDetailsScreen({
    Key? key, 
    required this.seminarSession,
    this.initialTabIndex,
  }) : super(key: key);
  
  @override
  State<SeminarSessionDetailsScreen> createState() => _SeminarSessionDetailsScreenState();
}

class _SeminarSessionDetailsScreenState extends State<SeminarSessionDetailsScreen> {
  final SeminarService _seminarService = SeminarService();
  final StudentService _studentService = StudentService();
  final ExportService _exportService = ExportService();
  bool _isLoading = false;
  String? _error;
  
  // Data
  late SeminarSession seminarSession;
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize seminarSession
    seminarSession = widget.seminarSession;
    
    // Load students
    _loadStudents();
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Get student details for each student ID
      final students = <StudentModel>[];
      for (final studentId in seminarSession.students) {
        final student = await _studentService.getStudent(studentId);
        if (student != null) {
          students.add(student);
        }
      }
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Get fresh seminar session data
      final refreshedSession = await _seminarService.getSeminarSession(seminarSession.id);
      if (refreshedSession != null) {
        setState(() {
          seminarSession = refreshedSession;
        });
      }
      
      // Load students again
      await _loadStudents();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // Export marks to Excel file
  void _exportMarks() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students data available to export'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      _exportService.exportSeminarMarks(
        seminarSession: seminarSession,
        students: _students,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting marks: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Show import dialog
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportSeminarMarksDialog(
        seminarSession: seminarSession,
        onImportComplete: _refreshData,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(seminarSession.subjectName),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportMarks(),
            tooltip: 'Export Marks',
          ),
          // Import button
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _showImportDialog(),
            tooltip: 'Import Marks',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading && _students.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null && _students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfo(),
          const SizedBox(height: 24),
          SeminarMarksTable(
            seminarSession: seminarSession,
            students: _students,
            onMarksSaved: _refreshData,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seminarSession.subjectName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem(
                  icon: Icons.school,
                  label: 'Branch',
                  value: seminarSession.branch,
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Year',
                  value: seminarSession.year,
                ),
                _buildInfoItem(
                  icon: Icons.groups,
                  label: 'Section',
                  value: seminarSession.section,
                ),
                _buildInfoItem(
                  icon: Icons.people,
                  label: 'Students',
                  value: seminarSession.students.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
