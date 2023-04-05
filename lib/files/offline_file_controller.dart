import "dart:convert";
import 'dart:io';
import "package:crypto/crypto.dart";
import "package:oss_surveys_customer/main.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as p;

class OfflineFileController {
  HttpClient httpClient = HttpClient();
  Future<Directory> getDownloadsDir() => getApplicationSupportDirectory();

  /// TODO: ADD DOCS
  Future<File?> getOfflineFile(String url, { download = true }) async {    
    try {
      if (download) {
        return _download(url);
      } else {
        return File(p.join((await getApplicationSupportDirectory()).path, _getOfflineFileName(url)));
      }
    } catch (e) {
      logger.shout("Couldn't download file from $url");
      return null;
    }
  }
  
  /// TODO: ADD DOCS
  Future<File?> _download(String url) async {
    Uri uri = Uri.parse(url);
    String fileName = _getOfflineFileName(url);
    File file = File(p.join((await getApplicationSupportDirectory()).path, fileName));
    HttpClientRequest request = await httpClient.getUrl(uri);
    String? eTag = await readFileETag(file);
    
    if (eTag != null) {
      request.headers.add("If-None-Match", eTag, preserveHeaderCase: true);  
    }
    
    HttpClientResponse response = await request.close();
    
    switch (response.statusCode) {
      case 200: {
        logger.info("Downloading file $url...");
        return await _handleSuccessfulDownload(fileName, response);
      }
      case 304: {
        logger.info("File not changed. Using offlined file $url");
        return file;
      }
      default: {
        logger.shout("Failed to download file $url, ${response.statusCode}, ${response.reasonPhrase}");
        return null;
      }
    }
  }

  /// TODO: ADD DOCS
  String _getOfflineFileName(String url) {
    String urlHash = _calculateMd5(url);
    String fileExtension = url.substring(url.lastIndexOf("."));
    
    return urlHash + fileExtension;
  }
  
  /// TODO: ADD DOCS
  String _calculateMd5(String string) => md5.convert(utf8.encode(string)).toString();
  
  /// TODO: ADD DOCS
  Future<String?> readFileETag(File file) async {
    FileMeta? metaFile = await _readFileMeta(file);
    
    return metaFile?.eTag;
  }
  
  /// TODO: ADD DOCS
  Future<FileMeta?> _readFileMeta(File file) async {
    if (!await file.exists()) {
      return null;
    }
    
    File metaFile = File(await _getMetafileName(file));
    
    if (!await metaFile.exists()) {
      return null;
    }
    
    return FileMeta.fromJson(jsonDecode(await metaFile.readAsString()));
  }
  
  /// TODO: ADD DOCS
  Future<void> _writeFileMeta(File file, String? eTag) async {
    File metaFile = File(await _getMetafileName(file));
    
    if (await metaFile.exists()) {
      metaFile.delete();
    }
    
    (await metaFile.create(recursive: true)).writeAsString(
      FileMeta.fromJson(jsonDecode(eTag ?? "")).toJson().toString()
    );
  }
  
  /// TODO: ADD DOCS
  Future<String> _getMetafileName(File file) async => "${(await getApplicationSupportDirectory()).path}/${p.basename(file.path)}.meta";
  
  /// TODO: ADD DOCS
  Future<File?> _handleSuccessfulDownload(String fileName, HttpClientResponse response) async {
    String? eTag = response.headers.value("If-None-Match");
    String stringData = response.transform(utf8.decoder).toString();
    File existingFile = File(fileName);
    
    if (stringData.isEmpty) {
      return null;
    }
    
    String filePartName = "${(await getApplicationSupportDirectory()).path}/$fileName.part";
    print("FILEPARTNAME: $filePartName");
    File filePart = File(filePartName);
    
    if (await filePart.exists()) {
      await filePart.delete();
    }
    
    (await filePart.create(recursive: true)).writeAsBytes(stringData.codeUnits);
    
    if (await existingFile.exists()) {
      existingFile.delete();
    }
    
    filePart.rename(fileName);
    await _writeFileMeta(existingFile, eTag);
    logger.info("Downloaded $fileName!");
    
    return existingFile;
  }
}

/// TODO: ADD DOCS
class FileMeta {
  
  FileMeta(this.eTag);
  
  String eTag;
  
  /// TODO: ADD DOCS
  factory FileMeta.fromJson(Map<String, dynamic> json) => FileMeta(json["eTag"] as String);
  
  /// TODO: ADD DOCS
  Map<String, dynamic> toJson() => {
    "eTag": eTag
  };
}