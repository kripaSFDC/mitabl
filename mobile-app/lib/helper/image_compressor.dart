import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static const int _defaultQuality = 80;
  static const int _defaultMaxWidth = 1920;
  static const int _defaultMaxHeight = 1920;

  static Future<File> compress(
    File input, {
    int quality = _defaultQuality,
    int maxWidth = _defaultMaxWidth,
    int maxHeight = _defaultMaxHeight,
  }) async {
    try {
      final ext = _extensionOf(input.path);
      final format = _formatFor(ext);
      if (format == null) return input;

      final tmpDir = await getTemporaryDirectory();
      final outName = '${DateTime.now().millisecondsSinceEpoch}_c${_extensionFor(format)}';
      final outPath = '${tmpDir.path}${Platform.pathSeparator}$outName';

      final result = await FlutterImageCompress.compressAndGetFile(
        input.absolute.path,
        outPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
        keepExif: false,
      );

      if (result == null) return input;
      return File(result.path);
    } catch (e, st) {
      AppLogger.error('ImageCompressor failed, returning original', e, st);
      return input;
    }
  }

  static Future<List<File>> compressAll(
    List<File> inputs, {
    int quality = _defaultQuality,
    int maxWidth = _defaultMaxWidth,
    int maxHeight = _defaultMaxHeight,
  }) async {
    final out = <File>[];
    for (final f in inputs) {
      out.add(await compress(f,
          quality: quality, maxWidth: maxWidth, maxHeight: maxHeight));
    }
    return out;
  }

  static String _extensionOf(String path) {
    final slash = path.lastIndexOf(RegExp(r'[\\/]'));
    final name = slash >= 0 ? path.substring(slash + 1) : path;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot).toLowerCase() : '';
  }

  static CompressFormat? _formatFor(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return CompressFormat.jpeg;
      case '.png':
        return CompressFormat.png;
      case '.webp':
        return CompressFormat.webp;
      case '.heic':
        return CompressFormat.heic;
      default:
        return null;
    }
  }

  static String _extensionFor(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return '.jpg';
      case CompressFormat.png:
        return '.png';
      case CompressFormat.webp:
        return '.webp';
      case CompressFormat.heic:
        return '.heic';
    }
  }
}
