import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/lab_service.dart';

class MarksImportService {
  final LabService _labService = LabService();
  
  // Import experiment marks from Excel file
  Future<List<Map<String, dynamic>>> importMarksFromExcel(BuildContext context) async {
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
      return await _parseMarksExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing marks: $e')),
      );
      return [];
    }
  }

  // Parse Excel file and convert to list of marks
  Future<List<Map<String, dynamic>>> _parseMarksExcelFile(Uint8List bytes) async {
    final marks = <Map<String, dynamic>>[];
    final validationErrors = <String>[];
    
    try {
      // Decode the Excel file
      final excel = Excel.decodeBytes(bytes);
      
      // Get the first sheet
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];
      
      if (table == null || table.rows.isEmpty) {
        throw Exception('No data found in the Excel file');
      }
      
      // Get headers from the first row
      final headers = _extractHeaderRow(table.rows[0]);
      
      // Validate required headers
      _validateRequiredHeaders(headers);
      
      // Process each row
      for (var rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }
        
        try {
          // Create mark map from row
          final mark = _createMarkMapFromRow(headers, row, rowIndex);
          marks.add(mark);
        } catch (e) {
          validationErrors.add('Error in row ${rowIndex + 1}: $e');
        }
      }
      
      // If there are validation errors, throw an exception
      if (validationErrors.isNotEmpty) {
        throw Exception(
          'Validation errors in Excel file:\n${validationErrors.join('\n')}'
        );
      }
      
      return marks;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  // Extract header row from Excel
  List<String> _extractHeaderRow(List<dynamic> headerRow) {
    return headerRow
        .where((cell) => cell?.value != null)
        .map((cell) => cell!.value.toString().toLowerCase().trim())
        .toList();
  }

  // Validate that required headers are present
  void _validateRequiredHeaders(List<String> headers) {
    // Define standard headers exactly as used in export
    final requiredHeaders = [
      'student id', 
      'name',
      'component a',
      'component b',
      'component c'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'component a': ['componenta', 'a', 'mark a', 'component a (0-5)', 'a (0-5)'],
      'component b': ['componentb', 'b', 'mark b', 'component b (0-5)', 'b (0-5)'],
      'component c': ['componentc', 'c', 'mark c', 'component c (0-10)', 'c (0-10)'],
      'total marks': ['total', 'total mark', 'total (20)'] // Added to match export format
    };
    
    // Normalize headers to lowercase for comparison
    final normalizedHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    // Check for missing headers
    final missingHeaders = <String>[];
    
    for (final required in requiredHeaders) {
      final alternates = alternateHeaders[required] ?? [];
      if (!normalizedHeaders.contains(required.toLowerCase()) && 
          !alternates.any((alt) => normalizedHeaders.contains(alt.toLowerCase()))) {
        missingHeaders.add(required);
      }
    }
    
    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing required headers: ${missingHeaders.join(', ')}\n\n' +
        'Please ensure your Excel file has the following columns:\n' +
        '- Student ID (or Roll No)\n' +
        '- Name\n' +
        '- Component A\n' +
        '- Component B\n' +
        '- Component C\n' +
        '- Total Marks (optional)'
      );
    }
  }

  // Create mark map from Excel row
  Map<String, dynamic> _createMarkMapFromRow(
    List<String> headers, 
    List<dynamic> row,
    int rowIndex
  ) {
    final markMap = <String, dynamic>{};
    
    // Map each cell to the corresponding header
    for (var i = 0; i < headers.length && i < row.length; i++) {
      final header = headers[i];
      final cell = row[i];
      
      if (cell?.value != null) {
        markMap[header] = cell!.value;
      }
    }
    
    // Validate required fields
    _validateMarkData(markMap, rowIndex);
    
    // Get studentId by checking different possible header names
    String? studentId;
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        studentId = markMap[key].toString();
        break;
      }
    }
    
    if (studentId == null) {
      throw Exception('Student ID not found in row ${rowIndex + 1}');
    }
    
    // Get component marks by checking different possible header names
    int componentA = 0, componentB = 0, componentC = 0;
    
    // Component A - match exactly with export format
    for (final key in ['component a', 'componenta', 'a', 'mark a', 'component a (0-5)', 'a (0-5)']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        componentA = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // Component B - match exactly with export format
    for (final key in ['component b', 'componentb', 'b', 'mark b', 'component b (0-5)', 'b (0-5)']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        componentB = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // Component C - match exactly with export format
    for (final key in ['component c', 'componentc', 'c', 'mark c', 'component c (0-10)', 'c (0-10)']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        componentC = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // We check for total marks column to match export format but don't use it
    // since the system will calculate totals automatically
    for (final key in ['total marks', 'total', 'total mark', 'total (20)']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        // Found total marks column, but we don't need to use this value
        // as the system will calculate it from A, B, C components
        break;
      }
    }
    
    // Get name
    final name = markMap['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'A': componentA,
      'B': componentB,
      'C': componentC,
      // We don't need to include total as it will be calculated by the system
    };
  }

  // Validate mark data
  void _validateMarkData(Map<String, dynamic> mark, int rowIndex) {
    // Check for student ID using different possible headers
    bool hasStudentId = false;
    for (final key in ['student id', 'studentid', 'student_id', 'roll no', 'id', 'roll number']) {
      if (mark.containsKey(key) && mark[key] != null && mark[key].toString().isNotEmpty) {
        hasStudentId = true;
        // Validate student ID format (should be at least 5 characters)
        if (mark[key].toString().length < 5) {
          throw Exception('Student ID should be at least 5 characters long in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasStudentId) {
      throw Exception('Missing Student ID in row ${rowIndex + 1}');
    }
    
    // Check for name
    if (!mark.containsKey('name') || mark['name'] == null || mark['name'].toString().isEmpty) {
      throw Exception('Missing student name in row ${rowIndex + 1}');
    }
    
    // Check for component A using different possible headers
    bool hasComponentA = false;
    for (final key in ['component a', 'componenta', 'a', 'mark a']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasComponentA = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 5) {  // Component A is 0-5
            throw Exception('Component A must be between 0 and 5 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Component A must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasComponentA) {
      throw Exception('Missing Component A marks in row ${rowIndex + 1}');
    }
    
    // Check for component B using different possible headers
    bool hasComponentB = false;
    for (final key in ['component b', 'componentb', 'b', 'mark b']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasComponentB = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 5) {  // Component B is 0-5
            throw Exception('Component B must be between 0 and 5 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Component B must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasComponentB) {
      throw Exception('Missing Component B marks in row ${rowIndex + 1}');
    }
    
    // Check for component C using different possible headers
    bool hasComponentC = false;
    for (final key in ['component c', 'componentc', 'c', 'mark c']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasComponentC = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 10) {  // Component C is 0-10
            throw Exception('Component C must be between 0 and 10 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Component C must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasComponentC) {
      throw Exception('Missing Component C marks in row ${rowIndex + 1}');
    }
  }
  
  // Import marks to lab session
  Future<void> saveImportedMarks({
    required String labSessionId,
    required String experimentNumber,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        await _labService.saveExperimentMarks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          experimentNumber: experimentNumber,
          markA: mark['A'] as int,
          markB: mark['B'] as int,
          markC: mark['C'] as int,
        );
      } catch (e) {
        print('Error saving marks for student ${mark['studentId']}: $e');
        // Continue with other students even if one fails
      }
    }
  }
  
  // Helper to safely parse integers
  int _parseIntSafely(String value) {
    if (value.isEmpty) return 0;
    // First, try to parse as-is
    int? result = int.tryParse(value);
    if (result != null) return result;
    
    // Try parsing as double and convert to int
    double? doubleResult = double.tryParse(value);
    if (doubleResult != null) return doubleResult.toInt();
    
    // If that fails, try extracting only numeric characters
    final numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isNotEmpty) {
      result = int.tryParse(numericOnly);
      if (result != null) return result;
    }
    
    // Default fallback
    return 0;
  }
}
