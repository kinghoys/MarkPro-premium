import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markpro_plus/services/lab_service.dart';

class VivaImportService {
  final LabService _labService = LabService();
  
  // Import Viva and Final Lab Grade marks from Excel file
  Future<List<Map<String, dynamic>>> importVivaMarksFromExcel(BuildContext context) async {
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
      return await _parseVivaExcelFile(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing viva marks: $e')),
      );
      return [];
    }
  }

  // Parse Excel file and convert to list of viva marks
  Future<List<Map<String, dynamic>>> _parseVivaExcelFile(Uint8List bytes) async {
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
      'viva marks',
      'final lab grade'
    ];
    
    // Also accept alternate forms of headers
    final alternateHeaders = {
      'student id': ['studentid', 'student_id', 'roll no', 'id', 'roll number'],
      'viva marks': ['viva', 'viva mark', 'lab viva', 'lab exam'],
      'final lab grade': ['final grade', 'grade', 'final marks', 'final score', 'overall grade']
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
        '- Viva Marks\n' +
        '- Final Lab Grade'
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
    
    // Get viva marks and final grade values by checking different possible header names
    int vivaMark = 0;
    double finalGrade = 0.0;
    
    // Viva Mark
    for (final key in ['viva marks', 'viva', 'viva mark', 'lab viva', 'lab exam']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        vivaMark = _parseIntSafely(markMap[key].toString());
        break;
      }
    }
    
    // Final Grade
    for (final key in ['final lab grade', 'final grade', 'grade', 'final marks', 'final score', 'overall grade']) {
      if (markMap.containsKey(key) && markMap[key] != null) {
        finalGrade = _parseDoubleSafely(markMap[key].toString());
        break;
      }
    }
    
    // Get name
    final name = markMap['name']?.toString() ?? 'Unknown';
    
    // Create standardized mark map
    return {
      'studentId': studentId,
      'name': name,
      'vivaMark': vivaMark,
      'finalGrade': finalGrade
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
    
    // Check for viva marks using different possible headers
    bool hasVivaMark = false;
    for (final key in ['viva marks', 'viva', 'viva mark', 'lab viva', 'lab exam']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasVivaMark = true;
        try {
          final value = int.parse(mark[key].toString());
          if (value < 0 || value > 20) {  // Viva is typically 0-20
            throw Exception('Viva marks must be between 0 and 20 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Viva marks must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasVivaMark) {
      throw Exception('Missing Viva marks in row ${rowIndex + 1}');
    }
    
    // Check for final grade using different possible headers
    bool hasFinalGrade = false;
    for (final key in ['final lab grade', 'final grade', 'grade', 'final marks', 'final score', 'overall grade']) {
      if (mark.containsKey(key) && mark[key] != null) {
        hasFinalGrade = true;
        try {
          final value = double.parse(mark[key].toString());
          if (value < 0 || value > 50) {  // Final grade is typically 0-50
            throw Exception('Final lab grade must be between 0 and 50 in row ${rowIndex + 1}');
          }
        } catch (e) {
          throw Exception('Final lab grade must be a number in row ${rowIndex + 1}');
        }
        break;
      }
    }
    
    if (!hasFinalGrade) {
      throw Exception('Missing Final lab grade in row ${rowIndex + 1}');
    }
  }
  
  // Import viva marks to lab session
  Future<void> saveImportedVivaMarks({
    required String labSessionId,
    required List<Map<String, dynamic>> marks,
  }) async {
    for (final mark in marks) {
      try {
        // Save viva marks
        await _labService.saveVivaMarks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          vivaMarks: mark['vivaMark'],
        );
        
        // Save final lab grade
        await _labService.saveFinalLabMarks(
          labSessionId: labSessionId,
          studentId: mark['studentId'],
          finalLabMarks: mark['finalGrade'],
        );
      } catch (e) {
        print('Error saving viva/final marks for student ${mark['studentId']}: $e');
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
