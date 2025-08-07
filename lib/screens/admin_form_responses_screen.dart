import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/survey_response.dart';
import '../services/api_service.dart';
import 'admin_form_analytics_screen.dart';

class AdminFormResponsesScreen extends StatefulWidget {
  final int formId;
  final String formTitle;

  const AdminFormResponsesScreen({
    super.key,
    required this.formId,
    required this.formTitle,
  });

  @override
  State<AdminFormResponsesScreen> createState() => _AdminFormResponsesScreenState();
}

class _AdminFormResponsesScreenState extends State<AdminFormResponsesScreen> {
  List<SurveyResponseData> responses = [];
  bool isLoading = true;
  String? error;
  String selectedLanguage = 'all';
  String selectedSeller = 'all';
  TextEditingController searchController = TextEditingController();
  List<SurveyResponseData> filteredResponses = [];

  @override
  void initState() {
    super.initState();
    _loadResponses();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResponses() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final result = await ApiService.getFormResponses(widget.formId);
      
      setState(() {
        responses = result.responses;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<SurveyResponseData> filtered = List.from(responses);

    // Apply language filter
    if (selectedLanguage != 'all') {
      filtered = filtered.where((r) => r.language == selectedLanguage).toList();
    }

    // Apply seller filter
    if (selectedSeller != 'all') {
      filtered = filtered.where((r) => r.sellerId == selectedSeller).toList();
    }

    // Apply search filter
    final searchQuery = searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((response) {
        return response.responses.any((field) => 
          field.label.toLowerCase().contains(searchQuery) ||
          field.displayValue.toLowerCase().contains(searchQuery)
        ) || response.sellerId.toLowerCase().contains(searchQuery);
      }).toList();
    }

    setState(() {
      filteredResponses = filtered;
    });
  }

  Set<String> get availableLanguages {
    final languages = responses.map((r) => r.language).toSet();
    return languages;
  }

  Set<String> get availableSellers {
    final sellers = responses.map((r) => r.sellerId).where((s) => s.isNotEmpty).toSet();
    return sellers;
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String getLanguageDisplayName(String lang) {
    switch (lang) {
      case 'en': return 'English';
      case 'ar': return 'العربية';
      case 'fa': return 'كوردی';
      default: return lang.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Survey Responses'),
            Text(
              widget.formTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 2,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _navigateToAnalytics(),
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResponses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search responses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedLanguage,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Languages')),
                          ...availableLanguages.map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(getLanguageDisplayName(lang)),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLanguage = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSeller,
                        decoration: InputDecoration(
                          labelText: 'Seller',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Sellers')),
                          ...availableSellers.map((seller) => DropdownMenuItem(
                            value: seller,
                            child: Text(seller),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSeller = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.lightGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredResponses.length} of ${responses.length} responses',
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 14,
                  ),
                ),
                if (filteredResponses.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _exportResponses(),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Responses List
          Expanded(
            child: _buildResponsesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesList() {
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
                'Failed to load responses',
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
                onPressed: _loadResponses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredResponses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.darkGrey,
            ),
            const SizedBox(height: 16),
            Text(
              responses.isEmpty ? 'No responses yet' : 'No responses match your filters',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              responses.isEmpty 
                ? 'Responses will appear here once people start submitting the form'
                : 'Try adjusting your search or filter criteria',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredResponses.length,
      itemBuilder: (context, index) {
        final response = filteredResponses[index];
        return _buildResponseCard(response, index);
      },
    );
  }

  Widget _buildResponseCard(SurveyResponseData response, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '#${response.id}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response #${response.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(response.submittedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLanguageColor(response.language).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getLanguageDisplayName(response.language),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getLanguageColor(response.language),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (response.sellerId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    response.sellerId,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...response.responses.where((field) => field.hasValue).map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.lightGrey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            field.displayValue,
                            style: const TextStyle(
                              color: AppColors.darkGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLanguageColor(String language) {
    switch (language) {
      case 'en': return Colors.blue;
      case 'ar': return Colors.green;
      case 'fa': return Colors.orange;
      default: return AppColors.primary;
    }
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminFormAnalyticsScreen(
          formId: widget.formId,
          formTitle: widget.formTitle,
        ),
      ),
    );
  }

  void _exportResponses() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
      ),
    );
  }
}
