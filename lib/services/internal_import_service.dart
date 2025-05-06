import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/lab_service.dart';

class InternalImportService {
  final LabService _labService = LabService();
  
  // Import internal marks from Excel file
  Future<List<Map<String, dynamic>>> importInternalMarksFromExcel(BuildContext context) async {
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
      return await _parseInternalExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing internal marks: $e')),
      );
      return [];
    }
  }

  // Parse Excel file and convert to list of internal marks
  Future<List<Map<String, dynamic>>> _parseInternalExcelFile(Uint8List bytes) async {
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
    // Define standard headers used in export (case insensitive)
    final requiredHeaders = [
      'student id', 
      'name',
      'internal 1',
      'internal 2'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'internal 1': ['internal1', 'int1', 'internal test 1', 'int test 1'],
      'internal 2': ['internal2', 'int2', 'internal test 2', 'int test 2']
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
        '- Internal 1\n' +
        '- Internal 2'
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
    
    // Get internal marks by checking different possible header names
    int internal1 = 0, internal2 = 0;
    
    // Internal 1
    for (final key in ['internal 1', 'internal1', 'int1', 'internal test 1', 'int test 1']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        internal1 = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // Internal 2
    for (final key in ['internal 2', 'internal2', 'int2', 'internal test 2', 'int test 2']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        internal2 = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // Get name
    final name = markMap['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'internal1': internal1,
      'internal2': internal2
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
    
    // Check for Internal 1 using different possible headers
    bool hasInternal1 = false;
    for (final key in ['internal 1', 'internal1', 'int1', 'internal test 1', 'int test 1']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasInternal1 = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 15) {  // Internal 1 is typically 0-15
            throw Exception('Internal 1 marks must be between 0 and 15 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Internal 1 marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasInternal1) {
      throw Exception('Missing Internal 1 marks in row ${rowIndex + 1}');
    }
    
    // Check for Internal 2 using different possible headers
    bool hasInternal2 = false;
    for (final key in ['internal 2', 'internal2', 'int2', 'internal test 2', 'int test 2']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasInternal2 = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 15) {  // Internal 2 is typically 0-15
            throw Exception('Internal 2 marks must be between 0 and 15 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Internal 2 marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasInternal2) {
      throw Exception('Missing Internal 2 marks in row ${rowIndex + 1}');
    }
  }
  
  // Import internal marks to lab session
  Future<void> saveImportedInternalMarks({
    required String labSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        // Save Internal 1 mark
        await _labService.saveInternalMarks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          internalNumber: '1',
          mark: mark['internal1'] as int,
        );
        
        // Save Internal 2 mark
        await _labService.saveInternalMarks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          internalNumber: '2',
          mark: mark['internal2'] as int,
        );
      } catch (e) {
        print('Error saving internal marks for student ${mark['studentId']}: $e');
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
