import 'package:nbts/core/data/models/json_utils.dart';

class Article {
  const Article({
    required this.id,
    required this.title,
    this.category,
    this.summary,
    this.body,
    this.imageUrl,
    this.status,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String? category;
  final String? summary;
  final String? body;
  final String? imageUrl;
  final String? status;
  final DateTime? publishedAt;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: readInt(json, ['id', 'article_id']) ?? 0,
      title: readString(json, ['title', 'heading', 'name']) ?? 'Article',
      category: readString(json, ['category', 'type', 'tag']),
      summary: readString(json, ['summary', 'excerpt', 'description']),
      body: readString(json, ['body', 'content', 'message']),
      imageUrl: readString(json, ['image_url', 'image', 'thumbnail_url']),
      status: readString(json, ['status', 'state']),
      publishedAt: readDate(json, ['published_at', 'created_at']),
    );
  }
}
