import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/assignment_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/assignment_export_service.dart';
import 'package:markpro_plus/services/assignment_import_service.dart';
import 'package:markpro_plus/widgets/import_assignment1_dialog.dart';
import 'package:markpro_plus/widgets/hover_card.dart';
import 'dart:async';
import 'package:markpro_plus/screens/create_assignment_session_screen.dart';
import 'package:markpro_plus/screens/assignment_session_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentSessionsScreen extends StatefulWidget {
  const AssignmentSessionsScreen({Key? key}) : super(key: key);

  @override
  _AssignmentSessionsScreenState createState() => _AssignmentSessionsScreenState();
}

class _AssignmentSessionsScreenState extends State<AssignmentSessionsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final StudentService _studentService = StudentService();
  final AssignmentExportService _exportService = AssignmentExportService();
  List<AssignmentSession> _assignmentSessions = [];
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String? searchQuery;
  String? filterBranch;
  String? filterYear;
  String? filterSection;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchAssignmentSessions();
  }

  Future<void> _fetchAssignmentSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _assignmentService.getAssignmentSessions();
      setState(() {
        _assignmentSessions = sessions;
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
            content: Text('Error loading assignment sessions: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<AssignmentSession> get filteredAssignmentSessions {
    return _assignmentSessions.where((assignment) {
      // Apply text search
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final matchesSubject = assignment.subjectName.toLowerCase().contains(query);
        final matchesBranch = assignment.branch.toLowerCase().contains(query);
        final matchesYear = assignment.year.toLowerCase().contains(query);
        final matchesSection = assignment.section.toLowerCase().contains(query);
        
        if (!(matchesSubject || matchesBranch || matchesYear || matchesSection)) {
          return false;
        }
      }
      
      // Apply filters
      if (filterBranch != null && assignment.branch != filterBranch) return false;
      if (filterYear != null && assignment.year != filterYear) return false;
      if (filterSection != null && assignment.section != filterSection) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignmentSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Error: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : filteredAssignmentSessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _assignmentSessions.isEmpty
                                      ? 'No assignment sessions found'
                                      : 'No assignment sessions match the filters',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreateAssignmentSession,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Assignment Session'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAssignmentSessions,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListView.builder(
                                itemCount: filteredAssignmentSessions.length,
                                itemBuilder: (context, index) {
                                  final assignment = filteredAssignmentSessions[index];
                                  return _buildAssignmentSessionCard(assignment);
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: filteredAssignmentSessions.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _navigateToCreateAssignmentSession,
              tooltip: 'Create Assignment Session',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by subject, branch, year, section...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.isEmpty ? null : value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Branch Filter
                if (filterBranch != null)
                  _buildFilterChip(
                    label: 'Branch: $filterBranch',
                    value: filterBranch,
                    onSelected: (selected) {},
                    onDeleted: () {
                      setState(() => filterBranch = null);
                    },
                  )
                else
                  PopupMenuButton<String>(
                    child: Chip(
                      label: const Text('Branch'),
                      avatar: const Icon(Icons.arrow_drop_down),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    onSelected: (value) {
                      setState(() => filterBranch = value);
                    },
                    itemBuilder: (context) {
                      return _getUniqueValues('branch')
                          .map((branch) => PopupMenuItem(
                                value: branch,
                                child: Text(branch),
                              ))
                          .toList();
                    },
                  ),
                const SizedBox(width: 8),
                
                // Year Filter
                if (filterYear != null)
                  _buildFilterChip(
                    label: 'Year: $filterYear',
                    value: filterYear,
                    onSelected: (selected) {},
                    onDeleted: () {
                      setState(() => filterYear = null);
                    },
                  )
                else
                  PopupMenuButton<String>(
                    child: Chip(
                      label: const Text('Year'),
                      avatar: const Icon(Icons.arrow_drop_down),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    onSelected: (value) {
                      setState(() => filterYear = value);
                    },
                    itemBuilder: (context) {
                      return _getUniqueValues('year')
                          .map((year) => PopupMenuItem(
                                value: year,
                                child: Text(year),
                              ))
                          .toList();
                    },
                  ),
                const SizedBox(width: 8),
                
                // Section Filter
                if (filterSection != null)
                  _buildFilterChip(
                    label: 'Section: $filterSection',
                    value: filterSection,
                    onSelected: (selected) {},
                    onDeleted: () {
                      setState(() => filterSection = null);
                    },
                  )
                else
                  PopupMenuButton<String>(
                    child: Chip(
                      label: const Text('Section'),
                      avatar: const Icon(Icons.arrow_drop_down),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    onSelected: (value) {
                      setState(() => filterSection = value);
                    },
                    itemBuilder: (context) {
                      return _getUniqueValues('section')
                          .map((section) => PopupMenuItem(
                                value: section,
                                child: Text(section),
                              ))
                          .toList();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required Function(bool) onSelected,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Set<String> _getUniqueValues(String field) {
    final values = <String>{};
    
    switch (field) {
      case 'branch':
        for (final assignment in _assignmentSessions) {
          values.add(assignment.branch);
        }
        break;
      case 'year':
        for (final assignment in _assignmentSessions) {
          values.add(assignment.year);
        }
        break;
      case 'section':
        for (final assignment in _assignmentSessions) {
          values.add(assignment.section);
        }
        break;
    }
    
    return values;
  }

  Widget _buildAssignmentSessionCard(AssignmentSession assignment) {
    String createdAt = 'Unknown';
    String updatedAt = 'Unknown';
    
    // Calculate completion percentage based on marks entries
    final totalStudents = assignment.students.length;
    final studentsWithMarks = assignment.assignmentMarks.isNotEmpty ? assignment.assignmentMarks.length : 0;
    final completionPercentage = totalStudents > 0 
        ? (studentsWithMarks / totalStudents * 100).toStringAsFixed(0)
        : '0';

    try {
      if (assignment.createdAt != null) {
        if (assignment.createdAt is Timestamp) {
          createdAt = DateFormat('MMM d, yyyy').format((assignment.createdAt as Timestamp).toDate());
        } else if (assignment.createdAt is DateTime) {
          createdAt = DateFormat('MMM d, yyyy').format(assignment.createdAt as DateTime);
        }
      }
      
      if (assignment.updatedAt != null) {
        if (assignment.updatedAt is Timestamp) {
          updatedAt = DateFormat('MMM d, yyyy').format((assignment.updatedAt as Timestamp).toDate());
        } else if (assignment.updatedAt is DateTime) {
          updatedAt = DateFormat('MMM d, yyyy').format(assignment.updatedAt as DateTime);
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    // Generate a consistent color based on the subject name
    final List<Color> subjectColors = [
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF6366F1), // Indigo
    ];
    
    final colorIndex = assignment.subjectName.length % subjectColors.length;
    final headerColor = subjectColors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: HoverCard(
        onTap: () => _navigateToAssignmentSession(assignment),
        shadowColor: headerColor.withOpacity(0.1),
        hoverShadowColor: headerColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.subjectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assignment.branch} · ${assignment.year} Year · Section ${assignment.section}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Completion percentage indicator
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      '$completionPercentage%',
                      style: TextStyle(
                        color: headerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditAssignmentDialog(assignment);
                      } else if (value == 'export') {
                        _showExportDialog(assignment);
                      } else if (value == 'import') {
                        _showImportDialog(assignment);
                      } else if (value == 'delete') {
                        // Show delete confirmation
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Assignment Session'),
                            content: const Text(
                                'Are you sure you want to delete this assignment session? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await _assignmentService.deleteAssignmentSession(assignment.id);
                                    Navigator.pop(context);
                                    _fetchAssignmentSessions();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Assignment session deleted successfully')),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting session: $e')),
                                    );
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Export Marks'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.upload_file, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Import Marks'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content area with divider
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        title: 'Created',
                        value: createdAt,
                      ),
                      _buildInfoItem(
                        icon: Icons.update,
                        title: 'Last Updated',
                        value: updatedAt,
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Action Buttons with grid lines
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.visibility,
                          label: 'View Details',
                          onTap: () => _navigateToAssignmentSession(assignment),
                          color: headerColor,
                          showRightBorder: true,
                        ),
                        _buildQuickActionButton(
                          icon: Icons.download,
                          label: 'Export',
                          onTap: () => _showExportDialog(assignment),
                          color: headerColor,
                          showRightBorder: true,
                        ),
                        _buildQuickActionButton(
                          icon: Icons.upload_file,
                          label: 'Import',
                          onTap: () => _showImportDialog(assignment),
                          color: headerColor,
                          showRightBorder: true,
                        ),
                        _buildQuickActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          onTap: () => _showEditAssignmentDialog(assignment),
                          color: headerColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAssignmentDialog(AssignmentSession assignment) async {
    final subjectNameController = TextEditingController(text: assignment.subjectName);
    final branchController = TextEditingController(text: assignment.branch);
    final yearController = TextEditingController(text: assignment.year);
    final sectionController = TextEditingController(text: assignment.section);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Assignment Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectNameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate and parse inputs
              final newSubjectName = subjectNameController.text.trim();
              final newBranch = branchController.text.trim();
              final newYear = yearController.text.trim();
              final newSection = sectionController.text.trim();
              
              if (newSubjectName.isEmpty || newBranch.isEmpty || 
                  newYear.isEmpty || newSection.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              // Update assignment session
              final updatedAssignment = assignment.copyWith(
                subjectName: newSubjectName,
                branch: newBranch,
                year: newYear,
                section: newSection,
              );
              
              try {
                await _assignmentService.updateAssignmentSession(updatedAssignment);
                
                // Close dialog and refresh
                Navigator.pop(context);
                _fetchAssignmentSessions();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assignment session updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating session: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateAssignmentSession() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateAssignmentSessionScreen(),
      ),
    );
    
    // Refresh after navigating back
    _fetchAssignmentSessions();
  }

  Future<void> _navigateToAssignmentSession(AssignmentSession assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignmentSessionDetailsScreen(
          sessionId: assignment.id,
        ),
      ),
    );
    
    // Refresh after navigating back
    _fetchAssignmentSessions();
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool showRightBorder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: showRightBorder
              ? Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(AssignmentSession assignment) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.blue),
              title: const Text('Import Assignment 1 Marks'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return ImportAssignment1Dialog(
                      assignmentSession: assignment,
                      isAssignment2: false,
                      onImportComplete: () {
                        _fetchAssignmentSessions();
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.green),
              title: const Text('Import Assignment 2 Marks'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return ImportAssignment1Dialog(
                      assignmentSession: assignment,
                      isAssignment2: true,
                      onImportComplete: () {
                        _fetchAssignmentSessions();
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_rounded, color: Colors.red),
              title: const Text('Import All Marks'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  // Create an instance of the import service
                  final importService = AssignmentImportService(); // Fixed the instantiation with a proper constructor call
                  final result = await importService.importAllAssignmentMarksFromExcel(context);
                  
                  // If we got some data, process it
                  if (result.hasAssignment1Data || result.hasAssignment2Data) {
                    // Import Assignment 1 marks if available
                    if (result.hasAssignment1Data) {
                      await importService.saveImportedAssignment1Marks(
                        assignmentSessionId: assignment.id,
                        marks: result.assignment1Marks,
                      );
                    }
                    
                    // Import Assignment 2 marks if available
                    if (result.hasAssignment2Data) {
                      await importService.saveImportedAssignment2Marks(
                        assignmentSessionId: assignment.id,
                        marks: result.assignment2Marks,
                      );
                    }
                    
                    // Refresh data
                    _fetchAssignmentSessions();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(
                          'Successfully imported marks: ' +
                          (result.hasAssignment1Data ? 'Assignment 1 (${result.assignment1Marks.length} students) ' : '') +
                          (result.hasAssignment2Data ? 'Assignment 2 (${result.assignment2Marks.length} students)' : '')
                        )),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error importing marks: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }



  Future<void> _showExportDialog(AssignmentSession assignmentSession) async {
    try {
      // Fetch all students in the assignment session
      final List<StudentModel> students = [];
      
      // Get all student IDs from the session
      for (final studentId in assignmentSession.students) {
        try {
          final student = await _studentService.getStudentByRollNo(
            studentId, 
            assignmentSession.branch, 
            assignmentSession.year, 
            assignmentSession.section,
          );
          if (student != null) {
            students.add(student);
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }
      
      // Show export options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Export Assignment 1 Marks'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _exportService.exportAssignment1Marks(
                      assignmentSession: assignmentSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment 1 Marks exported successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error exporting marks: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Export Assignment 2 Marks'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _exportService.exportAssignment2Marks(
                      assignmentSession: assignmentSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment 2 Marks exported successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error exporting marks: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_for_offline, color: Colors.red),
                title: const Text('Export All Marks'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _exportService.exportAllAssignmentMarks(
                      assignmentSession: assignmentSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All Assignment Marks exported successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error exporting marks: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }
}
