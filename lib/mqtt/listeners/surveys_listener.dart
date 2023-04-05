import 'dart:convert';
import 'package:oss_surveys_api/oss_surveys_api.dart';
import 'package:oss_surveys_customer/main.dart';
import 'package:oss_surveys_customer/mqtt/listeners/abstract_listener.dart';
import 'package:oss_surveys_customer/mqtt/model/status_message.dart';
import 'package:oss_surveys_customer/mqtt/model/survey_message.dart';

/// MQTT Surveys Messages listener class
class SurveysListener extends AbstractMqttListener {

  @override
  Map<String, Function(String)> getListeners() => {
    "oss/surveys/create":handleCreateSurvey
  };
  
  @override
  void handleMessage(String message) {
    StatusMessage status = StatusMessage.fromJson(jsonDecode(message));
    print(status.status);
  }
  
  void handleCreateSurvey(String message) async {
    SurveyMessage surveyMessage = SurveyMessage.fromJson(jsonDecode(message));
    SurveysApi surveysApi = await apiFactory.getSurveysApi();
    Survey foundSurvey = await surveysApi.findSurvey(surveyId: surveyMessage.id)
      .then((value) => value.data!);
    
  }
  
  SurveysListener() {
    setListeners();
  }
}