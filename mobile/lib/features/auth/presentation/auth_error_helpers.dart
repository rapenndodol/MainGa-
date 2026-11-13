/// Mengubah struktur `errors` dari API auth menjadi pesan per field.
///
/// Backend dapat mengirim nilai berupa `List<String>` atau `String`. Hanya pesan
/// pertama per field yang ditampilkan agar galat tetap ringkas dan inline.
Map<String, String> parseAuthFieldErrors(Map<String, dynamic>? errors) {
  if (errors == null || errors.isEmpty) return const <String, String>{};

  final Map<String, String> parsed = <String, String>{};
  errors.forEach((key, value) {
    String? message;
    if (value is List && value.isNotEmpty) {
      message = value.first?.toString();
    } else if (value != null) {
      message = value.toString();
    }

    if (message != null && message.trim().isNotEmpty) {
      parsed[key] = message.trim();
    }
  });
  return parsed;
}
