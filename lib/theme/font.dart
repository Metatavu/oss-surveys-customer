import "dart:io";
import "package:flutter/services.dart";
import "package:oss_surveys_customer/utils/offline_file_controller.dart";
import "package:oss_surveys_customer/main.dart";
import "package:path_provider/path_provider.dart";
import "package:simple_logger/simple_logger.dart";
import "package:typed_data/typed_data.dart";

/// Loads offlined font into Flutter Engine
Future<void> loadOfflinedFont() async {
  SimpleLogger().info("Loading offlined font...");
  FontLoader fontLoader = FontLoader("S-Bonus-Regular");
  fontLoader.addFont(getOfflinedFont());
  await fontLoader.load();
  SimpleLogger().info("Offlined font loaded into engine!");
}

/// Returns offlined font.
///
/// If font is already downloaded, returns that. Otherwise downloads it and stores it in disk.
Future<ByteData> getOfflinedFont() async {
  File offlinedFont =
      File("${(await getApplicationSupportDirectory()).path}/fonts/font.ttf");

  if (await offlinedFont.exists()) {
    SimpleLogger().info("Using already downloaded offlined font!");

    return await offlinedFont
        .readAsBytes()
        .then((value) => ByteData.view(value.buffer));
  }

  SimpleLogger().info("Didn't find offlined font, downloading...");
  HttpClient client = HttpClient();
  Uri uri = Uri.parse(configuration.getFontUrl());
  HttpClientResponse response =
      await client.getUrl(uri).then((request) => request.close());
  Int8Buffer byteBuffer =
      await offlineFileController.readResponseToBytes(response);
  String fontsDirPath =
      await Directory("${(await getApplicationSupportDirectory()).path}/fonts")
          .create()
          .then((value) => value.path);
  await File("$fontsDirPath/font.ttf").writeAsBytes(byteBuffer);

  return ByteData.view(byteBuffer.buffer);
}
