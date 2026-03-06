import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;

import '../models/student.dart';

/// Parses student data from CSV, Excel (.xlsx), and plain-text files
/// into a list of [Student] objects.
///
/// Column names are matched case-insensitively using a set of known aliases,
/// so files produced by different tools (e.g. `"First Name"` vs `"first_name"`)
/// are handled without manual pre-processing.
class FileParser {
  // ---------------------------------------------------------------------------
  // Column-name aliases (lower-case, spaces stripped for comparison)
  // ---------------------------------------------------------------------------

  static const List<String> _firstNameAliases = [
    'firstname', 'first_name', 'first'
  ];

  static const List<String> _lastNameAliases = [
    'lastname', 'last_name', 'last', 'surname'
  ];

  static const List<String> _regAliases = [
    'registrationnumber', 'regnumber', 'reg_number',
    'registration', 'regno', 'reg', 'id', 'studentid'
  ];

  static const List<String> _markAliases = [
    'mark', 'marks', 'score', 'total', 'grade'
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Inspects the file extension of [filePath] and returns one of:
  /// `"csv"`, `"excel"`, `"txt"`, or `"unsupported"`.
  ///
  /// Both `.xlsx` and `.xls` extensions map to `"excel"`.
  String detectFileType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.csv':
        return 'csv';
      case '.xlsx':
      case '.xls':
        return 'excel';
      case '.txt':
        return 'txt';
      default:
        return 'unsupported';
    }
  }

  /// Parses [filePath] and returns the student records it contains.
  ///
  /// Delegates to [_parseCsv], [_parseExcel], or [_parseTxt] based on the
  /// file type detected by [detectFileType].
  ///
  /// Throws a [FileSystemException] if the file does not exist on disk.
  /// Throws an [UnsupportedError] if the file extension is not recognised.
  List<Student> parseFile(String filePath) {
    if (!File(filePath).existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final fileType = detectFileType(filePath);
    switch (fileType) {
      case 'csv':
        return _parseCsv(filePath);
      case 'excel':
        return _parseExcel(filePath);
      case 'txt':
        return _parseTxt(filePath);
      default:
        throw UnsupportedError(
          'File type not supported: "${path.extension(filePath)}". '
          'Please provide a .csv, .xlsx, or .txt file.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Private parsers
  // ---------------------------------------------------------------------------

  /// Reads a CSV file at [filePath] and returns a list of [Student] objects.
  ///
  /// The first non-empty row is treated as the header. Subsequent rows are
  /// mapped to fields using case-insensitive alias matching. Malformed or
  /// incomplete rows are skipped with a printed warning.
  List<Student> _parseCsv(String filePath) {
    final content = File(filePath).readAsStringSync();

    // Support both \r\n and \n line endings.
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content.replaceAll('\r\n', '\n'));

    if (rows.isEmpty) {
      print('WARNING: CSV file is empty — $filePath');
      return [];
    }

    final headers = rows.first.map((h) => h.toString().trim()).toList();
    final columnMap = _buildColumnMap(headers);

    final students = <Student>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      final rawRow = <String, String>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        rawRow[headers[j]] = row[j].toString().trim();
      }

      final student = _buildStudent(
        _resolveRow(rawRow, columnMap),
        lineNumber: i + 1,
        source: filePath,
      );
      if (student != null) students.add(student);
    }

    return students;
  }

  /// Reads the first sheet of an Excel (.xlsx / .xls) file at [filePath] and
  /// returns a list of [Student] objects.
  ///
  /// The first non-empty row is treated as the header. Malformed or
  /// incomplete rows are skipped with a printed warning.
  List<Student> _parseExcel(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);

    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName]!;
    final rows = sheet.rows;

    if (rows.isEmpty) {
      print('WARNING: Excel sheet "$sheetName" is empty — $filePath');
      return [];
    }

    final headers = rows.first
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList();
    final columnMap = _buildColumnMap(headers);

    final students = <Student>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final allEmpty = row.every(
        (cell) => (cell?.value?.toString() ?? '').trim().isEmpty,
      );
      if (allEmpty) continue;

      final rawRow = <String, String>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        rawRow[headers[j]] = row[j]?.value?.toString().trim() ?? '';
      }

      final student = _buildStudent(
        _resolveRow(rawRow, columnMap),
        lineNumber: i + 1,
        source: filePath,
      );
      if (student != null) students.add(student);
    }

    return students;
  }

  /// Reads a plain-text file at [filePath] where columns are separated by
  /// tabs or two or more consecutive spaces, and returns a list of [Student]
  /// objects.
  ///
  /// The first non-empty line is treated as the header. Malformed or
  /// incomplete rows are skipped with a printed warning.
  List<Student> _parseTxt(String filePath) {
    final lines = File(filePath).readAsLinesSync();
    final nonEmpty = lines.where((l) => l.trim().isNotEmpty).toList();

    if (nonEmpty.isEmpty) {
      print('WARNING: TXT file is empty — $filePath');
      return [];
    }

    // Split on a tab OR two or more consecutive spaces.
    final splitter = RegExp(r'\t| {2,}');

    final headers =
        nonEmpty.first.split(splitter).map((h) => h.trim()).toList();
    final columnMap = _buildColumnMap(headers);

    final students = <Student>[];
    for (var i = 1; i < nonEmpty.length; i++) {
      final parts =
          nonEmpty[i].split(splitter).map((p) => p.trim()).toList();

      final rawRow = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        rawRow[headers[j]] = parts[j];
      }

      final student = _buildStudent(
        _resolveRow(rawRow, columnMap),
        lineNumber: i + 1,
        source: filePath,
      );
      if (student != null) students.add(student);
    }

    return students;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a map from canonical field names (`"firstName"`, `"lastName"`,
  /// `"reg"`, `"mark"`) to the actual header strings found in the file.
  ///
  /// Matching is case-insensitive and ignores spaces, so `"First Name"`,
  /// `"firstname"`, and `"first_name"` all resolve to `"firstName"`.
  Map<String, String> _buildColumnMap(List<String> headers) {
    final result = <String, String>{};

    for (final header in headers) {
      // Normalise: lower-case and strip spaces/underscores for alias lookup.
      final key = header.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');
      if (_firstNameAliases.contains(key)) result['firstName'] = header;
      if (_lastNameAliases.contains(key)) result['lastName'] = header;
      if (_regAliases.contains(key)) result['reg'] = header;
      if (_markAliases.contains(key)) result['mark'] = header;
    }

    return result;
  }

  /// Translates a raw row map (actual-header → value) into a canonical map
  /// (`fieldName → value`) using [columnMap] produced by [_buildColumnMap].
  Map<String, String> _resolveRow(
    Map<String, String> rawRow,
    Map<String, String> columnMap,
  ) {
    return {
      'firstName': rawRow[columnMap['firstName'] ?? ''] ?? '',
      'lastName': rawRow[columnMap['lastName'] ?? ''] ?? '',
      'reg': rawRow[columnMap['reg'] ?? ''] ?? '',
      'mark': rawRow[columnMap['mark'] ?? ''] ?? '',
    };
  }

  /// Constructs a [Student] from a canonical [row] map and returns it, or
  /// returns `null` if the row is malformed.
  ///
  /// A warning is printed when:
  /// - Any required field (`firstName`, `lastName`, `reg`, `mark`) is empty.
  /// - The mark value cannot be parsed as a [double].
  ///
  /// [lineNumber] and [source] are included in warning messages to help the
  /// user locate and fix bad data.
  ///
  /// The [Student.markOutOf100] is initialised to the same value as
  /// [Student.rawMark]. Scale conversion (out of 20 / 40 → out of 100)
  /// is deferred to `GradeService.convertMarks`.
  Student? _buildStudent(
    Map<String, String> row, {
    required int lineNumber,
    String source = '',
  }) {
    final firstName = row['firstName'] ?? '';
    final lastName = row['lastName'] ?? '';
    final reg = row['reg'] ?? '';
    final markStr = row['mark'] ?? '';

    if (firstName.isEmpty || lastName.isEmpty || reg.isEmpty || markStr.isEmpty) {
      print(
        'WARNING [$source, row $lineNumber]: Skipping — '
        'one or more required fields are missing. Row: $row',
      );
      return null;
    }

    final rawMark = double.tryParse(markStr);
    if (rawMark == null) {
      print(
        'WARNING [$source, row $lineNumber]: Skipping — '
        '"$markStr" is not a valid number.',
      );
      return null;
    }

    return Student.create(
      firstName: firstName,
      lastName: lastName,
      registrationNumber: reg,
      rawMark: rawMark,
      markOutOf100: rawMark, // Conversion deferred to GradeService.convertMarks
    );
  }
}
