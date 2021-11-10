import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../misc/configuration.dart';

class CrudApi {
  static final Logger log = Logger('Backend');

  final Configuration _configuration;
  final http.Client _httpClient = http.Client();

  CrudApi(Injector injector): _configuration = injector.get<Configuration>();

  void close() {
    _httpClient.close();
  }

  Future<http.Response> request(String method, String apiUri, {Map<String, dynamic>? params, Object? body}) async {
    try {
      String uriStr = '${_configuration.backendUrl()}$apiUri';
      if (params != null) {
        var delimiter = '?';
        params.forEach((key, value) { uriStr += '$delimiter$key=${Uri.encodeComponent(value)}'; delimiter = '&'; });
      }
      http.Request request = http.Request(method, Uri.parse(uriStr));
      request.encoding = utf8;
      if (body != null) {
        request.headers['Content-Type'] = 'application/json;charset=utf-8';
        request.bodyBytes = utf8.encode(jsonEncode(body));
      }
      request.headers['Authorization'] = 'Bearer ${_configuration.sessionId}';
    // Accept: application/json
      http.Response response = await http.Response.fromStream(await _httpClient.send(request));
      if (response.statusCode != 200) {
        log.severe('Backend error get $apiUri ${response.statusCode}\n${response.body}');
        throw ApiException('Server error ${response.statusCode}', response.body);
      }
      log.fine('Response received $apiUri ${response.statusCode}\n${response.body}');
      return response;
    } catch (e,s) {
      log.severe('Internal error get $apiUri', e, s);
      throw ApiException('Internal error', e.toString());
    }
  }

  Future<dynamic> requestJson(String method, String apiUri, {Map<String, dynamic>? params, Object? body}) async {
    try {
      var decoded = jsonDecode(utf8.decode((await request(method, apiUri, body: body, params: params)).bodyBytes));
      log.fine('Response decoded $decoded');
      return decoded;
    } on ApiException {
      rethrow;
    } catch (e,s) {
      log.severe('Internal error getJson $apiUri', e, s);
      throw ApiException('Internal error', e.toString());
    }
  }


}

class ApiException implements Exception {
  final String title;
  final String message;

  const ApiException(this.title, this.message);
}

final _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');
final _dateFormatter = DateFormat('yyyy-MM-dd');
DateTime dateTimeFromJson(String date) => _dateTimeFormatter.parse(date);
String dateTimeToJson(DateTime date) => _dateTimeFormatter.format(date);
DateTime? dateTimeFromJson_(String? date) => date != null ? _dateTimeFormatter.parse(date) : null;
String? dateTimeToJson_(DateTime? date) => date != null ? _dateTimeFormatter.format(date) : null;
DateTime dateFromJson(String date) => _dateFormatter.parse(date);
String dateToJson(DateTime date) => _dateFormatter.format(date);

// @JsonKey(name: 'registration_date_millis')
// @JsonKey(defaultValue: false)
// @JsonKey(required: true)
// @JsonKey(ignore: true)

// https://flutter.dev/docs/development/data-and-backend/json
// flutter pub run build_runner build
// flutter pub run build_runner watch