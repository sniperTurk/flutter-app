import 'profile_codec.dart';
import '../models/domain.dart';

/// Versioned envelope for persisted profile collections.
///
/// V1 originally stored a bare JSON array. Decode keeps that legacy format
/// readable, while new writes use an explicit schema version so future model
/// changes can add deterministic migrations instead of guessing the shape.
class ProfileDocumentCodec {
  static const currentSchemaVersion = 1;
  final ProfileCodec profileCodec;
  const ProfileDocumentCodec({this.profileCodec = const ProfileCodec()});

  Map<String, dynamic> encode(Iterable<RifleProfile> profiles) => {
    'schemaVersion': currentSchemaVersion,
    'profiles': profiles.map(profileCodec.encode).toList(growable: false),
  };

  List<RifleProfile> decode(Object? decoded) {
    final Object? rawProfiles;
    if (decoded is List) {
      // Legacy pre-envelope V1 payload.
      rawProfiles = decoded;
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final version = map['schemaVersion'];
      if (version is! int || version < 1) {
        throw const FormatException('Invalid profile document schemaVersion');
      }
      if (version > currentSchemaVersion) {
        throw FormatException(
          'Unsupported future profile schemaVersion: $version',
        );
      }
      rawProfiles = map['profiles'];
    } else {
      throw const FormatException('Invalid profile document');
    }

    if (rawProfiles is! List) {
      throw const FormatException('Invalid profile collection');
    }

    final byId = <String, RifleProfile>{};
    for (var index = 0; index < rawProfiles.length; index++) {
      final item = rawProfiles[index];
      if (item is! Map) {
        // Never return a partial collection. PersistentProfileStore treats a
        // FormatException as primary corruption and can recover the complete
        // previous snapshot from its backup. Silently dropping one malformed
        // record would let the next save overwrite storage and permanently
        // lose that profile.
        throw FormatException('Invalid profile record at index $index');
      }
      try {
        final profile = profileCodec.decode(Map<String, dynamic>.from(item));
        // Last valid duplicate wins; duplicate ids are a deterministic
        // collection-normalisation case, not malformed persisted data.
        byId.remove(profile.id);
        byId[profile.id] = profile;
      } on FormatException catch (error) {
        throw FormatException('Invalid profile record at index $index: $error');
      }
    }
    return List.unmodifiable(byId.values);
  }
}
