import 'package:flutter/foundation.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_state.dart';

class ProductViewModel {
  final ProductRepository repository;

  final ValueNotifier<ProductState> state = ValueNotifier(
    const ProductState(),
  );

  ProductViewModel(this.repository);

  Future<void> loadProducts() async {
    state.value = state.value.copyWith(status: ProductStatus.loading);

    try {
      final products = await repository.getProducts();
      state.value = state.value.copyWith(
        status: ProductStatus.success,
        products: products,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        status: ProductStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
