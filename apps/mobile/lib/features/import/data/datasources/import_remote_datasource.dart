import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for `/api/import/...`.
///
/// The import call returns either 200 (result) or 422 (refusal with a preview).
/// Dio treats 422 as an error, so it is caught here and reported as a normal
/// response — a refusal is an expected outcome, not an exception.
class ImportRemoteDatasource {
  final Dio _dio;

  ImportRemoteDatasource(this._dio);

  /// The template is served as a file download, so it is read as plain text.
  Future<String> template(String entity) async {
    final response = await _dio.get<String>(
      '/import/$entity/template',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<Map<String, dynamic>> preview(String entity, String csv) async {
    final response = await _dio.post(
      '/import/$entity/preview',
      data: {'csv': csv},
    );
    return (response.data as Map<String, dynamic>?) ?? const {};
  }

  /// Returns (status, body): 200 for a result, 422 for a refusal.
  Future<({int status, Map<String, dynamic> body})> importCsv(
    String entity,
    String csv,
  ) async {
    try {
      final response = await _dio.post(
        '/import/$entity',
        data: {'csv': csv},
      );
      return (
        status: response.statusCode ?? 200,
        body: (response.data as Map<String, dynamic>?) ?? const {},
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 422) {
        return (
          status: 422,
          body: (error.response?.data as Map<String, dynamic>?) ?? const {},
        );
      }
      rethrow;
    }
  }
}

/// Provider for the import remote data source.
final importRemoteDatasourceProvider = Provider<ImportRemoteDatasource>((ref) {
  return ImportRemoteDatasource(ref.read(dioProvider));
});
