// ============================================================
// SE 3242: Android Application Development
// Week 2 - Dart Exercises
// Exercise 3: Drawable Shapes with Interfaces
// Student: [Your Name]
// Date: March 2026
// Description: Demonstrates interfaces (abstract classes),
//              multiple interface implementation, and
//              polymorphism in Dart using geometric shapes.
// ============================================================

import 'dart:math';

// ─────────────────────────────────────────────────────────────
// Interfaces (abstract classes)
// ─────────────────────────────────────────────────────────────

/// Interface for any object that can be drawn to the console.
///
/// Implementors must provide [draw] and [shapeType].
abstract class Drawable {
  /// Prints an ASCII representation of the shape to the console.
  void draw();

  /// Returns the name of the shape type (e.g. `"Circle"`).
  String shapeType();
}

/// Interface for any geometric object whose area and perimeter
/// can be calculated.
///
/// Implementors must provide [area] and [perimeter].
abstract class Measurable {
  /// Returns the area of the shape.
  double area();

  /// Returns the perimeter (circumference) of the shape.
  double perimeter();
}

// ─────────────────────────────────────────────────────────────
// Concrete shape classes
// ─────────────────────────────────────────────────────────────

/// A circle defined by its [radius].
///
/// Implements both [Drawable] and [Measurable].
class Circle implements Drawable, Measurable {
  /// The radius of the circle.
  final double radius;

  /// Creates a [Circle] with the given [radius].
  Circle(this.radius);

  /// Prints an ASCII representation of a circle.
  @override
  void draw() {
    print('  Circle (r = $radius)');
    print('     .oOo.    ');
    print('   oO     Oo  ');
    print('  O         O ');
    print('   oO     Oo  ');
    print('     .oOo.    ');
  }

  /// Returns the area: π × radius².
  @override
  double area() => pi * radius * radius;

  /// Returns the circumference: 2 × π × radius.
  @override
  double perimeter() => 2 * pi * radius;

  /// Returns `"Circle"`.
  @override
  String shapeType() => 'Circle';
}

/// A square defined by its [side] length.
///
/// Implements both [Drawable] and [Measurable].
class Square implements Drawable, Measurable {
  /// The length of one side of the square.
  final double side;

  /// Creates a [Square] with the given [side] length.
  Square(this.side);

  /// Prints an ASCII representation of a square.
  @override
  void draw() {
    print('  Square (side = $side)');
    print('  +--------+');
    print('  |        |');
    print('  |        |');
    print('  +--------+');
  }

  /// Returns the area: side².
  @override
  double area() => side * side;

  /// Returns the perimeter: 4 × side.
  @override
  double perimeter() => 4 * side;

  /// Returns `"Square"`.
  @override
  String shapeType() => 'Square';
}

/// An equilateral triangle defined by its [base], [height], and [side].
///
/// For an equilateral triangle all three sides are equal, so [side]
/// is used for the perimeter calculation. [base] and [height] are
/// used for the area calculation.
///
/// Implements both [Drawable] and [Measurable].
class Triangle implements Drawable, Measurable {
  /// The length of the base of the triangle.
  final double base;

  /// The perpendicular height of the triangle.
  final double height;

  /// The length of one side (equilateral — all sides equal).
  final double side;

  /// Creates a [Triangle] with the given [base], [height], and [side].
  Triangle({required this.base, required this.height, required this.side});

  /// Prints an ASCII representation of a triangle.
  @override
  void draw() {
    print('  Triangle (base = $base, height = $height, side = $side)');
    print('      /\\      ');
    print('     /  \\     ');
    print('    /    \\    ');
    print('   /______\\   ');
  }

  /// Returns the area: 0.5 × base × height.
  @override
  double area() => 0.5 * base * height;

  /// Returns the perimeter: 3 × side (equilateral).
  @override
  double perimeter() => 3 * side;

  /// Returns `"Triangle"`.
  @override
  String shapeType() => 'Triangle';
}

// ─────────────────────────────────────────────────────────────
// Higher-order helper
// ─────────────────────────────────────────────────────────────

/// Applies [action] to every shape in [shapes].
///
/// This is a custom higher-order function — [action] is a lambda
/// (first-class function value) supplied by the caller, giving
/// full control over what happens to each shape.
///
/// Example — print each shape type:
/// ```dart
/// applyToShapes(shapes, (s) => print(s.shapeType()));
/// ```
void applyToShapes(List<Drawable> shapes, void Function(Drawable) action) {
  shapes.forEach(action);
}

// ─────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────

/// Demonstrates interfaces, multiple-interface implementation,
/// and polymorphism through a series of shape operations.
void main() {
  final separator = '─' * 50;

  // ── Create a mixed list of shapes ─────────────────────────
  final List<Drawable> shapes = [
    Circle(5.0),
    Square(4.0),
    Triangle(base: 6.0, height: 5.196, side: 6.0),
  ];

  // ── Section 1: forEach → draw() each shape ────────────────
  print(separator);
  print('Section 1 — Draw each shape (forEach + draw())');
  print(separator);
  shapes.forEach((shape) {
    shape.draw();
    print('');
  });

  // ── Section 2: cast to Measurable → area & perimeter ──────
  print(separator);
  print('Section 2 — Area & perimeter (Measurable interface)');
  print(separator);

  // Every shape in our list also implements Measurable, so the
  // cast is safe here.  In production code you would use
  // whereType<Measurable>() instead.
  final measurables = shapes.cast<Measurable>();
  measurables.forEach((m) {
    // Recover the shape name via the Drawable interface.
    final name = (m as Drawable).shapeType();
    print('$name → area: ${m.area().toStringAsFixed(4)}'
        '  |  perimeter: ${m.perimeter().toStringAsFixed(4)}');
  });

  print('');

  // ── Section 3: whereType<Circle>() ────────────────────────
  print(separator);
  print('Section 3 — Circles only (whereType<Circle>)');
  print(separator);
  shapes
      .whereType<Circle>()
      .forEach((c) => print('Circle with radius ${c.radius} '
          '→ area: ${c.area().toStringAsFixed(4)}'));

  print('');

  // ── Section 4: higher-order applyToShapes ─────────────────
  print(separator);
  print('Section 4 — Shape types via applyToShapes (higher-order)');
  print(separator);
  applyToShapes(shapes, (shape) => print('Shape type: ${shape.shapeType()}'));

  print(separator);
}
