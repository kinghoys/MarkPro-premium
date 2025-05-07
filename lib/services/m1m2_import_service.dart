import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/lab_service.dart';

class M1M2ImportService {
  final LabService _labService = LabService();
  
  // Import M1/M2 marks from Excel file
  Future<List<Map<String, dynamic>>> importM1M2FromExcel(BuildContext context) async {
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
      return await _parseM1M2ExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing M1/M2 marks: $e')),
      );
      return [];
    }
  }

  // Parse Excel file and convert to list of M1/M2 marks
  Future<List<Map<String, dynamic>>> _parseM1M2ExcelFile(Uint8List bytes) async {
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
      'm1 marks',
      'm2 marks'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'm1 marks': ['m1', 'mid1', 'midterm1', 'mid term 1', 'midterm 1', 'mid 1'],
      'm2 marks': ['m2', 'mid2', 'midterm2', 'mid term 2', 'midterm 2', 'mid 2']
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
        '- M1 Marks\n' +
        '- M2 Marks'
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
    
    // Get M1/M2 values by checking different possible header names
    double m1Mark = 0.0, m2Mark = 0.0;
    
    // M1 Mark
    for (final key in ['m1 marks', 'm1', 'mid1', 'midterm1', 'mid term 1', 'midterm 1', 'mid 1']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        m1Mark = _parseDoubleSafely(markMap[key].toString());
        break;
      }
    }
    
    // M2 Mark
    for (final key in ['m2 marks', 'm2', 'mid2', 'midterm2', 'mid term 2', 'midterm 2', 'mid 2']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        m2Mark = _parseDoubleSafely(markMap[key].toString());
        break;
      }
    }
    
    // Get name
    final name = markMap['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'm1Mark': m1Mark,
      'm2Mark': m2Mark
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
    
    // Check for M1 marks using different possible headers
    bool hasM1Mark = false;
    for (final key in ['m1 marks', 'm1', 'mid1', 'midterm1', 'mid term 1', 'midterm 1', 'mid 1']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasM1Mark = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 15) {  // M1 is typically 0-15
            throw Exception('M1 marks must be between 0 and 15 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('M1 marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasM1Mark) {
      throw Exception('Missing M1 marks in row ${rowIndex + 1}');
    }
    
    // Check for M2 marks using different possible headers
    bool hasM2Mark = false;
    for (final key in ['m2 marks', 'm2', 'mid2', 'midterm2', 'mid term 2', 'midterm 2', 'mid 2']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasM2Mark = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 15) {  // M2 is typically 0-15
            throw Exception('M2 marks must be between 0 and 15 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('M2 marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasM2Mark) {
      throw Exception('Missing M2 marks in row ${rowIndex + 1}');
    }
  }
  
  // Import M1/M2 marks to lab session
  Future<void> saveImportedM1M2Marks({
    required String labSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        await _labService.saveM1M2Marks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          m1Mark: mark['m1Mark'],
          m2Mark: mark['m2Mark'],
        );
      } catch (e) {
        print('Error saving M1/M2 marks for student ${mark['studentId']}: $e');
        // Continue with other students even if one fails
      }
    }
  }
  
  // Helper to safely parse doubles
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
}
