import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;

import '../models/student.dart';

/// Generates a formatted Excel (.xlsx) report file from graded student data.
///
/// The output workbook contains a single sheet with three sections:
/// a course-info header, a numbered student table, and a summary block.
class ExcelExporter {
  // ---------------------------------------------------------------------------
  // Colour constants (ARGB hex strings)
  // ---------------------------------------------------------------------------

  static final ExcelColor _passColour =
      ExcelColor.fromHexString('FF92D050'); // light green
  static final ExcelColor _failColour =
      ExcelColor.fromHexString('FFFF9999'); // light red
  static final ExcelColor _headerBg =
      ExcelColor.fromHexString('FF4472C4'); // blue header row
  static final ExcelColor _headerFg = ExcelColor.white;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Builds and writes an Excel report to [outputPath].
  ///
  /// Parameters:
  /// - [students]   — the fully graded list of [Student] objects.
  /// - [outputPath] — absolute or relative file path for the `.xlsx` output.
  /// - [courseInfo] — map with keys: `lecturerName`, `courseName`,
  ///                  `semester`, `academicYear`, `department`.
  /// - [summary]    — map with keys: `totalStudents` (int), `passCount` (int),
  ///                  `failCount` (int), `average` (double),
  ///                  `highest` (double), `lowest` (double).
  ///
  /// Creates any missing parent directories before writing.
  /// Throws a [FileSystemException] if the file cannot be written.
  void exportToExcel({
    required List<Student> students,
    required String outputPath,
    required Map<String, String> courseInfo,
    required Map<String, dynamic> summary,
  }) {
    // Ensure output directory exists.
    final dir = path.dirname(outputPath);
    if (dir.isNotEmpty && dir != '.') {
      Directory(dir).createSync(recursive: true);
    }

    final excel = Excel.createExcel();

    // Remove the default blank sheet created by the package.
    excel.delete('Sheet1');

    final sheetName = 'Grade Report';
    final sheet = excel[sheetName];

    // Track current row (0-based).
    var row = 0;

    row = _writeHeaderSection(sheet, row, courseInfo);
    row = _writeStudentTable(sheet, row, students);
    row = _writeSummarySection(sheet, row, summary);

    _setColumnWidths(sheet);

    // Encode and write bytes to disk.
    final bytes = excel.encode();
    if (bytes == null) {
      throw FileSystemException(
        'Excel encoding returned null — no data was written.',
        outputPath,
      );
    }
    File(outputPath).writeAsBytesSync(bytes);
  }

  // ---------------------------------------------------------------------------
  // Section writers
  // ---------------------------------------------------------------------------

  /// Writes rows 1–4 (0-based indices 0–3): course info labels and values.
  ///
  /// Layout (each pair occupies columns 0–1 and 3–4, column 2 is blank):
  /// ```
  /// Row 0: "Course Name:"   | value | "" | "Lecturer:"      | value
  /// Row 1: "Department:"    | value | "" | "Semester:"      | value
  /// Row 2: "Academic Year:" | value | "" | "Date Generated:"| DD/MM/YYYY
  /// Row 3: (empty)
  /// ```
  int _writeHeaderSection(
    Sheet sheet,
    int startRow,
    Map<String, String> courseInfo,
  ) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final boldStyle = CellStyle(bold: true);

    // Row 0
    _writeCell(sheet, startRow, 0, 'Course Name:', style: boldStyle);
    _writeCell(sheet, startRow, 1, courseInfo['courseName'] ?? '');
    _writeCell(sheet, startRow, 3, 'Lecturer:', style: boldStyle);
    _writeCell(sheet, startRow, 4, courseInfo['lecturerName'] ?? '');

    // Row 1
    _writeCell(sheet, startRow + 1, 0, 'Department:', style: boldStyle);
    _writeCell(sheet, startRow + 1, 1, courseInfo['department'] ?? '');
    _writeCell(sheet, startRow + 1, 3, 'Semester:', style: boldStyle);
    _writeCell(sheet, startRow + 1, 4, courseInfo['semester'] ?? '');

    // Row 2
    _writeCell(sheet, startRow + 2, 0, 'Academic Year:', style: boldStyle);
    _writeCell(sheet, startRow + 2, 1, courseInfo['academicYear'] ?? '');
    _writeCell(sheet, startRow + 2, 3, 'Date Generated:', style: boldStyle);
    _writeCell(sheet, startRow + 2, 4, dateStr);

    // Row 3 — blank separator
    return startRow + 4;
  }

  /// Writes the column-header row (bold, coloured) and one data row per student.
  ///
  /// Columns: No. | First Name | Last Name | Reg. Number |
  ///          Raw Mark | Mark /100 | Grade | Status
  ///
  /// The Status cell background is green for "Pass" and red for "Fail".
  int _writeStudentTable(
    Sheet sheet,
    int startRow,
    List<Student> students,
  ) {
    // Column header row
    final colHeaders = [
      'No.',
      'First Name',
      'Last Name',
      'Reg. Number',
      'Raw Mark',
      'Mark /100',
      'Grade',
      'Status',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: _headerBg,
      fontColorHex: _headerFg,
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var col = 0; col < colHeaders.length; col++) {
      _writeCell(sheet, startRow, col, colHeaders[col], style: headerStyle);
    }

    var row = startRow + 1;

    // Student data rows
    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      final isPass = s.status == 'Pass';

      final statusStyle = CellStyle(
        backgroundColorHex: isPass ? _passColour : _failColour,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      final centreStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

      _writeCell(sheet, row, 0, (i + 1).toString(),
          style: centreStyle);
      _writeCell(sheet, row, 1, s.firstName);
      _writeCell(sheet, row, 2, s.lastName);
      _writeCell(sheet, row, 3, s.registrationNumber);
      _writeCell(sheet, row, 4, s.rawMark.toStringAsFixed(2),
          style: centreStyle);
      _writeCell(sheet, row, 5, s.markOutOf100.toStringAsFixed(2),
          style: centreStyle);
      _writeCell(sheet, row, 6, s.grade ?? 'N/A', style: centreStyle);
      _writeCell(sheet, row, 7, s.status ?? 'N/A', style: statusStyle);

      row++;
    }

    return row; // points to the row after the last student
  }

  /// Writes the summary block after the student table.
  ///
  /// Layout:
  /// ```
  /// (empty row)
  /// "Total Students:" | value
  /// "Pass:"           | value  | "" | "Fail:"         | value
  /// "Class Average:"  | value (1 d.p.)
  /// "Highest Mark:"   | value  | "" | "Lowest Mark:"  | value
  /// ```
  int _writeSummarySection(
    Sheet sheet,
    int startRow,
    Map<String, dynamic> summary,
  ) {
    final boldStyle = CellStyle(bold: true);

    // Blank separator row
    var row = startRow + 1;

    // Total students
    _writeCell(sheet, row, 0, 'Total Students:', style: boldStyle);
    _writeCell(sheet, row, 1, '${summary['totalStudents'] ?? 0}');
    row++;

    // Pass / Fail counts
    _writeCell(sheet, row, 0, 'Pass:', style: boldStyle);
    _writeCell(sheet, row, 1, '${summary['passCount'] ?? 0}');
    _writeCell(sheet, row, 3, 'Fail:', style: boldStyle);
    _writeCell(sheet, row, 4, '${summary['failCount'] ?? 0}');
    row++;

    // Average
    final avg = (summary['average'] as num?)?.toDouble() ?? 0.0;
    _writeCell(sheet, row, 0, 'Class Average:', style: boldStyle);
    _writeCell(sheet, row, 1, avg.toStringAsFixed(1));
    row++;

    // Highest / Lowest
    final highest = (summary['highest'] as num?)?.toDouble() ?? 0.0;
    final lowest = (summary['lowest'] as num?)?.toDouble() ?? 0.0;
    _writeCell(sheet, row, 0, 'Highest Mark:', style: boldStyle);
    _writeCell(sheet, row, 1, highest.toStringAsFixed(2));
    _writeCell(sheet, row, 3, 'Lowest Mark:', style: boldStyle);
    _writeCell(sheet, row, 4, lowest.toStringAsFixed(2));
    row++;

    return row;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Writes [value] as a [TextCellValue] into the cell at ([rowIndex], [colIndex]).
  ///
  /// Optionally applies [style]. Uses [CellIndex.indexByColumnRow] for
  /// consistent zero-based indexing.
  void _writeCell(
    Sheet sheet,
    int rowIndex,
    int colIndex,
    String value, {
    CellStyle? style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
    );
    cell.value = TextCellValue(value);
    if (style != null) cell.cellStyle = style;
  }

  /// Sets appropriate column widths (in character units) for all eight
  /// student-table columns plus the label columns used by the summary.
  void _setColumnWidths(Sheet sheet) {
    // col 0 — No. / label column
    sheet.setColumnWidth(0, 18);
    // col 1 — First Name / value column
    sheet.setColumnWidth(1, 20);
    // col 2 — Last Name
    sheet.setColumnWidth(2, 20);
    // col 3 — Reg. Number / second label column
    sheet.setColumnWidth(3, 18);
    // col 4 — Raw Mark / second value column
    sheet.setColumnWidth(4, 14);
    // col 5 — Mark /100
    sheet.setColumnWidth(5, 13);
    // col 6 — Grade
    sheet.setColumnWidth(6, 10);
    // col 7 — Status
    sheet.setColumnWidth(7, 12);
  }
}
