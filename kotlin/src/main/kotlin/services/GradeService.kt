// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: GradeService.kt
// Branch: Precious
// Description: Grading logic using functional programming —
//              map, filter, forEach, higher-order functions.
// ============================================================

package com.gradecalculator.services

import com.gradecalculator.models.Student

/**
 * Service class encapsulating all grading logic for the Grade Calculator.
 *
 * Follows a functional programming style: all collection transformations use
 * [map], [filter], [forEach], and higher-order functions to keep operations
 * stateless, composable and easy to test.
 *
 * ### Grading scale
 * | Range    | Grade | Status |
 * |----------|-------|--------|
 * | 80–100   | A     | Pass   |
 * | 70–79    | B+    | Pass   |
 * | 60–69    | B     | Pass   |
 * | 55–59    | C+    | Pass   |
 * | 50–54    | C     | Pass   |
 * | 45–49    | D+    | Fail   |
 * | 40–44    | D     | Fail   |
 * | 0–39     | F     | Fail   |
 */
class GradeService {

    // ── Core grading ────────────────────────────────

    /**
     * Determines the letter grade for a given normalised mark (0–100 scale).
     *
     * Uses a Kotlin `when` expression for clarity and exhaustive coverage.
     *
     * @param mark The student's mark out of 100.
     * @return The corresponding letter grade string (e.g. `"A"`, `"B+"`, `"F"`).
     */
    fun assignGrade(mark: Double): String = when {
        mark >= 80.0 -> "A"
        mark >= 70.0 -> "B+"
        mark >= 60.0 -> "B"
        mark >= 55.0 -> "C+"
        mark >= 50.0 -> "C"