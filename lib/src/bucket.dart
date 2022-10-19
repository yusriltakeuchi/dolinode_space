import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dolinode_space/dolinode_space.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

enum Permissions {
  private,
  public,
}

class Bucket extends Client {
  Bucket({
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

  void bucket(String bucket) {
    if (endpointUrl == "https://$region.${DoLinodeCofig.baseHost(provider)}") {
    } else {
      throw Exception(
        "Endpoint URL not supported. Create Bucket client manually.",
      );
    }
  }

  /// List the Bucket's Contents.
  /// https://developers.digitalocean.com/documentation/spaces/#list-bucket-contents
  Future<List<BucketContentModel>> listContents({
    String? delimiter,
    String? prefix,
    int? maxKeys,
  }) async {
    bool? isTruncated;
    String? marker;

    List<BucketContentModel> contents = [];
    do {
      Uri uri = Uri.parse('$endpointUrl/');
      Map<String, dynamic> params = <String, dynamic>{};
      if (delimiter != null) params['delimiter'] = delimiter;
      if (marker != null) {
        params['marker'] = marker;
        marker = null;
      }
      if (maxKeys != null) params['max-keys'] = "$maxKeys";
      if (prefix != null) params['prefix'] = prefix;
      uri = uri.replace(queryParameters: params);
      XmlDocument doc = await getUri(uri);
      for (XmlElement root in doc.findElements('ListBucketResult')) {
        for (XmlNode node in root.children) {
          if (node is XmlElement) {
            XmlElement ele = node;
            switch ('${ele.name}') {
              case "NextMarker":
                marker = ele.text;
                break;
              case "IsTruncated":
                isTruncated =
                    ele.text.toLowerCase() != "false" && ele.text != "0";
                break;
              case "Contents":
                String? key;
                DateTime? lastModifiedUtc;
                String? eTag;
                int? size;
                for (XmlNode node in ele.children) {
                  if (node is XmlElement) {
                    XmlElement ele = node;
                    switch ('${ele.name}') {
                      case "Key":
                        key = ele.text;
                        break;
                      case "LastModified":
                        lastModifiedUtc = DateTime.parse(ele.text);
                        break;
                      case "ETag":
                        eTag = ele.text;
                        break;
                      case "Size":
                        size = int.parse(ele.text);
                        break;
                    }
                  }
                }
                contents.add(BucketContentModel(
                  key: key,
                  lastModifiedUtc: lastModifiedUtc,
                  eTag: eTag,
                  size: size,
                  url: "${DoLinodeCofig.baseHost(provider)}/$key"
                ));
                break;
            }
          }
        }
      }
    } while (isTruncated == true);
    return contents;
  }

  /// Uploads file. Returns Etag.
  Future<String?> uploadFile(
    String key,
    File file,
    String contentType,
    Permissions permissions, {
    Map<String, String>? meta,
  }) async {
    int? contentLength = await file.length();
    Digest contentSha256 = await sha256.bind(file.openRead()).first;
    String uriStr = '$endpointUrl/$key';
    http.StreamedRequest request = http.StreamedRequest(
      'PUT',
      Uri.parse(uriStr),
    );
    Stream<List<int>> stream = file.openRead();
    stream.listen(
      request.sink.add,
      onError: request.sink.addError,
      onDone: request.sink.close,
    );
    if (meta != null) {
      for (MapEntry<String, String> me in meta.entries) {
        request.headers["x-amz-meta-${me.key}"] = me.value;
      }
    }
    if (permissions == Permissions.public) {
      request.headers['x-amz-acl'] = 'public-read';
    }
    request.headers['Content-Length'] = contentLength.toString();
    request.headers['Content-Type'] = contentType;
    signRequest(request, contentSha256: contentSha256);
    http.StreamedResponse response = await httpClient.send(request);
    String body = await utf8.decodeStream(response.stream);
    if (response.statusCode != 200) {
      throw ClientException(
        response.statusCode,
        response.reasonPhrase ?? "",
        response.headers,
        body,
      );
    }
    String? etag = response.headers['etag'];
    return etag;
  }

  /// Uploads data from memory. Returns Etag.
  Future<String?> uploadData(
    String key,
    Uint8List data,
    String contentType,
    Permissions permissions, {
    Map<String, String>? meta,
    Digest? contentSha256,
  }) async {
    int contentLength = data.length;
    Digest contentSha256_ = contentSha256 ?? sha256.convert(data);
    String uriStr = '$endpointUrl/$key';
    http.Request request = http.Request('PUT', Uri.parse(uriStr));
    request.bodyBytes = data;
    if (meta != null) {
      for (MapEntry<String, String> me in meta.entries) {
        request.headers["x-amz-meta-${me.key}"] = me.value;
      }
    }
    if (permissions == Permissions.public) {
      request.headers['x-amz-acl'] = 'public-read';
    }
    request.headers['Content-Length'] = contentLength.toString();
    request.headers['Content-Type'] = contentType;
    signRequest(request, contentSha256: contentSha256_);
    http.StreamedResponse response = await httpClient.send(request);
    String body =
        await utf8.decodeStream(response.stream); // Should be empty when OK
    if (response.statusCode != 200) {
      throw ClientException(
        response.statusCode,
        response.reasonPhrase ?? "",
        response.headers,
        body,
      );
    }
    String? etag = response.headers['etag'];
    return etag;
  }

  String? preSignUpload(
    String key, {
    int? contentLength,
    String? contentType,
    Digest? contentSha256,
    Permissions permissions = Permissions.private,
    int expires = 900,
    Map<String, String>? meta,
  }) {
    String uriStr = '$endpointUrl/$key';
    Uri uriBase = Uri.parse(uriStr);
    Map<String, String> queryParameters = <String, String>{};
    if (meta != null) {
      for (MapEntry<String, String> me in meta.entries) {
        queryParameters["x-amz-meta-${me.key}"] = me.value;
      }
    }
    /*if (permissions == Permissions.public) {
      queryParameters['x-amz-acl'] = 'public-read';
    }*/ // This isn't working ?!
    http.Request request = http.Request(
      'PUT',
      uriBase.replace(queryParameters: queryParameters),
    );
    if (contentLength != null) {
      request.headers['Content-Length'] = contentLength.toString();
    }
    if (contentType != null) request.headers['Content-Type'] = contentType;
    if (permissions == Permissions.public) {
      request.headers['x-amz-acl'] = 'public-read';
    }
    return signRequest(
      request,
      contentSha256: contentSha256,
      expires: expires,
      preSignedUrl: true,
    );
  }
}
