import '../models/product_model.dart';

class ProductLocalDatasource {
  List<ProductModel> _cache = [];

  bool get hasCache => _cache.isNotEmpty;

  List<ProductModel> getCache() {
    return List.unmodifiable(_cache);
  }

  void saveCache(List<ProductModel> products) {
    _cache = List.of(products);
  }
}
