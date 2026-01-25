import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Firebase Cloud Storage Service
/// Handles file uploads, downloads, and management
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadFile({
    required File file,
    required String destination,
    Function(double)? onProgress,
  }) async {
    try {
      // Get file extension
      final extension = path.extension(file.path);
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create unique filename
      final uniqueFileName = '${timestamp}_$fileName';
      final fullPath = '$destination/$uniqueFileName';

      // Create reference
      final ref = _storage.ref().child(fullPath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': fileName,
        },
      );

      // Upload file with progress tracking
      final uploadTask = ref.putFile(file, metadata);

      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload workshop banner image
  Future<String> uploadWorkshopBanner(
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      destination: 'workshops/banners',
      onProgress: onProgress,
    );
  }

  /// Upload workshop syllabus PDF
  Future<String> uploadWorkshopSyllabus(
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      destination: 'workshops/syllabi',
      onProgress: onProgress,
    );
  }

  /// Upload user profile photo
  Future<String> uploadProfilePhoto(
    String userId,
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      destination: 'users/$userId/profile',
      onProgress: onProgress,
    );
  }

  /// Upload user document (CNIC, license, etc.)
  Future<String> uploadUserDocument(
    String userId,
    String documentType,
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: file,
      destination: 'users/$userId/documents/$documentType',
      onProgress: onProgress,
    );
  }

  /// Download file from URL
  Future<void> downloadFile({
    required String downloadUrl,
    required String savePath,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final file = File(savePath);

      // Download file with progress tracking
      final downloadTask = ref.writeToFile(file);

      // Listen to progress
      if (onProgress != null) {
        downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      await downloadTask;
      debugPrint('✅ File downloaded successfully: $savePath');
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('✅ File deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('❌ Error getting file metadata: $e');
      rethrow;
    }
  }

  /// List files in a directory
  Future<List<Reference>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('❌ Error listing files: $e');
      rethrow;
    }
  }

  /// Get file size in a human-readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Determine content type based on file extension
  String _getContentType(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';

      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';

      // Archives
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';

      // Default
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate file size (max 10MB by default)
  bool isFileSizeValid(File file, {int maxSizeInMB = 10}) {
    final fileSizeInMB = file.lengthSync() / (1024 * 1024);
    return fileSizeInMB <= maxSizeInMB;
  }

  /// Validate file extension
  bool isFileExtensionValid(File file, List<String> allowedExtensions) {
    final extension = path.extension(file.path).toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Compress image before upload (requires image package)
  /// This is a placeholder - implement actual compression if needed
  Future<File> compressImage(File imageFile) async {
    // TODO: Implement image compression using image package
    // For now, return original file
    return imageFile;
  }
}

/// Storage upload result
class UploadResult {
  final String downloadUrl;
  final String path;
  final int fileSize;
  final String contentType;
  final DateTime uploadedAt;

  UploadResult({
    required this.downloadUrl,
    required this.path,
    required this.fileSize,
    required this.contentType,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'downloadUrl': downloadUrl,
      'path': path,
      'fileSize': fileSize,
      'contentType': contentType,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

/// Storage error types
class StorageErrorType {
  static const String unauthorized = 'unauthorized';
  static const String objectNotFound = 'object-not-found';
  static const String bucketNotFound = 'bucket-not-found';
  static const String projectNotFound = 'project-not-found';
  static const String quotaExceeded = 'quota-exceeded';
  static const String unauthenticated = 'unauthenticated';
  static const String retryLimitExceeded = 'retry-limit-exceeded';
  static const String invalidChecksum = 'invalid-checksum';
  static const String canceled = 'canceled';
  static const String unknown = 'unknown';
}

/// Storage upload state
enum UploadState { none, uploading, paused, success, canceled, error }
