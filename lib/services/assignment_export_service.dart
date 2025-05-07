import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:markpro_plus/models/assignment_session.dart';
import 'package:markpro_plus/models/student_model.dart';

class AssignmentExportService {
  // Helper method to create Excel workbook and get the default sheet name
  Excel createExcel() {
    // Create a brand new workbook
    return Excel.createExcel();
  }
  
  // Get the default sheet name (typically 'Sheet1')
  String getDefaultSheetName(Excel excel) {
    // This sometimes returns null on web, so we'll provide a fallback
    return excel.getDefaultSheet() ?? excel.sheets.keys.first;
  }
  
  // Helper method to create a new sheet
  void _createSheet(Excel excel, String sheetName) {
    excel[sheetName]; // This creates a new sheet with the given name
  }
  
  // Convert marks to a 5-point scale, matching AssignmentService.convertTo5PointScale
  double convertTo5PointScale(int marks) {
    if (marks >= 36) return 5.0;       // 36-60 marks => 5/5
    if (marks >= 26) return 4.0;       // 26-35 marks => 4/5
    if (marks >= 16) return 3.0;       // 16-25 marks => 3/5
    if (marks >= 6) return 2.0;        // 6-15 marks => 2/5
    if (marks >= 1) return 1.0;        // 1-5 marks => 1/5
    return 0.0;                        // 0 marks => 0/5
  }
  
  // Export Assignment 1 marks
  Future<void> exportAssignment1Marks({
    required AssignmentSession assignmentSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Assignment 1 Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Marks',
        'Converted Marks'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final marksData = assignmentSession.assignmentMarks[studentId]?['assignment1'];
        
        int marks = 0;
        double convertedMarks = 0.0;
        
        if (marksData is Map) {
          // New format with structured data
          if (marksData['marks'] is int) {
            marks = marksData['marks'];
          } else if (marksData['marks'] is double) {
            marks = (marksData['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks with proper field names
          if (marksData['convertedMarks'] is double) {
            convertedMarks = marksData['convertedMarks'];
          } else if (marksData['convertedMarks'] is int) {
            convertedMarks = (marksData['convertedMarks'] as int).toDouble();
          } else if (marksData['assignment1Converted'] is int) {
            // Match the field name used in AssignmentService
            convertedMarks = (marksData['assignment1Converted'] as int).toDouble();
          } else if (marksData['assignment1Converted'] is double) {
            convertedMarks = marksData['assignment1Converted'];
          } else {
            // Calculate if not found using the same method as legacy format
            convertedMarks = convertTo5PointScale(marks);
          }
        } else if (marksData is int) {
          // Legacy format where marks is directly stored as a number
          marks = marksData;
          // Calculate converted marks for legacy format - use the 5-point scale
          convertedMarks = convertTo5PointScale(marks);
        } else if (marksData is double) {
          // Handle case where marks might be stored as double
          marks = marksData.round();
          convertedMarks = convertTo5PointScale(marks);
        }
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(marks);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${assignmentSession.subjectName}_${assignmentSession.branch}_${assignmentSession.year}_${assignmentSession.section}_Assignment1_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export Assignment 1 marks: $e');
    }
  }

  // Export Assignment 2 marks
  Future<void> exportAssignment2Marks({
    required AssignmentSession assignmentSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      
      // Get the default sheet and rename it
      final defaultSheet = getDefaultSheetName(excel);
      final sheetName = 'Assignment 2 Marks';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];
      
      // Add headers
      final headers = [
        'Student ID',
        'Name',
        'Marks',
        'Converted Marks'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final marksData = assignmentSession.assignmentMarks[studentId]?['assignment2'];
        
        int marks = 0;
        double convertedMarks = 0.0;
        
        if (marksData is Map) {
          // New format with structured data
          if (marksData['marks'] is int) {
            marks = marksData['marks'];
          } else if (marksData['marks'] is double) {
            marks = (marksData['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks with proper field names
          if (marksData['convertedMarks'] is double) {
            convertedMarks = marksData['convertedMarks'];
          } else if (marksData['convertedMarks'] is int) {
            convertedMarks = (marksData['convertedMarks'] as int).toDouble();
          } else if (marksData['assignment2Converted'] is int) {
            // Match the field name used in AssignmentService
            convertedMarks = (marksData['assignment2Converted'] as int).toDouble();
          } else if (marksData['assignment2Converted'] is double) {
            convertedMarks = marksData['assignment2Converted'];
          } else {
            // Calculate if not found using the same method as legacy format
            convertedMarks = convertTo5PointScale(marks);
          }
        } else if (marksData is int) {
          // Legacy format where marks is directly stored as a number
          marks = marksData;
          // Calculate converted marks for legacy format - use the 5-point scale
          convertedMarks = convertTo5PointScale(marks);
        } else if (marksData is double) {
          // Handle case where marks might be stored as double
          marks = marksData.round();
          convertedMarks = convertTo5PointScale(marks);
        }
        
        // Add student data
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(marks);
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks);
        
        rowIndex++;
      }
      
      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${assignmentSession.subjectName}_${assignmentSession.branch}_${assignmentSession.year}_${assignmentSession.section}_Assignment2_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export Assignment 2 marks: $e');
    }
  }

  // Export both Assignment 1 and Assignment 2 marks
  Future<void> exportAllAssignmentMarks({
    required AssignmentSession assignmentSession,
    required List<StudentModel> students,
  }) async {
    try {
      // Create a new Excel workbook
      final excel = createExcel();
      final defaultSheet = getDefaultSheetName(excel);
      
      // Create all three sheets
      final sheet1Name = 'Assignment 1 Marks';
      final sheet2Name = 'Assignment 2 Marks';
      final summarySheetName = 'Summary';
      
      // Rename default sheet to first sheet name
      excel.rename(defaultSheet, sheet1Name);
      
      // Create other sheets
      _createSheet(excel, sheet2Name);
      _createSheet(excel, summarySheetName);
      
      // Get sheet references
      final sheet1 = excel[sheet1Name];
      final sheet2 = excel[sheet2Name];
      final summarySheet = excel[summarySheetName];
      
      // Add headers for Assignment 1
      final headers = [
        'Student ID',
        'Name',
        'Marks',
        'Converted Marks'
      ];
      
      for (var i = 0; i < headers.length; i++) {
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data for Assignment 1
      var rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final assignment1Data = assignmentSession.assignmentMarks[studentId]?['assignment1'];
        
        int marks = 0;
        double convertedMarks = 0.0;
        
        if (assignment1Data is Map) {
          // New format with structured data
          if (assignment1Data['marks'] is int) {
            marks = assignment1Data['marks'];
          } else if (assignment1Data['marks'] is double) {
            marks = (assignment1Data['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks with proper field names
          if (assignment1Data['convertedMarks'] is double) {
            convertedMarks = assignment1Data['convertedMarks'];
          } else if (assignment1Data['convertedMarks'] is int) {
            convertedMarks = (assignment1Data['convertedMarks'] as int).toDouble();
          } else if (assignment1Data['assignment1Converted'] is int) {
            // Match the field name used in AssignmentService
            convertedMarks = (assignment1Data['assignment1Converted'] as int).toDouble();
          } else if (assignment1Data['assignment1Converted'] is double) {
            convertedMarks = assignment1Data['assignment1Converted'];
          } else {
            // Calculate if not found using the same method as legacy format
            convertedMarks = convertTo5PointScale(marks);
          }
        } else if (assignment1Data is int) {
          marks = assignment1Data;
          convertedMarks = convertTo5PointScale(marks);
        } else if (assignment1Data is double) {
          marks = assignment1Data.round();
          convertedMarks = convertTo5PointScale(marks);
        }
        
        // Add student data to Assignment 1 sheet
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(marks);
        
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks);
        
        rowIndex++;
      }
      
      // Auto-fit columns for Assignment 1
      for (var i = 0; i < headers.length; i++) {
        sheet1.setColumnWidth(i, 15);
      }
      
      // Add headers for Assignment 2
      for (var i = 0; i < headers.length; i++) {
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data for Assignment 2
      rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        final assignment2Data = assignmentSession.assignmentMarks[studentId]?['assignment2'];
        
        int marks = 0;
        double convertedMarks = 0.0;
        
        if (assignment2Data is Map) {
          // New format with structured data
          if (assignment2Data['marks'] is int) {
            marks = assignment2Data['marks'];
          } else if (assignment2Data['marks'] is double) {
            marks = (assignment2Data['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks with proper field names
          if (assignment2Data['convertedMarks'] is double) {
            convertedMarks = assignment2Data['convertedMarks'];
          } else if (assignment2Data['convertedMarks'] is int) {
            convertedMarks = (assignment2Data['convertedMarks'] as int).toDouble();
          } else if (assignment2Data['assignment2Converted'] is int) {
            // Match the field name used in AssignmentService
            convertedMarks = (assignment2Data['assignment2Converted'] as int).toDouble();
          } else if (assignment2Data['assignment2Converted'] is double) {
            convertedMarks = assignment2Data['assignment2Converted'];
          } else {
            // Calculate if not found using the same method as legacy format
            convertedMarks = convertTo5PointScale(marks);
          }
        } else if (assignment2Data is int) {
          marks = assignment2Data;
          convertedMarks = convertTo5PointScale(marks);
        } else if (assignment2Data is double) {
          marks = assignment2Data.round();
          convertedMarks = convertTo5PointScale(marks);
        }
        
        // Add student data to Assignment 2 sheet
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(marks);
        
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks);
        
        rowIndex++;
      }
      
      // Auto-fit columns for Assignment 2
      for (var i = 0; i < headers.length; i++) {
        sheet2.setColumnWidth(i, 15);
      }
      
      // Add headers for Summary sheet
      final summaryHeaders = [
        'Student ID',
        'Name',
        'Assignment 1 Marks',
        'Assignment 1 Converted',
        'Assignment 2 Marks',
        'Assignment 2 Converted',
        'Total Converted Marks'
      ];
      
      for (var i = 0; i < summaryHeaders.length; i++) {
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(summaryHeaders[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Add data for Summary sheet
      rowIndex = 1;
      for (final student in students) {
        final studentId = student.rollNo;
        
        // Assignment 1 data
        final assignment1Data = assignmentSession.assignmentMarks[studentId]?['assignment1'];
        int marks1 = 0;
        double convertedMarks1 = 0.0;
        
        if (assignment1Data is Map) {
          // New format with structured data
          if (assignment1Data['marks'] is int) {
            marks1 = assignment1Data['marks'];
          } else if (assignment1Data['marks'] is double) {
            marks1 = (assignment1Data['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks
          if (assignment1Data['convertedMarks'] is double) {
            convertedMarks1 = assignment1Data['convertedMarks'];
          } else if (assignment1Data['convertedMarks'] is int) {
            convertedMarks1 = (assignment1Data['convertedMarks'] as int).toDouble();
          } else if (assignment1Data['assignment1Converted'] is int) {
            convertedMarks1 = (assignment1Data['assignment1Converted'] as int).toDouble();
          } else if (assignment1Data['assignment1Converted'] is double) {
            convertedMarks1 = assignment1Data['assignment1Converted'];
          } else {
            // Calculate if not found
            // Calculate if not found using the same method as legacy format
            convertedMarks1 = convertTo5PointScale(marks1);
          }
        } else if (assignment1Data is int) {
          marks1 = assignment1Data;
          convertedMarks1 = convertTo5PointScale(marks1);
        } else if (assignment1Data is double) {
          marks1 = assignment1Data.round();
          convertedMarks1 = convertTo5PointScale(marks1);
        }
        
        // Assignment 2 data
        final assignment2Data = assignmentSession.assignmentMarks[studentId]?['assignment2'];
        int marks2 = 0;
        double convertedMarks2 = 0.0;
        
        if (assignment2Data is Map) {
          // New format with structured data
          if (assignment2Data['marks'] is int) {
            marks2 = assignment2Data['marks'];
          } else if (assignment2Data['marks'] is double) {
            marks2 = (assignment2Data['marks'] as double).round();
          }
          
          // We no longer need outOf since we're using convertTo5PointScale
          
          // Try to extract converted marks
          if (assignment2Data['convertedMarks'] is double) {
            convertedMarks2 = assignment2Data['convertedMarks'];
          } else if (assignment2Data['convertedMarks'] is int) {
            convertedMarks2 = (assignment2Data['convertedMarks'] as int).toDouble();
          } else if (assignment2Data['assignment2Converted'] is int) {
            convertedMarks2 = (assignment2Data['assignment2Converted'] as int).toDouble();
          } else if (assignment2Data['assignment2Converted'] is double) {
            convertedMarks2 = assignment2Data['assignment2Converted'];
          } else {
            // Calculate if not found
            // Calculate if not found using the same method as legacy format
            convertedMarks2 = convertTo5PointScale(marks2);
          }
        } else if (assignment2Data is int) {
          marks2 = assignment2Data;
          convertedMarks2 = convertTo5PointScale(marks2);
        } else if (assignment2Data is double) {
          marks2 = assignment2Data.round();
          convertedMarks2 = convertTo5PointScale(marks2);
        }
        
        // Calculate total converted marks
        double totalConvertedMarks = convertedMarks1 + convertedMarks2;
        // Round to 1 decimal place
        totalConvertedMarks = (totalConvertedMarks * 10).round() / 10;
        
        // Add student data to Summary sheet
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = TextCellValue(student.rollNo);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = TextCellValue(student.name);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = IntCellValue(marks1);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks1);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = IntCellValue(marks2);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          ..value = DoubleCellValue(convertedMarks2);
        
        summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          ..value = DoubleCellValue(totalConvertedMarks);
        
        rowIndex++;
      }
      
      // Auto-fit columns for Summary sheet
      for (var i = 0; i < summaryHeaders.length; i++) {
        summarySheet.setColumnWidth(i, 20);
      }
      
      // Generate the Excel file as bytes
      final bytes = excel.encode();
      
      // Download the file
      if (bytes != null) {
        final uint8list = Uint8List.fromList(bytes);
        final filename = '${assignmentSession.subjectName}_${assignmentSession.branch}_${assignmentSession.year}_${assignmentSession.section}_All_Assignment_Marks.xlsx';
        _downloadExcelFile(uint8list, filename);
      }
    } catch (e) {
      throw Exception('Failed to export all assignment marks: $e');
    }
  }

  // Private method to handle the download
  void _downloadExcelFile(Uint8List bytes, String filename) {
    // Create a Blob
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create a download anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    // Add to the DOM and trigger the download
    html.document.body?.children.add(anchor);
    anchor.click();
    
    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
