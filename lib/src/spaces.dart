import 'package:dolinode_space/src/bucket.dart';
import 'package:dolinode_space/src/config.dart';
import 'package:http/http.dart' as http;
import 'package:dolinode_space/src/client.dart';
import 'package:xml/xml.dart';

class DOLinodeSpaces extends Client {
  DOLinodeSpaces({
    required String? region,
    required String? accessKey,
    required String? secretKey,
    required Providers provider,
    String? endpointUrl,
    http.Client? httpClient,
  }) : super(
          region: region,
          accessKey: accessKey,
          secretKey: secretKey,
          service: "s3",
          provider: provider,
          endpointUrl: endpointUrl,
          httpClient: httpClient,
        ) {
    // ...
  }

  Bucket bucket(String? bucket) {
    if (endpointUrl == "https://$region.${DoLinodeCofig.baseHost(provider)}") {
      return Bucket(
        region: region,
        accessKey: accessKey,
        secretKey: secretKey,
        endpointUrl: "https://$bucket.$region.${DoLinodeCofig.baseHost(provider)}",
        httpClient: httpClient,
        provider: provider,
      );
    } else {
      throw Exception(
        "Endpoint URL not supported. Create Bucket client manually.",
      );
    }
  }

  Future<List<String>> listAllBuckets() async {
    XmlDocument doc = await getUri(Uri.parse('$endpointUrl/'));
    List<String> res = [];
    for (XmlElement root in doc.findElements('ListAllMyBucketsResult')) {
      for (XmlElement buckets in root.findElements('Buckets')) {
        for (XmlElement bucket in buckets.findElements('Bucket')) {
          for (XmlElement name in bucket.findElements('Name')) {
            res.add(name.text);
          }
        }
      }
    }
    return res;
  }

  String? preSignListAllBuckets() {
    http.Request request = http.Request(
      'GET',
      Uri.parse('$endpointUrl/'),
    );
    return signRequest(request, preSignedUrl: true);
  }
}
