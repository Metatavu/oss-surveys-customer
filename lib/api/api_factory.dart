import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:oss_surveys_api/oss_surveys_api.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";

/// API Factory
/// Provides initialized API Clients
class ApiFactory {
  ApiFactory._();

  factory ApiFactory() => _instance;
  static final ApiFactory _instance = ApiFactory._();

  /// Initializes API Client
  Future<OssSurveysApi> _getApi() async {
    var apiBasePath = dotenv.env["SURVEYS_API_BASE_PATH"];

    return OssSurveysApi(basePathOverride: apiBasePath);
    String? deviceKey = await keysDao.getDeviceKey();
    var api = OssSurveysApi(basePathOverride: apiBasePath);

    if (deviceKey != null) {
      api.dio.options.headers.addAll({"X-DEVICE-KEY": deviceKey});
    }

    return api;
  }

  /// Gets System API
  Future<SystemApi> getSystemApi() {
    return _getApi().then((api) => api.getSystemApi());
  }

  /// Gets Surveys API
  Future<SurveysApi> getSurveysApi() {
    return _getApi().then((api) => api.getSurveysApi());
  }

  /// Gets DeviceRequests API
  Future<DeviceRequestsApi> getDeviceRequestsApi() {
    return _getApi().then((api) => api.getDeviceRequestsApi());
  }
}
