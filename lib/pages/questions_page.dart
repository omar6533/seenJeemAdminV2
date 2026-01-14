import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import '../models/seenjeem_question_model.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/seenjeem_service.dart';
import '../services/excel_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

@RoutePage()
class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final SeenjeemService _seenjeemService = SeenjeemService();
  final ExcelService _excelService = ExcelService();

  List<SeenjeemQuestionModel> _questions = [];
  List<MainCategoryModel> _mainCategories = [];
  List<SubCategoryModel> _subCategories = [];
  List<SubCategoryModel> _filteredSubCategories = [];

  String? _filterMainCategoryId;
  String? _filterSubCategoryId;
  int? _filterPoints;
  String? _filterStatus;
  String _searchQuery = '';

  bool _loading = true;
  bool _uploading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final mainCats = await _seenjeemService.getMainCategoriesFuture();
      final subCats = await _seenjeemService.getSubCategoriesFuture();
      final questions = await _seenjeemService.getQuestionsFuture(
        mainCategoryId: _filterMainCategoryId,
        subCategoryId: _filterSubCategoryId,
        points: _filterPoints,
        status: _filterStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _mainCategories = mainCats;
        _subCategories = subCats;
        _questions = questions;
        _filteredSubCategories = _filterMainCategoryId != null
            ? subCats.where((sub) => sub.mainCategoryId == _filterMainCategoryId).toList()
            : subCats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showQuestionDialog([SeenjeemQuestionModel? question]) {
    final isEditing = question != null;

    final questionTextController = TextEditingController(text: question?.questionTextAr ?? '');
    final answerTextController = TextEditingController(text: question?.answerTextAr ?? '');

    String? subCategoryId = question?.subCategoryId ?? _filterSubCategoryId;
    int points = question?.points ?? 200;
    String status = question?.status ?? 'active';
    String? questionMediaUrl = question?.questionMediaUrl;
    String? answerMediaUrl = question?.answerMediaUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Question' : 'Add Question'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub Category *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: subCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _subCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text('${cat.mainCategoryNameAr ?? ''} - ${cat.nameAr}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => subCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Question Text (Arabic) *',
                    controller: questionTextController,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Answer Text (Arabic) *',
                    controller: answerTextController,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Points *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: points,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 200, child: Text('200 Points')),
                      DropdownMenuItem(value: 400, child: Text('400 Points')),
                      DropdownMenuItem(value: 600, child: Text('600 Points')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => points = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Question Media (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (questionMediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            questionMediaUrl!,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 128,
                                height: 128,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () => setDialogState(() => questionMediaUrl = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload),
                    label: const Text('Upload Question Media'),
                    onPressed: _uploading ? null : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );

                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => _uploading = true);
                        try {
                          final file = result.files.first;
                          final url = await _seenjeemService.uploadMedia(
                            file.bytes!,
                            file.name,
                            'questions',
                          );
                          setDialogState(() {
                            questionMediaUrl = url;
                            _uploading = false;
                          });
                        } catch (e) {
                          setDialogState(() => _uploading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Answer Media (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (answerMediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            answerMediaUrl!,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 128,
                                height: 128,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () => setDialogState(() => answerMediaUrl = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload),
                    label: const Text('Upload Answer Media'),
                    onPressed: _uploading ? null : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );

                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => _uploading = true);
                        try {
                          final file = result.files.first;
                          final url = await _seenjeemService.uploadMedia(
                            file.bytes!,
                            file.name,
                            'questions',
                          );
                          setDialogState(() {
                            answerMediaUrl = url;
                            _uploading = false;
                          });
                        } catch (e) {
                          setDialogState(() => _uploading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => status = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _uploading ? null : () async {
                if (questionTextController.text.isEmpty || answerTextController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question and answer text are required')),
                  );
                  return;
                }

                if (subCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sub category is required')),
                  );
                  return;
                }

                try {
                  final data = {
                    'sub_category_id': subCategoryId,
                    'question_text_ar': questionTextController.text,
                    'answer_text_ar': answerTextController.text,
                    'question_media_url': questionMediaUrl,
                    'answer_media_url': answerMediaUrl,
                    'points': points,
                    'status': status,
                  };

                  if (isEditing) {
                    await _seenjeemService.updateQuestionFromMap(question!.id, data);
                  } else {
                    await _seenjeemService.createQuestion(data);
                  }

                  await _loadData();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(SeenjeemQuestionModel question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Details'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildViewField('Sub Category', question.subCategoryNameAr ?? 'N/A'),
                const SizedBox(height: 12),
                _buildViewField('Question (Arabic)', question.questionTextAr, rtl: true),
                const SizedBox(height: 12),
                if (question.questionMediaUrl != null) ...[
                  const Text('Question Media:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(question.questionMediaUrl!, height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildViewField('Answer (Arabic)', question.answerTextAr, rtl: true),
                const SizedBox(height: 12),
                if (question.answerMediaUrl != null) ...[
                  const Text('Answer Media:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(question.answerMediaUrl!, height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildViewField('Points', question.points.toString()),
                const SizedBox(height: 12),
                _buildViewField('Status', question.status),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewField(String label, String value, {bool rtl = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ],
    );
  }

  Future<void> _handleToggleStatus(SeenjeemQuestionModel question) async {
    try {
      final newStatus = question.status == 'active' ? 'disabled' : 'active';
      await _seenjeemService.updateQuestionFromMap(question.id, {'status': newStatus});
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);

    try {
      final rows = await _excelService.parseExcelFile(result.files.first.bytes!);

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      for (final row in rows) {
        try {
          final mainCat = _mainCategories.firstWhere(
            (cat) => cat.nameAr == row['main_category_name_ar'],
            orElse: () => throw Exception('Main category not found'),
          );

          final subCat = _subCategories.firstWhere(
            (cat) => cat.mainCategoryId == mainCat.id && cat.nameAr == row['sub_category_name_ar'],
            orElse: () => throw Exception('Sub category not found'),
          );

          final points = int.parse(row['points'].toString());
          if (![200, 400, 600].contains(points)) {
            errors.add('Invalid points: ${row['points']}');
            errorCount++;
            continue;
          }

          final existing = _questions.any(
            (q) => q.subCategoryId == subCat.id && q.points == points,
          );
          if (existing) {
            skippedCount++;
            continue;
          }

          await _seenjeemService.createQuestion({
            'sub_category_id': subCat.id,
            'question_text_ar': row['question_text_ar'],
            'answer_text_ar': row['answer_text_ar'],
            'question_media_url': row['question_media_url'],
            'answer_media_url': row['answer_media_url'],
            'points': points,
            'status': row['status'] ?? 'active',
          });
          successCount++;
        } catch (e) {
          errors.add('Row error: $e');
          errorCount++;
        }
      }

      await _loadData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Created: $successCount\nSkipped: $skippedCount\nErrors: $errorCount'
              '${errors.isNotEmpty ? '\n\nErrors:\n${errors.take(5).join('\n')}' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  void _handleDownloadTemplate() {
    _excelService.downloadTemplate('questions');
  }

  void _handleExport() {
    _excelService.exportQuestions(_questions);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage quiz questions for SeenJeem game board',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Template'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
                      ),
                      onPressed: _handleDownloadTemplate,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
                      ),
                      onPressed: _handleExport,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload, size: 18),
                      label: Text(_importing ? 'Importing...' : 'Import'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importing ? null : _handleImport,
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Add Question',
                      icon: Icons.add,
                      onPressed: () => _showQuestionDialog(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                border: Border.all(color: Colors.yellow[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.yellow[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: Each sub-category must have exactly ONE question for each point value (200, 400, 600). The system prevents duplicate point values per sub-category.',
                      style: TextStyle(fontSize: 13, color: Colors.yellow[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      const Text('Filters', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterMainCategoryId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Main Categories'),
                            ),
                            ..._mainCategories.map((cat) {
                              return DropdownMenuItem<String?>(
                                value: cat.id,
                                child: Text(cat.nameAr),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterMainCategoryId = value;
                              _filterSubCategoryId = null;
                            });
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterSubCategoryId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Sub Categories'),
                            ),
                            ..._filteredSubCategories.map((cat) {
                              return DropdownMenuItem<String?>(
                                value: cat.id,
                                child: Text(cat.nameAr),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _filterSubCategoryId = value);
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _filterPoints,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem<int?>(value: null, child: Text('All Points')),
                            DropdownMenuItem<int?>(value: 200, child: Text('200 Points')),
                            DropdownMenuItem<int?>(value: 400, child: Text('400 Points')),
                            DropdownMenuItem<int?>(value: 600, child: Text('600 Points')),
                          ],
                          onChanged: (value) {
                            setState(() => _filterPoints = value);
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('All Status')),
                            DropdownMenuItem<String?>(value: 'active', child: Text('Active')),
                            DropdownMenuItem<String?>(value: 'disabled', child: Text('Disabled')),
                            DropdownMenuItem<String?>(value: 'draft', child: Text('Draft')),
                          ],
                          onChanged: (value) {
                            setState(() => _filterStatus = value);
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                            hintText: 'Search questions...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          ),
                          textDirection: TextDirection.rtl,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _questions.isEmpty
                    ? const Center(
                        child: Text(
                          'No questions found. Create your first question or adjust filters.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                            columns: const [
                              DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Media', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                            ],
                            rows: _questions.map((question) {
                              return DataRow(cells: [
                                DataCell(
                                  SizedBox(
                                    width: 300,
                                    child: Text(
                                      question.questionTextAr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    question.subCategoryNameAr ?? 'N/A',
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      question.points.toString(),
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (question.questionMediaUrl != null)
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Icon(Icons.image, size: 16, color: Colors.blue[600]),
                                        ),
                                      if (question.questionMediaUrl != null && question.answerMediaUrl != null)
                                        const SizedBox(width: 4),
                                      if (question.answerMediaUrl != null)
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Icon(Icons.image, size: 16, color: Colors.green[600]),
                                        ),
                                      if (question.questionMediaUrl == null && question.answerMediaUrl == null)
                                        Text('None', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: question.status == 'active'
                                          ? Colors.green[50]
                                          : question.status == 'draft'
                                              ? Colors.grey[200]
                                              : Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      question.status[0].toUpperCase() + question.status.substring(1),
                                      style: TextStyle(
                                        color: question.status == 'active'
                                            ? Colors.green[700]
                                            : question.status == 'draft'
                                                ? Colors.grey[700]
                                                : Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, size: 18),
                                        color: Colors.blue[600],
                                        onPressed: () => _showViewDialog(question),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        color: Colors.blue[600],
                                        onPressed: () => _showQuestionDialog(question),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.power_settings_new, size: 18),
                                        color: question.status == 'active' ? Colors.red[600] : Colors.green[600],
                                        onPressed: () => _handleToggleStatus(question),
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
