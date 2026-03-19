import '../../domain/entities/product.dart';

class ProductModel {
  final int id;
  final String title;
  final double price;
  final String image;
  final String description;
  final String category;
  final double ratingRate;
  final int ratingCount;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    required this.ratingRate,
    required this.ratingCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      ratingRate: (rating['rate'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }

  Product toEntity() => Product(
        id: id,
        title: title,
        price: price,
        image: image,
        description: description,
        category: category,
        ratingRate: ratingRate,
        ratingCount: ratingCount,
      );
}
