import '../../domain/entities/product.dart';

enum ProductStatus { initial, loading, success, error }

class ProductState {
  final ProductStatus status;
  final List<Product> products;
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.errorMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }
}
