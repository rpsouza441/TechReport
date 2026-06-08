/// Removes the "RAT-" (or "RAT ", "RAT-", "rat-", etc.) prefix from the RAT
/// number when the context already displays a "RAT" label.
///
/// Preserves legacy data: `RAT-123` → `123`, but `123` → `123`.
String ratDisplayNumber(String numero) {
  return numero.trim().replaceFirst(
    RegExp(r'^RAT[-\s]*', caseSensitive: false),
    '',
  );
}
