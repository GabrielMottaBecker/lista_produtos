import '../../core/network/http_client.dart';
import '../models/product_model.dart';

class ProductRemoteDatasource {
  final HttpClient client;
  static const _baseUrl = 'https://fakestoreapi.com/products';

  ProductRemoteDatasource(this.client);

  Future<List<ProductModel>> getProducts() async {
    final response = await client.get(_baseUrl);
    final List data = response.data as List;
    return data
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await client.get('$_baseUrl/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final response = await client.post(_baseUrl, product.toJson());
    // A FakeStore API retorna o produto criado com id gerado
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final response =
        await client.put('$_baseUrl/${product.id}', product.toJson());
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await client.delete('$_baseUrl/$id');
  }
}
