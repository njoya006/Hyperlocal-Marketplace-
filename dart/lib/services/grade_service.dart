import '../models/student.dart';

/// Provides all grading logic for the Grade Calculator application.
///
/// This service is intentionally stateless — every method is pure or
/// has clearly documented side effects (console output). Functional
/// programming patterns (map, where, forEach, higher-order functions)
/// are used throughout to keep the code declarative and testable.
class GradeService {
  // ---------------------------------------------------------------------------
  // Grading scale boundaries
  // ---------------------------------------------------------------------------

  static const Map<String, (double min, double max)> _gradeBands = {
    'A':  (80, 100),
    'B+': (70, 79.99),
    'B':  (60, 69.99),
    'C+': (55, 59.99),
    'C':  (50, 54.99),
    'D+': (45, 49.99),
    'D':  (40, 44.99),
    'F':  (0,  39.99),
  };

  /// The set of grades that constitute a passing result.
  static const Set<String> _passingGrades = {'A', 'B+', 'B', 'C+', 'C'};

  // ---------------------------------------------------------------------------
  // Core grading helpers
  // ---------------------------------------------------------------------------

  /// Returns the letter grade for [mark] based on the university grading scale.
  ///
  /// Scale:
  /// | Grade | Range       |
  /// |-------|-------------|
  /// | A     | 80 – 100    |
  /// | B+    | 70 – 79     |
  /// | B     | 60 – 69     |
  /// | C+    | 55 – 59     |
  /// | C     | 50 – 54     |
  /// | D+    | 45 – 49     |
  /// | D     | 40 – 44     |
  /// | F     | 0  – 39     |
  ///
  /// Throws an [ArgumentError] if [mark] is outside the range [0, 100].
  String assignGrade(double mark) {
    if (mark < 0 || mark > 100) {
      throw ArgumentError(
        'Mark must be between 0 and 100, got $mark.',
      );
    }

    // Iterate in display order; the first matching band wins.
    for (final entry in _gradeBands.entries) {
      final (min, max) = entry.value;
      if (mark >= min && mark <= max) return entry.key;
    }

    // Fallback — mathematically unreachable given the guard above.
    return 'F';
  }

  /// Returns `"Pass"` or `"Fail"` for the given [grade] string.
  ///
  /// Any grade not present in the passing set is treated as `"Fail"`,
  /// which makes this method safe to call with unexpected values.
  String assignStatus(String grade) =>
      _passingGrades.contains(grade) ? 'Pass' : 'Fail';

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns `true` if [student]'s [Student.markOutOf100] is within [0, 100].
  ///
  /// Prints a warning to the console when validation fails, so the caller
  /// can still choose to continue processing while the issue is surfaced
  /// to the user.
  bool validateStudent(Student student) {
    if (!student.isValid()) {
      print(
        'WARNING: Invalid mark for ${student.fullName} '
        '(${student.registrationNumber}): '
        '${student.markOutOf100}. Expected range 0–100.',
      );
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Reporting
  // ---------------------------------------------------------------------------

  /// Returns a multi-line formatted report string for a single [student].
  ///
  /// Example output:
  /// ```
  /// ─────────────────────────────────────────
  /// Name            : Alice Johnson
  /// Registration    : REG-001
  /// Raw Mark        : 15.00
  /// Mark / 100      : 75.00
  /// Grade           : B+
  /// Status          : Pass
  /// ─────────────────────────────────────────
  /// ```
  String formatStudentReport(Student student) {
    final divider = '─' * 41;
    final lines = [
      divider,
      'Name            : ${student.fullName}',
      'Registration    : ${student.registrationNumber}',
      'Raw Mark        : ${student.rawMark.toStringAsFixed(2)}',
      'Mark / 100      : ${student.markOutOf100.toStringAsFixed(2)}',
      'Grade           : ${student.grade ?? 'N/A'}',
      'Status          : ${student.status ?? 'N/A'}',
      divider,
    ];
    return lines.join('\n');
  }

  // ---------------------------------------------------------------------------
  // Functional list operations
  // ---------------------------------------------------------------------------

  /// Uses `map` to return a new list where every [Student] has been assigned
  /// a [Student.grade] and [Student.status] based on their [Student.markOutOf100].
  ///
  /// Invalid students (see [validateStudent]) are included in the returned list
  /// unchanged so that nothing is silently dropped; callers can filter them out
  /// with [getFailingStudents] or a custom predicate.
  List<Student> processStudents(List<Student> students) =>
      students.map((student) {
        if (!validateStudent(student)) return student;
        final grade = assignGrade(student.markOutOf100);
        final status = assignStatus(grade);
        return student.copyWith(grade: grade, status: status);
      }).toList();

  /// Uses `where` to return only students whose [Student.status] is `"Pass"`.
  ///
  /// Students with a `null` status (not yet graded) are excluded.
  List<Student> getPassingStudents(List<Student> students) =>
      students.where((s) => s.status == 'Pass').toList();

  /// Uses `where` to return only students whose [Student.status] is `"Fail"`.
  ///
  /// Students with a `null` status (not yet graded) are excluded.
  List<Student> getFailingStudents(List<Student> students) =>
      students.where((s) => s.status == 'Fail').toList();

  /// Uses `forEach` to print each student's display line to the console.
  ///
  /// Each line is produced by [Student.toDisplayString], which includes the
  /// registration number, full name, mark, grade, and status.
  void printAllStudents(List<Student> students) =>
      students.forEach((s) => print(s.toDisplayString()));

  /// A custom higher-order function that applies [operation] to every student
  /// and returns the collected results as a [List<String>].
  ///
  /// This demonstrates passing a lambda (function value) as a first-class
  /// parameter. The caller fully controls the transformation logic.
  ///
  /// Example — extract student names:
  /// ```dart
  /// final names = gradeService.applyToStudents(
  ///   students,
  ///   (s) => s.fullName,
  /// );
  /// ```
  List<String> applyToStudents(
    List<Student> students,
    String Function(Student) operation,
  ) =>
      students.map(operation).toList();

  // ---------------------------------------------------------------------------
  // Summary & statistics
  // ---------------------------------------------------------------------------

  /// Computes an aggregate summary for [students] and returns it as a [Map].
  ///
  /// Keys returned:
  /// | Key            | Type   | Description                              |
  /// |----------------|--------|------------------------------------------|
  /// | `totalStudents`| int    | Total number of students                 |
  /// | `passCount`    | int    | Number of students who passed            |
  /// | `failCount`    | int    | Number of students who failed            |
  /// | `average`      | double | Mean mark across all students            |
  /// | `highest`      | double | Highest [Student.markOutOf100]           |
  /// | `lowest`       | double | Lowest [Student.markOutOf100]            |
  ///
  /// Returns a map of zeroes when [students] is empty.
  Map<String, dynamic> generateSummary(List<Student> students) {
    if (students.isEmpty) {
      return {
        'totalStudents': 0,
        'passCount': 0,
        'failCount': 0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
      };
    }

    final marks = students.map((s) => s.markOutOf100).toList();
    final total = marks.fold<double>(0, (sum, m) => sum + m);

    return {
      'totalStudents': students.length,
      'passCount': getPassingStudents(students).length,
      'failCount': getFailingStudents(students).length,
      'average': total / students.length,
      'highest': marks.reduce((a, b) => a > b ? a : b),
      'lowest': marks.reduce((a, b) => a < b ? a : b),
    };
  }

  // ---------------------------------------------------------------------------
  // Mark-scale detection and conversion
  // ---------------------------------------------------------------------------

  /// Auto-detects whether the marks in [students] are on a scale of 20, 40,
  /// or 100 by inspecting the maximum raw mark present.
  ///
  /// Detection rules:
  /// - max ≤ 20  → scale is **20**
  /// - max ≤ 40  → scale is **40**
  /// - otherwise → scale is **100**
  ///
  /// Returns `100` when [students] is empty (safe default — no conversion).
  int detectMarkScale(List<Student> students) {
    if (students.isEmpty) return 100;

    final maxRaw = students
        .map((s) => s.rawMark)
        .reduce((a, b) => a > b ? a : b);

    if (maxRaw <= 20) return 20;
    if (maxRaw <= 40) return 40;
    return 100;
  }

  /// Returns a new list of [Student] objects whose [Student.markOutOf100] has
  /// been scaled from [detectedScale] to 100.
  ///
  /// Conversion formula: `markOutOf100 = (rawMark / detectedScale) * 100`
  ///
  /// When [detectedScale] is already `100` the list is returned unchanged
  /// (no unnecessary object allocation).
  ///
  /// Throws an [ArgumentError] if [detectedScale] is not 20, 40, or 100.
  List<Student> convertMarks(List<Student> students, int detectedScale) {
    if (![20, 40, 100].contains(detectedScale)) {
      throw ArgumentError(
        'detectedScale must be 20, 40, or 100 — got $detectedScale.',
      );
    }

    if (detectedScale == 100) return students;

    return students
        .map((s) => s.copyWith(
              markOutOf100: (s.rawMark / detectedScale) * 100,
            ))
        .toList();
  }
}
