import 'package:json_annotation/json_annotation.dart';

part "artifact_type.g.dart";

/// Artifact Type class
///
/// Used for deserializing Android build versioning file.
@JsonSerializable()
class ArtifactType {
  ArtifactType(this.type, this.kind);

  String type;
  String kind;

  factory ArtifactType.fromJson(Map<String, dynamic> json) =>
      _$ArtifactTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ArtifactTypeToJson(this);
}
