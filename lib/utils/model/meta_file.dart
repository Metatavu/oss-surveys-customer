import "package:json_annotation/json_annotation.dart";

part "meta_file.g.dart";

/// MetaFile class
///
/// Describes content of .meta files associated with offlined files.
/// Contains files ETag to check if online file has changed since last download.
@JsonSerializable()
class MetaFile {
  MetaFile(this.eTag);

  String? eTag;

  factory MetaFile.fromJson(Map<String, dynamic> json) =>
      _$MetaFileFromJson(json);

  Map<String, dynamic> toJson() => _$MetaFileToJson(this);
}
