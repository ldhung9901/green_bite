import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/tag.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import 'tag_management_screen.dart';

class AddEditFoodScreen extends StatefulWidget {
  final FoodItem? foodItem;

  const AddEditFoodScreen({super.key, this.foodItem});

  @override
  _AddEditFoodScreenState createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _nameKey = const TextFieldKey('name');
  final _descriptionKey = const TextFieldKey('description');

  String? _imagePath;
  String _selectedName = '';
  String _selectedDescription = '';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  List<String> _tags = [];
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isOcrProcessing = false;

  List<Tag> _availableTags = [];
  bool _tagsLoading = true;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _loadTags();
    if (widget.foodItem != null) {
      _isEditing = true;
      _loadExistingData();
    }
    // Initialize controller after possible existing data is loaded
    _descriptionController = TextEditingController(text: _selectedDescription);
    // Keep the backing model in sync without calling setState each keystroke
    _descriptionController.addListener(() {
      _selectedDescription = _descriptionController.text;
    });
  }

  Future<void> _loadTags() async {
    setState(() {
      _tagsLoading = true;
    });

    try {
      // Initialize default tags if none exist
      await _databaseService.initializeDefaultTags();
      final tags = await _databaseService.getAllTags();
      setState(() {
        _availableTags = tags;
        _tagsLoading = false;
      });
    } catch (e) {
      print('Error loading tags: $e');
      setState(() {
        _tagsLoading = false;
      });
    }
  }

  void _loadExistingData() {
    final item = widget.foodItem!;
    _selectedName = item.name;
    _selectedDescription = item.description ?? '';
    _imagePath = item.imagePath;
    _expiryDate = item.expiryDate;
    _tags = List.from(item.tags);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await PermissionService.requestCameraPermissionWithDialog(context);
      if (!hasPermission) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Camera permission is required to take photos.'),
            actions: [Button(style: ButtonStyle.primary(), onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          ),
        );
        return;
      }
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 70);

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        // Automatically OCR the newly selected image
        await _performOcrOnPath(image.path);
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _pickImageAndOcr() async {
    // Request camera permission first (with dialog to guide to Settings on iOS)
    final hasPermission = await PermissionService.requestCameraPermissionWithDialog(context);
    if (!hasPermission) {
      // Show a message or handle denial
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Camera permission is required to scan food labels.'),
          actions: [Button(style: ButtonStyle.primary(), onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (image == null) return;
      setState(() {
        _imagePath = image.path;
      });
      await _performOcrOnPath(image.path);
    } catch (e) {
      print('Lỗi khi chụp ảnh để OCR: $e');
    }
  }

  Future<void> _performOcrOnPath(String path) async {
    if (path.isEmpty) return;
    setState(() {
      _isOcrProcessing = true;
    });
    try {
      final text = await FlutterTesseractOcr.extractText(
        path,
        language: 'eng+vie', // Requires tessdata for languages, fallback handled below
      );
      String processed = text.trim();
      if (processed.isEmpty) {
        // Fallback attempt with English only
        try {
          final fallback = await FlutterTesseractOcr.extractText(path, language: 'eng');
          processed = fallback.trim();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        if (_selectedDescription.isEmpty) {
          _selectedDescription = processed;
        } else if (processed.isNotEmpty && !_selectedDescription.contains(processed)) {
          _selectedDescription = (_selectedDescription + '\n' + processed).trim();
        }
      });
    } catch (e) {
      print('OCR error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
        });
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _saveFoodItem() async {
    if (_selectedName.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final foodItem = FoodItem()
        ..name = _selectedName.trim()
        ..description = _selectedDescription.trim().isEmpty ? null : _selectedDescription.trim()
        ..imagePath = _imagePath
        ..expiryDate = _expiryDate
        ..tags = _tags
        ..createdAt = _isEditing ? widget.foodItem!.createdAt : DateTime.now();

      if (_isEditing) {
        foodItem.id = widget.foodItem!.id;
        await _databaseService.updateFoodItem(foodItem);
      } else {
        await _databaseService.insertFoodItem(foodItem);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error saving food item: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // show the indeterminate loading progress in the scaffold chrome when saving
      loadingProgressIndeterminate: _isLoading,
      headers: [
        AppBar(
          title: Text(_isEditing ? 'Chỉnh sửa thực phẩm' : 'Thêm thực phẩm'),
          subtitle: Text(_isEditing ? 'Cập nhật thông tin' : 'Tạo mục mới'),
          leading: [OutlineButton(density: ButtonDensity.icon, onPressed: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back))],
          trailing: [if (!_isLoading) OutlineButton(density: ButtonDensity.icon, onPressed: _saveFoodItem, child: const Icon(Icons.check))],
        ),
        const Divider(),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: _imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagePath!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.restaurant, size: 48);
                                },
                              ),
                            )
                          : const Icon(Icons.restaurant, size: 48),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SecondaryButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt, size: 18), Gap(8), Text('Chụp ảnh')]),
                      ),
                      const Gap(16),
                      SecondaryButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_library, size: 18), Gap(8), Text('Thư viện')]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form with proper shadcn components (moved tags & save button inside so FormErrorBuilder has context)
                  Form(
                    onSubmit: (context, values) {
                      _selectedName = _nameKey[values] ?? '';
                      _selectedDescription = _descriptionKey[values] ?? '';
                      _saveFoodItem();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        FormField(
                          key: _nameKey,
                          label: const Text('Tên thực phẩm *'),
                          child: TextField(
                            placeholder: const Text('Nhập tên thực phẩm...'),
                            initialValue: _selectedName,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                            onChanged: (value) {
                              setState(() {
                                _selectedName = value;
                              });
                            },
                          ),
                        ),
                        const Gap(16),

                        // Description Field
                        FormField(
                          key: _descriptionKey,
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mô tả'),
                              GhostButton(
                                density: ButtonDensity.compact,
                                onPressed: (_isLoading || _isOcrProcessing) ? null : _pickImageAndOcr,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isOcrProcessing) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) else const Icon(Icons.camera_alt, size: 16),
                                    const Gap(4),
                                    Text(_isOcrProcessing ? 'OCR...' : 'OCR'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          child: TextArea(placeholder: const Text('Mô tả thực phẩm (tùy chọn)...'), controller: _descriptionController, expandableHeight: true, initialHeight: 180),
                        ),
                        const Gap(16),

                        // Expiry Date
                        const Text('Ngày hết hạn'),
                        const Gap(8),
                        Row(
                          children: [
                            Expanded(
                              child: DatePicker(
                                value: _expiryDate,
                                mode: PromptMode.dialog,
                                dialogTitle: const Text('Chọn ngày'),
                                stateBuilder: (date) {
                                  if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                                    return DateState.disabled;
                                  }
                                  return DateState.enabled;
                                },
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _expiryDate = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const Gap(24),
                        // Tags Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Danh mục'),
                            GhostButton(
                              density: ButtonDensity.compact,
                              onPressed: () async {
                                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TagManagementScreen()));
                                if (result == true) {
                                  _loadTags(); // Reload tags if changes were made
                                }
                              },
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.settings, size: 16), Gap(4), Text('Quản lý')]),
                            ),
                          ],
                        ),
                        const Gap(8),
                        _tagsLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _availableTags.isEmpty
                            ? Column(
                                children: [
                                  Text('Chưa có danh mục nào').muted(),
                                  const Gap(8),
                                  GhostButton(
                                    onPressed: () async {
                                      final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TagManagementScreen()));
                                      if (result == true) {
                                        _loadTags();
                                      }
                                    },
                                    child: const Text('Thêm danh mục'),
                                  ),
                                ],
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableTags.map((tag) {
                                  final isSelected = _tags.contains(tag.name);
                                  return Chip(
                                    style: isSelected ? const ButtonStyle.primary() : const ButtonStyle.outline(),
                                    onPressed: () => _toggleTag(tag.name),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (tag.hasColor && isSelected) ...[
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(color: Color(int.parse(tag.color!.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(6)),
                                          ),
                                          const Gap(6),
                                        ],
                                        Text(tag.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                        const Gap(32),
                        // Save Button with Form validation
                        FormErrorBuilder(
                          builder: (context, errors, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                onPressed: _isLoading
                                    ? null
                                    : errors.isEmpty
                                    ? () => context.submitForm()
                                    : null,
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                          Gap(8),
                                          Text('Đang lưu...'),
                                        ],
                                      )
                                    : Text(_isEditing ? 'Cập nhật' : 'Lưu thực phẩm'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
