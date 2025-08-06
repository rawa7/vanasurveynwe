import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/survey_form.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import 'survey_screen.dart';
import 'admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SurveyForm> surveys = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSurveys();
  }

  Future<void> loadSurveys() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedSurveys = await ApiService.getPublicForms();
      
      setState(() {
        surveys = loadedSurveys;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.primary,
            ),
            onPressed: () => _navigateToAdminLogin(),
            tooltip: 'Admin Login',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              color: AppColors.white,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Vana Survey',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a survey to participate',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),

            // Survey List
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadSurveys,
                color: AppColors.primary,
                child: _buildSurveyList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
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
                'Failed to load surveys',
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
                style: TextStyle(
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loadSurveys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (surveys.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: AppColors.darkGrey,
              ),
              SizedBox(height: 16),
              Text(
                'No surveys available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please check back later',
                style: TextStyle(
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        final survey = surveys[index];
        return _buildSurveyCard(survey);
      },
    );
  }

  Widget _buildSurveyCard(SurveyForm survey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToSurvey(survey),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Survey Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Survey Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.darkGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(survey.createdAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSurvey(SurveyForm survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyScreen(surveyId: survey.id),
      ),
    );
  }

  void _navigateToAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLoginScreen(),
      ),
    );
  }
}