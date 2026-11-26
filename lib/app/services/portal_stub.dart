/// Web dışı platformlar: portal yok.
bool portalPresent() => false;

void portalCall(String fn) {}

Future<bool> portalBreak(String fn) async => false;
