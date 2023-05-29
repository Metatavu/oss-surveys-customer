import "package:json_annotation/json_annotation.dart";
import "filter.dart";

part "element.g.dart";

/// Element class
///
/// Used for deserializing Android build versioning file.
@JsonSerializable()
class Element {
  Element(
    this.type,
    this.attributes,
    this.versionCode,
    this.versionName,
    this.outputFile,
    this.filters,
  );

  String type;
  List<dynamic> attributes;
  int versionCode;
  String versionName;
  String outputFile;
  List<Filter> filters;

  factory Element.fromJson(Map<String, dynamic> json) =>
      _$ElementFromJson(json);
  Map<String, dynamic> toJson() => _$ElementToJson(this);
}
