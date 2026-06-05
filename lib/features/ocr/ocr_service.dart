import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> scanImage(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    // منطق بسيط لاستخراج أرقام اللوحة (يمكن تحسينه بناءً على شكل اللوحات)
    // نبحث عن أي نص يحتوي على أرقام أو حروف كبيرة
    String? plateNumber;
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (line.text.length >= 3) {
          plateNumber = line.text;
          break;
        }
      }
      if (plateNumber != null) break;
    }

    return plateNumber;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
