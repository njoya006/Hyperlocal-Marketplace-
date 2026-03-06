/// Represents a student with their academic record for grade calculation.
class Student {
  /// The student's first name.
  final String firstName;

  /// The student's last name (family name).
  final String lastName;

  /// The unique university registration number for the student.
  final String registrationNumber;

  /// The original mark as read directly from the input file (CSV or Excel).
  /// This value is preserved to allow tracing back to the source data.
  final double rawMark;

  /// The mark normalised to a scale of 0–100.
  /// If the source data is already out of 100, this equals [rawMark].
  final double markOutOf100;

  /// The letter/categorical grade assigned to the student (e.g. "A", "B+").
  /// Nullable because the grade is computed after the object is created.
  final String? grade;

  /// The pass/fail status derived from [markOutOf100].
  /// Either `"Pass"` or `"Fail"`. Nullable until the status has been assigned.
  final String? status;

  /// Creates a [Student] with all required academic fields.
  ///
  /// [firstName] and [lastName] form the student's display name.
  /// [registrationNumber] must uniquely identify the student within a cohort.
  /// [rawMark] is the value read from the source file before any conversion.
  /// [markOutOf100] is the normalised mark used for grading.
  /// [grade] and [status] are optional and are assigned during grading.
  const Student.create({
    required this.firstName,
    required this.lastName,
    required this.registrationNumber,
    required this.rawMark,
    required this.markOutOf100,
    this.grade,
    this.status,
  });

  /// Returns the student's full name as `"firstName lastName"`.
  String get fullName => '$firstName $lastName';

  /// Returns a new [Student] with the specified fields replaced.
  ///
  /// All parameters are optional. Fields that are not supplied retain the
  /// values from the current instance.
  ///
  /// Example:
  /// ```dart
  /// final graded = student.copyWith(grade: 'A', status: 'Pass');
  /// ```
  Student copyWith({
    String? firstName,
    String? lastName,
    String? registrationNumber,
    double? rawMark,
    double? markOutOf100,
    String? grade,
    String? status,
  }) {
    return Student.create(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      rawMark: rawMark ?? this.rawMark,
      markOutOf100: markOutOf100 ?? this.markOutOf100,
      grade: grade ?? this.grade,
      status: status ?? this.status,
    );
  }

  /// Returns `true` if [markOutOf100] falls within the valid range [0, 100].
  ///
  /// Returns `false` when the mark is negative or exceeds 100, which indicates
  /// a data-entry error or a conversion mistake that should be reported to the
  /// user before proceeding with grading.
  bool isValid() => markOutOf100 >= 0 && markOutOf100 <= 100;

  /// Formats the student record as a human-readable line for console output.
  ///
  /// Produces a fixed-width-friendly string suitable for tabular display, e.g.:
  /// ```
  /// [REG-001] Alice Johnson  |  Mark: 78.50 / 100  |  Grade: B+  |  Status: Pass
  /// ```
  /// Unassigned [grade] or [status] values are shown as `"N/A"`.
  String toDisplayString() {
    final gradeLabel = grade ?? 'N/A';
    final statusLabel = status ?? 'N/A';
    final mark = markOutOf100.toStringAsFixed(2);
    return '[${registrationNumber}] ${fullName.padRight(24)}'
        '|  Mark: $mark / 100  '
        '|  Grade: $gradeLabel  '
        '|  Status: $statusLabel';
  }

  /// Returns a concise debug representation of the student.
  ///
  /// Prefer [toDisplayString] for user-facing console output.
  @override
  String toString() {
    return 'Student('
        'name: $fullName, '
        'reg: $registrationNumber, '
        'mark: $markOutOf100, '
        'grade: $grade, '
        'status: $status'
        ')';
  }
}
