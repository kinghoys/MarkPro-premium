import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/lab_service.dart';
import 'package:markpro_plus/services/export_service_fixed.dart' as export_service;
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:excel/excel.dart' as excel;

class LabSessionsScreen extends StatefulWidget {
  const LabSessionsScreen({Key? key}) : super(key: key);

  @override
  _LabSessionsScreenState createState() => _LabSessionsScreenState();
}

class _LabSessionsScreenState extends State<LabSessionsScreen> {
  final LabService _labService = LabService();
  List<LabSession> _labSessions = [];
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
    _fetchLabSessions();
  }

  Future<void> _fetchLabSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _labService.getLabSessions();
      setState(() {
        _labSessions = sessions;
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
            content: Text('Error loading lab sessions: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<LabSession> get filteredLabSessions {
    return _labSessions.where((lab) {
      // Apply text search
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final matchesSubject = lab.subjectName.toLowerCase().contains(query);
        final matchesBranch = lab.branch.toLowerCase().contains(query);
        final matchesYear = lab.year.toLowerCase().contains(query);
        final matchesSection = lab.section.toLowerCase().contains(query);
        
        if (!(matchesSubject || matchesBranch || matchesYear || matchesSection)) {
          return false;
        }
      }
      
      // Apply filters
      if (filterBranch != null && lab.branch != filterBranch) return false;
      if (filterYear != null && lab.year != filterYear) return false;
      if (filterSection != null && lab.section != filterSection) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLabSessions,
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
                    : filteredLabSessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No lab sessions found. Create a new lab session to get started.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _navigateToCreateLabSession,
                                  child: const Text('Create Lab Session'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredLabSessions.length,
                            itemBuilder: (context, index) {
                              final lab = filteredLabSessions[index];
                              return _buildLabSessionCard(lab);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateLabSession,
        tooltip: 'Create Lab Session',
        child: const Icon(Icons.add),
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
              hintText: 'Search lab sessions...',
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
        for (final lab in _labSessions) {
          values.add(lab.branch);
        }
        break;
      case 'year':
        for (final lab in _labSessions) {
          values.add(lab.year);
        }
        break;
      case 'section':
        for (final lab in _labSessions) {
          values.add(lab.section);
        }
        break;
    }
    
    return values.toList()..sort();
  }

  Widget _buildLabSessionCard(LabSession lab) {
    // Check assessment status
    final bool m1Completed = lab.m1Marks.isNotEmpty;
    final bool m2Completed = lab.m2Marks.isNotEmpty;
    final bool vivaCompleted = lab.vivaMarks.isNotEmpty;
    final bool finalGradesCompleted = lab.finalLabMarks.isNotEmpty;
    
    // Calculate number of experiments with marks
    int experimentsWithMarks = 0;
    for (var i = 1; i <= lab.numberOfExperiments; i++) {
      // Check if any student has marks for this experiment
      bool hasMarks = false;
      for (var studentId in lab.students) {
        final marks = lab.getExperimentMarks(studentId, i.toString());
        if (marks != null) {
          hasMarks = true;
          break;
        }
      }
      if (hasMarks) experimentsWithMarks++;
    }
    
    // No need to calculate percentage as we show fraction directly
    
    // Format the last updated time
    final lastUpdated = lab.updatedAt;
    final formatter = DateFormat('MMM d, yyyy h:mm a');
    final lastUpdatedText = 'Last updated: ${formatter.format(lastUpdated)}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToLabSession(lab),
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
                    : vivaCompleted 
                        ? Colors.amber.withOpacity(0.1) 
                        : m1Completed || m2Completed 
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
                      lab.subjectName,
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
                              : vivaCompleted 
                                  ? Colors.amber[100] 
                                  : Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          finalGradesCompleted 
                              ? 'Final Grades Complete' 
                              : vivaCompleted 
                                  ? 'Viva Complete' 
                                  : m1Completed && m2Completed 
                                      ? 'M1/M2 Complete' 
                                      : 'In Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: finalGradesCompleted 
                                ? Colors.purple[800] 
                                : vivaCompleted 
                                    ? Colors.amber[800] 
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditLabDialog(lab);
                          } else if (value == 'export') {
                            _showExportAllDialog(lab);
                          } else if (value == 'import') {
                            _showImportAllDialog(lab);
                          } else if (value == 'delete') {
                            // Show delete confirmation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Lab Session'),
                                content: const Text(
                                    'Are you sure you want to delete this lab session? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await _labService.deleteLabSession(lab.id);
                                        Navigator.pop(context);
                                        _fetchLabSessions();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Lab session deleted successfully')),
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
                    '${lab.branch} | ${lab.year} Year | Section ${lab.section}',
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
                    'Academic Year: ${lab.subjectId.split('_').lastOrNull ?? 'Current'}',
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
                    '${lab.students.length} Students',
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
                  Icon(Icons.science, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${lab.numberOfExperiments} Experiments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Import/Export and completion indicator in a single row
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Import All button - smaller and more compact
                  InkWell(
                    onTap: () => _showImportAllDialog(lab),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_file, color: Colors.teal, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Import',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Export All button - smaller and more compact
                  InkWell(
                    onTap: () => _showExportAllDialog(lab),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.deepOrange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Experiments completed indicator
                  Text(
                    '$experimentsWithMarks/${lab.numberOfExperiments} completed',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: lab.numberOfExperiments > 0 
                      ? experimentsWithMarks / lab.numberOfExperiments 
                      : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    experimentsWithMarks == lab.numberOfExperiments 
                        ? Colors.green 
                        : Colors.blue,
                  ),
                  minHeight: 6,
                ),
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
                        label: 'M1',
                        completed: m1Completed,
                      ),
                      _buildStatusChip(
                        label: 'M2',
                        completed: m2Completed,
                      ),
                      _buildStatusChip(
                        label: 'Viva',
                        completed: vivaCompleted,
                        color: Colors.amber,
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
                      label: 'Edit Details',
                      onTap: () => _showEditLabDialog(lab),
                      color: Colors.blue,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.calculate,
                      label: 'Calculate M1/M2',
                      onTap: () => _navigateToLabSessionTab(lab, 2), // Index 2 for M1/M2 Results tab
                      color: Colors.green,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.edit_note,
                      label: 'Enter Marks',
                      onTap: () => _navigateToLabSessionTab(lab, 0), // Index 0 for Experiment Marks tab
                      color: Colors.orange,
                      showRightBorder: true,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.assessment,
                      label: 'Final Assessment',
                      onTap: () => _navigateToLabSessionTab(lab, 3), // Index 3 for Final Assessment tab
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

  void _navigateToCreateLabSession() {
    Navigator.pushNamed(context, '/create-lab-session').then((_) {
      _fetchLabSessions();
    });
  }

  void _navigateToLabSession(LabSession lab) {
    Navigator.pushNamed(
      context,
      '/lab-marks-entry',
      arguments: lab,
    ).then((_) {
      _fetchLabSessions();
    });
  }
  
  // Navigate to a specific tab in the lab marks entry screen
  void _navigateToLabSessionTab(LabSession lab, int tabIndex) {
    // Use a simpler approach - navigate to the specific route for each tab
    String route;
    
    switch (tabIndex) {
      case 0:
        route = '/lab-marks-entry/experiments';
        break;
      case 1:
        route = '/lab-marks-entry/internal';
        break;
      case 2:
        route = '/lab-marks-entry/results';
        break;
      case 3:
        route = '/lab-marks-entry/final';
        break;
      default:
        route = '/lab-marks-entry';
    }
    
    Navigator.pushNamed(
      context,
      route,
      arguments: lab,
    ).then((_) {
      _fetchLabSessions();
    });
  }
  
  // Build a quick action button for the card
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Show dialog to edit lab session details
  // Show dialog for Export All functionality
  void _showExportAllDialog(LabSession lab) async {
    final exportService = export_service.ExportService();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Convert student IDs to StudentModel objects
      // We need to fetch the actual student data from Firebase
      final List<StudentModel> studentModels = [];
      
      // For each student ID in the lab session
      for (final studentId in lab.students) {
        // Create a StudentModel with the available information
        // Since we don't have access to the full student data, we'll create minimal objects
        studentModels.add(StudentModel(
          id: studentId,
          name: studentId, // Using ID as name since we don't have the actual name
          rollNo: studentId, // Using ID as roll number
          branch: lab.branch,
          year: int.tryParse(lab.year) ?? 1,
          semester: 1, // Default value
          section: lab.section,
          academicYear: '${DateTime.now().year}-${DateTime.now().year + 1}',
        ));
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Show options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export All Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will export a comprehensive file with all marks data including:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('All experiment marks (A, B, C components)'),
              _buildBulletPoint('Internal assessment marks'),
              _buildBulletPoint('M1 and M2 marks'),
              _buildBulletPoint('Viva marks'),
              _buildBulletPoint('Final lab assessment results'),
              const SizedBox(height: 12),
              Text(
                'The export will be saved as an Excel file.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Export all experiments, which includes all marks data
                exportService.exportAllExperimentMarks(
                  labSession: lab,
                  students: studentModels,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export completed!')),
                );
              },
              child: const Text('Export'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  // Show dialog for Import All functionality
  void _showImportAllDialog(LabSession lab) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose what data to import:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // New option: Import All from a single file
            _buildImportButton(
              label: 'Import All',
              description: 'Import experiment, internal and viva marks from a single file',
              icon: Icons.upload_file,
              onTap: () {
                Navigator.pop(context);
                _showImportAllFromSingleFileDialog(lab);
              },
              highlight: true,
            ),
            const Divider(height: 24),
            Text(
              'Or import specific data:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            _buildImportButton(
              label: 'Experiment Marks',
              description: 'Import component A, B, C marks for all experiments',
              icon: Icons.science,
              onTap: () {
                Navigator.pop(context);
                _navigateToLabSessionTab(lab, 4); // Assuming 4 is the import tab index
              },
            ),
            const SizedBox(height: 12),
            _buildImportButton(
              label: 'Internal Assessment Marks',
              description: 'Import Internal 1 and Internal 2 marks',
              icon: Icons.assessment,
              onTap: () {
                Navigator.pop(context);
                // Add navigation to internal marks import
                _navigateToLabSessionTab(lab, 1); // Assuming 1 is internal tab
              },
            ),
            const SizedBox(height: 12),
            _buildImportButton(
              label: 'Viva Marks',
              description: 'Import viva marks for final assessment',
              icon: Icons.record_voice_over,
              onTap: () {
                Navigator.pop(context);
                _navigateToLabSessionTab(lab, 3); // Final assessment tab
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
  
  // Dialog for importing all marks from a single file
  void _showImportAllFromSingleFileDialog(LabSession lab) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import All Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will allow you to import key marks data from an Excel file similar to the one created with Export All:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Experiment marks (A, B, C components)'),
            _buildBulletPoint('Internal assessment marks (Internal 1, Internal 2)'),
            _buildBulletPoint('Viva marks'),
            const SizedBox(height: 12),
            Text(
              'Note: M1, M2 marks and Final Grades will not be imported as these are calculated values.',
              style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              'The Excel file should match the format used by Export All.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Use FilePicker to select an Excel file
              _pickAndImportFile(lab);
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  // Method to pick a file and import the data
  Future<void> _pickAndImportFile(LabSession lab) async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });
      
      // Use FilePicker to select an Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'Select Excel File with Marks Data',
        withData: true, // Request file bytes
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      if (result != null && result.files.first.bytes != null) {
        // File selected with data
        final file = result.files.first;
        final fileName = file.name;
        final bytes = file.bytes!;
        
        // Create a variable to track the current sheet being processed
        String processingText = 'Initializing import process...';
        
        // Show processing dialog with progress information
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Processing'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Importing data from $fileName...'),
                    const SizedBox(height: 12),
                    Text(
                      processingText,
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        
        // Process all sheets
        try {
          // Stats tracking
          int experimentsProcessed = 0;
          bool internalMarksProcessed = false;
          bool vivaMarksProcessed = false;
          int totalStudentsProcessed = 0;
          int totalMarksImported = 0;
          Map<String, List<String>> errors = {};
          
          // Parse Excel file
          final excelFile = excel.Excel.decodeBytes(bytes);
          
          // Helper to update dialog text
          void updateProcessingText(String text) {
            setState(() {
              processingText = text;
            });
          }
          
          // Process experiment sheets
          for (int i = 1; i <= lab.numberOfExperiments; i++) {
            final experimentNumber = i.toString();
            final sheetName = 'Experiment $experimentNumber';
            
            updateProcessingText('Processing $sheetName sheet...');
            await Future.delayed(const Duration(milliseconds: 100));
            
            if (excelFile.tables.containsKey(sheetName)) {
              final sheet = excelFile.tables[sheetName];
              
              if (sheet != null) {
                // Find column indices from the header row
                int studentIdCol = -1;
                int compACol = -1;
                int compBCol = -1;
                int compCCol = -1;
                
                // First, get the header row
                final headerRow = sheet.rows[0];
                
                // Iterate through cells in header row to find column indices
                for (int col = 0; col < headerRow.length; col++) {
                  final cell = headerRow[col];
                  if (cell != null && cell.value != null) {
                    final headerText = cell.value.toString().trim();
                    if (headerText == 'Student ID') studentIdCol = col;
                    if (headerText == 'Component A') compACol = col;
                    if (headerText == 'Component B') compBCol = col;
                    if (headerText == 'Component C') compCCol = col;
                  }
                }
                
                // Check if required columns are found
                if (studentIdCol >= 0 && compACol >= 0 && compBCol >= 0 && compCCol >= 0) {
                  // Process each row (skip header)
                  int rowsProcessed = 0;
                  
                  for (int row = 1; row < sheet.rows.length; row++) {
                    final rowData = sheet.rows[row];
                    
                    // Check if row has data and student ID column is in range
                    if (rowData.length > studentIdCol && rowData[studentIdCol] != null && rowData[studentIdCol]!.value != null) {
                      final studentId = rowData[studentIdCol]!.value.toString().trim();
                      
                      // Check if student ID exists in the lab
                      if (lab.students.contains(studentId)) {
                        // Safely access marks data
                        int markA = 0;
                        int markB = 0;
                        int markC = 0;
                        
                        if (rowData.length > compACol && rowData[compACol] != null) {
                          markA = _parseIntCellValue(rowData[compACol]!);
                        }
                        
                        if (rowData.length > compBCol && rowData[compBCol] != null) {
                          markB = _parseIntCellValue(rowData[compBCol]!);
                        }
                        
                        if (rowData.length > compCCol && rowData[compCCol] != null) {
                          markC = _parseIntCellValue(rowData[compCCol]!);
                        }
                        
                        // Save experiment marks
                        try {
                          await _labService.saveExperimentMarks(
                            labSessionId: lab.id,
                            studentId: studentId,
                            experimentNumber: experimentNumber,
                            markA: markA,
                            markB: markB,
                            markC: markC,
                          );
                          
                          rowsProcessed++;
                          totalMarksImported += 3; // Count A, B, C as separate marks
                        } catch (err) {
                          errors.putIfAbsent(sheetName, () => []).add('Error saving marks for student $studentId: $err');
                        }
                      } else {
                        errors.putIfAbsent(sheetName, () => []).add('Student ID $studentId not found in lab');
                      }
                    }
                  }
                  
                  if (rowsProcessed > 0) {
                    experimentsProcessed++;
                    totalStudentsProcessed += rowsProcessed;
                  }
                } else {
                  // Required columns not found
                  errors.putIfAbsent(sheetName, () => []).add(
                    'Missing required columns. Found: ' +
                    (studentIdCol >= 0 ? 'Student ID, ' : '') +
                    (compACol >= 0 ? 'Component A, ' : '') +
                    (compBCol >= 0 ? 'Component B, ' : '') +
                    (compCCol >= 0 ? 'Component C' : '')
                  );
                }
              }
            } else {
              errors.putIfAbsent('Missing Sheets', () => []).add('Sheet "$sheetName" not found in Excel file');
            }
          }
          
          // Process Internal Marks sheet
          updateProcessingText('Processing Internal Marks sheet...');
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (excelFile.tables.containsKey('Internal Marks')) {
            final sheet = excelFile.tables['Internal Marks'];
            
            if (sheet != null) {
              // Find column indices from the header row
              int studentIdCol = -1;
              int internal1Col = -1;
              int internal2Col = -1;
              
              // First, get the header row
              final headerRow = sheet.rows[0];
              
              // Iterate through cells in header row to find column indices
              for (int col = 0; col < headerRow.length; col++) {
                final cell = headerRow[col];
                if (cell != null && cell.value != null) {
                  final headerText = cell.value.toString().trim();
                  if (headerText == 'Student ID') studentIdCol = col;
                  if (headerText == 'Internal 1') internal1Col = col;
                  if (headerText == 'Internal 2') internal2Col = col;
                }
              }
              
              // Check if required columns are found
              if (studentIdCol >= 0 && (internal1Col >= 0 || internal2Col >= 0)) {
                // Process each row (skip header)
                int rowsProcessed = 0;
                
                for (int row = 1; row < sheet.rows.length; row++) {
                  final rowData = sheet.rows[row];
                  
                  // Check if row has data and student ID column is in range
                  if (rowData.length > studentIdCol && rowData[studentIdCol] != null && rowData[studentIdCol]!.value != null) {
                    final studentId = rowData[studentIdCol]!.value.toString().trim();
                    
                    // Check if student ID exists in the lab
                    if (lab.students.contains(studentId)) {
                      // Process Internal 1 if column exists
                      if (internal1Col >= 0 && rowData.length > internal1Col && rowData[internal1Col] != null) {
                        int mark = _parseIntCellValue(rowData[internal1Col]!);
                        
                        try {
                          await _labService.saveInternalMarks(
                            labSessionId: lab.id,
                            studentId: studentId,
                            internalNumber: '1',
                            mark: mark,
                          );
                          
                          totalMarksImported++;
                        } catch (err) {
                          errors.putIfAbsent('Internal Marks', () => []).add('Error saving Internal 1 for student $studentId: $err');
                        }
                      }
                      
                      // Process Internal 2 if column exists
                      if (internal2Col >= 0 && rowData.length > internal2Col && rowData[internal2Col] != null) {
                        int mark = _parseIntCellValue(rowData[internal2Col]!);
                        
                        try {
                          await _labService.saveInternalMarks(
                            labSessionId: lab.id,
                            studentId: studentId,
                            internalNumber: '2',
                            mark: mark,
                          );
                          
                          totalMarksImported++;
                        } catch (err) {
                          errors.putIfAbsent('Internal Marks', () => []).add('Error saving Internal 2 for student $studentId: $err');
                        }
                      }
                      
                      rowsProcessed++;
                    } else {
                      errors.putIfAbsent('Internal Marks', () => []).add('Student ID $studentId not found in lab');
                    }
                  }
                }
                
                if (rowsProcessed > 0) {
                  internalMarksProcessed = true;
                }
              } else {
                errors.putIfAbsent('Internal Marks', () => []).add('Missing required columns');
              }
            }
          }
          
          // Process Viva Marks / Final Assessment sheet
          updateProcessingText('Processing Viva Marks sheet...');
          await Future.delayed(const Duration(milliseconds: 100));
          
          final vivaSheetNames = ['Viva Marks', 'Final Assessment'];
          bool vivaSheetFound = false;
          
          for (final sheetName in vivaSheetNames) {
            if (excelFile.tables.containsKey(sheetName)) {
              vivaSheetFound = true;
              final sheet = excelFile.tables[sheetName];
              
              if (sheet != null) {
                // Find column indices from the header row
                int studentIdCol = -1;
                int vivaCol = -1;
                
                // First, get the header row
                final headerRow = sheet.rows[0];
                
                // Iterate through cells in header row to find column indices
                for (int col = 0; col < headerRow.length; col++) {
                  final cell = headerRow[col];
                  if (cell != null && cell.value != null) {
                    final headerText = cell.value.toString().trim();
                    if (headerText == 'Student ID') studentIdCol = col;
                    if (headerText == 'Viva Marks') vivaCol = col;
                  }
                }
                
                // Check if required columns are found
                if (studentIdCol >= 0 && vivaCol >= 0) {
                  // Process each row (skip header)
                  int rowsProcessed = 0;
                  
                  for (int row = 1; row < sheet.rows.length; row++) {
                    final rowData = sheet.rows[row];
                    
                    // Check if row has data and student ID column is in range
                    if (rowData.length > studentIdCol && rowData[studentIdCol] != null && rowData[studentIdCol]!.value != null) {
                      final studentId = rowData[studentIdCol]!.value.toString().trim();
                      
                      // Check if student ID exists in the lab
                      if (lab.students.contains(studentId)) {
                        // Safely access viva marks
                        int mark = 0;
                        if (rowData.length > vivaCol && rowData[vivaCol] != null) {
                          mark = _parseIntCellValue(rowData[vivaCol]!);
                        }
                        
                        try {
                          await _labService.saveVivaMarks(
                            labSessionId: lab.id,
                            studentId: studentId,
                            vivaMarks: mark,
                          );
                          
                          rowsProcessed++;
                          totalMarksImported++;
                        } catch (err) {
                          errors.putIfAbsent(sheetName, () => []).add('Error saving Viva marks for student $studentId: $err');
                        }
                      } else {
                        errors.putIfAbsent(sheetName, () => []).add('Student ID $studentId not found in lab');
                      }
                    }
                  }
                  
                  if (rowsProcessed > 0) {
                    vivaMarksProcessed = true;
                  }
                } else {
                  errors.putIfAbsent(sheetName, () => []).add('Missing required columns');
                }
              }
              
              // We only need to process one viva sheet
              break;
            }
          }
          
          if (!vivaSheetFound) {
            // Not necessarily an error
            print('No Viva Marks sheet found in Excel file');
          }
          
          // Finalize import
          updateProcessingText('Finalizing import...');
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (!mounted) return;
          Navigator.of(context).pop(); // Close processing dialog
          
          // Show success/results dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                errors.isEmpty ? 'Import Successful' : 'Import Completed with Issues',
                style: TextStyle(
                  color: errors.isEmpty ? Colors.green : Colors.orange,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Imported data from:'),
                    const SizedBox(height: 8),
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text('Import Summary:'),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Experiments processed: $experimentsProcessed of ${lab.numberOfExperiments}'),
                    _buildBulletPoint('Internal marks: ${internalMarksProcessed ? "Processed" : "Not processed"}'),
                    _buildBulletPoint('Viva marks: ${vivaMarksProcessed ? "Processed" : "Not processed"}'),
                    _buildBulletPoint('Total marks imported: $totalMarksImported'),
                    _buildBulletPoint('Students processed: $totalStudentsProcessed'),
                    
                    if (errors.isNotEmpty) ...[  
                      const SizedBox(height: 16),
                      Text(
                        'Issues encountered:',
                        style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...errors.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...entry.value.map((error) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text('• $error', style: TextStyle(fontSize: 12, color: Colors.red[800])),
                          )),
                          const SizedBox(height: 8),
                        ],
                      )).toList(),
                    ],
                    
                    const SizedBox(height: 12),
                    Text(
                      'Note: M1, M2 and Final Grades are calculated values and were not imported.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Refresh the lab sessions list
                    _fetchLabSessions();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          
        } catch (e) {
          // Handle Excel processing errors
          if (mounted) {
            Navigator.of(context).pop(); // Close processing dialog
            
            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Error'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Failed to process the Excel file:'),
                    const SizedBox(height: 8),
                    Text('$e', style: TextStyle(color: Colors.red)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          print('Error processing Excel file: $e');
        }
      } else {
        // No file selected or no bytes in file
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected or file has no data')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Helper to parse cell values to integers
  int _parseIntCellValue(excel.Data cell) {
    if (cell.value == null) return 0;
    
    if (cell.value is int) {
      return cell.value as int;
    } else if (cell.value is double) {
      return (cell.value as double).round();
    } else {
      try {
        return int.parse(cell.value.toString());
      } catch (e) {
        return 0;
      }
    }
  }
  
  // Helper to build import buttons
  Widget _buildImportButton({
    required String label,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: highlight ? Colors.blue.shade300 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: highlight ? Colors.blue.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: highlight ? Colors.blue : Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 16,
                      color: highlight ? Colors.blue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  // Helper to build bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
  
  void _showEditLabDialog(LabSession lab) {
    // Controllers for editable fields
    final subjectNameController = TextEditingController(text: lab.subjectName);
    final branchController = TextEditingController(text: lab.branch);
    final yearController = TextEditingController(text: lab.year);
    final sectionController = TextEditingController(text: lab.section);
    final experimentsController = TextEditingController(text: lab.numberOfExperiments.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Lab Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 12),
              TextField(
                controller: experimentsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Experiments',
                ),
                keyboardType: TextInputType.number,
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
              final newExperiments = int.tryParse(experimentsController.text.trim()) ?? lab.numberOfExperiments;
              
              if (newSubjectName.isEmpty || newBranch.isEmpty || 
                  newYear.isEmpty || newSection.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              // Update lab session
              try {
                setState(() => _isLoading = true);
                
                // Create updated lab session
                final updatedLab = lab.copyWith(
                  subjectName: newSubjectName,
                  branch: newBranch,
                  year: newYear,
                  section: newSection,
                  numberOfExperiments: newExperiments,
                );
                
                // Save to database
                await _labService.updateLabSession(updatedLab);
                
                // Close dialog
                if (mounted) Navigator.pop(context);
                
                // Refresh data
                _fetchLabSessions();
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lab details updated successfully')),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating lab details: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
