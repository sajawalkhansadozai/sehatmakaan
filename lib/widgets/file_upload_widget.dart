import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';

/// File Upload Widget
/// Provides UI for uploading files to Firebase Storage
class FileUploadWidget extends StatefulWidget {
  final String uploadType; // 'image', 'pdf', 'document'
  final String? currentFileUrl;
  final Function(String downloadUrl)? onUploadComplete;
  final List<String>? allowedExtensions;
  final int maxFileSizeMB;
  final String? label;
  final String? hint;

  const FileUploadWidget({
    super.key,
    required this.uploadType,
    this.currentFileUrl,
    this.onUploadComplete,
    this.allowedExtensions,
    this.maxFileSizeMB = 10,
    this.label,
    this.hint,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedFileUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uploadedFileUrl = widget.currentFileUrl;
  }

  Future<void> _pickFile() async {
    try {
      File? file;

      if (widget.uploadType == 'image') {
        // Use image picker for images
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          file = File(pickedFile.path);
        }
      } else {
        // Use file picker for documents/PDFs
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: widget.allowedExtensions ?? ['pdf', 'doc', 'docx'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file == null) return;

      // Validate file
      if (!_storageService.isFileSizeValid(
        file,
        maxSizeInMB: widget.maxFileSizeMB,
      )) {
        setState(() {
          _errorMessage = 'File size exceeds ${widget.maxFileSizeMB}MB limit';
        });
        return;
      }

      if (widget.allowedExtensions != null &&
          !_storageService.isFileExtensionValid(
            file,
            widget.allowedExtensions!,
          )) {
        setState(() {
          _errorMessage =
              'Invalid file type. Allowed: ${widget.allowedExtensions!.join(', ')}';
        });
        return;
      }

      // Upload file
      await _uploadFile(file);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final downloadUrl = await _storageService.uploadFile(
        file: file,
        destination: _getDestination(),
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _uploadedFileUrl = downloadUrl;
        _isUploading = false;
      });

      widget.onUploadComplete?.call(downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('File uploaded successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: $e';
      });
    }
  }

  String _getDestination() {
    switch (widget.uploadType) {
      case 'image':
        return 'uploads/images';
      case 'pdf':
        return 'uploads/pdfs';
      case 'document':
        return 'uploads/documents';
      default:
        return 'uploads/misc';
    }
  }

  IconData _getIcon() {
    switch (widget.uploadType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      default:
        return Icons.upload_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (_uploadedFileUrl != null && !_isUploading)
          _buildUploadedFile()
        else if (_isUploading)
          _buildUploadingState()
        else
          _buildUploadButton(),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],

        if (widget.hint != null && _errorMessage == null) ...[
          const SizedBox(height: 8),
          Text(
            widget.hint!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF14B8A6),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF14B8A6).withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(_getIcon(), size: 48, color: const Color(0xFF14B8A6)),
            const SizedBox(height: 12),
            const Text(
              'Click to upload',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Max size: ${widget.maxFileSizeMB}MB',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Uploading... ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIcon(), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File uploaded',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to change file',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _pickFile,
            icon: const Icon(Icons.edit, color: Color(0xFF14B8A6)),
          ),
        ],
      ),
    );
  }
}
