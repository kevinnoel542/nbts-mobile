import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/article.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class ArticlesRepository {
  ArticlesRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Article>> fetchAll() async {
    final response = await _api.get(
      '/articles',
      queryParameters: const {'per_page': 50},
      authenticated: false,
    );
    return readListPayload(response).map(Article.fromJson).toList();
  }

  Future<List<Article>> fetchPublications() async {
    final response = await _api.get(
      '/publications',
      queryParameters: const {'per_page': 50},
      authenticated: false,
    );
    return readListPayload(response).map(Article.fromJson).toList();
  }
}
