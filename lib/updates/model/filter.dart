import "package:json_annotation/json_annotation.dart";

part "filter.g.dart";

/// Filter class
///
/// Used for deserializing Android build versioning file.
@JsonSerializable()
class Filter {
  Filter(this.filterType, this.value);

  String filterType;
  String value;

  factory Filter.fromJson(Map<String, dynamic> json) => _$FilterFromJson(json);
  Map<String, dynamic> toJson() => _$FilterToJson(this);
}
