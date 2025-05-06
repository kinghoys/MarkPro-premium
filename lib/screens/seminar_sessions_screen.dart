import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markpro_plus/models/seminar_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/seminar_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/export_service_fixed.dart';
import 'package:markpro_plus/screens/create_seminar_session_screen.dart';
import 'package:markpro_plus/widgets/import_seminar_marks_dialog.dart';
import 'dart:async';

class SeminarSessionsScreen extends StatefulWidget {
  const SeminarSessionsScreen({Key? key}) : super(key: key);

  @override
  _SeminarSessionsScreenState createState() => _SeminarSessionsScreenState();
}

class _SeminarSessionsScreenState extends State<SeminarSessionsScreen> {
  final SeminarService _seminarService = SeminarService();
  final StudentService _studentService = StudentService();
  final ExportService _exportService = ExportService();
  List<SeminarSession> _seminarSessions = [];
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String searchQuery = '';
  String? filterBranch;
  String? filterYear;
  String? filterSection;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchSeminarSessions();
  }

  Future<void> _fetchSeminarSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _seminarService.getSeminarSessions();
      setState(() {
        _seminarSessions = sessions;
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
            content: Text('Error loading seminar sessions: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<SeminarSession> get filteredSeminarSessions {
    return _seminarSessions.where((seminar) {
      // Apply text search
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesSubject = seminar.subjectName.toLowerCase().contains(query);
        final matchesBranch = seminar.branch.toLowerCase().contains(query);
        final matchesYear = seminar.year.toLowerCase().contains(query);
        final matchesSection = seminar.section.toLowerCase().contains(query);
        
        if (!(matchesSubject || matchesBranch || matchesYear || matchesSection)) {
          return false;
        }
      }
      
      // Apply filters
      if (filterBranch != null && seminar.branch != filterBranch) return false;
      if (filterYear != null && seminar.year != filterYear) return false;
      if (filterSection != null && seminar.section != filterSection) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seminar Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSeminarSessions,
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
                    : filteredSeminarSessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No seminar sessions found. Create a new seminar session to get started.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreateSeminarSession,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Seminar Session'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSeminarSessions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredSeminarSessions.length,
                              itemBuilder: (context, index) {
                                return _buildSeminarSessionCard(filteredSeminarSessions[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSeminarSession,
        child: const Icon(Icons.add),
        tooltip: 'Create Seminar Session',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search seminar sessions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.trim();
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Branch',
                  value: filterBranch,
                  onSelected: (selected) {
                    setState(() {
                      filterBranch = selected ? _getUniqueValues('branch').first : null;
                    });
                  },
                  onDeleted: () {
                    setState(() {
                      filterBranch = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Year',
                  value: filterYear,
                  onSelected: (selected) {
                    setState(() {
                      filterYear = selected ? _getUniqueValues('year').first : null;
                    });
                  },
                  onDeleted: () {
                    setState(() {
                      filterYear = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Section',
                  value: filterSection,
                  onSelected: (selected) {
                    setState(() {
                      filterSection = selected ? _getUniqueValues('section').first : null;
                    });
                  },
                  onDeleted: () {
                    setState(() {
                      filterSection = null;
                    });
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
    return FilterChip(
      label: Text(value ?? label),
      selected: value != null,
      onSelected: onSelected,
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: value != null ? onDeleted : null,
    );
  }

  List<String> _getUniqueValues(String field) {
    final values = <String>{};
    
    switch (field) {
      case 'branch':
        for (final seminar in _seminarSessions) {
          values.add(seminar.branch);
        }
        break;
      case 'year':
        for (final seminar in _seminarSessions) {
          values.add(seminar.year);
        }
        break;
      case 'section':
        for (final seminar in _seminarSessions) {
          values.add(seminar.section);
        }
        break;
    }
    
    return values.toList()..sort();
  }

  Widget _buildSeminarSessionCard(SeminarSession seminar) {
    // Check assessment status
    final bool presentationCompleted = seminar.presentationMarks.isNotEmpty;
    final bool reportCompleted = seminar.reportMarks.isNotEmpty;
    final bool finalGradesCompleted = seminar.finalSeminarMarks.isNotEmpty;
    
    // Format the last updated time
    final lastUpdated = seminar.updatedAt;
    final formatter = DateFormat('MMM d, yyyy h:mm a');
    final lastUpdatedText = 'Last updated: ${formatter.format(lastUpdated)}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToSeminarSession(seminar),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                finalGradesCompleted 
                    ? Colors.purple.withOpacity(0.1) 
                    : presentationCompleted && reportCompleted 
                        ? Colors.amber.withOpacity(0.1) 
                        : presentationCompleted || reportCompleted
                            ? Colors.blue.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      seminar.subjectName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: finalGradesCompleted 
                            ? Colors.purple[800] 
                            : Colors.blue[800],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: finalGradesCompleted 
                              ? Colors.purple[100] 
                              : presentationCompleted && reportCompleted 
                                  ? Colors.amber[100] 
                                  : Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          finalGradesCompleted 
                              ? 'Final Grades Complete' 
                              : presentationCompleted && reportCompleted 
                                  ? 'All Assessments Complete' 
                                  : presentationCompleted 
                                      ? 'Presentation Complete' 
                                      : reportCompleted
                                          ? 'Report Complete'
                                          : 'In Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: finalGradesCompleted 
                                ? Colors.purple[800] 
                                : presentationCompleted && reportCompleted 
                                    ? Colors.amber[800] 
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditSeminarDialog(seminar);
                          } else if (value == 'export') {
                            _navigateToSeminarSessionWithAction(seminar, 'export');
                          } else if (value == 'import') {
                            _navigateToSeminarSessionWithAction(seminar, 'import');
                          } else if (value == 'delete') {
                            // Show delete confirmation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Seminar Session'),
                                content: const Text(
                                    'Are you sure you want to delete this seminar session? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await _seminarService.deleteSeminarSession(seminar.id);
                                        Navigator.pop(context);
                                        _fetchSeminarSessions();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Seminar session deleted successfully')),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${seminar.branch} | ${seminar.year} Year | Section ${seminar.section}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Academic Year: ${seminar.subjectId.split('_').lastOrNull ?? 'Current'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${seminar.students.length} Students',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip(
                        label: 'Presentation',
                        completed: presentationCompleted,
                      ),
                      _buildStatusChip(
                        label: 'Report',
                        completed: reportCompleted,
                      ),
                      _buildStatusChip(
                        label: 'Final',
                        completed: finalGradesCompleted,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lastUpdatedText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 4),
              // Action buttons row with grid lines
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
                      icon: Icons.edit,
                      label: 'Edit',
                      onTap: () => _showEditSeminarDialog(seminar),
                      color: Colors.blue,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.download,
                      label: 'Export',
                      onTap: () => _navigateToSeminarSessionWithAction(seminar, 'export'),
                      color: Colors.green,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.upload,
                      label: 'Import',
                      onTap: () => _navigateToSeminarSessionWithAction(seminar, 'import'),
                      color: Colors.orange,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.edit_note,
                      label: 'Marks',
                      onTap: () => _navigateToSeminarSession(seminar),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required bool completed, Color? color}) {
    final displayColor = color ?? Colors.green;
    return Chip(
      label: Text(label),
      backgroundColor: completed ? displayColor.withOpacity(0.15) : Colors.grey[200],
      avatar: Icon(
        completed ? Icons.check_circle : Icons.pending,
        size: 16,
        color: completed ? displayColor : Colors.grey,
      ),
    );
  }

  void _navigateToCreateSeminarSession() {
    // Use MaterialPageRoute directly instead of named routes
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateSeminarSessionScreen(),
      ),
    ).then((_) {
      _fetchSeminarSessions();
    });
  }
  
  void _navigateToSeminarSession(SeminarSession seminarSession) {
    Navigator.pushNamed(
      context,
      '/seminar-session-details',
      arguments: seminarSession,
    ).then((_) {
      _fetchSeminarSessions();
    });
  }
  
  // Navigate to seminar session with specific action (export/import)
  void _navigateToSeminarSessionWithAction(SeminarSession seminarSession, String action) async {
    if (action == 'export') {
      try {
        setState(() {
          _isLoading = true;
        });
        
        // First load students for this session
        final students = <StudentModel>[];
        for (final studentId in seminarSession.students) {
          final student = await _studentService.getStudent(studentId);
          if (student != null) {
            students.add(student);
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        
        // Now export the marks
        if (students.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students data available to export'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        await _exportService.exportSeminarMarks(
          seminarSession: seminarSession,
          students: students,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seminar marks exported successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error exporting marks: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (action == 'import') {
      // Handle import action directly
      try {
        setState(() {
          _isLoading = true;
        });
        
        // First load students for this session
        final students = <StudentModel>[];
        for (final studentId in seminarSession.students) {
          final student = await _studentService.getStudent(studentId);
          if (student != null) {
            students.add(student);
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        
        // Show import dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ImportSeminarMarksDialog(
              seminarSession: seminarSession,
              onImportComplete: _fetchSeminarSessions,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error preparing import: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      _navigateToSeminarSession(seminarSession);
    }
  }
  
  // Show dialog to edit seminar session details
  void _showEditSeminarDialog(SeminarSession seminar) {
    // Create form controllers with the current values
    final nameController = TextEditingController(text: seminar.subjectName);
    final branchController = TextEditingController(text: seminar.branch);
    final yearController = TextEditingController(text: seminar.year);
    final sectionController = TextEditingController(text: seminar.section);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Seminar Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
              ),
              const SizedBox(height: 16),
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
          TextButton(
            onPressed: () async {
              try {
                // Validate input
                if (nameController.text.isEmpty ||
                    branchController.text.isEmpty ||
                    yearController.text.isEmpty ||
                    sectionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }
                
                // Update the session with new values
                final updatedSession = seminar.copyWith(
                  subjectName: nameController.text.trim(),
                  branch: branchController.text.trim(),
                  year: yearController.text.trim(),
                  section: sectionController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                
                // Save to database
                await _seminarService.updateSeminarSession(updatedSession);
                
                // Close dialog and refresh
                Navigator.pop(context);
                _fetchSeminarSessions();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seminar session updated successfully')),
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
  
  // Navigate to a specific tab in the seminar session details screen
  void _navigateToSeminarSessionTab(SeminarSession seminar, int tabIndex) {
    String route;
    
    switch (tabIndex) {
      case 0:
        route = '/seminar-session-details/presentation';
        break;
      case 1:
        route = '/seminar-session-details/report';
        break;
      case 2:
        route = '/seminar-session-details/final';
        break;
      default:
        route = '/seminar-session-details';
    }
    
    Navigator.pushNamed(
      context,
      route,
      arguments: seminar,
    ).then((_) {
      _fetchSeminarSessions();
    });
  }
  
  // Build a quick action button with optional right border for grid layout
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


}
