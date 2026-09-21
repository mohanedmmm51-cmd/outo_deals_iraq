import 'dart:convert';
import 'dart:js_interop';

@JS('autoDealsPushEnable')
external JSPromise<JSString> _enable();
@JS('autoDealsPushCurrent')
external JSPromise<JSString> _current();
@JS('autoDealsPushDisable')
external JSPromise<JSString> _disable();

Future<Map<String, dynamic>> enableWebPush() async =>
    Map<String, dynamic>.from(jsonDecode((await _enable().toDart).toDart) as Map);
Future<Map<String, dynamic>?> currentWebPush() async {
  final data = jsonDecode((await _current().toDart).toDart);
  return data == null ? null : Map<String, dynamic>.from(data as Map);
}
Future<void> disableWebPush() async { await _disable().toDart; }
