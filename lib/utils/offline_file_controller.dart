import "dart:async";
import "dart:convert";
import "dart:io";
import "package:crypto/crypto.dart";
import "package:oss_surveys_customer/utils/model/meta_file.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as p;
import "package:simple_logger/simple_logger.dart";
import "package:typed_data/typed_data.dart";

/// Offline File Controller class
class OfflineFileController {
  HttpClient httpClient = HttpClient();

  /// Gets offlined file by [url]
  ///
  /// Downloads file by default, can be changed by setting [download] to false.
  Future<File?> getOfflineFile(String url, {download = true}) async {
    try {
      if (download) {
        return _download(url);
      } else {
        File offlinedFile = File(
            p.join((await getImagesDirectoryPath()), _getOfflineFileName(url)));
        if (await offlinedFile.exists()) {
          return offlinedFile;
        }

        return null;
      }
    } catch (exception) {
      SimpleLogger().shout("Couldn't download file from $url");

      return null;
    }
  }

  /// Downloads file from [url]
  ///
  /// If the same file is already downloaded, applies its ETag to the request headers to not download it again in case it is not modified.
  /// In case of file not modified, returns the already offlined file.
  Future<File?> _download(String url) async {
    SimpleLogger().info("Offlining file $url...");

    Uri uri = Uri.parse(url);
    String fileName = _getOfflineFileName(url);
    File? metaFile = await _getDirectoryFileByNameAndExt(
      await getImagesDirectoryPath(),
      p.basenameWithoutExtension(fileName),
      ".meta",
    );

    HttpClientRequest request = await httpClient.getUrl(uri);

    if (metaFile != null) {
      String? eTag = (await _readMetaFile(metaFile))?.eTag;

      if (eTag != null) {
        request.headers.add("If-None-Match", eTag, preserveHeaderCase: true);
      }
    }

    HttpClientResponse response = await request.close();

    switch (response.statusCode) {
      case 200:
        {
          SimpleLogger().info("Downloading file $url...");

          return await _handleNewFile(fileName, response);
        }
      case 304:
        {
          SimpleLogger().info("File not changed. Using offlined file $url");

          return await _getDirectoryFile(
            await getImagesDirectoryPath(),
            fileName,
          );
        }
      default:
        {
          SimpleLogger().shout(
            "Failed to download file $url, ${response.statusCode}, ${response.reasonPhrase}",
          );

          return null;
        }
    }
  }

  /// Gets offline file name based on hash of [url] and name of the file.
  String _getOfflineFileName(String url) {
    String urlHash = md5.convert(utf8.encode(url)).toString();
    String fileName = url.substring(url.lastIndexOf("/") + 1);

    return "$urlHash-$fileName";
  }

  /// Reads given .meta [file].
  ///
  /// Returns null if given file or metafile does not exist.
  Future<MetaFile?> _readMetaFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    File metaFile = File(await _getMetaFilePath(file));

    if (!await metaFile.exists()) {
      return null;
    }

    return MetaFile.fromJson(jsonDecode(await metaFile.readAsString()));
  }

  /// Writes .meta file for [file] and [eTag] as JSON with its content.
  Future<void> _writeMetaFile(File file, String? eTag) async {
    File metaFile = File(await _getMetaFilePath(file));

    if (await metaFile.exists()) {
      await metaFile.delete();
    }

    await metaFile.writeAsString(
      jsonEncode(MetaFile(eTag).toJson()),
    );
  }

  /// Gets path to given [file]s .meta file
  Future<String> _getMetaFilePath(File file) async =>
      "${(await getImagesDirectoryPath())}/${p.basenameWithoutExtension(file.path)}.meta";

  /// Handles creating of new file with [fileName].
  ///
  /// ETag and file content is parsed from [response].
  Future<File?> _handleNewFile(
      String fileName, HttpClientResponse response) async {
    String? eTag = response.headers.value("ETag");
    File existingFile = File(fileName);
    String filePartName = "${(await getImagesDirectoryPath())}/$fileName.part";
    File filePart = File(filePartName);
    String newFileName = filePart.path.replaceAll(".part", "");

    if (await filePart.exists()) {
      await filePart.delete();
    }

    await filePart.writeAsBytes(await readResponseToBytes(response));

    if (await existingFile.exists()) {
      await existingFile.delete();
    }

    File newFile = await filePart.rename(newFileName);
    await _writeMetaFile(existingFile, eTag);
    SimpleLogger().info("Downloaded $newFileName!");

    return newFile;
  }

  /// Reads [response] to bytes and awaits for it to be ready.
  Future<Int8Buffer> readResponseToBytes(HttpClientResponse response) {
    final completer = Completer<Int8Buffer>();
    final byteBuffer = Int8Buffer();
    response.listen((data) => byteBuffer.addAll(data),
        onDone: () => completer.complete(byteBuffer));

    return completer.future;
  }

  /// Returns path to offlined images directory as string.
  Future<String> getImagesDirectoryPath() async {
    return (await Directory(
                "${(await getApplicationDocumentsDirectory()).path}/images")
            .create())
        .path;
  }

  /// Searches directory at [directoryPath] for file with [fileName] and extension [fileExt].
  ///
  /// Returns found file or null, if specified file was not found.
  Future<File?> _getDirectoryFileByNameAndExt(
    String directoryPath,
    String fileName,
    String fileExt,
  ) async =>
      await _getDirectoryFile(directoryPath, fileName + fileExt);

  /// Searches directory at [directoryPath] for file with [fileName].
  ///
  /// Returns found file or null, if specified file was not found.
  Future<File?> _getDirectoryFile(
    String directoryPath,
    String fileName,
  ) async {
    try {
      return File((await Directory(directoryPath).list().firstWhere(
              (fileSystemEntity) =>
                  p.basename(fileSystemEntity.path) == fileName))
          .path);
    } catch (exception) {
      SimpleLogger().warning("Couldn't find File $fileName in $directoryPath");

      return null;
    }
  }
}

final offlineFileController = OfflineFileController();
