import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/constants.dart';
import 'customers_provider.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _textController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isImage = false;

  Future<void> _pickFile(FileType type) async {
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = result.files.single;
        _isImage = type == FileType.image;
      });
    }
  }

  void _clearMedia() {
    setState(() {
      _pickedFile = null;
      _isImage = false;
    });
  }

  void _handleSend() async {
    if (_textController.text.isEmpty && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال نص أو اختيار ملف')),
      );
      return;
    }

    final customers = ref.read(customersProvider);
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد عملاء لإرسال الرسالة لهم')),
      );
      return;
    }

    try {
      if (_pickedFile != null) {
        await Share.shareXFiles(
          [XFile(_pickedFile!.path!)],
          text: _textController.text,
        );
      } else {
        await Share.share(_textController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء المشاركة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال رسالة جماعية'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'محتوى الرسالة (عرض خاص أو تهنئة):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'اكتب نص الرسالة هنا...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.grey[50],
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text('إرفاق وسائط (اختياري):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickFile(FileType.image),
                    icon: const Icon(Icons.image),
                    label: const Text('صورة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickFile(FileType.video),
                    icon: const Icon(Icons.videocam),
                    label: const Text('فيديو'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_pickedFile!.path!), fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_file, size: 50, color: Colors.grey),
                                Text('تم اختيار فيديو', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                  IconButton.filled(
                    onPressed: _clearMedia,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _handleSend,
                icon: const Icon(Icons.share),
                label: const Text('مشاركة مع العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ملاحظة: سيتم فتح قائمة المشاركة، اختر التطبيق (مثل WhatsApp) ثم حدد المستلمين.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
