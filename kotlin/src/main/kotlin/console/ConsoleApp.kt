// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: ConsoleApp.kt
// Branch: Precious
// Description: Interactive terminal/console mode of the
//              Grade Calculator application.
// ============================================================

package com.gradecalculator.console

import com.gradecalculator.models.Student
import com.gradecalculator.services.ExcelExporter
import com.gradecalculator.services.FileParser
import com.gradecalculator.services.GradeService

/**
 * Drives the interactive console (terminal) mode of the Grade Calculator.
 *
 * Call [run] once to start the guided session. The session walks the operator
 * through six sequential steps:
 *
 * 1. Display the welcome banner.
 * 2. Collect course metadata (lecturer, course name, semester, etc.).
 * 3. Load a student data file (CSV, Excel or TXT) via [FileParser].
 * 4. Detect and optionally override the mark scale, then convert marks.
 * 5. Assign grades, display a formatted student table and print summary stats.
 * 6. Export the results to a formatted `.xlsx` report via [ExcelExporter].
 */
class ConsoleApp {

	// ── Service dependencies ────────────────────────────────
	private val fileParser    = FileParser()
	private val gradeService  = GradeService()
	private val excelExporter = ExcelExporter()

	// ────────────────────────────────────────────────────────
	// Public entry point
	// ────────────────────────────────────────────────────────

	/**
	 * Starts the interactive console session and runs all six steps in sequence.
	 *
	 * Errors at each step are caught and displayed without crashing the application;
	 * the operator is given the opportunity to retry where applicable.
	 */
	fun run() {
		printBanner()

		// Step 2 — Collect course info
		// ...existing code...
	}
}