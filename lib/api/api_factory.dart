import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:oss_surveys_api/oss_surveys_api.dart";

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
  }
  
  /// Gets System API
  Future<SystemApi> getSystemApi() {
    return _getApi().then((api) => api.getSystemApi());
  }
  
  /// Gets Surveys API
  Future<SurveysApi> getSurveysApi() {
    return _getApi().then((api) => api.getSurveysApi());
  }
}