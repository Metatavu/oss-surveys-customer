import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oss_surveys_api/oss_surveys_api.dart';

class SurveysApiFactory {
  
  SurveysApiFactory._();
  
  static final SurveysApiFactory instance = SurveysApiFactory._();
  
  Future<OssSurveysApi> _getSurveysApi() async {
    // TODO: Add support for planned asymmetric key authentication
    var apiBasePath = dotenv.env["SURVEYS_API_BASE_PATH"];
    
    return OssSurveysApi(basePathOverride: apiBasePath);
  }
}