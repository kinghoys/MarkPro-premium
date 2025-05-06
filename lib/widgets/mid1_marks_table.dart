import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/mid_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/mid_service.dart';

class Mid1MarksTable extends StatefulWidget {
  final MidSession midSession;
  final List<StudentModel> students;
  final VoidCallback onMarksSaved;

  const Mid1MarksTable({
    Key? key,
    required this.midSession,
    required this.students,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  State<Mid1MarksTable> createState() => _Mid1MarksTableState();
}

class _Mid1MarksTableState extends State<Mid1MarksTable> {
  final MidService _midService = MidService();
  
  // Controllers for text fields
  final Map<String, TextEditingController> _descriptiveControllers = {};
  final Map<String, TextEditingController> _objectiveControllers = {};
  final Map<String, FocusNode> _descriptiveFocusNodes = {};
  final Map<String, FocusNode> _objectiveFocusNodes = {};
  
  // Student with active focus
  String? _activeStudentId;
  
  // Field navigation matrix
  List<List<FocusNode>> _fieldMatrix = [];
  
  // Track current position for navigation
  int _currentRow = 0;
  int _currentColumn = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(Mid1MarksTable oldWidget) {
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
  
  // Initialize controllers and focus nodes for all students
  void _initializeControllers() {
    for (final student in widget.students) {
      final studentId = student.rollNo;
      
      // Get current marks if available
      final marks = widget.midSession.getMid1Marks(studentId);
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
    
    // Build navigation matrix once all focus nodes are created
    _buildNavigationMatrix();
  }
  
  // Build a matrix of focus nodes for keyboard navigation
  void _buildNavigationMatrix() {
    _fieldMatrix = [];
    
    for (final student in widget.students) {
      final studentId = student.rollNo;
      final rowFocusNodes = <FocusNode>[];
      
      // Add descriptive field focus node
      if (_descriptiveFocusNodes.containsKey(studentId)) {
        rowFocusNodes.add(_descriptiveFocusNodes[studentId]!);
      }
      
      // Add objective field focus node
      if (_objectiveFocusNodes.containsKey(studentId)) {
        rowFocusNodes.add(_objectiveFocusNodes[studentId]!);
      }
      
      if (rowFocusNodes.isNotEmpty) {
        _fieldMatrix.add(rowFocusNodes);
      }
    }
  }
  
  // Clean up resources
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
  
  // Save marks for a specific student
  Future<void> _saveMid1Marks(String studentId) async {
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
            const SnackBar(content: Text('Descriptive marks must be between 0 and 20')),
          );
        }
        return;
      }
      
      if (objective != null && (objective < 0 || objective > 10)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objective marks must be between 0 and 10')),
          );
        }
        return;
      }
      
      // Default values for null fields
      double desc = descriptive ?? 0.0;
      double obj = objective ?? 0.0;
      
      // Update marks in database
      await _midService.updateMid1Marks(
        midSessionId: widget.midSession.id,
        studentId: studentId,
        descriptive: desc,
        objective: obj,
      );
      
      // Notify parent widget
      widget.onMarksSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    }
  }
  
  // Save all marks in the table
  Future<void> _saveAllMid1Marks() async {
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
        await _midService.updateMid1Marks(
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
  
  // Navigate to the next field using Enter key
  void _navigateToNextField(String studentId, bool isDescriptive) {
    // Update current position in matrix
    _updatePosition(studentId, isDescriptive);
    
    if (_fieldMatrix.isEmpty) return;
    
    int newRow = _currentRow;
    int newCol = _currentColumn;
    
    if (isDescriptive) {
      // Move from descriptive to objective in same row
      newCol = 1;
    } else {
      // Move from objective to next row's descriptive
      newRow = _currentRow + 1;
      newCol = 0;
      
      // Wrap around to first row if at end
      if (newRow >= _fieldMatrix.length) {
        newRow = 0;
      }
    }
    
    // Request focus on the new field
    if (newRow >= 0 && newRow < _fieldMatrix.length &&
        newCol >= 0 && newCol < _fieldMatrix[newRow].length) {
      _fieldMatrix[newRow][newCol].requestFocus();
      _currentRow = newRow;
      _currentColumn = newCol;
    }
  }
  
  // Update current position in navigation matrix
  void _updatePosition(String studentId, bool isDescriptive) {
    for (int i = 0; i < _fieldMatrix.length; i++) {
      for (int j = 0; j < _fieldMatrix[i].length; j++) {
        final focusNode = _fieldMatrix[i][j];
        final isDescriptiveColumn = j == 0;
        
        if (isDescriptive == isDescriptiveColumn) {
          if ((isDescriptive && focusNode == _descriptiveFocusNodes[studentId]) ||
              (!isDescriptive && focusNode == _objectiveFocusNodes[studentId])) {
            _currentRow = i;
            _currentColumn = j;
            return;
          }
        }
      }
    }
  }
  
  // Handle arrow key navigation
  void _navigateWithArrowKeys(String studentId, bool isDescriptive, int rowOffset, int colOffset) {
    _updatePosition(studentId, isDescriptive);
    
    int newRow = _currentRow + rowOffset;
    int newCol = _currentColumn + colOffset;
    
    // Wrap around for rows
    if (newRow < 0) {
      newRow = _fieldMatrix.length - 1;
    } else if (newRow >= _fieldMatrix.length) {
      newRow = 0;
    }
    
    // Wrap around for columns
    if (newCol < 0) {
      newCol = _fieldMatrix[newRow].length - 1;
    } else if (newCol >= _fieldMatrix[newRow].length) {
      newCol = 0;
    }
    
    // Ensure indices are valid
    if (newRow >= 0 && newRow < _fieldMatrix.length &&
        newCol >= 0 && newCol < _fieldMatrix[newRow].length) {
      _fieldMatrix[newRow][newCol].requestFocus();
      _currentRow = newRow;
      _currentColumn = newCol;
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
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mid 1 marks: Descriptive (out of 20) + Objective (out of 10) = Total (out of 30)',
                    style: TextStyle(
                      color: Colors.blue[800],
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
                  onPressed: _saveAllMid1Marks,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save All Mid 1 Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          
          // Header
          _buildHeader(),
          
          // Student Rows
          Expanded(
            child: ListView.builder(
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
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100]!),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
  
  Widget _buildStudentRow(StudentModel student) {
    final studentId = student.rollNo;
    final isActive = _activeStudentId == studentId;
    
    // Get current marks
    final marks = widget.midSession.getMid1Marks(studentId);
    final total = marks?['total'] as double? ?? 0.0;
    
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
              student.name,
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
                            _navigateWithArrowKeys(studentId, true, -1, 0);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            _navigateWithArrowKeys(studentId, true, 1, 0);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            _navigateWithArrowKeys(studentId, true, 0, -1);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            _navigateWithArrowKeys(studentId, true, 0, 1);
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
                            _navigateWithArrowKeys(studentId, false, -1, 0);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            _navigateWithArrowKeys(studentId, false, 1, 0);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            _navigateWithArrowKeys(studentId, false, 0, -1);
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            _navigateWithArrowKeys(studentId, false, 0, 1);
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
