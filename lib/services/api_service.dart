import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_form.dart';
import '../models/form_detail.dart';
import '../models/seller.dart';
import '../models/admin.dart';

class ApiService {
  static const String baseUrl = 'https://dasroor.com/forms';
  
  static Future<List<SurveyForm>> getPublicForms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_public_forms.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => SurveyForm.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load forms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load forms: $e');
    }
  }

  static Future<FormDetail> getFormDetail(int formId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_form.php?id=$formId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return FormDetail.fromJson(jsonData);
      } else {
        throw Exception('Failed to load form detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load form detail: $e');
    }
  }

  static Future<Map<String, String>> getFormTitleAndIntro(int formId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_titleandintro.php?id=$formId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return {
          'title_en': jsonData['title_en'] ?? '',
          'title_fa': jsonData['title_fa'] ?? '',
          'title_ar': jsonData['title_ar'] ?? '',
          'introduction_en': jsonData['introduction_en'] ?? '',
          'introduction_fa': jsonData['introduction_fa'] ?? '',
          'introduction_ar': jsonData['introduction_ar'] ?? '',
        };
      } else {
        throw Exception('Failed to load form title and intro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load form title and intro: $e');
    }
  }

  static Future<List<Seller>> getSellers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_sellers.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // The API returns {columns: [...], records: [...]}
        if (jsonData.containsKey('records')) {
          final List<dynamic> records = jsonData['records'];
          return records.map((record) {
            return Seller(
              id: int.parse(record['id'].toString()),
              username: record['username'].toString(),
            );
          }).toList();
        } else {
          throw Exception('No records found in response');
        }
      } else {
        throw Exception('Failed to load sellers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sellers: $e');
    }
  }

  static Future<Map<String, dynamic>> submitForm({
    required int formId,
    required int sellerId,
    required List<FormResponse> responses,
    required String language,
  }) async {
    try {
      final requestBody = {
        'formId': formId,
        'sellerid': sellerId,
        'responses': responses.map((r) => r.toJson()).toList(),
        'language': language,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/submit_form.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit form: $e');
    }
  }

  // Admin Authentication Methods
  static Future<Admin> adminLogin(AdminLoginRequest loginRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loginapi.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(loginRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final admin = Admin.fromJson(jsonData['data']);
          await _saveAdminToPrefs(admin);
          return admin;
        } else {
          throw Exception(jsonData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  static Future<void> adminLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_data');
  }

  static Future<Admin?> getStoredAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminJson = prefs.getString('admin_data');
      
      if (adminJson != null) {
        final admin = Admin.fromJson(json.decode(adminJson));
        if (!admin.isTokenExpired) {
          return admin;
        } else {
          await adminLogout();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveAdminToPrefs(Admin admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_data', json.encode(admin.toJson()));
  }

  // Admin Form Management Methods
  static Future<List<SurveyForm>> getAdminForms() async {
    try {
      final admin = await getStoredAdmin();
      if (admin == null) throw Exception('Admin not authenticated');

      // Use the existing public forms endpoint since admin can see all forms
      final response = await http.get(
        Uri.parse('$baseUrl/get_public_forms.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${admin.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => SurveyForm.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load admin forms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load admin forms: $e');
    }
  }

  static Future<FormDetail> getAdminFormDetail(int formId) async {
    try {
      final admin = await getStoredAdmin();
      if (admin == null) throw Exception('Admin not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/get_form2.php?id=$formId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${admin.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return FormDetail.fromJson(jsonData);
      } else {
        throw Exception('Failed to load form detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load form detail: $e');
    }
  }

  static Future<Map<String, dynamic>> saveForm(AdminFormData formData) async {
    try {
      final admin = await getStoredAdmin();
      if (admin == null) throw Exception('Admin not authenticated');

      final requestBody = {
        'title': formData.title,
        'fields': json.encode(formData.fields.map((f) => f.toJson()).toList()),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/save_form.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer ${admin.token}',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save form: $e');
    }
  }

  static Future<Map<String, dynamic>> updateForm(AdminFormData formData) async {
    try {
      final admin = await getStoredAdmin();
      if (admin == null) throw Exception('Admin not authenticated');

      if (formData.id == null) throw Exception('Form ID is required for update');

      final requestBody = {
        'id': formData.id.toString(),
        'title': formData.title,
        'fields': json.encode(formData.fields.map((f) => f.toJson()).toList()),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/update_form.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer ${admin.token}',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData;
        } else {
          throw Exception(jsonData['message'] ?? 'Update failed');
        }
      } else {
        throw Exception('Failed to update form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update form: $e');
    }
  }
}