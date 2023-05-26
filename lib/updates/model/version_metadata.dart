import 'package:json_annotation/json_annotation.dart';
import 'package:oss_surveys_customer/updates/model/artifact_type.dart';
import 'package:oss_surveys_customer/updates/model/element.dart';

part "version_metadata.g.dart";

/// Version metadata class
///
/// Used for deserializing Android build versioning file.
@JsonSerializable()
class VersionMetadata {
  VersionMetadata(this.version, this.artifactType, this.applicationId,
      this.variantName, this.elementType, this.elements);

  int version;
  ArtifactType artifactType;
  String applicationId;
  String variantName;
  String elementType;
  List<Element> elements;

  factory VersionMetadata.fromJson(Map<String, dynamic> json) =>
      _$VersionMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$VersionMetadataToJson(this);
}
