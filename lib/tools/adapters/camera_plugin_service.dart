import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;

import '../ports/camera_service.dart';

/// Production [CameraService] backed by `camera`. Audio is never enabled.
/// Captured files are read into memory and deleted immediately; nothing is
/// written to the photo library.
class CameraPluginService implements CameraService {
  const CameraPluginService();

  @override
  Future<CameraSession> open() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const CameraUnavailable(
        CameraUnavailableReason.error,
        'Kamera listesi alınamadı.',
      );
    }
    CameraDescription? back;
    for (final c in cameras) {
      if (c.lensDirection == CameraLensDirection.back) {
        back = c;
        break;
      }
    }
    final chosen = back ?? (cameras.isEmpty ? null : cameras.first);
    if (chosen == null) {
      throw const CameraUnavailable(
        CameraUnavailableReason.noCamera,
        'Bu cihazda kamera yok.',
      );
    }
    final controller = CameraController(
      chosen,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await _disposeQuietly(controller);
      throw _map(e);
    } catch (_) {
      await _disposeQuietly(controller);
      throw const CameraUnavailable(
        CameraUnavailableReason.error,
        'Kamera başlatılamadı.',
      );
    }
    // Reflections off the scope glass would hurt marking; never fire a flash.
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // Not every device supports it; the capture still works.
    }
    return _PluginSession(controller);
  }

  /// After a failed `initialize()` a disposal can throw again; that must not
  /// replace the permission mapping the caller is about to report.
  static Future<void> _disposeQuietly(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // Already failed; nothing else to release.
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      // The camera plugin has no settings opener; the location plugin's
      // generic app-settings call opens the same Settings page on iOS.
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  CameraUnavailable _map(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return const CameraUnavailable(
          CameraUnavailableReason.denied,
          'Kamera izni verilmedi.',
        );
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return const CameraUnavailable(
          CameraUnavailableReason.deniedPermanently,
          'Kamera erişimi kapalı. Ayarlar\'dan açın.',
        );
      default:
        return const CameraUnavailable(
          CameraUnavailableReason.error,
          'Kamera kullanılamıyor.',
        );
    }
  }
}

class _PluginSession implements CameraSession {
  final CameraController _controller;
  _PluginSession(this._controller);

  @override
  Widget buildPreview(BuildContext context) => CameraPreview(_controller);

  @override
  Future<Uint8List> capture() async {
    final file = await _controller.takePicture();
    try {
      return await file.readAsBytes();
    } finally {
      try {
        await File(file.path).delete();
      } catch (_) {
        // Best effort: the file lives in the app's temporary directory.
      }
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _controller.dispose();
    } catch (_) {
      // Never surface a disposal error as an unhandled zone error.
    }
  }
}
