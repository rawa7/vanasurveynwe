import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/admin.dart';
import '../models/survey_form.dart';
import '../services/api_service.dart';
import 'admin_form_create_screen.dart';
import 'admin_form_edit_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Admin admin;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<SurveyForm> forms = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedForms = await ApiService.getAdminForms();
      
      setState(() {
        forms = loadedForms;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService.adminLogout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Admin Dashboard'),
        elevation: 2,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        actions: [
          // User Info
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.admin.username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadForms,
        color: AppColors.primary,
        child: Column(
          children: [
            // Stats Cards
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Forms',
                      forms.length.toString(),
                      Icons.assignment,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Forms',
                      forms.length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Forms List
            Expanded(
              child: _buildFormsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Form'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildFormsList() {
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
                'Failed to load forms',
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
                onPressed: _loadForms,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (forms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.darkGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No forms created yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first form to get started',
              style: TextStyle(
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateForm(),
              icon: const Icon(Icons.add),
              label: const Text('Create Form'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: forms.length,
      itemBuilder: (context, index) {
        final form = forms[index];
        return _buildFormCard(form);
      },
    );
  }

  Widget _buildFormCard(SurveyForm form) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.assignment,
            color: AppColors.white,
            size: 24,
          ),
        ),
        title: Text(
          form.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.darkGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created: ${formatDate(form.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToEditForm(form);
                break;
              case 'view':
                _viewFormDetails(form);
                break;
              case 'delete':
                _showDeleteDialog(form);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditForm(form),
      ),
    );
  }

  void _navigateToCreateForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminFormCreateScreen(),
      ),
    ).then((_) => _loadForms());
  }

  void _navigateToEditForm(SurveyForm form) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminFormEditScreen(formId: form.id),
      ),
    ).then((_) => _loadForms());
  }

  void _viewFormDetails(SurveyForm form) {
    // TODO: Implement form details view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form details view coming soon'),
      ),
    );
  }

  void _showDeleteDialog(SurveyForm form) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: Text('Are you sure you want to delete "${form.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement form deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Form deletion coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}