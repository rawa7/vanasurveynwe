import 'package:flutter/material.dart';
import '../models/form_detail.dart';
import '../models/seller.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import '../widgets/survey_field_widget.dart';

class SurveyScreen extends StatefulWidget {
  final int surveyId;

  const SurveyScreen({super.key, required this.surveyId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  FormDetail? formDetail;
  List<Seller> sellers = [];
  bool isLoading = true;
  bool isSellersLoading = true;
  String? error;
  String currentLanguage = 'en';
  Map<int, dynamic> fieldResponses = {};
  bool isSubmitting = false;
  Seller? selectedSeller;
  bool isSellerRequired = true; // Seller selection is now working

  final Map<String, String> languages = {
    'en': 'English',
    'fa': 'کوردی',
    'ar': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    loadFormDetail();
    loadSellers();
  }

  Future<void> loadFormDetail() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final detail = await ApiService.getFormDetail(widget.surveyId);
      
      setState(() {
        formDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> loadSellers() async {
    try {
      setState(() {
        isSellersLoading = true;
      });

      print('Loading sellers from API...');
      final loadedSellers = await ApiService.getSellers();
      print('Loaded ${loadedSellers.length} sellers: $loadedSellers');
      
      setState(() {
        sellers = loadedSellers;
        isSellersLoading = false;
      });
    } catch (e) {
      setState(() {
        isSellersLoading = false;
      });
      print('Error loading sellers: $e');
      
      // Show error message to user for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sellers: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String getIntroduction() {
    if (formDetail == null) return '';
    
    switch (currentLanguage) {
      case 'fa':
        return formDetail!.kintroduction.isNotEmpty 
            ? formDetail!.kintroduction 
            : formDetail!.introduction;
      case 'ar':
        return formDetail!.aintroduction.isNotEmpty 
            ? formDetail!.aintroduction 
            : formDetail!.introduction;
      default:
        return formDetail!.introduction;
    }
  }

  String getEndText() {
    if (formDetail == null) return '';
    
    switch (currentLanguage) {
      case 'fa':
        return formDetail!.kendtext.isNotEmpty 
            ? formDetail!.kendtext 
            : formDetail!.endtext;
      case 'ar':
        return formDetail!.aendtext.isNotEmpty 
            ? formDetail!.aendtext 
            : formDetail!.endtext;
      default:
        return formDetail!.endtext;
    }
  }

  bool isFieldVisible(SurveyField field) {
    // TEMPORARY: For debugging, show all fields initially
    // Uncomment the line below to disable conditional logic temporarily
    // return true;
    
    // If no dependency is set, always show the field
    if (field.condition.dependsOn.isEmpty || field.condition.dependsOn == '') return true;
    
    // Try to find the dependency field
    int? dependentFieldIndex;
    for (int i = 0; i < formDetail!.fields.length; i++) {
      if (formDetail!.fields[i].id.toString() == field.condition.dependsOn ||
          i.toString() == field.condition.dependsOn) {
        dependentFieldIndex = i;
        break;
      }
    }
    
    // If dependency field not found, show the field
    if (dependentFieldIndex == null) {
      print('Dependency field not found for: ${field.labelEn}, dependsOn: ${field.condition.dependsOn}');
      return true;
    }
    
    final dependentResponse = fieldResponses[dependentFieldIndex];
    
    // Get condition values and check if any are set
    final conditionValueEn = field.condition.valueEn.trim();
    final conditionValueFa = field.condition.valueFa.trim();
    final conditionValueAr = field.condition.valueAr.trim();
    
    // If no condition values are set, show the field
    if (conditionValueEn.isEmpty && conditionValueFa.isEmpty && conditionValueAr.isEmpty) {
      print('No condition values set for: ${field.labelEn}');
      return true;
    }
    
    // If no response yet, hide the field (wait for dependency to be answered)
    if (dependentResponse == null || dependentResponse.toString().trim().isEmpty) {
      print('No response yet for dependency: ${field.labelEn}');
      return false;
    }
    
    // Check condition value in all languages
    final responseStr = dependentResponse.toString().trim().toLowerCase();
    
    final result = (conditionValueEn.isNotEmpty && responseStr == conditionValueEn.toLowerCase()) ||
                   (conditionValueFa.isNotEmpty && responseStr == conditionValueFa.toLowerCase()) ||
                   (conditionValueAr.isNotEmpty && responseStr == conditionValueAr.toLowerCase());
    
    // Debug logging only for fields with conditions
    if (field.condition.dependsOn.isNotEmpty) {
      print('Field visibility check:');
      print('  Field label: ${field.labelEn}');
      print('  Depends on: ${field.condition.dependsOn}');
      print('  Dependent field index: $dependentFieldIndex');
      print('  Response: "$responseStr"');
      print('  Condition EN: "$conditionValueEn"');
      print('  Condition FA: "$conditionValueFa"');
      print('  Condition AR: "$conditionValueAr"');
      print('  Result: $result');
      print('---');
    }
    
    return result;
  }

  bool isFormValid() {
    if (formDetail == null) return false;
    
    // Check if seller is required and selected
    if (isSellerRequired && selectedSeller == null) {
      return false;
    }
    
    for (int i = 0; i < formDetail!.fields.length; i++) {
      final field = formDetail!.fields[i];
      if (field.required && isFieldVisible(field)) {
        final response = fieldResponses[i];
        if (response == null || 
            (response is String && response.trim().isEmpty) ||
            (response is List && response.isEmpty)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> submitForm() async {
    if (!isFormValid()) {
      String errorMessage;
      
      if (isSellerRequired && selectedSeller == null) {
        errorMessage = currentLanguage == 'ar' ? 'يرجى اختيار بائع' : 
                      currentLanguage == 'fa' ? 'تکایە فرۆشیارێک هەڵبژێرە' : 
                      'Please select a seller';
      } else {
        errorMessage = currentLanguage == 'ar' ? 'يرجى ملء جميع الحقول المطلوبة' : 
                      currentLanguage == 'fa' ? 'تکایە هەموو ئەو بەشانە پڕبکەنەوە کە پێویستن' : 
                      'Please fill all required fields';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final responses = <FormResponse>[];
      
      for (int i = 0; i < formDetail!.fields.length; i++) {
        final field = formDetail!.fields[i];
        final response = fieldResponses[i];
        
        if (response != null) {
          responses.add(FormResponse(
            label: field.labelEn,
            value: response,
          ));
        }
      }

      final result = await ApiService.submitForm(
        formId: widget.surveyId,
        sellerId: selectedSeller?.id ?? 0,
        responses: responses,
        language: currentLanguage,
      );

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        throw Exception(result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      final errorPrefix = currentLanguage == 'ar' ? 'خطأ في إرسال النموذج: ' : 
                          currentLanguage == 'fa' ? 'هەڵەیەک لە ناردنی فۆرمدا: ' : 
                          'Error submitting form: ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorPrefix${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    final thankYouText = currentLanguage == 'ar' ? 'شكرا لك!' : 
                        currentLanguage == 'fa' ? 'سوپاس!' : 'Thank You!';
    final okText = currentLanguage == 'ar' ? 'موافق' : 
                   currentLanguage == 'fa' ? 'باشە' : 'OK';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: currentLanguage == 'ar' ? TextDirection.rtl : 
                     currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(thankYouText),
          content: Text(getEndText()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to home
              },
              child: Text(okText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 2,
        title: Text(
          formDetail?.title ?? 'Survey',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          // Language Selector
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentLanguage,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      currentLanguage = newValue;
                    });
                  }
                },
                items: languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load survey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loadFormDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (formDetail == null) {
      return const Center(child: Text('No survey data'));
    }

    if (formDetail!.isArchived == 1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 64,
                color: AppColors.darkGrey,
              ),
              SizedBox(height: 16),
              Text(
                'Survey Archived',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This survey has been archived and is no longer available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkGrey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Introduction
        if (getIntroduction().isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
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
            child: Directionality(
              textDirection: currentLanguage == 'ar' ? TextDirection.rtl : 
                           currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLanguage == 'ar' ? 'مقدمة' : 
                    currentLanguage == 'fa' ? 'سەرەتا' : 'Introduction',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getIntroduction(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Seller Selection - Always show, even when loading or empty
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
              // Seller Label
              Directionality(
                textDirection: currentLanguage == 'ar' ? TextDirection.rtl : 
                             currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: currentLanguage == 'ar' ? 'اختر البائع' :
                              currentLanguage == 'fa' ? 'فرۆشیار هەڵبژێرە' :
                              'Select Seller',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                          height: 1.4,
                        ),
                      ),
                      if (isSellerRequired)
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
              
              // Seller Dropdown or Loading/Error State
              if (isSellersLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.darkGrey),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.lightGrey.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentLanguage == 'ar' ? 'جاري تحميل البائعين...' :
                        currentLanguage == 'fa' ? 'فرۆشیارەکان دەخوێنرێتەوە...' :
                        'Loading sellers...',
                        style: const TextStyle(color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                )
              else if (sellers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  child: Text(
                    currentLanguage == 'ar' ? 'لا يوجد بائعين متاحين' :
                    currentLanguage == 'fa' ? 'هیچ فرۆشیارێک نەدۆزرایەوە' :
                    'No sellers available',
                    style: const TextStyle(color: Colors.orange),
                  ),
                )
              else
                DropdownButtonFormField<Seller>(
                  value: selectedSeller,
                  onChanged: (Seller? seller) {
                    setState(() {
                      selectedSeller = seller;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: currentLanguage == 'ar' ? 'اختر بائعًا' :
                              currentLanguage == 'fa' ? 'فرۆشیارێک هەڵبژێرە' :
                              'Select a seller',
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
                  items: sellers.map((seller) {
                    return DropdownMenuItem<Seller>(
                      value: seller,
                      child: Text(
                        seller.username,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        // Form Fields
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: formDetail!.fields.length,
            itemBuilder: (context, index) {
              final field = formDetail!.fields[index];
              
              try {
                if (!isFieldVisible(field)) {
                  return const SizedBox.shrink();
                }
              } catch (e) {
                // If there's an error with visibility logic, show the field
                print('Error checking field visibility for field $index: $e');
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: SurveyFieldWidget(
                  field: field,
                  language: currentLanguage,
                  value: fieldResponses[index],
                  onChanged: (value) {
                    setState(() {
                      fieldResponses[index] = value;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Submit Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    currentLanguage == 'ar' ? 'إرسال الاستبيان' : 
                    currentLanguage == 'fa' ? 'ناردنی پرسیارنامە' : 'Submit Survey',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}