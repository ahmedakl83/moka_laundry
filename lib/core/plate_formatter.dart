import 'package:flutter/services.dart';

class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // إزالة كافة المسافات الحالية للبدء في التنسيق من جديد
    String rawText = newValue.text.replaceAll(' ', '');
    StringBuffer formatted = StringBuffer();

    for (int i = 0; i < rawText.length; i++) {
      String char = rawText[i];
      formatted.write(char);

      // إذا لم يكن هذا هو الحرف الأخير في النص
      if (i < rawText.length - 1) {
        String nextChar = rawText[i + 1];

        // الحالات التي نضيف فيها مسافة:
        // 1. إذا كان العنصر الحالي حرفاً (يجب فصله عما بعده دائماً)
        // 2. إذا كان العنصر الحالي رقماً ولكن الذي يليه حرف (يجب فصل الأرقام عن الحروف)
        if (_isLetter(char) || (_isDigit(char) && _isLetter(nextChar))) {
          formatted.write(' ');
        }
      }
    }

    String result = formatted.toString();

    // إعادة قيمة النص الجديد مع وضع المؤشر في نهاية النص
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  bool _isDigit(String char) {
    // التحقق من الأرقام الإنجليزية (0-9) والأرقام العربية/الهندية (٠-٩)
    return RegExp(r'[0-9\u0660-\u0669]').hasMatch(char);
  }

  bool _isLetter(String char) {
    // أي شيء ليس رقماً وليس مسافة نعتبره حرفاً (يدعم العربية والإنجليزية)
    return !_isDigit(char) && char != ' ';
  }
}
