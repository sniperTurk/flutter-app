import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../ports/photo_picker.dart';

/// Production [PhotoPicker] backed by `image_picker` (iOS PHPicker).
///
/// `requestFullMetadata: false` keeps the system picker permission-less: the
/// app never asks for the whole photo library, it only receives the one photo
/// the user selects. The copy the plugin makes in the temporary directory is
/// read into memory and deleted immediately.
class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  @override
  Future<Uint8List?> pickPhoto() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: 3200,
      );
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('access') && (text.contains('denied') || text.contains('restricted'))) {
        throw const PhotoPickFailure(PhotoPickFailureReason.denied, 'Fotoğraflara erişim kapalı.');
      }
      throw const PhotoPickFailure(PhotoPickFailureReason.error, 'Galeri açılamadı.');
    }
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } catch (_) {
      throw const PhotoPickFailure(PhotoPickFailureReason.error, 'Fotoğraf okunamadı.');
    } finally {
      try {
        await File(file.path).delete();
      } catch (_) {
        // Best effort: the copy lives in the app's temporary directory.
      }
    }
  }
}
