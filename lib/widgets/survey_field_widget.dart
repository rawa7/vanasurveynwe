import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/form_detail.dart';
import '../constants/app_colors.dart';

class SurveyFieldWidget extends StatefulWidget {
  final SurveyField field;
  final String language;
  final dynamic value;
  final Function(dynamic) onChanged;

  const SurveyFieldWidget({
    super.key,
    required this.field,
    required this.language,
    this.value,
    required this.onChanged,
  });

  @override
  State<SurveyFieldWidget> createState() => _SurveyFieldWidgetState();
}

// Custom TextInputFormatter to handle RTL text properly
class RTLTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // For RTL languages, we want to preserve the natural order of Latin characters
    // This prevents "good" from becoming "doog" while allowing proper RTL cursor behavior
    String text = newValue.text;
    
    // If the text contains primarily Latin characters, maintain LTR order
    if (_isPrimarilyLatin(text)) {
      return newValue;
    }
    
    return newValue;
  }
  
  bool _isPrimarilyLatin(String text) {
    if (text.isEmpty) return true;
    
    int latinCount = 0;
    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);
      // Latin characters range (including extended Latin)
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
          (codeUnit >= 0x0061 && codeUnit <= 0x007A) || // a-z
          (codeUnit >= 0x0030 && codeUnit <= 0x0039) || // 0-9
          (codeUnit >= 0x0020 && codeUnit <= 0x007F)) {  // Basic ASCII
        latinCount++;
      }
    }
    
    return latinCount > (text.length * 0.5); // More than 50% Latin characters
  }
}

class _SurveyFieldWidgetState extends State<SurveyFieldWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(SurveyFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _textController.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Label
          Directionality(
            textDirection: widget.language == 'ar' ? TextDirection.rtl : 
                         widget.language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.field.getLabel(widget.language),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                      height: 1.4,
                    ),
                  ),
                  if (widget.field.required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Field Input
          _buildFieldInput(),
        ],
      ),
    );
  }

  Widget _buildFieldInput() {
    switch (widget.field.type) {
      case 'text':
        return _buildTextInput();
      case 'dropdown':
        return _buildDropdownInput();
      case 'checkbox':
        return _buildCheckboxInput();
      case 'star':
        return _buildStarRatingInput();
      case 'emoji':
        return _buildEmojiRatingInput();
      default:
        return _buildTextInput();
    }
  }

  Widget _buildTextInput() {
    // Determine text direction and alignment based on language
    final isRTL = widget.language == 'ar' || widget.language == 'fa';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRTL ? TextAlign.right : TextAlign.left;
    
    // Determine hint text based on language
    final hintText = widget.language == 'ar' ? 'أدخل إجابتك...' :
                     widget.language == 'fa' ? 'وەڵامەکەت بنووسە...' :
                     'Enter your response...';
    
    return Directionality(
      textDirection: textDirection,
      child: TextField(
        onChanged: widget.onChanged,
        controller: _textController,
        maxLines: 2,
        minLines: 1,
        textDirection: textDirection,
        textAlign: textAlign,
        inputFormatters: isRTL ? [RTLTextInputFormatter()] : null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.lightGrey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildDropdownInput() {
    final options = widget.field.getOptions(widget.language);
    
    return DropdownButtonFormField<String>(
      value: widget.value?.toString(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Select an option',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.lightGrey.withOpacity(0.3),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: const TextStyle(fontSize: 16),
            textDirection: widget.language == 'ar' ? TextDirection.rtl : 
                         widget.language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput() {
    final options = widget.field.getOptions(widget.language);
    final selectedValues = widget.value as List<String>? ?? <String>[];

    return Column(
      children: options.map((option) {
        return Directionality(
          textDirection: widget.language == 'ar' ? TextDirection.rtl : 
                       widget.language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
          child: CheckboxListTile(
            value: selectedValues.contains(option),
            onChanged: (bool? checked) {
              final updatedValues = List<String>.from(selectedValues);
              if (checked == true) {
                if (!updatedValues.contains(option)) {
                  updatedValues.add(option);
                }
              } else {
                updatedValues.remove(option);
              }
              widget.onChanged(updatedValues);
            },
            title: Text(
              option,
              style: const TextStyle(fontSize: 16),
            ),
            activeColor: AppColors.primary,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStarRatingInput() {
    final currentRating = widget.value as int? ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => widget.onChanged(starValue),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: starValue <= currentRating
                      ? AppColors.secondary
                      : AppColors.darkGrey.withOpacity(0.3),
                ),
              ),
            );
          }),
        ),
        if (currentRating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$currentRating out of 5 stars',
              style: const TextStyle(
                color: AppColors.darkGrey,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiRatingInput() {
    const emojis = ['😡', '😟', '😐', '😊', '😃'];
    const emojiLabels = ['Very Bad', 'Bad', 'Neutral', 'Good', 'Excellent'];
    final selectedEmoji = widget.value?.toString();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(emojis.length, (index) {
            final emoji = emojis[index];
            final isSelected = selectedEmoji == emoji;
            
            return GestureDetector(
              onTap: () => widget.onChanged(emoji),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected 
                      ? AppColors.secondary.withOpacity(0.2)
                      : Colors.transparent,
                  border: isSelected 
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.darkGrey.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emojiLabels[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.darkGrey.withOpacity(0.6),
                        fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}