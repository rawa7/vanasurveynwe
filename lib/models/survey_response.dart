class SurveyResponseData {
  final int id;
  final String submittedAt;
  final List<ResponseField> responses;
  final String language;
  final String sellerId;

  SurveyResponseData({
    required this.id,
    required this.submittedAt,
    required this.responses,
    required this.language,
    required this.sellerId,
  });

  factory SurveyResponseData.fromJson(Map<String, dynamic> json) {
    return SurveyResponseData(
      id: int.tryParse(json['id'].toString()) ?? 0,
      submittedAt: json['submitted_at']?.toString() ?? '',
      responses: (json['responses'] as List<dynamic>?)
          ?.map((response) => ResponseField.fromJson(response))
          .toList() ?? [],
      language: json['lang']?.toString() ?? 'en',
      sellerId: json['seller_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submitted_at': submittedAt,
      'responses': responses.map((r) => r.toJson()).toList(),
      'lang': language,
      'seller_id': sellerId,
    };
  }
}

class ResponseField {
  final String label;
  final dynamic value;

  ResponseField({
    required this.label,
    required this.value,
  });

  factory ResponseField.fromJson(Map<String, dynamic> json) {
    return ResponseField(
      label: json['label']?.toString() ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  String get displayValue {
    if (value == null) return '';
    if (value is List) {
      return (value as List).join(', ');
    }
    return value.toString();
  }

  bool get hasValue {
    if (value == null) return false;
    if (value is String) return value.toString().trim().isNotEmpty;
    if (value is List) return (value as List).isNotEmpty;
    return true;
  }
}

class SurveyResponsesResult {
  final bool success;
  final List<SurveyResponseData> responses;

  SurveyResponsesResult({
    required this.success,
    required this.responses,
  });

  factory SurveyResponsesResult.fromJson(Map<String, dynamic> json) {
    return SurveyResponsesResult(
      success: json['success'] ?? false,
      responses: (json['responses'] as List<dynamic>?)
          ?.map((response) => SurveyResponseData.fromJson(response))
          .toList() ?? [],
    );
  }
}

class AnalyticsData {
  final Map<String, int> cityCounts;
  final Map<String, int> languageCounts;
  final Map<String, int> satisfactionCounts;
  final Map<String, int> hearAboutCounts;
  final Map<String, int> improvementCounts;
  final Map<String, int> sellerCounts;
  final int totalResponses;
  final double averageRating;

  AnalyticsData({
    required this.cityCounts,
    required this.languageCounts,
    required this.satisfactionCounts,
    required this.hearAboutCounts,
    required this.improvementCounts,
    required this.sellerCounts,
    required this.totalResponses,
    required this.averageRating,
  });

  static AnalyticsData fromResponses(List<SurveyResponseData> responses) {
    final cityCounts = <String, int>{};
    final languageCounts = <String, int>{};
    final satisfactionCounts = <String, int>{};
    final hearAboutCounts = <String, int>{};
    final improvementCounts = <String, int>{};
    final sellerCounts = <String, int>{};
    
    var totalRating = 0.0;
    var ratingCount = 0;

    for (final response in responses) {
      // Count languages
      languageCounts[response.language] = (languageCounts[response.language] ?? 0) + 1;
      
      // Count sellers
      if (response.sellerId.isNotEmpty) {
        sellerCounts[response.sellerId] = (sellerCounts[response.sellerId] ?? 0) + 1;
      }

      // Process individual response fields
      for (final field in response.responses) {
        final label = field.label.toLowerCase();
        final value = field.displayValue;
        
        if (value.isEmpty) continue;

        // City analysis
        if (label.contains('city') || label.contains('شار') || label.contains('مدينة')) {
          cityCounts[value] = (cityCounts[value] ?? 0) + 1;
        }
        
        // Satisfaction/Rating analysis
        if (label.contains('satisfied') || label.contains('rate') || label.contains('quality')) {
          // Handle numeric ratings
          final numericRating = double.tryParse(value);
          if (numericRating != null) {
            totalRating += numericRating;
            ratingCount++;
            satisfactionCounts[value] = (satisfactionCounts[value] ?? 0) + 1;
          } else if (value.contains('😊') || value.contains('😃')) {
            // Handle emoji ratings
            satisfactionCounts['Satisfied'] = (satisfactionCounts['Satisfied'] ?? 0) + 1;
          }
        }
        
        // How did you hear about us
        if (label.contains('hear') || label.contains('بیست') || label.contains('سمعت')) {
          if (field.value is List) {
            for (final item in field.value as List) {
              hearAboutCounts[item.toString()] = (hearAboutCounts[item.toString()] ?? 0) + 1;
            }
          } else {
            hearAboutCounts[value] = (hearAboutCounts[value] ?? 0) + 1;
          }
        }
        
        // Areas for improvement
        if (label.contains('improve') || label.contains('باشتر') || label.contains('تحسين')) {
          if (field.value is List) {
            for (final item in field.value as List) {
              improvementCounts[item.toString()] = (improvementCounts[item.toString()] ?? 0) + 1;
            }
          } else if (value.isNotEmpty) {
            improvementCounts[value] = (improvementCounts[value] ?? 0) + 1;
          }
        }
      }
    }

    final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

    return AnalyticsData(
      cityCounts: cityCounts,
      languageCounts: languageCounts,
      satisfactionCounts: satisfactionCounts,
      hearAboutCounts: hearAboutCounts,
      improvementCounts: improvementCounts,
      sellerCounts: sellerCounts,
      totalResponses: responses.length,
      averageRating: averageRating,
    );
  }
}
