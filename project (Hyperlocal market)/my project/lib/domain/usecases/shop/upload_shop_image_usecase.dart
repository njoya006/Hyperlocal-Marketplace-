import 'dart:typed_data';

import '../../repositories/storage_repository.dart';

/// Usecase for uploading a shop image to Firebase Storage.
class UploadShopImageUsecase {
  /// Creates an [UploadShopImageUsecase].
  const UploadShopImageUsecase({required IStorageRepository storageRepository})
      : _storageRepository = storageRepository;

  final IStorageRepository _storageRepository;

  /// Uploads image bytes and returns a public URL.
  Future<String> call({
    required String shopId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    return await _storageRepository.uploadShopImage(
      shopId: shopId,
      bytes: bytes,
      fileExtension: fileExtension,
    );
  }
}
