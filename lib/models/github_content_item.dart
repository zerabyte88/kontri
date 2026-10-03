import 'package:flutter/material.dart';

class GitHubContentItem {
  final String name;
  final String path;
  final String sha;
  final int size;
  final String type; // 'file', 'dir', 'submodule', 'symlink'
  final String? downloadUrl;
  final String? htmlUrl;

  const GitHubContentItem({
    required this.name,
    required this.path,
    required this.sha,
    required this.size,
    required this.type,
    this.downloadUrl,
    this.htmlUrl,
  });

  factory GitHubContentItem.fromJson(Map<String, dynamic> json) {
    return GitHubContentItem(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      sha: json['sha'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      type: json['type'] as String? ?? 'file',
      downloadUrl: json['download_url'] as String?,
      htmlUrl: json['html_url'] as String?,
    );
  }

  bool get isDirectory => type == 'dir';
  bool get isFile => type == 'file';

  bool get isImage {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return const {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'ico', 'bmp'}.contains(ext);
  }

  bool get isSvg => name.toLowerCase().endsWith('.svg');

  String get formattedSize {
    if (isDirectory) return '';
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  IconData get iconData {
    if (isDirectory) return Icons.folder_rounded;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
      case 'py':
      case 'java':
      case 'kt':
      case 'swift':
      case 'c':
      case 'cpp':
      case 'h':
      case 'rs':
      case 'go':
      case 'rb':
      case 'php':
      case 'html':
      case 'css':
        return Icons.code_rounded;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
      case 'toml':
        return Icons.data_object_rounded;
      case 'md':
      case 'txt':
      case 'rst':
        return Icons.description_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
      case 'ico':
        return Icons.image_outlined;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color get iconColor {
    if (isDirectory) return const Color(0xFFF1E05A);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'js':
        return const Color(0xFFF1E05A);
      case 'ts':
        return const Color(0xFF3178C6);
      case 'py':
        return const Color(0xFF3572A5);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF563D7C);
      case 'md':
        return const Color(0xFF58A6FF);
      case 'json':
      case 'yaml':
      case 'yml':
        return const Color(0xFFCB8FFF);
      case 'png':
      case 'jpg':
      case 'svg':
        return const Color(0xFF3FB950);
      default:
        return const Color(0xFF8B949E);
    }
  }
}
