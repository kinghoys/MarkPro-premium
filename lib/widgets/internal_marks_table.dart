import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markpro_plus/models/lab_session.dart';
import 'package:markpro_plus/models/student_model.dart';
import 'package:markpro_plus/services/lab_service.dart';

class InternalMarksTable extends StatefulWidget {
  final LabSession labSession;
  final List<StudentModel> students;
  final VoidCallback onMarksSaved;

  const InternalMarksTable({
    Key? key,
    required this.labSession,
    required this.students,
    required this.onMarksSaved,
  }) : super(key: key);

  @override
  _InternalMarksTableState createState() => _InternalMarksTableState();
}

class _InternalMarksTableState extends State<InternalMarksTable> {
  final LabService _labService = LabService();
  
  // Controllers and focus nodes
  final Map<String, TextEditingController> _internal1Controllers = {};
  final Map<String, TextEditingController> _internal2Controllers = {};
  final Map<String, FocusNode> _internal1FocusNodes = {};
  final Map<String, FocusNode> _internal2FocusNodes = {};
  
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
  void didUpdateWidget(InternalMarksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labSession.id != widget.labSession.id) {
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
      final internal1 = widget.labSession.getInternalMark(studentId, '1');
      final internal2 = widget.labSession.getInternalMark(studentId, '2');
      
      // Create controllers with initial values
      _internal1Controllers[studentId] = TextEditingController(
        text: internal1 != null ? internal1.toString() : '',
      );
      _internal2Controllers[studentId] = TextEditingController(
        text: internal2 != null ? internal2.toString() : '',
      );
      
      // Create focus nodes with listeners
      _internal1FocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_internal1FocusNodes[studentId]!.hasFocus) {
            setState(() {
              _activeStudentId = studentId;
            });
          }
        });
      
      _internal2FocusNodes[studentId] = FocusNode()
        ..addListener(() {
          if (_internal2FocusNodes[studentId]!.hasFocus) {
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
      
      // Add Internal 1 field
      if (_internal1FocusNodes.containsKey(studentId)) {
        studentRow.add(_internal1FocusNodes[studentId]!);
      }
      
      // Add Internal 2 field
      if (_internal2FocusNodes.containsKey(studentId)) {
        studentRow.add(_internal2FocusNodes[studentId]!);
      }
      
      if (studentRow.isNotEmpty) {
        _fieldMatrix!.add(studentRow);
      }
    }
  }
  
  void _disposeControllers() {
    for (final controller in _internal1Controllers.values) {
      controller.dispose();
    }
    for (final controller in _internal2Controllers.values) {
      controller.dispose();
    }
    
    for (final focusNode in _internal1FocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _internal2FocusNodes.values) {
      focusNode.dispose();
    }
    
    _internal1Controllers.clear();
    _internal2Controllers.clear();
    _internal1FocusNodes.clear();
    _internal2FocusNodes.clear();
  }
  
  Future<void> _saveInternalMark(String studentId, String internalNumber) async {
    // Get controller based on internal number
    final controller = internalNumber == '1' 
      ? _internal1Controllers[studentId] 
      : _internal2Controllers[studentId];
    
    if (controller == null) return;
    
    // Get value from controller
    final markText = controller.text.trim();
    
    // Check if mark is provided
    if (markText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter Internal $internalNumber mark'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Parse and validate mark
    final mark = int.tryParse(markText) ?? 0;
    
    if (mark < 0 || mark > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid mark. Internal marks should be between 0-10'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      await _labService.saveInternalMarks(
        labSessionId: widget.labSession.id,
        studentId: studentId,
        internalNumber: internalNumber,
        mark: mark,
      );
      
      widget.onMarksSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Internal $internalNumber mark saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mark: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAllInternalMarks() async {
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
            Text('Saving all internal marks...'),
          ],
        ),
      ),
    );
    
    try {
      // First, handle Internal 1 marks
      for (final student in widget.students) {
        final studentId = student.rollNo;
        
        // Get value from Internal 1 controller
        final internal1Text = _internal1Controllers[studentId]!.text.trim();
        
        // Skip if empty
        if (internal1Text.isNotEmpty) {
          // Parse and validate mark
          final mark = int.tryParse(internal1Text) ?? 0;
          
          if (mark < 0 || mark > 10) {
            errors.add("${student.name}: Internal 1 mark should be between 0-10");
          } else {
            try {
              await _labService.saveInternalMarks(
                labSessionId: widget.labSession.id,
                studentId: studentId,
                internalNumber: '1',
                mark: mark,
              );
              
              studentsToUpdate.add(studentId);
            } catch (e) {
              errors.add("${student.name} Internal 1: $e");
            }
          }
        }
        
        // Get value from Internal 2 controller
        final internal2Text = _internal2Controllers[studentId]!.text.trim();
        
        // Skip if empty
        if (internal2Text.isNotEmpty) {
          // Parse and validate mark
          final mark = int.tryParse(internal2Text) ?? 0;
          
          if (mark < 0 || mark > 10) {
            errors.add("${student.name}: Internal 2 mark should be between 0-10");
          } else {
            try {
              await _labService.saveInternalMarks(
                labSessionId: widget.labSession.id,
                studentId: studentId,
                internalNumber: '2',
                mark: mark,
              );
              
              if (!studentsToUpdate.contains(studentId)) {
                studentsToUpdate.add(studentId);
              }
            } catch (e) {
              errors.add("${student.name} Internal 2: $e");
            }
          }
        }
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      if (mounted) {
        if (studentsToUpdate.isNotEmpty) {
          widget.onMarksSaved(); // Refresh data
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved internal marks for ${studentsToUpdate.length} students'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        
        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Errors'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $e'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving internal marks: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Internal marks are out of 10. Internal 1 is used for M1 calculation and Internal 2 is used for M2 calculation.',
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
                  onPressed: _saveAllInternalMarks,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save All Internal Marks'),
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
                        'Internal 1 (M1)',
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
                  child: Container(), // Spacing
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'Internal 2 (M2)',
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
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent) {
                                if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                                  // Find the position of the current field in the matrix
                                  int currentRow = -1;
                                  int currentCol = -1;
                                  
                                  for (int i = 0; i < _fieldMatrix!.length; i++) {
                                    for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                      if (_fieldMatrix![i][j] == _internal1FocusNodes[studentId]) {
                                        currentRow = i;
                                        currentCol = j;
                                        break;
                                      }
                                    }
                                    if (currentRow != -1) break;
                                  }
                                  
                                  if (currentRow == -1) return;
                                  
                                  // Handle key events
                                  bool handled = false;
                                  
                                  // Enter key - move to next field
                                  if (event.logicalKey == LogicalKeyboardKey.enter || 
                                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                                    int nextRow = currentRow;
                                    int nextCol = currentCol + 1;
                                    
                                    // If we're at the end of a row, move to the next row
                                    if (nextCol >= _fieldMatrix![currentRow].length) {
                                      nextCol = 0;
                                      nextRow++;
                                      
                                      // If we're at the end of all rows, loop back to first row
                                      if (nextRow >= _fieldMatrix!.length) {
                                        nextRow = 0;
                                      }
                                    }
                                    
                                    _fieldMatrix![nextRow][nextCol].requestFocus();
                                    handled = true;
                                  }
                                  // Arrow keys
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                    if (currentCol < _fieldMatrix![currentRow].length - 1) {
                                      _fieldMatrix![currentRow][currentCol + 1].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                    if (currentCol > 0) {
                                      _fieldMatrix![currentRow][currentCol - 1].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                    if (currentRow < _fieldMatrix!.length - 1) {
                                      // Make sure we don't go out of bounds for this row
                                      int targetCol = currentCol;
                                      if (targetCol >= _fieldMatrix![currentRow + 1].length) {
                                        targetCol = _fieldMatrix![currentRow + 1].length - 1;
                                      }
                                      _fieldMatrix![currentRow + 1][targetCol].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                    if (currentRow > 0) {
                                      // Make sure we don't go out of bounds for this row
                                      int targetCol = currentCol;
                                      if (targetCol >= _fieldMatrix![currentRow - 1].length) {
                                        targetCol = _fieldMatrix![currentRow - 1].length - 1;
                                      }
                                      _fieldMatrix![currentRow - 1][targetCol].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  
                                  if (handled) {
                                    // Prevent default handling if we handled the key
                                    //event.preventDefault();
                                  }
                                }
                              }
                            },
                            child: TextFormField(
                              controller: _internal1Controllers[studentId],
                              focusNode: _internal1FocusNodes[studentId],
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
                              textAlign: TextAlign.center,
                              onFieldSubmitted: (_) {
                                // Move to the next field on enter
                                if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                                  // Find the position of the current field in the matrix
                                  int currentRow = -1;
                                  int currentCol = -1;
                                  
                                  for (int i = 0; i < _fieldMatrix!.length; i++) {
                                    for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                      if (_fieldMatrix![i][j] == _internal1FocusNodes[studentId]) {
                                        currentRow = i;
                                        currentCol = j;
                                        break;
                                      }
                                    }
                                    if (currentRow != -1) break;
                                  }
                                  
                                  if (currentRow == -1) return;
                                  
                                  // Move to next field (similar to Enter key logic)
                                  int nextRow = currentRow;
                                  int nextCol = currentCol + 1;
                                  
                                  if (nextCol >= _fieldMatrix![currentRow].length) {
                                    nextCol = 0;
                                    nextRow++;
                                    
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
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => _saveInternalMark(studentId, '1'),
                          color: Colors.blue,
                          tooltip: 'Save Internal 1',
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent) {
                                if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                                  // Find the position of the current field in the matrix
                                  int currentRow = -1;
                                  int currentCol = -1;
                                  
                                  for (int i = 0; i < _fieldMatrix!.length; i++) {
                                    for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                      if (_fieldMatrix![i][j] == _internal2FocusNodes[studentId]) {
                                        currentRow = i;
                                        currentCol = j;
                                        break;
                                      }
                                    }
                                    if (currentRow != -1) break;
                                  }
                                  
                                  if (currentRow == -1) return;
                                  
                                  // Handle key events
                                  bool handled = false;
                                  
                                  // Enter key - move to next field
                                  if (event.logicalKey == LogicalKeyboardKey.enter || 
                                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                                    int nextRow = currentRow;
                                    int nextCol = currentCol + 1;
                                    
                                    // If we're at the end of a row, move to the next row
                                    if (nextCol >= _fieldMatrix![currentRow].length) {
                                      nextCol = 0;
                                      nextRow++;
                                      
                                      // If we're at the end of all rows, loop back to first row
                                      if (nextRow >= _fieldMatrix!.length) {
                                        nextRow = 0;
                                      }
                                    }
                                    
                                    _fieldMatrix![nextRow][nextCol].requestFocus();
                                    handled = true;
                                  }
                                  // Arrow keys
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                    if (currentCol < _fieldMatrix![currentRow].length - 1) {
                                      _fieldMatrix![currentRow][currentCol + 1].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                    if (currentCol > 0) {
                                      _fieldMatrix![currentRow][currentCol - 1].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                    if (currentRow < _fieldMatrix!.length - 1) {
                                      // Make sure we don't go out of bounds for this row
                                      int targetCol = currentCol;
                                      if (targetCol >= _fieldMatrix![currentRow + 1].length) {
                                        targetCol = _fieldMatrix![currentRow + 1].length - 1;
                                      }
                                      _fieldMatrix![currentRow + 1][targetCol].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                    if (currentRow > 0) {
                                      // Make sure we don't go out of bounds for this row
                                      int targetCol = currentCol;
                                      if (targetCol >= _fieldMatrix![currentRow - 1].length) {
                                        targetCol = _fieldMatrix![currentRow - 1].length - 1;
                                      }
                                      _fieldMatrix![currentRow - 1][targetCol].requestFocus();
                                      handled = true;
                                    }
                                  }
                                  
                                  if (handled) {
                                    // Prevent default handling if we handled the key
                                    //event.preventDefault();
                                  }
                                }
                              }
                            },
                            child: TextFormField(
                              controller: _internal2Controllers[studentId],
                              focusNode: _internal2FocusNodes[studentId],
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
                              textAlign: TextAlign.center,
                              onFieldSubmitted: (_) {
                                // Move to the next field on enter
                                if (_fieldMatrix != null && _fieldMatrix!.isNotEmpty) {
                                  // Find the position of the current field in the matrix
                                  int currentRow = -1;
                                  int currentCol = -1;
                                  
                                  for (int i = 0; i < _fieldMatrix!.length; i++) {
                                    for (int j = 0; j < _fieldMatrix![i].length; j++) {
                                      if (_fieldMatrix![i][j] == _internal2FocusNodes[studentId]) {
                                        currentRow = i;
                                        currentCol = j;
                                        break;
                                      }
                                    }
                                    if (currentRow != -1) break;
                                  }
                                  
                                  if (currentRow == -1) return;
                                  
                                  // Move to next field (similar to Enter key logic)
                                  int nextRow = currentRow;
                                  int nextCol = currentCol + 1;
                                  
                                  if (nextCol >= _fieldMatrix![currentRow].length) {
                                    nextCol = 0;
                                    nextRow++;
                                    
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
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => _saveInternalMark(studentId, '2'),
                          color: Colors.blue,
                          tooltip: 'Save Internal 2',
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
}
