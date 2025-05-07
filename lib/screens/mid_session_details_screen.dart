import 'package:flutter/material.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/mid_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/export_service_fixed.dart';
import 'package:markpro_plus/widgets/mid1_marks_table.dart';
import 'package:markpro_plus/widgets/mid2_marks_table.dart';
import 'package:markpro_plus/widgets/final_mid_marks_table.dart';
import 'package:markpro_plus/widgets/import_mid1_dialog.dart';
import 'package:markpro_plus/widgets/import_mid2_dialog.dart';

class MidSessionDetailsScreen extends StatefulWidget {
  final MidSession midSession;
  final int? initialTabIndex;
  
  const MidSessionDetailsScreen({
    Key? key, 
    required this.midSession,
    this.initialTabIndex,
  }) : super(key: key);
  
  @override
  State<MidSessionDetailsScreen> createState() => _MidSessionDetailsScreenState();
}

class _MidSessionDetailsScreenState extends State<MidSessionDetailsScreen> with SingleTickerProviderStateMixin {
  final MidService _midService = MidService();
  final StudentService _studentService = StudentService();
  final ExportService _exportService = ExportService();
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  // Data
  late MidSession midSession;
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize midSession
    midSession = widget.midSession;
    
    // Initialize tab controller with 3 tabs (Mid 1, Mid 2, Final Mid)
    _tabController = TabController(length: 3, vsync: this);
    
    // Set initial tab if specified
    if (widget.initialTabIndex != null) {
      _tabController.index = widget.initialTabIndex!;
    }
    
    _fetchStudents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch student details for all roll numbers in mid session
      final studentMap = <String, StudentModel>{};
      
      for (final studentId in midSession.students) {
        try {
          final student = await _studentService.getStudentByRollNo(
            studentId, 
            midSession.branch, 
            midSession.year, 
            midSession.section,
          );
          if (student != null) {
            studentMap[studentId] = student;
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }
      
      setState(() {
        _students = studentMap.values.toList();
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
  
  Future<void> _refreshMidSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedSession = await _midService.getMidSession(midSession.id);
      setState(() {
        midSession = updatedSession;
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
            content: Text('Error refreshing mid session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _calculateFinalMidMarks() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate Final Mid Marks'),
        content: const Text('This will calculate the final mid marks as the average of Mid 1 and Mid 2 marks, rounded up. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _midService.calculateAndSaveFinalMidMarks(midSession.id);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Final mid marks calculated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshMidSession();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating final mid marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _exportMid1Marks() async {
    await _exportService.exportMid1Marks(
      midSession: midSession,
      students: _students,
    );
  }
  
  Future<void> _exportMid2Marks() async {
    await _exportService.exportMid2Marks(
      midSession: midSession,
      students: _students,
    );
  }
  
  Future<void> _exportFinalMidMarks() async {
    await _exportService.exportFinalMidMarks(
      midSession: midSession,
      students: _students,
    );
  }
  
  Future<void> _exportAllMidMarks() async {
    await _exportService.exportAllMidMarks(
      midSession: midSession,
      students: _students,
    );
  }
  
  // Show import dialog for Mid 1 marks
  void _showImportMid1Dialog() {
    showDialog(
      context: context,
      builder: (context) => ImportMid1Dialog(
        midSession: midSession,
        onImportComplete: _refreshMidSession,
      ),
    );
  }
  
  // Show import dialog for Mid 2 marks
  void _showImportMid2Dialog() {
    showDialog(
      context: context,
      builder: (context) => ImportMid2Dialog(
        midSession: midSession,
        onImportComplete: _refreshMidSession,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(midSession.subjectName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mid 1 Marks'),
            Tab(text: 'Mid 2 Marks'),
            Tab(text: 'Final Mid Marks'),
          ],
        ),
        actions: [
          // Export button with dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Marks',
            onSelected: (value) {
              switch (value) {
                case 'mid1':
                  _exportMid1Marks();
                  break;
                case 'mid2':
                  _exportMid2Marks();
                  break;
                case 'final':
                  _exportFinalMidMarks();
                  break;
                case 'all':
                  _exportAllMidMarks();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mid1',
                child: Text('Export Mid 1 Marks'),
              ),
              const PopupMenuItem(
                value: 'mid2',
                child: Text('Export Mid 2 Marks'),
              ),
              const PopupMenuItem(
                value: 'final',
                child: Text('Export Final Mid Marks'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('Export All Marks'),
              ),
            ],
          ),
          // Calculate button moved to the Final Mid tab
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshMidSession,
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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Mid 1 Marks
                            Column(
                              children: [
                                // Export & Import Buttons
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _exportMid1Marks,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Export'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: _showImportMid1Dialog,
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
                                
                                // Mid 1 Marks Table
                                Expanded(
                                  child: Mid1MarksTable(
                                    midSession: midSession,
                                    students: _students,
                                    onMarksSaved: _refreshMidSession,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Tab 2: Mid 2 Marks
                            Column(
                              children: [
                                // Export & Import Buttons
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _exportMid2Marks,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Export'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: _showImportMid2Dialog,
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('Import'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Mid 2 Marks Table
                                Expanded(
                                  child: Mid2MarksTable(
                                    midSession: midSession,
                                    students: _students,
                                    onMarksSaved: _refreshMidSession,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Tab 3: Final Mid Marks
                            Column(
                              children: [
                                // Export Button
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _calculateFinalMidMarks,
                                        icon: const Icon(Icons.calculate),
                                        label: const Text('Calculate Final Marks'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _exportFinalMidMarks,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Export Final Marks'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Final Mid Marks Table
                                Expanded(
                                  child: FinalMidMarksTable(
                                    midSession: midSession,
                                    students: _students,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.class_, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Class: ${midSession.branch} - ${midSession.year} - ${midSession.section}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Students: ${_students.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Mid 1', 'Desc (20) + Obj (10) = 30'),
                ),
                Expanded(
                  child: _buildInfoItem('Mid 2', 'Desc (20) + Obj (10) = 30'),
                ),
                Expanded(
                  child: _buildInfoItem('Final Mid', 'Average of Mid 1 & Mid 2'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
