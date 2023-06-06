import "dart:convert";
import "dart:io";
import "package:flutter_app_installer/flutter_app_installer.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:oss_surveys_customer/updates/model/version_metadata.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path_provider/path_provider.dart";
import "package:typed_data/typed_data.dart";
import "../main.dart";
import "../utils/offline_file_controller.dart";

/// Version updater
class Updater {
  /// Gets applications current version number
  static Future<String> getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo.version;
  }

  /// Checks latest version from the server
  static Future<VersionMetadata> checkVersion() async {
    logger.info("Checking version...");
    Int8Buffer fileContent = await _doRequest("output-metadata.json");

    return VersionMetadata.fromJson(jsonDecode(utf8.decode(fileContent)));
  }

  /// Updates the app to the latest version by [platform]
  static Future updateVersion(String platform) async {
    logger.info("Downloading new version...");
    Int8Buffer fileContent = await _doRequest("app-$platform-release.apk");

    String? storageDir = (await getExternalStorageDirectory())?.absolute.path;
    File apkFile = File("$storageDir/fi.metatavu.oss_surveys_customer.apk");

    logger.info("Creating new .apk file...");

    if (await apkFile.exists()) {
      await apkFile.delete();
    }
    await apkFile.create();

    logger.info("Writing content to the .apk file...");
    await apkFile.writeAsBytes(fileContent);

    logger.info("Installing the new .apk file...");

    await FlutterAppInstaller.installApk(
      filePath: apkFile.path,
      silently: false,
    );
    logger.info("Installed!");
  }

  /// Does HTTP request to given [url] and return the response as ByteArray
  static Future<Int8Buffer> _doRequest(String url) async {
    String appUpdatesBaseUrl = dotenv.env["APP_UPDATES_BASE_URL"]!;
    HttpClient httpClient = HttpClient();
    HttpClientRequest request =
        await httpClient.getUrl(Uri.parse(appUpdatesBaseUrl + url));
    HttpClientResponse response = await request.close();

    return await offlineFileController.readResponseToBytes(response);
  }
}
