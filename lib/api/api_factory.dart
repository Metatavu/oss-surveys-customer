import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/main.dart";

/// API Factory
/// Provides initialized API Clients
class ApiFactory {
  ApiFactory._();

  factory ApiFactory() => _instance;
  static final ApiFactory _instance = ApiFactory._();

  /// Initializes API Client
  Future<surveys_api.OssSurveysApi> _getApi({
    String? overrideApiBasePath,
    String? overrideDeviceKey,
  }) async {
    late String apiBasePath;
    late String? deviceKey;

    if (overrideApiBasePath != null) {
      apiBasePath = overrideApiBasePath;
    } else {
      apiBasePath = configuration.getSurveysApiBasePath();
    }
    if (overrideDeviceKey != null) {
      deviceKey = overrideDeviceKey;
    } else {
      deviceKey = await keysDao.getDeviceKey();
    }
    var api = surveys_api.OssSurveysApi(basePathOverride: apiBasePath);

    if (deviceKey != null) {
      api.dio.options.headers.addAll({"X-DEVICE-KEY": deviceKey});
    }

    api.dio.options.connectTimeout = const Duration(seconds: 5);
    api.dio.options.receiveTimeout = const Duration(seconds: 5);

    return api;
  }

  /// Gets System API
  Future<surveys_api.SystemApi> getSystemApi() {
    return _getApi().then((api) => api.getSystemApi());
  }

  /// Gets Surveys API
  Future<surveys_api.SurveysApi> getSurveysApi() {
    return _getApi().then((api) => api.getSurveysApi());
  }

  /// Gets DeviceRequests API
  Future<surveys_api.DeviceRequestsApi> getDeviceRequestsApi() {
    return _getApi().then((api) => api.getDeviceRequestsApi());
  }

  /// Gets DeviceSurveys API
  Future<surveys_api.DeviceSurveysApi> getDeviceSurveysApi() {
    return _getApi().then((api) => api.getDeviceSurveysApi());
  }

  /// Gets DeviceData API
  Future<surveys_api.DeviceDataApi> getDeviceDataApi({
    String? overrideApiBasePath,
    String? overrideDeviceKey,
  }) {
    return _getApi(
            overrideApiBasePath: overrideApiBasePath,
            overrideDeviceKey: overrideDeviceKey)
        .then((api) => api.getDeviceDataApi());
  }
}
