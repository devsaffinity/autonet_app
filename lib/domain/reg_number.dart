/// UK registration handling, mirroring `regNumberSchema`
/// (autonect-backend vehicles.routes.ts:11-14) byte for byte.
///
/// The server TRANSFORMS before it validates — uppercase, then strip all
/// whitespace, then `^[A-Z0-9]{2,8}$`. Validating the raw text instead would
/// reject 'lr19 abc', which the server accepts.
library;

/// Uppercase and strip every whitespace run, exactly as the server does.
String normaliseReg(String v) => v.toUpperCase().replaceAll(RegExp(r'\s+'), '');

/// True when the server's regex would accept [v] AFTER normalisation.
bool isValidReg(String v) => RegExp(r'^[A-Z0-9]{2,8}$').hasMatch(normaliseReg(v));
