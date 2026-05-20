import 'package:dio/dio.dart';

import '../../../core/models.dart';

class ZapshopApiClient {
  ZapshopApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://zapshop.by/wp-json/pmm/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));
  final Dio _dio;

  Future<List<Part>> getParts({int page = 1, int perPage = 20, String? search, String? brand, String? model, String? generation}) async {
    final res = await _dio.get('/parts', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (model != null && model.isNotEmpty) 'model': model,
      if (generation != null && generation.isNotEmpty) 'generation': generation,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items.map((e) => Part.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Part>> matchCar({required String brand, required String model, String? generation}) async {
    Future<List<Part>> run(Map<String, dynamic> q) async {
      final res = await _dio.get('/parts/match-car', queryParameters: q);
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? []);
      return items.map((e) => Part.fromJson(e as Map<String, dynamic>)).toList();
    }

    final base = {'brand': brand, 'model': model, if (generation != null && generation.isNotEmpty) 'generation': generation};
    var list = await run(base);
    if (list.isNotEmpty) return list;

    list = await run({'brand': brand, 'model': model});
    if (list.isNotEmpty) return list;

    return getParts(search: '$brand $model ${generation ?? ''}'.trim(), perPage: 40);
  }

  Future<Part> getPartDetails(int id) async {
    final res = await _dio.get('/parts/$id');
    final root = res.data as Map<String, dynamic>;
    final item = Map<String, dynamic>.from((root['item'] ?? root) as Map);
    final raw = item['raw'] is Map ? Map<String, dynamic>.from(item['raw'] as Map) : <String, dynamic>{};
    final oem = item['oem'];
    if ((oem == null || (oem is List && oem.isEmpty) || (oem is String && oem.trim().isEmpty)) && raw['original_number'] != null) {
      item['oem'] = raw['original_number'];
    }
    if (item['images'] == null && item['main_image'] != null) {
      item['images'] = [item['main_image']];
    }
    return Part.fromJson(item);
  }

  Future<void> createRequest(Map<String, dynamic> payload) async {
    await _dio.post('/requests', data: payload);
  }
}
