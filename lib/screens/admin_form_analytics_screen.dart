import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/survey_response.dart';
import '../services/api_service.dart';

class AdminFormAnalyticsScreen extends StatefulWidget {
  final int formId;
  final String formTitle;

  const AdminFormAnalyticsScreen({
    super.key,
    required this.formId,
    required this.formTitle,
  });

  @override
  State<AdminFormAnalyticsScreen> createState() => _AdminFormAnalyticsScreenState();
}

class _AdminFormAnalyticsScreenState extends State<AdminFormAnalyticsScreen> {
  AnalyticsData? analytics;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final analyticsData = await ApiService.getFormAnalytics(widget.formId);
      
      setState(() {
        analytics = analyticsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
            const Text('Analytics'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: AppColors.primary,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
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
                'Failed to load analytics',
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
                onPressed: _loadAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (analytics == null || analytics!.totalResponses == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.darkGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data to analyze',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analytics will be available once responses are submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGrey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 16),
          
          // Languages Chart
          if (analytics!.languageCounts.isNotEmpty)
            _buildChartCard(
              'Languages',
              analytics!.languageCounts,
              _getLanguageColors(),
            ),
          
          // Cities Chart
          if (analytics!.cityCounts.isNotEmpty)
            _buildChartCard(
              'Cities',
              analytics!.cityCounts,
              _getCityColors(),
            ),
          
          // How did you hear about us
          if (analytics!.hearAboutCounts.isNotEmpty)
            _buildChartCard(
              'How did you hear about us?',
              analytics!.hearAboutCounts,
              _getHearAboutColors(),
            ),
          
          // Areas for improvement
          if (analytics!.improvementCounts.isNotEmpty)
            _buildChartCard(
              'Areas for improvement',
              analytics!.improvementCounts,
              _getImprovementColors(),
            ),
          
          // Sellers performance
          if (analytics!.sellerCounts.isNotEmpty)
            _buildChartCard(
              'Responses by Seller',
              analytics!.sellerCounts,
              _getSellerColors(),
            ),
          
          // Satisfaction ratings
          if (analytics!.satisfactionCounts.isNotEmpty)
            _buildChartCard(
              'Satisfaction Ratings',
              analytics!.satisfactionCounts,
              _getSatisfactionColors(),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Responses',
            analytics!.totalResponses.toString(),
            Icons.assessment,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Average Rating',
            analytics!.averageRating > 0 
              ? analytics!.averageRating.toStringAsFixed(1) 
              : 'N/A',
            Icons.star,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Map<String, int> data, List<Color> colors) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Simple bar chart representation
            ...sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final percentage = (item.value / sortedEntries.fold(0, (sum, e) => sum + e.value) * 100);
              final color = colors[index % colors.length];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _truncateText(item.key, 30),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${item.value} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  List<Color> _getLanguageColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
  }

  List<Color> _getCityColors() {
    return [
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.pink,
      Colors.lime,
      Colors.deepPurple,
    ];
  }

  List<Color> _getHearAboutColors() {
    return [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];
  }

  List<Color> _getImprovementColors() {
    return [
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.yellow,
      Colors.brown,
      Colors.grey,
    ];
  }

  List<Color> _getSellerColors() {
    return [
      AppColors.primary,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];
  }

  List<Color> _getSatisfactionColors() {
    return [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
  }
}
