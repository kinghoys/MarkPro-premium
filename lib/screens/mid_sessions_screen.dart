import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/mid_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/services/export_service_fixed.dart';
import 'package:markpro_plus/widgets/import_all_mid_dialog.dart';
import 'package:markpro_plus/widgets/hover_card.dart';
import 'dart:async';
import 'package:markpro_plus/screens/create_mid_session_screen.dart';
import 'package:markpro_plus/screens/mid_session_details_screen.dart';

class MidSessionsScreen extends StatefulWidget {
  const MidSessionsScreen({Key? key}) : super(key: key);

  @override
  _MidSessionsScreenState createState() => _MidSessionsScreenState();
}

class _MidSessionsScreenState extends State<MidSessionsScreen> {
  final MidService _midService = MidService();
  final StudentService _studentService = StudentService();
  final ExportService _exportService = ExportService();
  List<MidSession> _midSessions = [];
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
    _fetchMidSessions();
  }

  Future<void> _fetchMidSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _midService.getMidSessions();
      setState(() {
        _midSessions = sessions;
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
            content: Text('Error loading mid sessions: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<MidSession> get filteredMidSessions {
    return _midSessions.where((mid) {
      // Apply text search
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        final matchesSubject = mid.subjectName.toLowerCase().contains(query);
        final matchesBranch = mid.branch.toLowerCase().contains(query);
        final matchesYear = mid.year.toLowerCase().contains(query);
        final matchesSection = mid.section.toLowerCase().contains(query);
        
        if (!(matchesSubject || matchesBranch || matchesYear || matchesSection)) {
          return false;
        }
      }
      
      // Apply filters
      if (filterBranch != null && mid.branch != filterBranch) return false;
      if (filterYear != null && mid.year != filterYear) return false;
      if (filterSection != null && mid.section != filterSection) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mid Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMidSessions,
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
                    : filteredMidSessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'No mid sessions found. Create a new mid session to get started.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreateMidSession,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Mid Session'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMidSessions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredMidSessions.length,
                              itemBuilder: (context, index) {
                                return _buildMidSessionCard(filteredMidSessions[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateMidSession,
        child: const Icon(Icons.add),
        tooltip: 'Create Mid Session',
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
              hintText: 'Search mid sessions...',
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
        for (final mid in _midSessions) {
          values.add(mid.branch);
        }
        break;
      case 'year':
        for (final mid in _midSessions) {
          values.add(mid.year);
        }
        break;
      case 'section':
        for (final mid in _midSessions) {
          values.add(mid.section);
        }
        break;
    }
    
    return values.toList()..sort();
  }

  Widget _buildMidSessionCard(MidSession mid) {
    final totalStudents = mid.students.length;
    final studentsWithMarks = (mid.mid1Marks.keys.length + mid.mid2Marks.keys.length) > 0 ? mid.mid1Marks.keys.length : 0;
    final completionPercentage = totalStudents > 0 
        ? (studentsWithMarks / totalStudents * 100).toStringAsFixed(0)
        : '0';
        
    return HoverCard(
      onTap: () => _navigateToMidSession(mid),
      elevation: 2,
      hoverElevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      hoverShadowColor: Colors.purple.withOpacity(0.4),
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: BorderRadius.circular(12),
      useTranslation: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6), // Purple
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
                        mid.subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mid.branch} - ${mid.year} - ${mid.section}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        '$completionPercentage%',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditMidDialog(mid);
                        } else if (value == 'export') {
                          _showExportDialog(mid);
                        } else if (value == 'import') {
                          _showImportDialog(mid);
                        } else if (value == 'delete') {
                          // Show delete confirmation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Mid Session'),
                              content: const Text(
                                  'Are you sure you want to delete this mid session? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await _midService.deleteMidSession(mid.id);
                                      Navigator.pop(context);
                                      _fetchMidSessions();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Mid session deleted successfully')),
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
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics
                Row(
                  children: [
                    _buildInfoItem(
                      icon: Icons.people,
                      title: 'Students',
                      value: '$totalStudents',
                    ),
                    _buildInfoItem(
                      icon: Icons.assignment_turned_in,
                      title: 'Marks Entered',
                      value: '$studentsWithMarks',
                    ),
                    _buildInfoItem(
                      icon: Icons.calendar_today,
                      title: 'Updated',
                      value: DateFormat('MMM d, yyyy').format(mid.updatedAt),
                    ),
                  ],
                ),
                
                const Divider(height: 32),
                
                // Actions with grid lines
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
                        label: 'Enter Marks',
                        onTap: () => _navigateToMidSession(mid),
                        color: Colors.blue,
                        showRightBorder: true,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.file_download,
                        label: 'Export',
                        onTap: () => _showExportDialog(mid),
                        color: Colors.green,
                        showRightBorder: true,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.file_upload,
                        label: 'Import All',
                        onTap: () => _showImportDialog(mid),
                        color: Colors.amber,
                        showRightBorder: true,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.edit_note,
                        label: 'Edit Details',
                        onTap: () => _showEditMidDialog(mid),
                        color: Colors.orange,
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
  
  Future<void> _showImportDialog(MidSession midSession) async {
    showDialog(
      context: context,
      builder: (context) => ImportAllMidDialog(
        midSession: midSession,
        onImportComplete: _fetchMidSessions,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateMidSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateMidSessionScreen(),
      ),
    ).then((_) => _fetchMidSessions());
  }

  void _navigateToMidSession(MidSession mid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MidSessionDetailsScreen(midSession: mid),
      ),
    ).then((_) => _fetchMidSessions());
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

  void _showEditMidDialog(MidSession mid) {
    final subjectNameController = TextEditingController(text: mid.subjectName);
    final branchController = TextEditingController(text: mid.branch);
    final yearController = TextEditingController(text: mid.year);
    final sectionController = TextEditingController(text: mid.section);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mid Session Details'),
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
              
              // Update mid session
              try {
                setState(() => _isLoading = true);
                
                // Create updated mid session
                final updatedMid = mid.copyWith(
                  subjectName: newSubjectName,
                  branch: newBranch,
                  year: newYear,
                  section: newSection,
                );
                
                // Save to database
                await _midService.updateMidSession(updatedMid);
                
                // Close dialog
                if (mounted) Navigator.pop(context);
                
                // Refresh data
                _fetchMidSessions();
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mid session details updated successfully')),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating mid session details: $e')),
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
  
  Future<void> _showExportDialog(MidSession midSession) async {
    // Fetch students for this mid session
    List<StudentModel> students = [];
    try {
      for (final studentId in midSession.students) {
        try {
          final student = await _studentService.getStudentByRollNo(
            studentId, 
            midSession.branch, 
            midSession.year, 
            midSession.section,
          );
          if (student != null) {
            students.add(student);
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }

      // Show export options dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Export Mid 1 Marks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportService.exportMid1Marks(
                      midSession: midSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mid 1 Marks exported successfully')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('Export Mid 2 Marks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportService.exportMid2Marks(
                      midSession: midSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mid 2 Marks exported successfully')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.purple),
                  title: const Text('Export Final Mid Marks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportService.exportFinalMidMarks(
                      midSession: midSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Final Mid Marks exported successfully')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline, color: Colors.red),
                  title: const Text('Export All Marks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportService.exportAllMidMarks(
                      midSession: midSession,
                      students: students,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All Mid Marks exported successfully')),
                      );
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }
}

// The MidSessionDetailsScreen has been moved to its own file: mid_session_details_screen.dart
