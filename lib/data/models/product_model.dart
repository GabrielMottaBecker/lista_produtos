import '../../domain/entities/product.dart';

class ProductModel {
  final int? id;
  final String title;
  final double price;
  final String image;
  final String description;
  final String category;
  final double ratingRate;
  final int ratingCount;
  final bool isLocal;

  ProductModel({
    this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    required this.ratingRate,
    required this.ratingCount,
    this.isLocal = false,
  });

  /// Cria a partir do JSON da API remota — sempre isLocal = false
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      ratingRate: (rating['rate'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
      isLocal: false,
    );
  }

  /// Cria a partir de um Map do SQLite
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      ratingRate: (map['ratingRate'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      isLocal: (map['isLocal'] as int? ?? 0) == 1,
    );
  }

  /// Cria a partir de uma entidade do domínio
  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      title: entity.title,
      price: entity.price,
      image: entity.image,
      description: entity.description,
      category: entity.category,
      ratingRate: entity.ratingRate,
      ratingCount: entity.ratingCount,
      isLocal: entity.isLocal,
    );
  }

  /// Converte para JSON enviado à API (sem id, sem isLocal)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
    };
  }

  /// Converte para Map usado pelo SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
      'ratingRate': ratingRate,
      'ratingCount': ratingCount,
      'isLocal': isLocal ? 1 : 0,
    };
  }

  /// Converte para entidade de domínio
  Product toEntity() => Product(
        id: id,
        title: title,
        price: price,
        image: image,
        description: description,
        category: category,
        ratingRate: ratingRate,
        ratingCount: ratingCount,
        isLocal: isLocal,
      );
}
