import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/mid_service.dart';

class Mid2MarksTable extends StatefulWidget {
  final MidSession midSession;
  final List<StudentModel> students;
  final VoidCallback onMarksSaved;

  const Mid2MarksTable({
    Key? key,
    required this.midSession,
    required this.students,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  State<Mid2MarksTable> createState() => _Mid2MarksTableState();
}

class _Mid2MarksTableState extends State<Mid2MarksTable> {
  final MidService _midService = MidService();
  
  // Controllers for text fields
  final Map<String, TextEditingController> _descriptiveControllers = {};
  final Map<String, TextEditingController> _objectiveControllers = {};
  final Map<String, FocusNode> _descriptiveFocusNodes = {};
  final Map<String, FocusNode> _objectiveFocusNodes = {};
  
  // Student with active focus
  String? _activeStudentId;
  
  // Field navigation
  List<List<FocusNode>>? _fieldMatrix;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(Mid2MarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.midSession.id != widget.midSession.id) {
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
      
      // Get current marks if available
      final marks = widget.midSession.getMid2Marks(studentId);
      final descriptive = marks?['descriptive'] as double?;
      final objective = marks?['objective'] as double?;
      
      // Create controllers with initial values
      _descriptiveControllers[studentId] = TextEditingController(
        text: descriptive != null ? descriptive.toString() : '',
      );
      _objectiveControllers[studentId] = TextEditingController(
        text: objective != null ? objective.toString() : '',
      );
      
      // Create focus nodes with listeners
      _descriptiveFocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_descriptiveFocusNodes[studentId]!.hasFocus) {
            setState(() {
              _activeStudentId = studentId;
            });
          }
        });
      
      _objectiveFocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_objectiveFocusNodes[studentId]!.hasFocus) {
            setState(() {
              _activeStudentId = studentId;
            });
          }
        });
    }
    
    // Initialize field matrix for navigation
    _buildFieldMatrix();
  }
  
  void _buildFieldMatrix() {
    if (widget.students.isEmpty) {
      _fieldMatrix = [];
      return;
    }
    
    // Create a field matrix for keyboard navigation
    _fieldMatrix = [];
    
    for (final student in widget.students) {
      final studentId = student.rollNo;
      final studentRow = <FocusNode>[];
      
      // Add Descriptive field
      if (_descriptiveFocusNodes.containsKey(studentId)) {
        studentRow.add(_descriptiveFocusNodes[studentId]!);
      }
      
      // Add Objective field
      if (_objectiveFocusNodes.containsKey(studentId)) {
        studentRow.add(_objectiveFocusNodes[studentId]!);
      }
      
      if (studentRow.isNotEmpty) {
        _fieldMatrix!.add(studentRow);
      }
    }
  }
  
  void _disposeControllers() {
    for (final controller in _descriptiveControllers.values) {
      controller.dispose();
    }
    for (final controller in _objectiveControllers.values) {
      controller.dispose();
    }
    
    for (final focusNode in _descriptiveFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _objectiveFocusNodes.values) {
      focusNode.dispose();
    }
    
    _descriptiveControllers.clear();
    _objectiveControllers.clear();
    _descriptiveFocusNodes.clear();
    _objectiveFocusNodes.clear();
  }
  
  Future<void> _saveMid2Marks(String studentId) async {
    try {
      // Get values from controllers
      final descriptiveText = _descriptiveControllers[studentId]?.text ?? '';
      final objectiveText = _objectiveControllers[studentId]?.text ?? '';
      
      // Parse values
      double? descriptive;
      double? objective;
      
      if (descriptiveText.isNotEmpty) {
        descriptive = double.tryParse(descriptiveText);
      }
      
      if (objectiveText.isNotEmpty) {
        objective = double.tryParse(objectiveText);
      }
      
      // Validate marks
      if (descriptive != null && (descriptive < 0 || descriptive > 20)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${descriptive.toString()} is invalid. Descriptive marks must be between 0 and 20')),
          );
        }
        return;
      }
      
      if (objective != null && (objective < 0 || objective > 10)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${objective.toString()} is invalid. Objective marks must be between 0 and 10')),
          );
        }
        return;
      }
      
      // Default values for null fields
      double desc = descriptive ?? 0.0;
      double obj = objective ?? 0.0;
      
      // Update marks in database
      await _midService.updateMid2Marks(
        midSessionId: widget.midSession.id,
        studentId: studentId,
        descriptive: desc,
        objective: obj,
      );
      
      // Notify parent widget
      widget.onMarksSaved();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marks saved for ${studentId}')),
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
  
  Future<void> _saveAllMid2Marks() async {
    try {
      int savedCount = 0;
      
      for (final student in widget.students) {
        final studentId = student.rollNo;
        
        // Get values from controllers
        final descriptiveText = _descriptiveControllers[studentId]?.text ?? '';
        final objectiveText = _objectiveControllers[studentId]?.text ?? '';
        
        // Skip if both fields are empty
        if (descriptiveText.isEmpty && objectiveText.isEmpty) {
          continue;
        }
        
        // Parse values
        double? descriptive;
        double? objective;
        
        if (descriptiveText.isNotEmpty) {
          descriptive = double.tryParse(descriptiveText);
        }
        
        if (objectiveText.isNotEmpty) {
          objective = double.tryParse(objectiveText);
        }
        
        // Validate marks
        if (descriptive != null && (descriptive < 0 || descriptive > 20)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${student.name}: Descriptive marks must be between 0 and 20')),
            );
          }
          continue;
        }
        
        if (objective != null && (objective < 0 || objective > 10)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${student.name}: Objective marks must be between 0 and 10')),
            );
          }
          continue;
        }
        
        // Default values for null fields
        double desc = descriptive ?? 0.0;
        double obj = objective ?? 0.0;
        
        // Update marks in database
        await _midService.updateMid2Marks(
          midSessionId: widget.midSession.id,
          studentId: studentId,
          descriptive: desc,
          objective: obj,
        );
        
        savedCount++;
      }
      
      // Show success message
      if (savedCount > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved marks for $savedCount students')),
          );
        }
        
        // Notify parent widget
        widget.onMarksSaved();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No changes to save')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mid 2 marks: Descriptive (out of 20) + Objective (out of 10) = Total (out of 30)',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveAllMid2Marks,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save All Mid 2 Marks'),
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
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(color: Colors.green[100]!),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'Descriptive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Out of 20',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(), // Spacing
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'Objective',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Out of 10',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Out of 30',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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
  
  // Navigate to the next field using Enter key
  void _navigateToNextField(String studentId, bool isDescriptive) {
    // Find current position in field matrix
    int currentRow = -1;
    int currentCol = -1;
    
    // Find the current position in the field matrix
    for (int i = 0; i < _fieldMatrix!.length; i++) {
      for (int j = 0; j < _fieldMatrix![i].length; j++) {
        final focusNode = _fieldMatrix![i][j];
        final isDescriptiveField = j == 0;
        
        if (isDescriptive == isDescriptiveField) {
          if ((isDescriptive && focusNode == _descriptiveFocusNodes[studentId]) ||
              (!isDescriptive && focusNode == _objectiveFocusNodes[studentId])) {
            currentRow = i;
            currentCol = j;
            break;
          }
        }
      }
      if (currentRow >= 0) break;
    }
    
    if (currentRow < 0 || _fieldMatrix!.isEmpty) return;
    
    int newRow = currentRow;
    int newCol = currentCol;
    
    if (isDescriptive) {
      // Move from descriptive to objective in same row
      newCol = 1;
    } else {
      // Move from objective to next row's descriptive
      newRow = currentRow + 1;
      newCol = 0;
      
      // Wrap around to first row if at end
      if (newRow >= _fieldMatrix!.length) {
        newRow = 0;
      }
    }
    
    // Request focus on the new field
    if (newRow >= 0 && newRow < _fieldMatrix!.length &&
        newCol >= 0 && newCol < _fieldMatrix![newRow].length) {
      _fieldMatrix![newRow][newCol].requestFocus();
    }
  }
  
  Widget _buildStudentRow(StudentModel student) {
    final studentId = student.rollNo;
    final isActive = _activeStudentId == studentId;
    
    // Get current marks
    final marks = widget.midSession.getMid2Marks(studentId);
    final total = marks?['total'] as double? ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.yellow[50] : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              student.name ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                // Descriptive marks field
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            // Navigate up
                            int currentRow = 0;
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][0] == _descriptiveFocusNodes[studentId]) {
                                currentRow = i;
                                break;
                              }
                            }
                            
                            int newRow = currentRow - 1;
                            if (newRow < 0) {
                              newRow = _fieldMatrix!.length - 1;
                            }
                            
                            _fieldMatrix![newRow][0].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            // Navigate down
                            int currentRow = 0;
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][0] == _descriptiveFocusNodes[studentId]) {
                                currentRow = i;
                                break;
                              }
                            }
                            
                            int newRow = (currentRow + 1) % _fieldMatrix!.length;
                            _fieldMatrix![newRow][0].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            // Navigate to objective field
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][0] == _descriptiveFocusNodes[studentId]) {
                                _fieldMatrix![i][1].requestFocus();
                                break;
                              }
                            }
                          }
                        }
                      },
                      child: TextField(
                        controller: _descriptiveControllers[studentId],
                        focusNode: _descriptiveFocusNodes[studentId],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _navigateToNextField(studentId, true),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Container(), // Spacing
                ),
                
                // Objective marks field
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            // Navigate up
                            int currentRow = 0;
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][1] == _objectiveFocusNodes[studentId]) {
                                currentRow = i;
                                break;
                              }
                            }
                            
                            int newRow = currentRow - 1;
                            if (newRow < 0) {
                              newRow = _fieldMatrix!.length - 1;
                            }
                            
                            _fieldMatrix![newRow][1].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            // Navigate down
                            int currentRow = 0;
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][1] == _objectiveFocusNodes[studentId]) {
                                currentRow = i;
                                break;
                              }
                            }
                            
                            int newRow = (currentRow + 1) % _fieldMatrix!.length;
                            _fieldMatrix![newRow][1].requestFocus();
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            // Navigate to descriptive field
                            for (int i = 0; i < _fieldMatrix!.length; i++) {
                              if (_fieldMatrix![i][1] == _objectiveFocusNodes[studentId]) {
                                _fieldMatrix![i][0].requestFocus();
                                break;
                              }
                            }
                          }
                        }
                      },
                      child: TextField(
                        controller: _objectiveControllers[studentId],
                        focusNode: _objectiveFocusNodes[studentId],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _navigateToNextField(studentId, false),
                      ),
                    ),
                  ),
                ),
                
                // Total
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      total.toString(),
                      style: const TextStyle(
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
}
