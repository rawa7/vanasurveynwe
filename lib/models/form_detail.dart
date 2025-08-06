class FormDetail {
  final int id;
  final String title;
  final List<SurveyField> fields;
  final int adminId;
  final String createdAt;
  final String displayCondition;
  final String introduction;
  final String endtext;
  final String aintroduction;
  final String kintroduction;
  final String aendtext;
  final String kendtext;
  final int isArchived;

  FormDetail({
    required this.id,
    required this.title,
    required this.fields,
    required this.adminId,
    required this.createdAt,
    required this.displayCondition,
    required this.introduction,
    required this.endtext,
    required this.aintroduction,
    required this.kintroduction,
    required this.aendtext,
    required this.kendtext,
    required this.isArchived,
  });

  factory FormDetail.fromJson(Map<String, dynamic> json) {
    return FormDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      fields: (json['fields'] as List<dynamic>?)
          ?.map((field) => SurveyField.fromJson(field))
          .toList() ?? [],
      adminId: json['admin_id'] != null ? int.tryParse(json['admin_id'].toString()) ?? 0 : 0,
      createdAt: json['created_at']?.toString() ?? '',
      displayCondition: json['display_condition']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      endtext: json['endtext']?.toString() ?? '',
      aintroduction: json['aintroduction']?.toString() ?? '',
      kintroduction: json['kintroduction']?.toString() ?? '',
      aendtext: json['aendtext']?.toString() ?? '',
      kendtext: json['kendtext']?.toString() ?? '',
      isArchived: int.tryParse(json['is_archived'].toString()) ?? 0,
    );
  }
}

class SurveyField {
  final int id;
  final String type;
  final String labelEn;
  final String labelFa;
  final String labelAr;
  final bool required;
  final List<String> optionsEn;
  final List<String> optionsFa;
  final List<String> optionsAr;
  final FieldCondition condition;

  SurveyField({
    required this.id,
    required this.type,
    required this.labelEn,
    required this.labelFa,
    required this.labelAr,
    required this.required,
    required this.optionsEn,
    required this.optionsFa,
    required this.optionsAr,
    required this.condition,
  });

  factory SurveyField.fromJson(Map<String, dynamic> json) {
    return SurveyField(
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      labelEn: json['label_en']?.toString() ?? '',
      labelFa: json['label_fa']?.toString() ?? '',
      labelAr: json['label_ar']?.toString() ?? '',
      required: json['required'] is bool ? json['required'] : (json['required'].toString().toLowerCase() == 'true'),
      optionsEn: (json['options_en'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      optionsFa: (json['options_fa'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      optionsAr: (json['options_ar'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      condition: FieldCondition.fromJson(json['condition'] ?? {}),
    );
  }

  String getLabel(String language) {
    switch (language) {
      case 'fa':
        return labelFa.isNotEmpty ? labelFa : labelEn;
      case 'ar':
        return labelAr.isNotEmpty ? labelAr : labelEn;
      default:
        return labelEn;
    }
  }

  List<String> getOptions(String language) {
    switch (language) {
      case 'fa':
        return optionsFa.isNotEmpty ? optionsFa : optionsEn;
      case 'ar':
        return optionsAr.isNotEmpty ? optionsAr : optionsEn;
      default:
        return optionsEn;
    }
  }
}

class FieldCondition {
  final String dependsOn;
  final String valueEn;
  final String valueFa;
  final String valueAr;

  FieldCondition({
    required this.dependsOn,
    required this.valueEn,
    required this.valueFa,
    required this.valueAr,
  });

  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    return FieldCondition(
      dependsOn: json['dependsOn']?.toString() ?? '',
      valueEn: json['value_en']?.toString() ?? '',
      valueFa: json['value_fa']?.toString() ?? '',
      valueAr: json['value_ar']?.toString() ?? '',
    );
  }

  String getValue(String language) {
    switch (language) {
      case 'fa':
        return valueFa.isNotEmpty ? valueFa : valueEn;
      case 'ar':
        return valueAr.isNotEmpty ? valueAr : valueEn;
      default:
        return valueEn;
    }
  }
}

class FormResponse {
  final String label;
  final dynamic value;

  FormResponse({
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}