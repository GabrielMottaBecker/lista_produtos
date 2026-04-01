import 'package:flutter/material.dart';
import 'core/network/http_client.dart';
import 'core/routes/app_routes.dart';
import 'data/datasources/product_local_datasource.dart';
import 'data/datasources/product_remote_datasource.dart';
import 'data/repositories/product_repository_impl.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/product_detail_page.dart';
import 'presentation/pages/product_form_page.dart';
import 'presentation/pages/product_page.dart';
import 'presentation/viewmodels/product_viewmodel.dart';

void main() async {
  // Obrigatório antes de qualquer operação assíncrona no main()
  // e necessário para inicializar o sqflite corretamente
  WidgetsFlutterBinding.ensureInitialized();

  final httpClient = HttpClient();
  final remoteDatasource = ProductRemoteDatasource(httpClient);
  final localDatasource = ProductLocalDatasource();
  final repository = ProductRepositoryImpl(
    remoteDatasource: remoteDatasource,
    localDatasource: localDatasource,
  );
  final viewModel = ProductViewModel(repository);

  runApp(MyApp(viewModel: viewModel));
}

class MyApp extends StatelessWidget {
  final ProductViewModel viewModel;

  const MyApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.products: (_) => ProductPage(viewModel: viewModel),
        AppRoutes.productDetail: (_) => const ProductDetailPage(),
        AppRoutes.productCreate: (_) =>
            ProductFormPage(viewModel: viewModel),
        AppRoutes.productEdit: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as Map<String, dynamic>;
          return ProductFormPage(
            viewModel: viewModel,
            product: args['product'],
          );
        },
      },
    );
  }
}
