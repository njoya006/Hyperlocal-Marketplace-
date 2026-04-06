import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/errors/exceptions.dart';

/// Abstract datasource for Firebase Storage upload operations.
abstract class IStorageDatasource {
  /// Uploads a shop image and returns the public download URL.
  Future<String> uploadShopImage({
    required String shopId,
    required Uint8List bytes,
    required String fileExtension,
  });
}

/// Firebase Storage implementation of [IStorageDatasource].
class FirebaseStorageDatasource implements IStorageDatasource {
  /// Creates a [FirebaseStorageDatasource].
  const FirebaseStorageDatasource({required FirebaseStorage firebaseStorage})
      : _firebaseStorage = firebaseStorage;

  final FirebaseStorage _firebaseStorage;

  @override
  Future<String> uploadShopImage({
    required String shopId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      final extension = fileExtension.isEmpty ? 'jpg' : fileExtension;
      final ref = _firebaseStorage
          .ref()
          .child('shops')
          .child(shopId)
          .child('cover.$extension');

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$extension'),
      );

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        code: e.code,
        message: e.message ?? 'Failed to upload image',
      );
    } catch (e) {
      throw StorageException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }
}
