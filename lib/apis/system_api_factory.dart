import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oss_surveys_api/oss_surveys_api.dart';

class SystemApiFactory {
  
  SystemApiFactory._();
  
  static final SystemApiFactory instance = SystemApiFactory._();
  
  Future<SystemApi> _getSurveysApi() async {
    var apiBasePath = dotenv.env["SURVEYS_API_BASE_PATH"];
    
    return SystemApi();
  }
}