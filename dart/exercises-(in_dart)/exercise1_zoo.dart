// ============================================================
// SE 3242: Android Application Development
// Week 2 - Dart Exercises
// Exercise 1: Model a Zoo
// Student: [Your Name]
// Date: March 2026
// Description: Demonstrates abstract classes, inheritance,
//              and polymorphism in Dart using a Zoo example.
// ============================================================

// ─────────────────────────────────────────────────────────────
// Abstract base class
// ─────────────────────────────────────────────────────────────

/// Abstract base class representing any animal in the zoo.
///
/// Concrete subclasses must implement [legs] and [makeSound].
/// The concrete method [describe] is shared by all animals.
abstract class Animal {
  /// The animal's name (e.g. "Rex", "Whiskers").
  final String name;

  /// Creates an [Animal] with the given [name].
  Animal(this.name);

  /// Returns the number of legs this animal has.
  int get legs;

  /// Returns the sound this animal makes as a [String].
  String makeSound();

  /// Returns a human-readable description using [name], [legs], and [makeSound].
  ///
  /// Example: `"Rex has 4 legs and says Woof!"`
  String describe() => '$name has $legs legs and says ${makeSound()}';

  /// Returns a concise debug representation of the animal.
  @override
  String toString() => '${runtimeType}(name: $name, legs: $legs)';
}

// ─────────────────────────────────────────────────────────────
// Concrete subclasses
// ─────────────────────────────────────────────────────────────

/// A [Dog] — a four-legged animal that barks.
class Dog extends Animal {
  /// Creates a [Dog] with the given [name].
  Dog(super.name);

  /// Dogs have 4 legs.
  @override
  int get legs => 4;

  /// Dogs say "Woof!".
  @override
  String makeSound() => 'Woof!';
}

/// A [Cat] — a four-legged animal that meows.
class Cat extends Animal {
  /// Creates a [Cat] with the given [name].
  Cat(super.name);

  /// Cats have 4 legs.
  @override
  int get legs => 4;

  /// Cats say "Meow!".
  @override
  String makeSound() => 'Meow!';
}

/// A [Bird] — a two-legged animal that chirps.
class Bird extends Animal {
  /// Creates a [Bird] with the given [name].
  Bird(super.name);

  /// Birds have 2 legs.
  @override
  int get legs => 2;

  /// Birds say "Tweet!".
  @override
  String makeSound() => 'Tweet!';
}

// ─────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────

/// Demonstrates abstract classes, inheritance, and polymorphism
/// by building a small zoo and performing various list operations.
void main() {
  // ── Create a mixed list of animals ────────────────────────
  final List<Animal> zoo = [
    Dog('Rex'),
    Cat('Whiskers'),
    Bird('Tweety'),
    Dog('Buddy'),
    Cat('Luna'),
    Bird('Sky'),
  ];

  final separator = '─' * 50;

  // ── Section 1: for loop — print each animal's sound ───────
  print(separator);
  print('Section 1 — Each animal\'s sound (for loop)');
  print(separator);
  for (final animal in zoo) {
    print('${animal.name}: ${animal.makeSound()}');
  }

  print('');

  // ── Section 2: forEach — print full describe() ────────────
  print(separator);
  print('Section 2 — Full description (forEach)');
  print(separator);
  zoo.forEach((animal) => print(animal.describe()));

  print('');

  // ── Section 3: whereType<Dog>() — filter only dogs ────────
  print(separator);
  print('Section 3 — Dogs only (whereType<Dog>)');
  print(separator);
  final dogs = zoo.whereType<Dog>().toList();
  dogs.forEach((dog) => print(dog.toString()));

  print(separator);
}
