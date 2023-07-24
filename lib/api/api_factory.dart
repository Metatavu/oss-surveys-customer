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
  Future<surveys_api.OssSurveysApi> _getApi() async {
    var apiBasePath = configuration.getSurveysApiBasePath();

    String? deviceKey = await keysDao.getDeviceKey();
    var api = surveys_api.OssSurveysApi(basePathOverride: apiBasePath);

    if (deviceKey != null) {
      api.dio.options.headers.addAll({"X-DEVICE-KEY": deviceKey});
    }

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
  Future<surveys_api.DeviceDataApi> getDeviceDataApi() {
    return _getApi().then((api) => api.getDeviceDataApi());
  }
}
