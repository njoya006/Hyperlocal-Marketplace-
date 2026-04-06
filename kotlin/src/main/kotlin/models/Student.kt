// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: Student.kt
// Branch: Precious
// Description: Data class representing a student record.
// ============================================================

package com.gradecalculator.models

/**
 * Represents a single student record processed by the Grade Calculator.
 *
 * Instances are typically constructed from an input file (CSV, Excel, or TXT)
 * and enriched in later pipeline stages when [grade] and [status] are assigned.
 *
 * @property firstName          The student's first name.
 * @property lastName           The student's last name.
 * @property registrationNumber The unique registration / student ID number.
 * @property rawMark            The original mark exactly as read from the input file,
 *                              before any scale conversion.
 * @property markOutOf100       The mark normalised to a 0–100 scale, used for
 *                              grade assignment and reporting.
 * @property grade              The letter grade (e.g. "A", "B+") assigned after
 *                              processing; `null` until the grading stage runs.
 * @property status             Pass/fail status ("Pass" or "Fail") assigned after
 *                              processing; `null` until the grading stage runs.
 */
data class Student(
    /** The student's first (given) name. */
    val firstName: String,

    /** The student's last (family) name. */
    val lastName: String,

    /** Unique registration number identifying the student (e.g. "REG001"). */
    val registrationNumber: String,

    /**
     * The raw mark as it appears in the source file.
     * May be on a different scale (e.g. out of 50 or 70) before conversion.
     */
    val rawMark: Double,

    /**
     * The mark converted to a 0–100 scale.
     * This value is used for all grading logic.
     */
    val markOutOf100: Double,