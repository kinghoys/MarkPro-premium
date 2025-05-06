import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/assignment_service.dart';

// Result model for storing import results
class AllAssignmentMarksImportResult {
  final List<Map<String, dynamic>> assignment1Marks;
  final List<Map<String, dynamic>> assignment2Marks;
  final bool hasAssignment1Data;
  final bool hasAssignment2Data;
  
  AllAssignmentMarksImportResult({
    required this.assignment1Marks,
    required this.assignment2Marks,
    required this.hasAssignment1Data,
    required this.hasAssignment2Data,
  });
}

class AssignmentImportService {
  final AssignmentService _assignmentService = AssignmentService();
  
  // Import Assignment 1 marks from Excel file
  Future<List<Map<String, dynamic>>> importAssignment1MarksFromExcel(BuildContext context) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.bytes == null) {
        return [];
      }

      // Get the file as bytes
      final bytes = result.files.single.bytes!;
      
      // Parse the Excel file
      return await _parseAssignment1ExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Assignment 1 marks: $e')),
      );
      return [];
    }
  }

  // Import Assignment 2 marks from Excel file
  Future<List<Map<String, dynamic>>> importAssignment2MarksFromExcel(BuildContext context) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.bytes == null) {
        return [];
      }

      // Get the file as bytes
      final bytes = result.files.single.bytes!;
      
      // Parse the Excel file
      return await _parseAssignment2ExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Assignment 2 marks: $e')),
      );
      return [];
    }
  }
  
  // Import both Assignment 1 and Assignment 2 marks from a single Excel file with multiple sheets
  Future<AllAssignmentMarksImportResult> importAllAssignmentMarksFromExcel(BuildContext context) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.bytes == null) {
        return AllAssignmentMarksImportResult(
          assignment1Marks: [],
          assignment2Marks: [],
          hasAssignment1Data: false,
          hasAssignment2Data: false,
        );
      }

      // Get the file as bytes
      final bytes = result.files.single.bytes!;
      
      // Parse the Excel file for both Assignment 1 and Assignment 2 marks
      return await _parseAllAssignmentMarksExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing all Assignment marks: $e')),
      );
      return AllAssignmentMarksImportResult(
        assignment1Marks: [],
        assignment2Marks: [],
        hasAssignment1Data: false,
        hasAssignment2Data: false,
      );
    }
  }

  // Parse Excel file for Assignment 1 marks
  Future<List<Map<String, dynamic>>> _parseAssignment1ExcelFile(Uint8List bytes) async {
    final marks = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Get the first sheet
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file');
      }
      
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];
      
      if (table == null || table.rows.isEmpty) {
        throw Exception('No data found in the Excel file');
      }
      
      // Get headers from the first row
      final headers = <String>[];
      final headerRow = table.rows[0];
      
      for (final cell in headerRow) {
        if (cell?.value != null) {
          headers.add(cell!.value.toString().trim());
        } else {
          headers.add(''); // Add empty string for null headers
        }
      }
      
      // Validate required headers
      try {
        _validateRequiredHeadersForAssignment1(headers);
      } catch (e) {
        throw Exception('Header validation failed: $e');
      }
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create mark map from row
          final mark = _createAssignment1MarkMapFromRow(headers, row, rowIndex);
          marks.add(mark);
        } catch (e) {
          validationErrors.add('Row ${rowIndex + 1}: $e');
        }
      }
      
      // Check if we have any valid data
      if (marks.isEmpty && validationErrors.isNotEmpty) {
        throw Exception('No valid data found. Errors: ${validationErrors.join(', ')}');
      }
      
      return marks;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  // Parse Excel file for Assignment 2 marks
  Future<List<Map<String, dynamic>>> _parseAssignment2ExcelFile(Uint8List bytes) async {
    final marks = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Get the first sheet
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file');
      }
      
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];
      
      if (table == null || table.rows.isEmpty) {
        throw Exception('No data found in the Excel file');
      }
      
      // Get headers from the first row
      final headers = <String>[];
      final headerRow = table.rows[0];
      
      for (final cell in headerRow) {
        if (cell?.value != null) {
          headers.add(cell!.value.toString().trim());
        } else {
          headers.add(''); // Add empty string for null headers
        }
      }
      
      // Validate required headers
      try {
        _validateRequiredHeadersForAssignment2(headers);
      } catch (e) {
        throw Exception('Header validation failed: $e');
      }
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create mark map from row
          final mark = _createAssignment2MarkMapFromRow(headers, row, rowIndex);
          marks.add(mark);
        } catch (e) {
          validationErrors.add('Row ${rowIndex + 1}: $e');
        }
      }
      
      // Check if we have any valid data
      if (marks.isEmpty && validationErrors.isNotEmpty) {
        throw Exception('No valid data found. Errors: ${validationErrors.join(', ')}');
      }
      
      return marks;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  void _validateRequiredHeadersForAssignment1(List<String> headers) {
    // Simply check if we have student ID and marks columns - don't be strict about other fields
    final normalizedHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    bool hasStudentId = false;
    for (final pattern in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (normalizedHeaders.any((h) => h.contains(pattern))) {
        hasStudentId = true;
        break;
      }
    }
    
    bool hasMarks = false;
    for (final pattern in ['marks', 'mark', 'assignment marks', 'assignment 1 marks', 'assignment1', 'assign1', 'score']) {
      if (normalizedHeaders.any((h) => h.contains(pattern))) {
        hasMarks = true;
        break;
      }
    }
    
    final missingHeaders = <String>[];
    if (!hasStudentId) missingHeaders.add('Student ID');
    if (!hasMarks) missingHeaders.add('Marks');
    
    if (missingHeaders.isNotEmpty) {
      throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
    }
  }

  void _validateRequiredHeadersForAssignment2(List<String> headers) {
    // Simply check if we have student ID and marks columns - don't be strict about other fields
    final normalizedHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    bool hasStudentId = false;
    for (final pattern in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (normalizedHeaders.any((h) => h.contains(pattern))) {
        hasStudentId = true;
        break;
      }
    }
    
    bool hasMarks = false;
    for (final pattern in ['marks', 'mark', 'assignment marks', 'assignment 2 marks', 'assignment2', 'assign2', 'score']) {
      if (normalizedHeaders.any((h) => h.contains(pattern))) {
        hasMarks = true;
        break;
      }
    }
    
    final missingHeaders = <String>[];
    if (!hasStudentId) missingHeaders.add('Student ID');
    if (!hasMarks) missingHeaders.add('Marks');
    
    if (missingHeaders.isNotEmpty) {
      throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
    }
  }

  Map<String, dynamic> _createAssignment1MarkMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    // Create initial map from headers and row values
    final rowData = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (row[i]?.value != null) {
        rowData[headers[i].toLowerCase()] = row[i]!.value.toString().trim();
      }
    }
    
    // Find student ID
    String studentId = '';
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('student id') || key.contains('studentid') || key.contains('roll') || key.contains('id')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          studentId = row[index]!.value.toString().trim();
          break;
        }
      }
    }
    
    if (studentId.isEmpty) {
      throw Exception('Row ${rowIndex + 1}: Student ID is required');
    }
    
    // Find marks - only care about the marks value
    int marks = 0;
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('mark') || key.contains('score') || key.contains('assignment')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          try {
            marks = _parseIntSafely(row[index]!.value.toString());
            break;
          } catch (e) {
            // Just continue to the next potential marks column
          }
        }
      }
    }
    
    // Get name if available, but don't require it
    String name = 'Unknown';
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('name') && !key.contains('id')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          name = row[index]!.value.toString().trim();
          break;
        }
      }
    }
    
    // Always use default values for outOf
    int outOf = 60;  // Default to 60
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'marks': marks,
      'outOf': outOf
    };
  }

  Map<String, dynamic> _createAssignment2MarkMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    // Create initial map from headers and row values
    final rowData = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (row[i]?.value != null) {
        rowData[headers[i].toLowerCase()] = row[i]!.value.toString().trim();
      }
    }
    
    // Find student ID
    String studentId = '';
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('student id') || key.contains('studentid') || key.contains('roll') || key.contains('id')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          studentId = row[index]!.value.toString().trim();
          break;
        }
      }
    }
    
    if (studentId.isEmpty) {
      throw Exception('Row ${rowIndex + 1}: Student ID is required');
    }
    
    // Find marks - only care about the marks value
    int marks = 0;
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('mark') || key.contains('score') || key.contains('assignment')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          try {
            marks = _parseIntSafely(row[index]!.value.toString());
            break;
          } catch (e) {
            // Just continue to the next potential marks column
          }
        }
      }
    }
    
    // Get name if available, but don't require it
    String name = 'Unknown';
    for (final key in headers.map((h) => h.toLowerCase())) {
      if (key.contains('name') && !key.contains('id')) {
        final index = headers.indexWhere((h) => h.toLowerCase() == key);
        if (index >= 0 && index < row.length && row[index]?.value != null) {
          name = row[index]!.value.toString().trim();
          break;
        }
      }
    }
    
    // Always use default values for outOf
    int outOf = 60;  // Default to 60
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'marks': marks,
      'outOf': outOf
    };
  }

  // Helper to safely parse doubles, similar to MidImportService
  double _parseDoubleSafely(String value) {
    if (value.isEmpty) return 0.0;
    // First, try to parse as-is
    double? result = double.tryParse(value);
    if (result != null) return result;
    
    // If that fails, try extracting only numeric characters with a decimal point
    final numericOnly = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numericOnly.isNotEmpty) {
      result = double.tryParse(numericOnly);
      if (result != null) return result;
    }
    
    // Default fallback
    return 0.0;
  }
  
  // Helper to safely parse integers
  int _parseIntSafely(String value) {
    if (value.isEmpty) return 0;
    
    // First try to parse as an integer
    int? result = int.tryParse(value);
    if (result != null) return result;
    
    // If that fails, try parsing as double then convert to int
    try {
      return _parseDoubleSafely(value).round();
    } catch (e) {
      // If all parsing fails, return 0
      return 0;
    }
  }

  // Save imported Assignment 1 marks to Firebase
  Future<Map<String, dynamic>> saveImportedAssignment1Marks({
    required String assignmentSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    final successCount = await _assignmentService.importAssignment1Marks(
      assignmentSessionId: assignmentSessionId,
      marks: marks,
    );
    
    return {
      'successCount': successCount,
      'failedIds': [], // Not tracking failed IDs in this implementation
    };
  }

  // Save imported Assignment 2 marks to Firebase
  Future<Map<String, dynamic>> saveImportedAssignment2Marks({
    required String assignmentSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    final successCount = await _assignmentService.importAssignment2Marks(
      assignmentSessionId: assignmentSessionId,
      marks: marks,
    );
    
    return {
      'successCount': successCount,
      'failedIds': [], // Not tracking failed IDs in this implementation
    };
  }

  // Save both Assignment 1 and Assignment 2 marks to Firebase in one batch
  Future<Map<String, dynamic>> saveAllImportedAssignmentMarks({
    required String assignmentSessionId,
    required List<Map<String, dynamic>> assignment1Marks,
    required List<Map<String, dynamic>> assignment2Marks,
  }) async {
    // Get the latest version of the session since we need to update its marks
    final session = await _assignmentService.getAssignmentSession(assignmentSessionId);
    final updatedAssignmentMarks = Map<String, Map<String, dynamic>>.from(session.assignmentMarks);
    
    int assignment1SuccessCount = 0;
    int assignment2SuccessCount = 0;
    
    // Process Assignment 1 marks first
    for (final mark in assignment1Marks) {
      try {
        final studentId = mark['studentId'];
        if (studentId == null || studentId.isEmpty) continue;
        
        // Parse marks - handle different possible formats
        final markValue = mark['marks'];
        int markInt = 0;
        
        if (markValue is int) {
          markInt = markValue;
        } else if (markValue is double) {
          markInt = markValue.round();
        } else if (markValue is String) {
          markInt = int.tryParse(markValue) ?? 0;
        }
        
        // Calculate converted marks
        final convertedMarks = _assignmentService.convertTo5PointScale(markInt);
        
        // Get existing marks or create new entry
        final existingMarks = updatedAssignmentMarks[studentId] ?? {};
        
        // Update assignment1 in the marks map
        updatedAssignmentMarks[studentId] = {
          ...existingMarks,
          'assignment1': {
            'marks': markInt,
            'outOf': 60,
            'convertedMarks': convertedMarks
          },
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        assignment1SuccessCount++;
      } catch (e) {
        print('Error processing Assignment 1 mark for student ${mark['studentId']}: $e');
      }
    }
    
    // Process Assignment 2 marks
    for (final mark in assignment2Marks) {
      try {
        final studentId = mark['studentId'];
        if (studentId == null || studentId.isEmpty) continue;
        
        // Parse marks - handle different possible formats
        final markValue = mark['marks'];
        int markInt = 0;
        
        if (markValue is int) {
          markInt = markValue;
        } else if (markValue is double) {
          markInt = markValue.round();
        } else if (markValue is String) {
          markInt = int.tryParse(markValue) ?? 0;
        }
        
        // Calculate converted marks
        final convertedMarks = _assignmentService.convertTo5PointScale(markInt);
        
        // Get existing marks or create new entry
        final existingMarks = updatedAssignmentMarks[studentId] ?? {};
        
        // Update assignment2 in the marks map
        updatedAssignmentMarks[studentId] = {
          ...existingMarks,
          'assignment2': {
            'marks': markInt,
            'outOf': 60,
            'convertedMarks': convertedMarks
          },
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        assignment2SuccessCount++;
      } catch (e) {
        print('Error processing Assignment 2 mark for student ${mark['studentId']}: $e');
      }
    }
    
    // Calculate averages for all students
    for (final studentId in updatedAssignmentMarks.keys) {
      final studentMarks = updatedAssignmentMarks[studentId]!;
      
      // Get marks for both assignments
      dynamic assignment1 = studentMarks['assignment1'];
      dynamic assignment2 = studentMarks['assignment2'];
      
      // Initialize mark values
      int assignment1Value = 0;
      int assignment2Value = 0;
      
      // Extract values based on format
      if (assignment1 is int) {
        assignment1Value = assignment1;
      } else if (assignment1 is Map<String, dynamic>) {
        assignment1Value = assignment1['marks'] ?? 0;
      } else if (assignment1 != null) {
        // Handle any other type
        print('Assignment 1 for student $studentId has unexpected type: ${assignment1.runtimeType}');
      }
      
      if (assignment2 is int) {
        assignment2Value = assignment2;
      } else if (assignment2 is Map<String, dynamic>) {
        assignment2Value = assignment2['marks'] ?? 0;
      } else if (assignment2 != null) {
        // Handle any other type
        print('Assignment 2 for student $studentId has unexpected type: ${assignment2.runtimeType}');
      }
      
      // Calculate average and update
      final average = _assignmentService.calculateAssignmentAverage(assignment1Value, assignment2Value);
      studentMarks['average'] = average;
      
      // Update the student's entry
      updatedAssignmentMarks[studentId] = studentMarks;
    }
    
    // Update the entire session with all marks at once
    final updatedSession = session.copyWith(
      assignmentMarks: updatedAssignmentMarks,
      updatedAt: DateTime.now(),
    );
    
    // Save to database
    await _assignmentService.updateAssignmentSession(updatedSession);
    
    return {
      'assignment1SuccessCount': assignment1SuccessCount,
      'assignment2SuccessCount': assignment2SuccessCount,
      'totalSuccessCount': assignment1SuccessCount + assignment2SuccessCount,
      'failedIds': [], // Not tracking failed IDs in this implementation
    };
  }

  // Parse Excel file for both Assignment 1 and Assignment 2 marks
  Future<AllAssignmentMarksImportResult> _parseAllAssignmentMarksExcelFile(Uint8List bytes) async {
    final assignment1Marks = <Map<String, dynamic>>[];
    final assignment2Marks = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    bool hasAssignment1Data = false;
    bool hasAssignment2Data = false;
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Check if the file has any sheets
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file');
      }
      
      // Look for Assignment 1, Assignment 2 or similarly named sheets
      final sheetNames = excel.tables.keys.toList();
      
      // First, look for sheets with exact names
      String? assignment1SheetName;
      String? assignment2SheetName;
      
      for (final name in sheetNames) {
        final lowerName = name.toLowerCase();
        if (lowerName.contains('assignment 1') || lowerName.contains('assignment1')) {
          assignment1SheetName = name;
        } else if (lowerName.contains('assignment 2') || lowerName.contains('assignment2')) {
          assignment2SheetName = name;
        }
      }
      
      // If not found, try to use the first two sheets
      if (assignment1SheetName == null && sheetNames.length >= 1) {
        assignment1SheetName = sheetNames[0];
      }
      
      if (assignment2SheetName == null && sheetNames.length >= 2) {
        assignment2SheetName = sheetNames[1];
      }
      
      // Process Assignment 1 sheet if available
      if (assignment1SheetName != null) {
        final table = excel.tables[assignment1SheetName];
        
        if (table != null && table.rows.isNotEmpty) {
          try {
            // Get headers from the first row
            final headers = <String>[];
            final headerRow = table.rows[0];
            
            for (final cell in headerRow) {
              if (cell?.value != null) {
                headers.add(cell!.value.toString().trim());
              } else {
                headers.add(''); // Add empty string for null headers
              }
            }
            
            // Try to validate the headers for Assignment 1
            try {
              _validateRequiredHeadersForAssignment1(headers);
              
              // Process each row in the Assignment 1 sheet
              for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
                final row = table.rows[rowIndex];
                
                // Skip empty rows
                if (row.isEmpty || row.every((cell) => cell?.value == null)) {
                  continue;
                }
                
                try {
                  // Create mark map from row
                  final mark = _createAssignment1MarkMapFromRow(headers, row, rowIndex);
                  
                  // Skip rows with empty student IDs
                  if (mark['studentId'].toString().trim().isEmpty) {
                    continue;
                  }
                  
                  assignment1Marks.add(mark);
                } catch (e) {
                  validationErrors.add('Assignment 1 sheet, row ${rowIndex + 1}: $e');
                }
              }
              
              hasAssignment1Data = assignment1Marks.isNotEmpty;
            } catch (e) {
              validationErrors.add('Assignment 1 sheet validation error: $e');
            }
          } catch (e) {
            validationErrors.add('Error processing Assignment 1 sheet: $e');
          }
        }
      }
      
      // Process Assignment 2 sheet if available
      if (assignment2SheetName != null) {
        final table = excel.tables[assignment2SheetName];
        
        if (table != null && table.rows.isNotEmpty) {
          try {
            // Get headers from the first row
            final headers = <String>[];
            final headerRow = table.rows[0];
            
            for (final cell in headerRow) {
              if (cell?.value != null) {
                headers.add(cell!.value.toString().trim());
              } else {
                headers.add(''); // Add empty string for null headers
              }
            }
            
            // Try to validate the headers for Assignment 2
            try {
              _validateRequiredHeadersForAssignment2(headers);
              
              // Process each row in the Assignment 2 sheet
              for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
                final row = table.rows[rowIndex];
                
                // Skip empty rows
                if (row.isEmpty || row.every((cell) => cell?.value == null)) {
                  continue;
                }
                
                try {
                  // Create mark map from row
                  final mark = _createAssignment2MarkMapFromRow(headers, row, rowIndex);
                  
                  // Skip rows with empty student IDs
                  if (mark['studentId'].toString().trim().isEmpty) {
                    continue;
                  }
                  
                  assignment2Marks.add(mark);
                } catch (e) {
                  validationErrors.add('Assignment 2 sheet, row ${rowIndex + 1}: $e');
                }
              }
              
              hasAssignment2Data = assignment2Marks.isNotEmpty;
            } catch (e) {
              validationErrors.add('Assignment 2 sheet validation error: $e');
            }
          } catch (e) {
            validationErrors.add('Error processing Assignment 2 sheet: $e');
          }
        }
      }
      
      // If there are validation errors and no valid data was found, throw an exception
      if (validationErrors.isNotEmpty && !hasAssignment1Data && !hasAssignment2Data) {
        throw Exception(
          'Validation errors in Excel file:\n${validationErrors.join('\n')}'
        );
      }
      
      return AllAssignmentMarksImportResult(
        assignment1Marks: assignment1Marks,
        assignment2Marks: assignment2Marks,
        hasAssignment1Data: hasAssignment1Data,
        hasAssignment2Data: hasAssignment2Data,
      );
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }
}
