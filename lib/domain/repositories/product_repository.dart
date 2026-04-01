import '../entities/product.dart';

abstract class ProductRepository {
  /// Retorna todos os produtos (local primeiro, depois remoto)
  Future<List<Product>> getProducts();

  /// Busca um produto pelo ID no banco local
  Future<Product?> getProductById(int id);

  /// Cria um novo produto via POST e persiste localmente
  Future<Product> createProduct(Product product);

  /// Atualiza um produto via PUT e sincroniza localmente
  Future<Product> updateProduct(Product product);

  /// Remove um produto via DELETE e exclui localmente
  Future<void> deleteProduct(int id);

  /// Força resincronização com a API remota
  Future<void> syncProducts();
}
