class ClientException implements Exception {
  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> responseHeaders;
  final String responseBody;
  const ClientException(this.statusCode, this.reasonPhrase,
      this.responseHeaders, this.responseBody);
  @override
  String toString() {
    return "ClientException { statusCode: $statusCode, reasonPhrase: \"$reasonPhrase\", responseBody: \"$responseBody\" }";
  }
}
