import '../../core/errors/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDatasource;
  final ProductLocalDatasource localDatasource;

  ProductRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<List<Product>> getProducts() async {
    try {
      final models = await remoteDatasource.getProducts();
      localDatasource.saveCache(models);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      if (localDatasource.hasCache) {
        final cached = localDatasource.getCache();
        return cached.map((m) => m.toEntity()).toList();
      }
      throw Failure(e.toString());
    }
  }
}
