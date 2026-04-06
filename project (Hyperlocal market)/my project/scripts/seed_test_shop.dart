/// Script to seed test shop data in Firestore
/// Run with: dart scripts/seed_test_shop.dart
/// Make sure to set GOOGLE_APPLICATION_CREDENTIALS environment variable first
library;

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Initialize Firebase (uses GOOGLE_APPLICATION_CREDENTIALS env var)
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  try {
    stdout.writeln('Seeding test shop data...');

    // Update the existing test shop with numeric latitude/longitude
    await firestore.collection('shops').doc('your_existing_doc_id').update({
      'latitude': 3.9552,
      'longitude': 11.5883,
      'isApproved': true,
    });

    stdout.writeln('Test shop updated successfully!');
    stdout.writeln('Added numeric fields:');
    stdout.writeln('- latitude: 3.9552');
    stdout.writeln('- longitude: 11.5883');
    stdout.writeln('- isApproved: true');
  } catch (e) {
    stdout.writeln('Error updating test shop: $e');
    rethrow;
  }
}
