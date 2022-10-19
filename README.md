Client library to interact with the DigitalOcean & Linode Spaces API.

## Features
- Upload files
- Get list files from buckets


## Usage

Setup space instance
```dart
/// Initialize space
DOLinodeSpaces spaces = DOLinodeSpaces(
    region: "ap-south-1",
    accessKey: "accessKey",
    secretKey: "secretKey",
    provider: Providers.linodeobject,
);
```

A simple usage to upload file to specific bucket

```dart
/// Uploading file to space and
/// get direct link to file
Future<String> uploadFile(File file) async {
    String bucket = "example"
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

final url = await uploadFile(File("/images/image-example.jpg"));
debugPrint("Uploaded url: $url");
```

A simple usage to get list files from bucket
```dart
/// Get list file from specific bucket
Future<List<BucketContentModel>> listFile() async {
    String bucket = "example"
    return await spaces!.bucket(bucket).listContents();
}

/// Get list file from specific bucket
List<BucketContentModel> contents = await listFile();
for (var content in contents) {
    debugPrint("- ${content.url}");
}
```

## Additional information
* https://pub.dev/packages/dospace