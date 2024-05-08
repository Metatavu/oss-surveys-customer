import "dart:convert";
import "dart:io";
import "package:flutter_app_installer/flutter_app_installer.dart";
import "package:list_ext/list_ext.dart";
import "package:oss_surveys_customer/updates/model/version_metadata.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path_provider/path_provider.dart";
import "package:simple_logger/simple_logger.dart";
import "package:typed_data/typed_data.dart";
import "../main.dart";
import "../utils/offline_file_controller.dart";

/// Version updater
class Updater {
  /// Returns whether given value is an integer
  static bool _isInt(String? s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  /// Gets applications current version
  static Future<String> getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo.version;
  }

  /// Parses version code from version string
  static int _parseVersionCodeFromVersion(String version) {
    List<String> versionArray = [];
    int? parsedVersionCode;
    for (final segment in version.split(".")) {
      List<String> parsedSegmentChars = [];
      for (final char in segment.split("")) {
        if (_isInt(char)) {
          parsedSegmentChars.add(char);
        }
      }
      String parsedSegment = parsedSegmentChars.join("").padLeft(2, "0");
      versionArray.add(parsedSegment);
    }
    parsedVersionCode = int.tryParse(versionArray.join(""));
    if (parsedVersionCode == null) {
      throw Exception("Couldn't parse versionCode from $version");
    }

    return parsedVersionCode;
  }

  /// Gets applications current version code
  static Future<int> getCurrentVersionCode() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    int? versionCode = int.tryParse(packageInfo.buildNumber);

    if (versionCode == null || versionCode == 1) {
      SimpleLogger().warning("Couldn't parse versionCode");
      String version = await getCurrentVersion();
      return _parseVersionCodeFromVersion(version);
    }

    return versionCode;
  }

  /// Gets latest version from the server
  static Future<String?> getServerVersion(String platform) async {
    try {
      SimpleLogger().info("Checking version...");
      Int8Buffer fileContent = await _doRequest("output-metadata.json");
      VersionMetadata versionMetadata =
          VersionMetadata.fromJson(jsonDecode(utf8.decode(fileContent)));
      String? foundVersion = versionMetadata.elements
          .firstWhereOrNull((element) =>
              element.filters.first.value == configuration.getPlatform())
          ?.versionName;

      return foundVersion;
    } catch (exception) {
      SimpleLogger().warning("Couldn't get version from server: $exception");
      return null;
    }
  }

  /// Updates the app to the latest version by [platform]
  static Future<void> updateVersion(String platform) async {
    SimpleLogger().info("Downloading new version...");
    Int8Buffer fileContent = await _doRequest("app-$platform-release.apk");

    String? storageDir = (await getExternalStorageDirectory())?.absolute.path;
    File apkFile = File("$storageDir/fi.metatavu.oss_surveys_customer.apk");

    SimpleLogger().info("Creating new .apk file...");

    if (await apkFile.exists()) {
      await apkFile.delete();
    }
    await apkFile.create();

    SimpleLogger().info("Writing content to the .apk file...");
    await apkFile.writeAsBytes(fileContent);

    SimpleLogger().info("Installing the new .apk file...");

    await FlutterAppInstaller.installApk(
      filePath: apkFile.path,
      silently: false,
    );
    SimpleLogger().info("Installed!");
  }

  /// Does HTTP request to given [url] and return the response as ByteArray
  static Future<Int8Buffer> _doRequest(String url) async {
    String appUpdatesBaseUrl = configuration.getAppUpdatesBaseUrl();
    HttpClient httpClient = HttpClient();
    HttpClientRequest request =
        await httpClient.getUrl(Uri.parse(appUpdatesBaseUrl + url));
    HttpClientResponse response = await request.close();

    return await offlineFileController.readResponseToBytes(response);
  }
}
