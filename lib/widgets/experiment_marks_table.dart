import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/lab_service.dart';
import 'package:markpro_plus/widgets/import_marks_dialog.dart';
import 'package:markpro_plus/utils/marks_field_navigator.dart';

class ExperimentMarksTable extends StatefulWidget {
  final LabSession labSession;
  final List<StudentModel> students;
  final String experimentNumber;
  final bool isExperimentPastDue;
  final VoidCallback onMarksSaved;

  const ExperimentMarksTable({
    Key? key,
    required this.labSession,
    required this.students,
    required this.experimentNumber,
    required this.isExperimentPastDue,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  State<ExperimentMarksTable> createState() => _ExperimentMarksTableState();
}

class _ExperimentMarksTableState extends State<ExperimentMarksTable> {
  final LabService _labService = LabService();
  
  // Controllers and focus nodes for marks
  final Map<String, Map<String, TextEditingController>> _markControllers = {
    'A': {},
    'B': {},
    'C': {},
  };
  
  final Map<String, Map<String, FocusNode>> _markFocusNodes = {
    'A': {},
    'B': {},
    'C': {},
  };
  
  // Student with active focus
  String? _activeStudentId;
  
  // Field navigation
  List<List<FocusNode>>? _fieldMatrix;
  
  // Loading states
  final Map<String, bool> _isLoading = {};
  bool _isBatchSaving = false;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(ExperimentMarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the experiment number changed or lab session was refreshed
    if (oldWidget.experimentNumber != widget.experimentNumber ||
        oldWidget.labSession != widget.labSession) {
      _disposeControllers();
      _initializeControllers();
    }
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  void _initializeControllers() {
    for (final student in widget.students) {
      final studentId = student.rollNo;
      
      // Get existing experiment marks if available
      final marks = widget.labSession.getExperimentMarks(
        studentId, 
        widget.experimentNumber,
      );
      
      // Initialize controllers and focus nodes for each component
      for (final component in ['A', 'B', 'C']) {
        // Create controller with initial value
        _markControllers[component]![studentId] = TextEditingController(
          text: marks != null && marks[component] != null 
              ? marks[component].toString() 
              : '',
        );
        
        // Create focus node with listener
        _markFocusNodes[component]![studentId] = FocusNode()
          ..addListener(() {
            if (_markFocusNodes[component]![studentId]!.hasFocus) {
              setState(() {
                _activeStudentId = studentId;
              });
            }
          });
      }
    }
    
    // Initialize field matrix for navigation
    _buildFieldMatrix();
  }
  
  void _buildFieldMatrix() {
    if (widget.students.isEmpty) {
      _fieldMatrix = [];
      return;
    }
    
    // Get all student IDs in order
    final studentIds = widget.students.map((s) => s.rollNo).toList();
    
    // Create field matrix for keyboard navigation
    _fieldMatrix = MarksFieldNavigator.createFieldMatrix(
      studentIds: studentIds,
      markFocusNodes: _markFocusNodes, 
      components: ['A', 'B', 'C'],
    );
  }
  
  void _disposeControllers() {
    for (final component in ['A', 'B', 'C']) {
      for (final controller in _markControllers[component]!.values) {
        controller.dispose();
      }
      
      for (final focusNode in _markFocusNodes[component]!.values) {
        focusNode.dispose();
      }
      
      _markControllers[component]!.clear();
      _markFocusNodes[component]!.clear();
    }
  }
  
  Future<bool> _saveMarks(String studentId) async {
    if (_isLoading[studentId] == true) return false;
    
    setState(() {
      _isLoading[studentId] = true;
    });
    
    try {
      // Get values from controllers
      final componentA = int.tryParse(_markControllers['A']![studentId]!.text.trim()) ?? 0;
      final componentB = int.tryParse(_markControllers['B']![studentId]!.text.trim()) ?? 0;
      final componentC = int.tryParse(_markControllers['C']![studentId]!.text.trim()) ?? 0;
      
      // Validate marks
      if (componentA < 0 || componentA > 5) {
        _showErrorSnackBar('Component A should be between 0-5');
        return false;
      }
      
      if (componentB < 0 || componentB > 5) {
        _showErrorSnackBar('Component B should be between 0-5');
        return false;
      }
      
      if (componentC < 0 || componentC > 10) {
        _showErrorSnackBar('Component C should be between 0-10');
        return false;
      }
      
      // Save marks
      await _labService.saveExperimentMarks(
        labSessionId: widget.labSession.id,
        studentId: studentId,
        experimentNumber: widget.experimentNumber,
        markA: componentA,
        markB: componentB,
        markC: componentC,
      );
      
      // Call refresh callback
      widget.onMarksSaved();
      
      // Show success message
      if (mounted) {
        _showSuccessSnackBar('Marks saved for ${_getStudentName(studentId)}');
      }
      
      return true;
    } catch (e) {
      // Show error
      if (mounted) {
        _showErrorSnackBar('Error saving marks: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[studentId] = false;
        });
      }
    }
  }
  
  Future<void> _saveAllMarks() async {
    if (_isBatchSaving) return;
    
    setState(() {
      _isBatchSaving = true;
    });
    
    final studentsToUpdate = <String>[];
    final errors = <String>[];
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Saving all marks...'),
          ],
        ),
      ),
    );
    
    try {
      // Validate marks for all students
      for (final student in widget.students) {
        final studentId = student.rollNo;
        
        // Check if any component has a value
        final hasValues = ['A', 'B', 'C'].any((component) {
          return _markControllers[component]![studentId]!.text.trim().isNotEmpty;
        });
        
        if (!hasValues) continue;
        
        // Validate all components
        final componentA = int.tryParse(_markControllers['A']![studentId]!.text.trim());
        final componentB = int.tryParse(_markControllers['B']![studentId]!.text.trim());
        final componentC = int.tryParse(_markControllers['C']![studentId]!.text.trim());
        
        if (componentA == null || componentB == null || componentC == null) {
          errors.add('${_getStudentName(studentId)}: All components must have numeric values');
          continue;
        }
        
        if (componentA < 0 || componentA > 5) {
          errors.add('${_getStudentName(studentId)}: Component A should be between 0-5');
          continue;
        }
        
        if (componentB < 0 || componentB > 5) {
          errors.add('${_getStudentName(studentId)}: Component B should be between 0-5');
          continue;
        }
        
        if (componentC < 0 || componentC > 10) {
          errors.add('${_getStudentName(studentId)}: Component C should be between 0-10');
          continue;
        }
        
        studentsToUpdate.add(studentId);
      }
      
      // Save marks for all valid students
      for (final studentId in studentsToUpdate) {
        try {
          final componentA = int.parse(_markControllers['A']![studentId]!.text.trim());
          final componentB = int.parse(_markControllers['B']![studentId]!.text.trim());
          final componentC = int.parse(_markControllers['C']![studentId]!.text.trim());
          
          await _labService.saveExperimentMarks(
            labSessionId: widget.labSession.id,
            studentId: studentId,
            experimentNumber: widget.experimentNumber,
            markA: componentA,
            markB: componentB,
            markC: componentC,
          );
        } catch (e) {
          errors.add('${_getStudentName(studentId)}: $e');
        }
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Call refresh callback
      widget.onMarksSaved();
      
      // Show results
      if (mounted) {
        if (studentsToUpdate.isEmpty) {
          _showInfoSnackBar('No marks to save');
        } else {
          _showSuccessSnackBar('Saved marks for ${studentsToUpdate.length} students');
        }
        
        // Show errors if any
        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Errors'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $error'),
                  )).toList(),
                ),
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
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        _showErrorSnackBar('Error saving marks: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchSaving = false;
        });
      }
    }
  }
  
  String _getStudentName(String studentId) {
    final student = widget.students.firstWhere(
      (s) => s.rollNo == studentId,
      orElse: () => StudentModel(
        id: '', 
        name: 'Unknown', 
        rollNo: studentId, 
        branch: '',
        year: 1,
        semester: 1,
        section: '',
        academicYear: '',
      ),
    );
    return student.name;
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Show the import marks dialog
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImportMarksDialog(
          labSession: widget.labSession,
          experimentNumber: widget.experimentNumber,
          onImportComplete: () async {
            // Refresh the lab session first
            widget.onMarksSaved();
            
            // Wait a moment for the database refresh to complete
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Force complete rebuild of controllers
            if (mounted) {
              setState(() {
                // First completely dispose all existing controllers
                _disposeControllers();
              });
              
              // Wait for dispose to complete
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (mounted) {
                setState(() {
                  // Initialize fresh controllers with new data
                  _initializeControllers();
                });
                
                // Final reload to ensure UI matches data
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Marks imported successfully',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.students.isEmpty) 
          const Expanded(
            child: Center(
              child: Text('No students found'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Import Marks button
                ElevatedButton.icon(
                  onPressed: widget.isExperimentPastDue ? null : _showImportDialog,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Save All Marks button
                ElevatedButton.icon(
                  onPressed: widget.isExperimentPastDue ? null : _saveAllMarks,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save All Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          _buildHeader(),
          Expanded(
            child: widget.students.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.builder(
                    itemCount: widget.students.length,
                    itemBuilder: (context, index) {
                      final student = widget.students[index];
                      return _buildStudentRow(student);
                    },
                  ),
          ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100] ?? Colors.blue),
        ),
      ),
      child: Row(
        children: [
          // Student column
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Marks columns
          Expanded(
            flex: 8,
            child: Row(
              children: [
                // Component A column (5 marks)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Component A\n(0-5)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Component B column (5 marks)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Component B\n(0-5)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Component C column (10 marks)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Component C\n(0-10)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Total column (20 marks)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Total\n(20)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Actions column
                const Expanded(
                  child: Center(
                    child: Text(
                      'Actions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
  
  Widget _buildStudentRow(StudentModel student) {
    final studentId = student.rollNo;
    final marks = widget.labSession.getExperimentMarks(studentId, widget.experimentNumber);
    final isLoading = _isLoading[studentId] == true;
    
    // Calculate total marks
    int totalMarks = 0;
    if (marks != null && marks['total'] != null) {
      totalMarks = marks['total'] as int;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300] ?? Colors.grey),
        ),
        color: _activeStudentId == studentId ? Colors.blue.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Student name and roll number
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  studentId,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Marks columns
          Expanded(
            flex: 8,
            child: Row(
              children: [
                // Component A input (0-5 marks)
                Expanded(
                  child: Center(
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        // Skip keyboard handling if past due
                        if (widget.isExperimentPastDue) return;
                        
                        // Only process key down events
                        if (event is! RawKeyDownEvent) return;
                        
                        // Find current focus position in matrix
                        if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                          int currentRow = -1;
                          int currentCol = -1;
                          
                          // Find position of current field
                          for (int i = 0; i < _fieldMatrix!.length; i++) {
                            for (int j = 0; j < _fieldMatrix![i].length; j++) {
                              if (_fieldMatrix![i][j] == _markFocusNodes['A']![studentId]) {
                                currentRow = i;
                                currentCol = j;
                                break;
                              }
                            }
                            if (currentRow != -1) break;
                          }
                          
                          if (currentRow == -1) return;
                          
                          // Handle specific key events
                          if (event.logicalKey == LogicalKeyboardKey.enter || 
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            if (currentCol < _fieldMatrix![currentRow].length - 1) {
                              _fieldMatrix![currentRow][currentCol + 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            if (currentCol > 0) {
                              _fieldMatrix![currentRow][currentCol - 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (currentRow < _fieldMatrix!.length - 1) {
                              _fieldMatrix![currentRow + 1][currentCol].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            if (currentRow > 0) {
                              _fieldMatrix![currentRow - 1][currentCol].requestFocus();
                            }
                          }
                        }
                      },
                      child: TextFormField(
                        controller: _markControllers['A']![studentId],
                        focusNode: _markFocusNodes['A']![studentId],
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0-5',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !widget.isExperimentPastDue,
                        textAlign: TextAlign.center,
                        onFieldSubmitted: (_) {
                          // Find current focus position in matrix
                          if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                            int currentRow = -1;
                            int currentCol = -1;
                            
                            // Find position of current field
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                if (_fieldMatrix![i][j] == _markFocusNodes['A']![studentId]) {
                                  currentRow = i;
                                  currentCol = j;
                                  break;
                                }
                              }
                              if (currentRow != -1) break;
                            }
                            
                            if (currentRow == -1) return;
                            
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                // Component B input (0-5 marks)
                Expanded(
                  child: Center(
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        // Skip keyboard handling if past due
                        if (widget.isExperimentPastDue) return;
                        
                        // Only process key down events
                        if (event is! RawKeyDownEvent) return;
                        
                        // Find current focus position in matrix
                        if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                          int currentRow = -1;
                          int currentCol = -1;
                          
                          // Find position of current field
                          for (int i = 0; i < _fieldMatrix!.length; i++) {
                            for (int j = 0; j < _fieldMatrix![i].length; j++) {
                              if (_fieldMatrix![i][j] == _markFocusNodes['B']![studentId]) {
                                currentRow = i;
                                currentCol = j;
                                break;
                              }
                            }
                            if (currentRow != -1) break;
                          }
                          
                          if (currentRow == -1) return;
                          
                          // Handle specific key events
                          if (event.logicalKey == LogicalKeyboardKey.enter || 
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            if (currentCol < _fieldMatrix![currentRow].length - 1) {
                              _fieldMatrix![currentRow][currentCol + 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            if (currentCol > 0) {
                              _fieldMatrix![currentRow][currentCol - 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (currentRow < _fieldMatrix!.length - 1) {
                              _fieldMatrix![currentRow + 1][currentCol].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            if (currentRow > 0) {
                              _fieldMatrix![currentRow - 1][currentCol].requestFocus();
                            }
                          }
                        }
                      },
                      child: TextFormField(
                        controller: _markControllers['B']![studentId],
                        focusNode: _markFocusNodes['B']![studentId],
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0-5',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !widget.isExperimentPastDue,
                        textAlign: TextAlign.center,
                        onFieldSubmitted: (_) {
                          // Find current focus position in matrix
                          if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                            int currentRow = -1;
                            int currentCol = -1;
                            
                            // Find position of current field
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                if (_fieldMatrix![i][j] == _markFocusNodes['B']![studentId]) {
                                  currentRow = i;
                                  currentCol = j;
                                  break;
                                }
                              }
                              if (currentRow != -1) break;
                            }
                            
                            if (currentRow == -1) return;
                            
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                // Component C input (0-10 marks)
                Expanded(
                  child: Center(
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        // Skip keyboard handling if past due
                        if (widget.isExperimentPastDue) return;
                        
                        // Only process key down events
                        if (event is! RawKeyDownEvent) return;
                        
                        // Find current focus position in matrix
                        if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                          int currentRow = -1;
                          int currentCol = -1;
                          
                          // Find position of current field
                          for (int i = 0; i < _fieldMatrix!.length; i++) {
                            for (int j = 0; j < _fieldMatrix![i].length; j++) {
                              if (_fieldMatrix![i][j] == _markFocusNodes['C']![studentId]) {
                                currentRow = i;
                                currentCol = j;
                                break;
                              }
                            }
                            if (currentRow != -1) break;
                          }
                          
                          if (currentRow == -1) return;
                          
                          // Handle specific key events
                          if (event.logicalKey == LogicalKeyboardKey.enter || 
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            if (currentCol < _fieldMatrix![currentRow].length - 1) {
                              _fieldMatrix![currentRow][currentCol + 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            if (currentCol > 0) {
                              _fieldMatrix![currentRow][currentCol - 1].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (currentRow < _fieldMatrix!.length - 1) {
                              _fieldMatrix![currentRow + 1][currentCol].requestFocus();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            if (currentRow > 0) {
                              _fieldMatrix![currentRow - 1][currentCol].requestFocus();
                            }
                          }
                        }
                      },
                      child: TextFormField(
                        controller: _markControllers['C']![studentId],
                        focusNode: _markFocusNodes['C']![studentId],
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0-10',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !widget.isExperimentPastDue,
                        textAlign: TextAlign.center,
                        onFieldSubmitted: (_) {
                          // Find current focus position in matrix
                          if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                            int currentRow = -1;
                            int currentCol = -1;
                            
                            // Find position of current field
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                if (_fieldMatrix![i][j] == _markFocusNodes['C']![studentId]) {
                                  currentRow = i;
                                  currentCol = j;
                                  break;
                                }
                              }
                              if (currentRow != -1) break;
                            }
                            
                            if (currentRow == -1) return;
                            
                            // Move to next field
                            int nextCol = currentCol + 1;
                            int nextRow = currentRow;
                            
                            if (nextCol >= _fieldMatrix![currentRow].length) {
                              nextCol = 0;
                              nextRow = currentRow + 1;
                              
                              if (nextRow >= _fieldMatrix!.length) {
                                nextRow = 0;
                              }
                            }
                            
                            _fieldMatrix![nextRow][nextCol].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                // Total marks display
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: totalMarks > 0 ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: totalMarks > 0 
                            ? Border.all(color: Colors.green[200] ?? Colors.green) 
                            : null,
                      ),
                      child: Text(
                        marks != null ? totalMarks.toString() : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: totalMarks > 0 ? Colors.green[800] : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Actions
                Expanded(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: !widget.isExperimentPastDue && !isLoading 
                          ? () => _saveMarks(studentId) 
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(80, 30),
                        backgroundColor: Colors.green,
                      ),
                      child: isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              marks != null ? 'Update' : 'Save',
                              style: const TextStyle(fontSize: 12),
                            ),
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
}