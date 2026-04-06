import 'dart:typed_data';

/// Abstract interface for storage operations.
abstract class IStorageRepository {
  /// Uploads a shop image and returns the resulting public URL.
  Future<String> uploadShopImage({
    required String shopId,
    required Uint8List bytes,
    required String fileExtension,
  });
}
