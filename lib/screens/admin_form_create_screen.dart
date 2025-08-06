import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../models/admin.dart';

class AdminFormCreateScreen extends StatefulWidget {
  const AdminFormCreateScreen({super.key});

  @override
  State<AdminFormCreateScreen> createState() => _AdminFormCreateScreenState();
}

class _AdminFormCreateScreenState extends State<AdminFormCreateScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  List<FormField> formFields = [];
  int questionIdCounter = 0;
  
  // Current question being added
  final _questionLabelEnController = TextEditingController();
  final _questionLabelFaController = TextEditingController();
  final _questionLabelArController = TextEditingController();
  final _conditionValueEnController = TextEditingController();
  final _conditionValueFaController = TextEditingController();
  final _conditionValueArController = TextEditingController();
  
  String selectedQuestionType = 'text';
  bool isRequired = false;
  String dependsOn = '';
  List<OptionSet> options = [];
  
  bool isSaving = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionLabelEnController.dispose();
    _questionLabelFaController.dispose();
    _questionLabelArController.dispose();
    _conditionValueEnController.dispose();
    _conditionValueFaController.dispose();
    _conditionValueArController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearQuestionForm() {
    _questionLabelEnController.clear();
    _questionLabelFaController.clear();
    _questionLabelArController.clear();
    _conditionValueEnController.clear();
    _conditionValueFaController.clear();
    _conditionValueArController.clear();
    setState(() {
      selectedQuestionType = 'text';
      isRequired = false;
      dependsOn = '';
      options.clear();
    });
  }

  void _addOption() {
    setState(() {
      options.add(OptionSet());
    });
  }

  void _removeOption(int index) {
    setState(() {
      options.removeAt(index);
    });
  }

  String? _getValidDependsOnValue() {
    if (dependsOn.isEmpty) return '';
    
    // Check if the current dependsOn value exists in available questions
    final availableIds = formFields
        .where((field) => field.type != 'text' && field.optionsEn.isNotEmpty)
        .map((field) => field.id.toString())
        .toSet();
    
    if (availableIds.contains(dependsOn)) {
      return dependsOn;
    } else {
      // Reset to empty if invalid
      dependsOn = '';
      return '';
    }
  }

  List<DropdownMenuItem<String>> _buildDependsOnItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '',
        child: Text('Always show (no condition)'),
      ),
    ];
    
    // Only include questions that have options (dropdown, checkbox) and avoid duplicates
    final seenIds = <String>{''};
    
    for (final field in formFields) {
      final fieldId = field.id.toString();
      
      // Only include questions with options and avoid duplicates
      if ((field.type == 'dropdown' || field.type == 'checkbox') && 
          field.optionsEn.isNotEmpty && 
          !seenIds.contains(fieldId)) {
        
        seenIds.add(fieldId);
        items.add(
          DropdownMenuItem(
            value: fieldId,
            child: Text('${field.labelEn} (${field.type})'),
          ),
        );
      }
    }
    
    return items;
  }

  void _addQuestion() {
    if (_questionLabelEnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question label'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure unique question ID
    final newQuestionId = questionIdCounter;
    questionIdCounter++;
    
    final question = FormField(
      id: newQuestionId,
      type: selectedQuestionType,
      labelEn: _questionLabelEnController.text,
      labelFa: _questionLabelFaController.text,
      labelAr: _questionLabelArController.text,
      optionsEn: options.map((o) => o.en).toList(),
      optionsFa: options.map((o) => o.fa).toList(),
      optionsAr: options.map((o) => o.ar).toList(),
      condition: FormCondition(
        dependsOn: dependsOn,
        valueEn: _conditionValueEnController.text,
        valueFa: _conditionValueFaController.text,
        valueAr: _conditionValueArController.text,
      ),
      required: isRequired,
    );

    setState(() {
      formFields.add(question);
    });

    _clearQuestionForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      formFields.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to form settings tab
      return;
    }
    
    if (formFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      _tabController.animateTo(1); // Go to add questions tab
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final adminFormData = AdminFormData(
        title: _titleController.text,
        fields: formFields.map((f) => f.toAdminFormField()).toList(),
      );

      final result = await ApiService.saveForm(adminFormData);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Create New Form'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkGrey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.settings),
              text: 'Settings',
            ),
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Add Questions',
            ),
            Tab(
              icon: Icon(Icons.preview),
              text: 'Manage & Preview',
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFormSettingsTab(),
            _buildAddQuestionsTab(),
            _buildPreviewTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                : const Text(
                    'Save Form',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Form Configuration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Form Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Form Title (English)',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                      helperText: 'Enter a descriptive title for your form',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter form title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Next Steps',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Enter your form title above\n'
                          '2. Go to "Questions" tab to add questions\n'
                          '3. Use "Preview" tab to see how it looks\n'
                          '4. Save when ready!',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddQuestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Add New Question Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Add New Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Question Type
                  DropdownButtonFormField<String>(
                    value: selectedQuestionType,
                    decoration: const InputDecoration(
                      labelText: 'Question Type',
                      prefixIcon: Icon(Icons.quiz),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'text',
                        child: Row(
                          children: [
                            Icon(Icons.text_fields, size: 20),
                            SizedBox(width: 8),
                            Text('Text Input'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'dropdown',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_drop_down_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Dropdown'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'checkbox',
                        child: Row(
                          children: [
                            Icon(Icons.check_box, size: 20),
                            SizedBox(width: 8),
                            Text('Checkbox'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'star',
                        child: Row(
                          children: [
                            Icon(Icons.star_rate, size: 20),
                            SizedBox(width: 8),
                            Text('Star Rating'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'emoji',
                        child: Row(
                          children: [
                            Icon(Icons.emoji_emotions, size: 20),
                            SizedBox(width: 8),
                            Text('Emoji Rating'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedQuestionType = value!;
                        if (value != 'dropdown' && value != 'checkbox') {
                          options.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Question Labels
                  TextFormField(
                    controller: _questionLabelEnController,
                    decoration: const InputDecoration(
                      labelText: 'Question Label (English)',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _questionLabelFaController,
                    decoration: const InputDecoration(
                      labelText: 'ناوی پرسیار (كوردی)',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _questionLabelArController,
                    decoration: const InputDecoration(
                      labelText: 'تسمية السؤال (العربية)',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Required Checkbox
                  Card(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    child: CheckboxListTile(
                      title: const Text('Is this question required?'),
                      subtitle: const Text('Required questions must be answered'),
                      value: isRequired,
                      onChanged: (value) {
                        setState(() {
                          isRequired = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Conditional Logic Section
                  _buildConditionalLogicSection(),
                  const SizedBox(height: 16),
                  
                  // Options Section
                  if (selectedQuestionType == 'dropdown' || selectedQuestionType == 'checkbox')
                    _buildOptionsSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Add Question Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Added Questions Management
          if (formFields.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Manage Questions (${formFields.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...formFields.asMap().entries.map((entry) {
                      int index = entry.key;
                      FormField field = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: AppColors.lightGrey.withOpacity(0.3),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          title: Text(
                            field.labelEn,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      field.type.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: AppColors.primary.withOpacity(0.2),
                                  ),
                                  if (field.required) ...[
                                    const SizedBox(width: 8),
                                    const Chip(
                                      label: Text(
                                        'Required',
                                        style: TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  ],
                                  if (field.condition.dependsOn.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Chip(
                                      label: Text(
                                        'Conditional',
                                        style: TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.secondary,
                                    ),
                                  ],
                                ],
                              ),
                              if (field.condition.dependsOn.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Shows when question ${field.condition.dependsOn} = "${field.condition.valueEn}"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeQuestion(index),
                            tooltip: 'Delete Question',
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Form Preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_titleController.text.isEmpty && formFields.isEmpty) 
                    _buildEmptyPreview()
                  else
                    _buildFormPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.darkGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Form preview will appear here',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkGrey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a title and questions to see the preview',
            style: TextStyle(
              color: AppColors.darkGrey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_titleController.text.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _titleController.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        if (formFields.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkGrey.withOpacity(0.3)),
            ),
            child: const Text(
              'No questions added yet.\nGo to "Questions" tab to add questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 16,
              ),
            ),
          )
        else
          ...formFields.asMap().entries.map((entry) {
            int index = entry.key;
            FormField field = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field.labelEn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (field.required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      field.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (field.labelFa.isNotEmpty || field.labelAr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (field.labelFa.isNotEmpty)
                      Text('Kurdish: ${field.labelFa}', style: const TextStyle(fontSize: 14)),
                    if (field.labelAr.isNotEmpty)
                      Text('Arabic: ${field.labelAr}', style: const TextStyle(fontSize: 14)),
                  ],
                  if (field.optionsEn.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: field.optionsEn.map((option) => Chip(
                        label: Text(option),
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                      )).toList(),
                    ),
                  ],
                  if (field.condition.dependsOn.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔗 Conditional: Shows when question ${field.condition.dependsOn} = "${field.condition.valueEn}"',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildConditionalLogicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Conditional Logic (Show If...)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Conditional Logic Help',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This question will only appear if another question has a specific answer.\n'
                    'Example: Show "Why did you rate us low?" only if rating is 1 or 2 stars.',
                    style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Depends On Dropdown
            DropdownButtonFormField<String>(
              value: _getValidDependsOnValue(),
              decoration: const InputDecoration(
                labelText: 'Show this question ONLY if...',
                prefixIcon: Icon(Icons.help_outline),
                border: OutlineInputBorder(),
                helperText: 'Select a previous question',
              ),
              items: _buildDependsOnItems(),
              onChanged: (value) {
                setState(() {
                  dependsOn = value ?? '';
                  if (dependsOn.isEmpty) {
                    // Clear condition values when no condition is selected
                    _conditionValueEnController.clear();
                    _conditionValueFaController.clear();
                    _conditionValueArController.clear();
                  }
                });
              },
            ),
            
            // Show condition value inputs only if a question is selected
            if (dependsOn.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              // Find the selected question to show its options
              Builder(
                builder: (context) {
                  FormField? selectedField;
                  try {
                    selectedField = formFields.cast<FormField?>().firstWhere(
                      (field) => field?.id.toString() == dependsOn,
                      orElse: () => null,
                    );
                  } catch (e) {
                    selectedField = null;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rule, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Condition: When "${selectedField?.labelEn ?? 'Selected Question'}" equals:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Show options if the selected question has them
                        if (selectedField?.optionsEn.isNotEmpty == true) ...[
                          const Text(
                            'Select the answer that should trigger this question:',
                            style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: selectedField?.optionsEn.map((option) {
                              final isSelected = _conditionValueEnController.text == option;
                              return FilterChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected && selectedField != null) {
                                    setState(() {
                                      _conditionValueEnController.text = option;
                                      // Try to find matching translations
                                      final optionIndex = selectedField.optionsEn.indexOf(option);
                                      if (optionIndex != -1) {
                                        if (selectedField.optionsFa.length > optionIndex) {
                                          _conditionValueFaController.text = selectedField.optionsFa[optionIndex];
                                        }
                                        if (selectedField.optionsAr.length > optionIndex) {
                                          _conditionValueArController.text = selectedField.optionsAr[optionIndex];
                                        }
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      _conditionValueEnController.clear();
                                      _conditionValueFaController.clear();
                                      _conditionValueArController.clear();
                                    });
                                  }
                                },
                                backgroundColor: isSelected 
                                    ? AppColors.secondary.withOpacity(0.2)
                                    : null,
                                selectedColor: AppColors.secondary.withOpacity(0.3),
                              );
                            }).toList() ?? [],
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Manual condition values for text fields or custom values
                        const Text(
                          'Or enter custom condition values:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Condition Value Fields
                        TextFormField(
                          controller: _conditionValueEnController,
                          decoration: const InputDecoration(
                            labelText: 'Condition Value (English)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            helperText: 'The exact answer that should trigger this question',
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _conditionValueFaController,
                                decoration: const InputDecoration(
                                  labelText: 'Kurdish Value',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _conditionValueArController,
                                decoration: const InputDecoration(
                                  labelText: 'Arabic Value',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Option'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkGrey.withOpacity(0.3)),
            ),
            child: const Text(
              'No options added yet.\nClick "Add Option" to add choices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkGrey),
            ),
          )
        else
          ...options.asMap().entries.map((entry) {
            int index = entry.key;
            OptionSet option = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppColors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: option.enController,
                            decoration: const InputDecoration(
                              labelText: 'Option (English)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => option.en = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeOption(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 36), // Space for avatar
                        Expanded(
                          child: TextFormField(
                            controller: option.faController,
                            decoration: const InputDecoration(
                              labelText: 'Option (Kurdish)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => option.fa = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: option.arController,
                            decoration: const InputDecoration(
                              labelText: 'Option (Arabic)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => option.ar = value,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}

// Supporting Classes (keeping the same as before)
class FormField {
  final int id;
  final String type;
  final String labelEn;
  final String labelFa;
  final String labelAr;
  final List<String> optionsEn;
  final List<String> optionsFa;
  final List<String> optionsAr;
  final FormCondition condition;
  final bool required;

  FormField({
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

  AdminFormField toAdminFormField() {
    return AdminFormField(
      id: id,
      type: type,
      labelEn: labelEn,
      labelFa: labelFa,
      labelAr: labelAr,
      optionsEn: optionsEn,
      optionsFa: optionsFa,
      optionsAr: optionsAr,
      condition: AdminFieldCondition(
        dependsOn: condition.dependsOn,
        valueEn: condition.valueEn,
        valueFa: condition.valueFa,
        valueAr: condition.valueAr,
      ),
      required: required,
    );
  }
}

class FormCondition {
  final String dependsOn;
  final String valueEn;
  final String valueFa;
  final String valueAr;

  FormCondition({
    required this.dependsOn,
    required this.valueEn,
    required this.valueFa,
    required this.valueAr,
  });
}

class OptionSet {
  String en = '';
  String fa = '';
  String ar = '';
  
  final TextEditingController enController = TextEditingController();
  final TextEditingController faController = TextEditingController();
  final TextEditingController arController = TextEditingController();
}