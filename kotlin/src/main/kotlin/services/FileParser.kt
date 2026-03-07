// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: FileParser.kt
// Branch: Precious
// Description: Reads student data from CSV, Excel and TXT
//              files into a list of Student objects.
// ============================================================

package com.gradecalculator.services

import com.gradecalculator.models.Student
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser
import org.apache.poi.ss.usermodel.Cell
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.Row
import org.apache.poi.ss.usermodel.WorkbookFactory
import java.io.File
import java.io.FileReader

/**
 * Parses student data from CSV, Excel (.xlsx) and plain-text (TXT) files into
 * a list of [Student] objects ready for the grading pipeline.
 *
 * ### Supported file types
 * | Extension       | Format                          |
 * |-----------------|---------------------------------|
 * | `.csv`          | Comma-separated values          |
 * | `.xlsx` / `.xls`| Microsoft Excel workbook        |
 * | `.txt`          | Tab- or multi-space-delimited   |
 *
 * ### Flexible column detection
 * The parser recognises all of the following header aliases (case-insensitive):
 * | Canonical field      | Accepted aliases                                        |
 * |----------------------|---------------------------------------------------------|
 * | `firstName`          | `firstname`, `first_name`, `first`                      |
 * | `lastName`           | `lastname`, `last_name`, `surname`                      |
 * | `registrationNumber` | `registrationnumber`, `reg_number`, `regno`, `reg`, `id`|
 * | `mark`               | `mark`, `marks`, `score`                                |
 *
 * Malformed rows are skipped with a printed warning rather than aborting the
 * entire import, allowing partial results to be returned for valid rows.
 */
class FileParser {

    // ── Column alias map ────────────────────────────────

    /**
     * Maps every accepted header alias (lower-cased, trimmed) to its canonical