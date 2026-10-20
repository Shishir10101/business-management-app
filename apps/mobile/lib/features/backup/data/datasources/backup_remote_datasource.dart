import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for `/api/backup/...`.
class BackupRemoteDatasource {
  final Dio _dio;

  BackupRemoteDatasource(this._dio);

  /// The export is served as a file download, so the bytes are fetched rather
  /// than a decoded DTO — the same payload is handed straight back on restore.
  Future<List<int>> export() async {
    final response = await _dio.get<List<int>>(
      '/backup/export',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  Future<Map<String, dynamic>> restore(Map<String, dynamic> payload) async {
    final response = await _dio.post('/backup/restore', data: payload);
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the backup remote data source.
final backupRemoteDatasourceProvider = Provider<BackupRemoteDatasource>((ref) {
  return BackupRemoteDatasource(ref.read(dioProvider));
});
