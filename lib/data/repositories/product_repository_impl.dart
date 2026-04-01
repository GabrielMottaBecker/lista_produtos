import '../../core/errors/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Implementação híbrida: prefere dados locais e sincroniza com a API.
///
/// Estratégia de origem (isLocal):
///   • Produtos vindos da API           → isLocal = false  (badge "API")
///   • Produtos criados pelo usuário    → isLocal = true   (badge "LOCAL")
///   • Sincronização (sync) reseta tudo → isLocal = false
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDatasource;
  final ProductLocalDatasource localDatasource;

  ProductRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  // ── Read ────────────────────────────────────────────────────────

  @override
  Future<List<Product>> getProducts() async {
    if (await localDatasource.hasData) {
      final local = await localDatasource.getAllProducts();
      return local.map((m) => m.toEntity()).toList();
    }

    try {
      // Produtos da API chegam com isLocal = false (padrão do fromJson)
      final models = await remoteDatasource.getProducts();
      await localDatasource.insertAll(models);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<Product?> getProductById(int id) async {
    final local = await localDatasource.getProductById(id);
    return local?.toEntity();
  }

  // ── Create ──────────────────────────────────────────────────────

  @override
  Future<Product> createProduct(Product product) async {
    // Produto criado pelo usuário → isLocal = true
    final localProduct = product.copyWith(isLocal: true);

    try {
      final remoteModel = await remoteDatasource
          .createProduct(ProductModel.fromEntity(localProduct));

      // Preserva isLocal = true na persistência local
      final localModel = ProductModel(
        id: remoteModel.id,
        title: remoteModel.title,
        price: remoteModel.price,
        image: remoteModel.image,
        description: remoteModel.description,
        category: remoteModel.category,
        ratingRate: remoteModel.ratingRate,
        ratingCount: remoteModel.ratingCount,
        isLocal: true,
      );
      final localId = await localDatasource.insertProduct(localModel);
      return localModel.toEntity().copyWith(id: localId);
    } catch (_) {
      // Fallback local
      final localId = await localDatasource
          .insertProduct(ProductModel.fromEntity(localProduct));
      return localProduct.copyWith(id: localId);
    }
  }

  // ── Update ──────────────────────────────────────────────────────

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final remoteModel = await remoteDatasource
          .updateProduct(ProductModel.fromEntity(product));
      // Mantém o isLocal original do produto ao atualizar
      final merged = ProductModel(
        id: remoteModel.id,
        title: remoteModel.title,
        price: remoteModel.price,
        image: remoteModel.image,
        description: remoteModel.description,
        category: remoteModel.category,
        ratingRate: remoteModel.ratingRate,
        ratingCount: remoteModel.ratingCount,
        isLocal: product.isLocal,
      );
      await localDatasource.updateProduct(merged);
      return merged.toEntity();
    } catch (_) {
      final model = ProductModel.fromEntity(product);
      await localDatasource.updateProduct(model);
      return product;
    }
  }

  // ── Delete ──────────────────────────────────────────────────────

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await remoteDatasource.deleteProduct(id);
    } catch (_) {}
    await localDatasource.deleteProduct(id);
  }

  // ── Sync ────────────────────────────────────────────────────────

  @override
  Future<void> syncProducts() async {
    // Sincronização reseta tudo → todos ficam isLocal = false
    final models = await remoteDatasource.getProducts();
    await localDatasource.clearAll();
    await localDatasource.insertAll(models);
  }
}
