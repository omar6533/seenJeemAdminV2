import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/seenjeem_service.dart';
import '../services/excel_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

@RoutePage()
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  final SeenjeemService _seenjeemService = SeenjeemService();
  final ExcelService _excelService = ExcelService();

  late TabController _tabController;
  List<MainCategoryModel> _mainCategories = [];
  List<SubCategoryModel> _subCategories = [];
  String? _selectedMainCategoryId;
  bool _loading = true;
  bool _uploading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    try {
      final mainCats = await _seenjeemService.getMainCategoriesFuture();
      final subCats = await _seenjeemService.getSubCategoriesFuture(
          mainCategoryId: _selectedMainCategoryId);

      setState(() {
        _mainCategories = mainCats;
        _subCategories = subCats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  void _showCategoryDialog([dynamic category]) {
    final isMainTab = _tabController.index == 0;
    final isEditing = category != null;

    final nameController = TextEditingController(
      text: isEditing
          ? (isMainTab
              ? (category as MainCategoryModel).nameAr
              : (category as SubCategoryModel).nameAr)
          : '',
    );
    final displayOrderController = TextEditingController(
      text: isEditing
          ? (isMainTab
              ? (category as MainCategoryModel).displayOrder.toString()
              : (category as SubCategoryModel).displayOrder.toString())
          : (isMainTab
              ? _mainCategories.length.toString()
              : _subCategories.length.toString()),
    );

    String? mediaUrl = isEditing
        ? (isMainTab
            ? (category as MainCategoryModel).mediaUrl
            : (category as SubCategoryModel).mediaUrl)
        : null;

    bool isActive = isEditing
        ? (isMainTab
            ? (category as MainCategoryModel).isActive
            : (category as SubCategoryModel).isActive)
        : true;

    String? selectedMainCatId = !isMainTab && isEditing
        ? (category as SubCategoryModel).mainCategoryId
        : (_selectedMainCategoryId ??
            (_mainCategories.isNotEmpty ? _mainCategories.first.id : null));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Edit ${isMainTab ? 'Main' : 'Sub'} Category'
                : 'Add ${isMainTab ? 'Main' : 'Sub'} Category',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMainTab) ...[
                    const Text(
                      'Main Category *',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedMainCatId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: _mainCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.nameAr),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedMainCatId = value);
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    label: 'Name (Arabic) *',
                    controller: nameController,
                    // textDirection: TextDirection.rtl,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Display Order *',
                    controller: displayOrderController,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Media (Image) ${!isMainTab ? '*' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (mediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            mediaUrl!,
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
                            onPressed: () =>
                                setDialogState(() => mediaUrl = null),
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_uploading ? 'Uploading...' : 'Upload Image'),
                    onPressed: _uploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() => _uploading = true);
                              try {
                                final file = result.files.first;
                                final bucket = isMainTab
                                    ? 'main-categories'
                                    : 'sub-categories';
                                final url = await _seenjeemService.uploadMedia(
                                  file.bytes!,
                                  file.name,
                                  bucket,
                                );
                                setDialogState(() {
                                  mediaUrl = url;
                                  _uploading = false;
                                });
                              } catch (e) {
                                setDialogState(() => _uploading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Upload failed: $e')),
                                  );
                                }
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMainTab
                        ? 'Optional: Upload a banner image for this main category'
                        : 'Required: Upload an icon/image for this sub category',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
              onPressed: _uploading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }

                      if (!isMainTab && mediaUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Media is required for sub categories')),
                        );
                        return;
                      }

                      try {
                        if (isMainTab) {
                          final data = {
                            'name_ar': nameController.text,
                            'display_order':
                                int.parse(displayOrderController.text),
                            'is_active': isActive,
                            'status': isActive ? 'active' : 'disabled',
                            'media_url': mediaUrl,
                          };

                          if (isEditing) {
                            await _seenjeemService.updateMainCategoryFromMap(
                                (category as MainCategoryModel).id, data);
                          } else {
                            await _seenjeemService.createMainCategory(data);
                          }
                        } else {
                          final data = {
                            'main_category_id': selectedMainCatId!,
                            'name_ar': nameController.text,
                            'display_order':
                                int.parse(displayOrderController.text),
                            'is_active': isActive,
                            'media_url': mediaUrl!,
                          };

                          if (isEditing) {
                            await _seenjeemService.updateSubCategoryFromMap(
                                (category as SubCategoryModel).id, data);
                          } else {
                            await _seenjeemService.createSubCategory(data);
                          }
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

  Future<void> _handleToggleStatus(dynamic category) async {
    final isMainTab = _tabController.index == 0;

    try {
      if (isMainTab) {
        final cat = category as MainCategoryModel;
        await _seenjeemService.updateMainCategoryFromMap(cat.id, {
          'is_active': !cat.isActive,
          'status': cat.isActive ? 'disabled' : 'active',
        });
      } else {
        final cat = category as SubCategoryModel;
        await _seenjeemService.updateSubCategoryFromMap(cat.id, {
          'is_active': !cat.isActive,
        });
      }
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
      final isMainTab = _tabController.index == 0;
      final rows =
          await _excelService.parseExcelFile(result.files.first.bytes!);

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      for (final row in rows) {
        try {
          if (isMainTab) {
            final existing =
                _mainCategories.any((cat) => cat.nameAr == row['name_ar']);
            if (existing) {
              skippedCount++;
              continue;
            }

            await _seenjeemService.createMainCategory({
              'name_ar': row['name_ar'],
              'display_order': row['display_order'] ?? _mainCategories.length,
              'is_active':
                  row['is_active'] == 'true' || row['is_active'] == true,
              'status': (row['is_active'] == 'true' || row['is_active'] == true)
                  ? 'active'
                  : 'disabled',
              'media_url': row['media_url'],
            });
            successCount++;
          } else {
            final mainCat = _mainCategories.firstWhere(
              (cat) => cat.nameAr == row['main_category_name_ar'],
              orElse: () => throw Exception('Main category not found'),
            );

            final existing = _subCategories.any(
              (cat) =>
                  cat.mainCategoryId == mainCat.id &&
                  cat.nameAr == row['name_ar'],
            );
            if (existing) {
              skippedCount++;
              continue;
            }

            if (row['media_url'] == null ||
                row['media_url'].toString().isEmpty) {
              errors.add('Media required for: ${row['name_ar']}');
              errorCount++;
              continue;
            }

            await _seenjeemService.createSubCategory({
              'main_category_id': mainCat.id,
              'name_ar': row['name_ar'],
              'display_order': row['display_order'] ?? 0,
              'is_active':
                  row['is_active'] == 'true' || row['is_active'] == true,
              'media_url': row['media_url'],
            });
            successCount++;
          }
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
    final isMainTab = _tabController.index == 0;
    _excelService
        .downloadTemplate(isMainTab ? 'main-categories' : 'sub-categories');
  }

  void _handleExport() {
    final isMainTab = _tabController.index == 0;
    if (isMainTab) {
      _excelService.exportMainCategories(_mainCategories);
    } else {
      _excelService.exportSubCategories(_subCategories);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMainTab = _tabController.index == 0;

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
                      'Categories',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage main categories and sub categories for SeenJeem board',
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
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
                      text:
                          'Add ${isMainTab ? 'Main Category' : 'Sub Category'}',
                      icon: Icons.add,
                      onPressed: () => _showCategoryDialog(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue[600],
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Colors.blue[600],
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder),
                              const SizedBox(width: 8),
                              Text(
                                  'Main Categories (${_mainCategories.length})'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open),
                              const SizedBox(width: 8),
                              Text('Sub Categories (${_subCategories.length})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isMainTab) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter by Main Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: _selectedMainCategoryId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
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
                                setState(() => _selectedMainCategoryId = value);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor:
                                MaterialStateProperty.all(Colors.grey[50]),
                            columns: [
                              const DataColumn(
                                  label: Text('Order',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              const DataColumn(
                                  label: Text('Name (Arabic)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              if (!isMainTab)
                                const DataColumn(
                                    label: Text('Main Category',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600))),
                              const DataColumn(
                                  label: Text('Media',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              const DataColumn(
                                  label: Text('Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              const DataColumn(
                                  label: Text('Created At',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              const DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                            ],
                            rows: isMainTab
                                ? _mainCategories.map((category) {
                                    return DataRow(cells: [
                                      DataCell(Text(
                                          category.displayOrder.toString())),
                                      DataCell(Text(category.nameAr,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500))),
                                      DataCell(
                                        category.mediaUrl != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.network(
                                                  category.mediaUrl!,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Icon(Icons.image,
                                                    color: Colors.grey[400]),
                                              ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: category.isActive
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            category.isActive
                                                ? 'Active'
                                                : 'Disabled',
                                            style: TextStyle(
                                              color: category.isActive
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(
                                          _formatDate(category.createdAt))),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 18),
                                              color: Colors.blue[600],
                                              onPressed: () =>
                                                  _showCategoryDialog(category),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.power_settings_new,
                                                  size: 18),
                                              color: category.isActive
                                                  ? Colors.red[600]
                                                  : Colors.green[600],
                                              onPressed: () =>
                                                  _handleToggleStatus(category),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList()
                                : _subCategories.map((category) {
                                    return DataRow(cells: [
                                      DataCell(Text(
                                          category.displayOrder.toString())),
                                      DataCell(Text(category.nameAr,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500))),
                                      DataCell(Text(
                                          category.mainCategoryNameAr ??
                                              'N/A')),
                                      DataCell(
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Image.network(
                                            category.mediaUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: category.isActive
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            category.isActive
                                                ? 'Active'
                                                : 'Disabled',
                                            style: TextStyle(
                                              color: category.isActive
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(
                                          _formatDate(category.createdAt))),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 18),
                                              color: Colors.blue[600],
                                              onPressed: () =>
                                                  _showCategoryDialog(category),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.power_settings_new,
                                                  size: 18),
                                              color: category.isActive
                                                  ? Colors.red[600]
                                                  : Colors.green[600],
                                              onPressed: () =>
                                                  _handleToggleStatus(category),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
