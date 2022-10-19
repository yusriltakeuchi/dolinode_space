import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import "package:path/path.dart" as path;
import 'package:dolinode_space/dolinode_space.dart';

DOLinodeSpaces? spaces;
String bucket = "example";
Providers provider = Providers.linodeobject;

void main() async {
  /// Initialize space
  spaces = DOLinodeSpaces(
    region: "ap-south-1",
    accessKey: "accessKey",
    secretKey: "secretKey",
    provider: provider,
  );

  /// Upload file to space and get url
  final url = await uploadFile(File("/images/image-example.jpg"));
  debugPrint("Uploaded url: $url");

  /// Get list file from specific bucket
  List<BucketContentModel> contents = await listFile();
  for (var content in contents) {
    debugPrint("- ${content.url}");
  }
}

/// Uploading file to space and
/// get direct link to file
Future<String> uploadFile(File file) async {
  String filename = file.path.split('/').last.split(".").first;
  /// Encrypting filename using base64
  /// and use the value as the key in spaces
  String fileKey = "images/${base64.encode(utf8.encode(filename))}${path.extension(file.path)}";

  String? eTag = await spaces?.bucket(bucket)
      .uploadFile(fileKey, file, "image/jpeg", Permissions.public);
  List<BucketContentModel> contents =
      await spaces!.bucket(bucket).listContents();
  return contents.firstWhere((item) => item.eTag == eTag).url ?? "";
}

/// Get list file from specific bucket
Future<List<BucketContentModel>> listFile() async {
  return await spaces!.bucket(bucket).listContents();
}
