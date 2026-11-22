import 'dart:io';

// Dart's HttpClient ignores Android's network security config,
// so plain HTTP (including redirects) is rejected here too.
class HttpsOnlyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      if (uri.scheme != 'https') {
        throw HttpException('Cleartext traffic blocked', uri: uri);
      }
      return HttpClient.findProxyFromEnvironment(uri);
    };
    return client;
  }
}
