import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

const _errors = <String, String>{
  'WRONG_PASSWORD': 'رمز اشتباه است',
  'BUILDING_NOT_FOUND': 'ساختمان پیدا نشد',
  'AMBIGUOUS_BUILDING': 'چند ساختمان با این نام است؛ کد ساختمان را بنویسید',
  'UNIT_NOT_FOUND': 'واحد پیدا نشد',
  'CHECK_FAILED': 'کد تأیید واحد اشتباه است',
  'ADMIN_ONLY': 'کلید ثبت ساختمان درست نیست',
  'SESSION_INVALID': 'نشست تمام شده؛ دوباره وارد شوید',
  'BUILDING_DISABLED': 'دسترسی این ساختمان توسط ادمین قطع شده است',
};

/// Calls a Supabase RPC function (same functions the web app uses).
Future<dynamic> rpc(String fn, Map<String, dynamic> args) async {
  try {
    final res = await http
        .post(
          Uri.parse('$supabaseUrl/rest/v1/rpc/$fn'),
          headers: {'apikey': supabaseKey, 'Content-Type': 'application/json'},
          body: jsonEncode(args),
        )
        .timeout(const Duration(seconds: 15));
    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 300) {
      final raw = (data is Map ? data['message'] : null)?.toString() ?? 'خطای سرور';
      throw ApiException(_errors[raw] ?? raw);
    }
    return data;
  } on SocketException {
    throw ApiException('اتصال برقرار نشد؛ اینترنت را بررسی کنید');
  } on HttpException {
    throw ApiException('اتصال برقرار نشد؛ اینترنت را بررسی کنید');
  }
}
