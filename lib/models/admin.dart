class Admin {
  final int id;
  final String username;
  final String token;
  final String expiresAt;

  Admin({
    required this.id,
    required this.username,
    required this.token,
    required this.expiresAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'token': token,
      'expires_at': expiresAt,
    };
  }

  bool get isTokenExpired {
    try {
      final expiry = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }
}

class AdminLoginRequest {
  final String username;
  final String password;

  AdminLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class AdminFormData {
  final int? id;
  final String title;
  final List<AdminFormField> fields;
  final String? introduction;
  final String? endtext;
  final String? aintroduction;
  final String? kintroduction;
  final String? aendtext;
  final String? kendtext;

  AdminFormData({
    this.id,
    required this.title,
    required this.fields,
    this.introduction,
    this.endtext,
    this.aintroduction,
    this.kintroduction,
    this.aendtext,
    this.kendtext,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'fields': fields.map((field) => field.toJson()).toList(),
      'introduction': introduction ?? '',
      'endtext': endtext ?? '',
      'aintroduction': aintroduction ?? '',
      'kintroduction': kintroduction ?? '',
      'aendtext': aendtext ?? '',
      'kendtext': kendtext ?? '',
    };
  }
}

class AdminFormField {
  final int id;
  final String type;
  final String labelEn;
  final String labelFa;
  final String labelAr;
  final List<String> optionsEn;
  final List<String> optionsFa;
  final List<String> optionsAr;
  final AdminFieldCondition condition;
  final bool required;

  AdminFormField({
    required this.id,
    required this.type,
    required this.labelEn,
    required this.labelFa,
    required this.labelAr,
    required this.optionsEn,
    required this.optionsFa,
    required this.optionsAr,
    required this.condition,
    required this.required,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label_en': labelEn,
      'label_fa': labelFa,
      'label_ar': labelAr,
      'options_en': optionsEn,
      'options_fa': optionsFa,
      'options_ar': optionsAr,
      'condition': condition.toJson(),
      'required': required,
    };
  }

  factory AdminFormField.fromJson(Map<String, dynamic> json) {
    return AdminFormField(
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      labelEn: json['label_en']?.toString() ?? '',
      labelFa: json['label_fa']?.toString() ?? '',
      labelAr: json['label_ar']?.toString() ?? '',
      optionsEn: (json['options_en'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      optionsFa: (json['options_fa'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      optionsAr: (json['options_ar'] as List<dynamic>?)
          ?.map((option) => option.toString())
          .toList() ?? [],
      condition: AdminFieldCondition.fromJson(json['condition'] ?? {}),
      required: json['required'] is bool ? json['required'] : (json['required'].toString().toLowerCase() == 'true'),
    );
  }
}

class AdminFieldCondition {
  final String dependsOn;
  final String valueEn;
  final String valueFa;
  final String valueAr;

  AdminFieldCondition({
    required this.dependsOn,
    required this.valueEn,
    required this.valueFa,
    required this.valueAr,
  });

  Map<String, dynamic> toJson() {
    return {
      'dependsOn': dependsOn,
      'value_en': valueEn,
      'value_fa': valueFa,
      'value_ar': valueAr,
    };
  }

  factory AdminFieldCondition.fromJson(Map<String, dynamic> json) {
    return AdminFieldCondition(
      dependsOn: json['dependsOn']?.toString() ?? '',
      valueEn: json['value_en']?.toString() ?? '',
      valueFa: json['value_fa']?.toString() ?? '',
      valueAr: json['value_ar']?.toString() ?? '',
    );
  }
}