import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oss_surveys_api/oss_surveys_api.dart';

class ApiFactory {
  
  ApiFactory._();
  
  static final ApiFactory instance = ApiFactory._();
  
  Future<OssSurveysApi> _getApi() async {
    // TODO: Add support for planned asymmetric key authentication
    var apiBasePath = dotenv.env["SURVEYS_API_BASE_PATH"];
    
    return OssSurveysApi(basePathOverride: apiBasePath);
  }
  
  /// Gets System API
  Future<SystemApi> getSystemApi() {
    return _getApi().then((api) => api.getSystemApi());
  }
}