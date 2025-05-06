import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/lab_service.dart';
import 'package:markpro_plus/services/student_service.dart';
import 'package:markpro_plus/widgets/experiment_marks_table.dart';
import 'package:markpro_plus/widgets/internal_marks_table.dart';
import 'package:markpro_plus/widgets/m1_m2_results_table.dart';
import 'package:markpro_plus/widgets/final_lab_marks_table.dart';
import 'package:markpro_plus/widgets/export_options_dialog.dart';
import 'package:markpro_plus/widgets/import_m1m2_dialog.dart';
import 'package:markpro_plus/widgets/import_viva_dialog.dart';
import 'package:markpro_plus/widgets/import_marks_dialog.dart';
import 'package:markpro_plus/widgets/import_internal_dialog.dart';

class LabMarksEntryScreen extends StatefulWidget {
  final dynamic labSession;
  final int? initialTabIndex;

  const LabMarksEntryScreen({
    super.key, 
    required this.labSession,
    this.initialTabIndex,
  });

  @override
  _LabMarksEntryScreenState createState() => _LabMarksEntryScreenState();
}

class _LabMarksEntryScreenState extends State<LabMarksEntryScreen> with SingleTickerProviderStateMixin {
  final LabService _labService = LabService();
  final StudentService _studentService = StudentService();
  
  late TabController _tabController;
  bool isLoading = false;
  String? _error;
  
  // Data
  late LabSession labSession;
  List<StudentModel> students = [];
  String selectedExperiment = '1';
  
  // M1/M2 calculation
  int m1LastExperiment = 5; // Default to experiment 5 for M1
  bool m1Calculated = false;
  bool m2Calculated = false;

  @override
  void initState() {
    super.initState();
    
    // Get the lab session directly
    labSession = widget.labSession as LabSession;
    
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial tab if specified
    if (widget.initialTabIndex != null) {
      _tabController.index = widget.initialTabIndex!;
    }
    
    _fetchStudents();
    _checkCalculationStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkCalculationStatus() {
    setState(() {
      m1Calculated = labSession.m1Marks.isNotEmpty;
      m2Calculated = labSession.m2Marks.isNotEmpty;
      if (labSession.m1LastExperiment != null) {
        m1LastExperiment = labSession.m1LastExperiment!;
      }
    });
  }

  Future<void> _fetchStudents() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      // Fetch student details for all roll numbers in lab session
      final studentMap = <String, StudentModel>{};
      
      for (final studentId in labSession.students) {
        try {
          final student = await _studentService.getStudentByRollNo(
            studentId, 
            labSession.branch, 
            labSession.year, 
            labSession.section,
          );
          if (student != null) {
            studentMap[studentId] = student;
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }
      
      setState(() {
        students = studentMap.values.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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

  Future<void> _refreshLabSession() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final updatedSession = await _labService.getLabSession(labSession.id);
      if (updatedSession != null) {
        setState(() {
          labSession = updatedSession;
          isLoading = false;
        });
        _checkCalculationStatus();
      } else {
        throw Exception('Lab session not found');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing lab session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setExperimentDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (pickedDate != null) {
      try {
        await _labService.setExperimentDate(
          labSessionId: labSession.id,
          experimentNumber: selectedExperiment,
          dateOfExperiment: pickedDate,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Experiment date set successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _refreshLabSession();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting experiment date: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _calculateM1() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate M1'),
        content: Text(
          'This will calculate M1 marks based on experiments 1 to $m1LastExperiment. '
          'Are you sure you want to proceed?'
        ),
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
      isLoading = true;
    });
    
    try {
      await _labService.calculateAndSaveM1Marks(
        labSessionId: labSession.id,
        lastExperiment: m1LastExperiment,
      );
      
      setState(() {
        isLoading = false;
        m1Calculated = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M1 marks calculated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshLabSession();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating M1 marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _calculateM2() async {
    if (!m1Calculated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please calculate M1 before calculating M2'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate M2'),
        content: Text(
          'This will calculate M2 marks based on experiments ${m1LastExperiment + 1} to ${labSession.numberOfExperiments}. '
          'Are you sure you want to proceed?'
        ),
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
      isLoading = true;
    });
    
    try {
      await _labService.calculateAndSaveM2Marks(
        labSessionId: labSession.id,
      );
      
      setState(() {
        isLoading = false;
        m2Calculated = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M2 marks calculated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshLabSession();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating M2 marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final experimentMeta = labSession.experimentMeta[selectedExperiment];
    final experimentDate = experimentMeta?.dateOfExperiment;
    final dueDate = experimentMeta?.dueDate;
    final isExperimentPastDue = experimentMeta?.isAfterDueDate() ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Marks Entry: ${labSession.subjectName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ExportOptionsDialog(
                  labSession: labSession,
                  students: students,
                  selectedExperiment: selectedExperiment,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLabSession,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Experiment Marks'),
            Tab(text: 'Internal Marks'),
            Tab(text: 'M1/M2 Results'),
            Tab(text: 'Final Assessment'),
          ],
        ),
      ),
      body: isLoading && students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSessionInfo(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Experiment Marks Tab
                          Column(
                            children: [
                              _buildExperimentControls(
                                experimentDate: experimentDate,
                                dueDate: dueDate,
                                isExperimentPastDue: isExperimentPastDue,
                              ),
                              Expanded(
                                child: ExperimentMarksTable(
                                  labSession: labSession,
                                  students: students,
                                  experimentNumber: selectedExperiment,
                                  isExperimentPastDue: isExperimentPastDue,
                                  onMarksSaved: _refreshLabSession,
                                ),
                              ),
                            ],
                          ),
                          
                          // Internal Marks Tab
                          Column(
                            children: [
                              // Add import internal marks controls
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Internal Test Marks',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo[800],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _showImportInternalDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.upload_file, size: 16),
                                      label: const Text('Import Internal Marks'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: InternalMarksTable(
                                  labSession: labSession,
                                  students: students,
                                  onMarksSaved: _refreshLabSession,
                                ),
                              ),
                            ],
                          ),
                          
                          // M1/M2 Results Tab
                          Column(
                            children: [
                              _buildM1M2Controls(),
                              Expanded(
                                child: M1M2ResultsTable(
                                  labSession: labSession,
                                  students: students,
                                ),
                              ),
                            ],
                          ),
                          
                          // Final Assessment Tab
                          Column(
                            children: [
                              // Viva & Final Assessment controls
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Final Lab Assessment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showImportVivaDialog(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Import Viva & Final'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: FinalLabMarksTable(
                                  labSession: labSession,
                                  students: students,
                                  onMarksSaved: _refreshLabSession,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labSession.subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${labSession.branch} | ${labSession.year} Year | Section ${labSession.section}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${labSession.students.length} Students',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentControls({
    DateTime? experimentDate,
    DateTime? dueDate,
    bool isExperimentPastDue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Experiment',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  value: selectedExperiment,
                  items: List.generate(labSession.numberOfExperiments, (i) {
                    final experimentNum = (i + 1).toString();
                    return DropdownMenuItem<String>(
                      value: experimentNum,
                      child: Text('Experiment $experimentNum'),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedExperiment = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _setExperimentDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Set Date'),
              ),
            ],
          ),
          if (experimentDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExperimentPastDue ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Experiment Date: ${DateFormat('dd MMM yyyy').format(experimentDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isExperimentPastDue ? Colors.red[800] : Colors.green[800],
                            ),
                          ),
                          if (dueDate != null)
                            Text(
                              'Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isExperimentPastDue ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                        ],
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

  Widget _buildM1M2Controls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'M1/M2 Calculation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('M1 Last Experiment:'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: m1LastExperiment.toDouble(),
                            min: 1,
                            max: labSession.numberOfExperiments.toDouble(),
                            divisions: labSession.numberOfExperiments - 1,
                            onChanged: m1Calculated ? null : (value) {
                              setState(() {
                                m1LastExperiment = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            m1LastExperiment.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: m1Calculated
                        ? () => _recalculateM1()
                        : _calculateM1,
                    child: Text(m1Calculated ? 'Recalculate M1' : 'Calculate M1'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: m2Calculated
                        ? () => _calculateM2()
                        : m1Calculated
                            ? _calculateM2
                            : null,
                    child: Text(m2Calculated ? 'Recalculate M2' : 'Calculate M2'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[800], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'M1 includes Experiments 1 to $m1LastExperiment. '
                    'M2 includes Experiments ${m1LastExperiment + 1} to ${labSession.numberOfExperiments}.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
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

  void _recalculateM1() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recalculate M1?'),
        content: const Text(
          'This will recalculate M1 marks based on the current experiment marks and may '
          'change previous results. Are you sure you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      _calculateM1();
    }
  }
  
  // Show the dialog for importing M1/M2 marks
  void _showImportM1M2Dialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImportM1M2Dialog(
          labSession: labSession,
          onImportComplete: () async {
            // Refresh the lab session data after import
            await _refreshLabSession();
            
            // Force UI update with a small delay to ensure data is refreshed
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (mounted) {
              setState(() {
                // Force UI refresh
                // Also update calculation status
                _checkCalculationStatus();
              });
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'M1/M2 marks imported successfully',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
  
  // Show the dialog for importing Viva & Final assessment marks
  void _showImportVivaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImportVivaDialog(
          labSession: labSession,
          onImportComplete: () async {
            // Refresh the lab session data after import
            await _refreshLabSession();
            
            // Force UI update with a small delay to ensure data is refreshed
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (mounted) {
              setState(() {
                // Force UI refresh
              });
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Viva & Final marks imported successfully',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
  
  // Show the dialog for importing experiment marks
  void _showImportExperimentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImportMarksDialog(
          labSession: labSession,
          experimentNumber: selectedExperiment,
          onImportComplete: () {
            // Refresh the lab session data after import
            _refreshLabSession();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Experiment $selectedExperiment marks imported successfully',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
  
  // Show the dialog for importing internal marks
  void _showImportInternalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImportInternalDialog(
          labSession: labSession,
          onImportComplete: () async {
            // Refresh the lab session data after import
            await _refreshLabSession();
            
            // Force UI update with a small delay to ensure data is refreshed
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (mounted) {
              setState(() {
                // Force UI refresh
              });
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Internal marks imported successfully',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}
