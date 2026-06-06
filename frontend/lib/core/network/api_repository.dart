import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiRepository {
  final Dio _dio;

  ApiRepository() : _dio = ApiClient.create();

  Future<Map<String, dynamic>> fetchDailyQuest() async {
    final res = await _dio.get('/puzzles/daily');
    return res.data;
  }

  Future<List<dynamic>> fetchFlashcards({String suite = 'all', int count = 10}) async {
    final res = await _dio.get('/puzzles/flashcards', queryParameters: {
      'suite': suite,
      'count': count,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> submitShanten(List<String> tiles) async {
    final res = await _dio.post('/mahjong/shanten', data: {'tiles': tiles});
    return res.data;
  }

  Future<Map<String, dynamic>> submitSrsReport(Map<String, dynamic> report) async {
    final res = await _dio.post('/srs/report', data: report);
    return res.data;
  }
}
