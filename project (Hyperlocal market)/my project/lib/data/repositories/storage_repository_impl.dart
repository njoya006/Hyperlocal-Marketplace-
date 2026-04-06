import 'dart:typed_data';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/firebase_storage_datasource.dart';

/// Concrete implementation of [IStorageRepository].
class StorageRepository implements IStorageRepository {
  /// Creates a [StorageRepository].
  const StorageRepository({required IStorageDatasource storageDatasource})
      : _storageDatasource = storageDatasource;

  final IStorageDatasource _storageDatasource;

  @override
  Future<String> uploadShopImage({
    required String shopId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      return await _storageDatasource.uploadShopImage(
        shopId: shopId,
        bytes: bytes,
        fileExtension: fileExtension,
      );
    } on StorageException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }
}
