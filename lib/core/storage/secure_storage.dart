import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared secure storage config. Web needs explicit [WebOptions] or reads can hang.
const vmfsSecureStorage = FlutterSecureStorage(
  webOptions: WebOptions(
    dbName: 'vmfs_secure_storage',
    publicKey: 'vmfs_secure_storage_key',
  ),
);
