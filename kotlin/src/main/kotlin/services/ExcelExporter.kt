// ============================================================
// SE 3242: Android Application Development
// Grade Calculator — Kotlin Implementation
// File: ExcelExport.kt
// Branch: Precious
// Description: Generates formatted Excel (.xlsx) grade report
//              using Apache POI.
// ============================================================

package com.gradecalculator.services

import com.gradecalculator.models.Student
import org.apache.poi.ss.usermodel.BorderStyle
import org.apache.poi.ss.usermodel.FillPatternType
import org.apache.poi.ss.usermodel.HorizontalAlignment
import org.apache.poi.ss.usermodel.IndexedColors
import org.apache.poi.ss.usermodel.VerticalAlignment
import org.apache.poi.xssf.usermodel.XSSFCellStyle
import org.apache.poi.xssf.usermodel.XSSFColor
import org.apache.poi.xssf.usermodel.XSSFFont
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * Exports a fully-graded list of [Student] records to a formatted Excel (.xlsx)
 * workbook using Apache POI.
 *
 * The generated workbook contains a single sheet ("Grade Report") structured in
 * three logical sections:
 * 1. **Course info header** (rows 1–3) — lecturer, course, department, semester,
 *    academic year, and generation date.
 * 2. **Student data table** (row 5 onward) — bold blue header row followed by one
 *    row per student; the Status cell is colour-coded green (Pass) or red (Fail).
 * 3. **Summary section** — total, pass/fail counts, class average, highest and
 *    lowest mark.
 */
class ExcelExporter {

    // ── Colour constants (RGB) ────────────────────────────────

    private val colourHeaderBg  = byteArrayOf(0x1F.toByte(), 0x56.toByte(), 0x9A.toByte()) // deep blue
    private val colourPassBg    = byteArrayOf(0xC6.toByte(), 0xEF.toByte(), 0xCE.toByte()) // light green
    private val colourFailBg    = byteArrayOf(0xFF.toByte(), 0xC7.toByte(), 0xCE.toByte()) // light red
    private val colourLabelBg   = byteArrayOf(0xF2.toByte(), 0xF2.toByte(), 0xF2.toByte()) // light grey

    // ── Column widths (in POI units: 1/256th of a character) ──
    private val columnWidths = intArrayOf(