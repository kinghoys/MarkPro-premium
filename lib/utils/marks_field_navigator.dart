import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class to manage keyboard navigation between mark input fields
class MarksFieldNavigator {
  /// Handles keyboard events for navigating between mark input fields
  /// 
  /// Returns true if the event was handled, false otherwise
  static bool handleKeyEvent(
    RawKeyEvent event, {
    required List<List<FocusNode>> fieldMatrix,
    required int currentRow,
    required int currentCol,
  }) {
    if (event is! RawKeyDownEvent) return false;

    // Handle enter key
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return _moveToNextField(fieldMatrix, currentRow, currentCol);
    }

    // Handle arrow keys
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (currentCol < fieldMatrix[currentRow].length - 1) {
        fieldMatrix[currentRow][currentCol + 1].requestFocus();
        return true;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (currentCol > 0) {
        fieldMatrix[currentRow][currentCol - 1].requestFocus();
        return true;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (currentRow < fieldMatrix.length - 1) {
        fieldMatrix[currentRow + 1][currentCol].requestFocus();
        return true;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (currentRow > 0) {
        fieldMatrix[currentRow - 1][currentCol].requestFocus();
        return true;
      }
    }

    return false;
  }

  /// Move to the next field in sequence: A → B → C → next student's A for experiments
  /// or Internal 1 → next student's Internal 1 for internal marks
  static bool _moveToNextField(
    List<List<FocusNode>> fieldMatrix,
    int currentRow,
    int currentCol,
  ) {
    final rowCount = fieldMatrix.length;
    final colCount = fieldMatrix[0].length;
    
    // Move to next column
    int nextCol = currentCol + 1;
    int nextRow = currentRow;
    
    // If at the end of row, move to the next row
    if (nextCol >= colCount) {
      nextCol = 0;
      nextRow = currentRow + 1;
      
      // If at the end of all rows, loop back to the first row
      if (nextRow >= rowCount) {
        nextRow = 0;
      }
    }
    
    // Request focus on the next field
    fieldMatrix[nextRow][nextCol].requestFocus();
    return true;
  }
  
  /// Creates a field matrix for keyboard navigation
  /// 
  /// For experiment marks: [student1: [A, B, C], student2: [A, B, C], ...]
  /// For internal marks: [student1: [I1, I2], student2: [I1, I2], ...]
  static List<List<FocusNode>> createFieldMatrix({
    required List<String> studentIds,
    required Map<String, Map<String, FocusNode>> markFocusNodes,
    required List<String> components,
  }) {
    final List<List<FocusNode>> matrix = [];
    
    for (final studentId in studentIds) {
      final List<FocusNode> studentFields = [];
      
      for (final component in components) {
        final focusNode = markFocusNodes[component]?[studentId];
        if (focusNode != null) {
          studentFields.add(focusNode);
        }
      }
      
      if (studentFields.isNotEmpty) {
        matrix.add(studentFields);
      }
    }
    
    return matrix;
  }
  
  /// Find the position of the currently focused node in the field matrix
  static Map<String, int> findFocusedPosition(
    List<List<FocusNode>> fieldMatrix,
    FocusNode currentFocus,
  ) {
    for (int i = 0; i < fieldMatrix.length; i++) {
      for (int j = 0; j < fieldMatrix[i].length; j++) {
        if (fieldMatrix[i][j] == currentFocus) {
          return {'row': i, 'col': j};
        }
      }
    }
    
    return {'row': 0, 'col': 0}; // Default position if not found
  }
}
