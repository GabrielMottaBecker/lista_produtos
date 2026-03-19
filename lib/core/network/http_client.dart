import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../errors/failure.dart';

class HttpResponse {
  final dynamic data;

  HttpResponse({required this.data});
}

class HttpClient {
  Future<HttpResponse> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HttpResponse(data: data);
      } else {
        throw Failure('Erro no servidor: ${response.statusCode}');
      }
    } on SocketException {
      throw Failure('Sem conexão com a internet.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure('Erro inesperado ao buscar dados.');
    }
  }
}
