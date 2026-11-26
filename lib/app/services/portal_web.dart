import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// `window.gs100Portal` (portal paketindeki `portal.js`).
JSObject? get _bridge {
  if (!globalContext.has('gs100Portal')) return null;
  final w = globalContext['gs100Portal'];
  if (w == null || !w.isA<JSObject>()) return null;
  return w as JSObject;
}

bool portalPresent() => _bridge != null;

void portalCall(String fn) {
  final b = _bridge;
  if (b == null || !b.has(fn)) return;
  try {
    b.callMethod<JSAny?>(fn.toJS);
  } catch (_) {}
}

Future<bool> portalBreak(String fn) async {
  final b = _bridge;
  if (b == null || !b.has(fn)) return false;
  final r = b.callMethod<JSAny?>(fn.toJS);
  if (r == null || !r.isA<JSPromise<JSAny?>>()) return false;
  final v = await (r as JSPromise<JSAny?>).toDart;
  return v.dartify() == true;
}
