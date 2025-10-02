import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  int _quantity = 1;
  String _selectedUnit = 'cái';
  bool _isEditing = false;
  bool _isLoading = false;

  List<Tag> _availableTags = [];
  bool _tagsLoading = true;
  late final TextEditingController _descriptionController;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  bool _showSuggestions = false;
  List<String> _currentSuggestions = [];

  // Common Vietnamese food names for autocomplete
  static const List<String> _commonVietnameseFoods = [
    // Rau củ quả
    'Cà chua', 'Dưa leo', 'Cà rốt', 'Khoai tây', 'Khoai lang', 'Su hào', 'Bắp cải',
    'Rau muống', 'Rau cải', 'Rau xà lách', 'Rau thơm', 'Húng quế', 'Ngò rí', 'Hành lá',
    'Tỏi', 'Hành tím', 'Gừng', 'Ớt', 'Chanh', 'Táo', 'Cam', 'Chuối', 'Xoài',
    'Đu đủ', 'Dưa hấu', 'Dưa gang', 'Nho', 'Dứa', 'Bưởi', 'Quýt',

    // Thịt, cá, hải sản
    'Thịt heo', 'Thịt bò', 'Thịt gà', 'Thịt vịt', 'Cá thu', 'Cá chép', 'Cá lóc',
    'Cá tra', 'Cá hồi', 'Tôm', 'Cua', 'Mực', 'Sò', 'Nghêu', 'Trứng gà', 'Trứng vịt',

    // Thực phẩm chế biến
    'Gạo tẻ', 'Gạo nếp', 'Bún', 'Miến', 'Phở', 'Bánh mì', 'Bánh bao', 'Nem',
    'Chả cá', 'Giò lụa', 'Thịt nguội', 'Pate', 'Bơ', 'Phô mai', 'Sữa tươi',
    'Sữa chua', 'Kem', 'Bánh quy', 'Kẹo', 'Chocolate',

    // Gia vị và nguyên liệu nấu ăn
    'Nước mắm', 'Tương ớt', 'Dầu ăn', 'Dấm', 'Đường', 'Muối', 'Tiêu', 'Ngũ vị hương',
    'Bột ngọt', 'Bột mì', 'Bột năng', 'Nước dừa', 'Sả', 'Lá chanh', 'Me',

    // Đồ uống
    'Nước lọc', 'Nước ngọt', 'Bia', 'Rượu', 'Trà', 'Cà phê', 'Nước cam',
    'Nước dừa tươi', 'Sinh tố', 'Sữa đậu nành',

    // Đồ khô, hạt
    'Đậu phộng', 'Hạt điều', 'Hạt óc chó', 'Nho khô', 'Mít sấy', 'Chuối sấy',
    'Khô bò', 'Khô cá', 'Mắm tôm', 'Tôm khô', 'Nấm khô',
  ];

  List<String> _getFilteredSuggestions(String query) {
    if (query.isEmpty) return [];

    return _commonVietnameseFoods
        .where((food) => food.toLowerCase().contains(query.toLowerCase()))
        .take(8) // Limit to 8 suggestions
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTags();
    if (widget.foodItem != null) {
      _isEditing = true;
      _loadExistingData();
    }
    // Initialize controllers and focus nodes after possible existing data is loaded
    _nameController = TextEditingController(text: _selectedName);
    _descriptionController = TextEditingController(text: _selectedDescription);
    _nameFocusNode = FocusNode();

    // Keep the backing model in sync without calling setState each keystroke
    _nameController.addListener(() {
      _selectedName = _nameController.text;
    });
    _descriptionController.addListener(() {
      _selectedDescription = _descriptionController.text;
    });

    // Hide suggestions when focus is lost (with delay to allow tap selection)
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        // Add a small delay to allow taps to register before hiding
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_nameFocusNode.hasFocus) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      }
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
    _quantity = item.quantity;
    _selectedUnit = item.unit;
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
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
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
        ..quantity = _quantity
        ..unit = _selectedUnit
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
                        // Name Field with Custom Autocomplete
                        FormField(
                          key: _nameKey,
                          label: const Text('Tên thực phẩm *'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                placeholder: const Text('Nhập tên thực phẩm...'),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedName = value;
                                    _currentSuggestions = _getFilteredSuggestions(value);
                                    _showSuggestions = _currentSuggestions.isNotEmpty && value.isNotEmpty;
                                  });
                                },
                              ),
                              if (_showSuggestions) ...[
                                const Gap(4),
                                Card(
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.all(4),
                                      itemCount: _currentSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion = _currentSuggestions[index];
                                        return GhostButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedName = suggestion;
                                              _nameController.text = suggestion;
                                              _showSuggestions = false;
                                              _currentSuggestions.clear();
                                            });
                                            FocusScope.of(context).unfocus();
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(suggestion, style: const TextStyle(fontSize: 14), textAlign: TextAlign.left),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Gap(16),

                        // Description Field
                        FormField(
                          key: _descriptionKey,
                          label: const Text('Mô tả'),
                          child: TextArea(placeholder: const Text('Mô tả thực phẩm (tùy chọn)...'), controller: _descriptionController, expandableHeight: true, initialHeight: 180),
                        ),
                        const Gap(16),

                        // Quantity and Unit Fields
                        const Text('Số lượng & Đơn vị'),
                        const Gap(8),
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextField(
                                initialValue: _quantity.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (value) {
                                  final quantity = int.tryParse(value) ?? 1;
                                  setState(() {
                                    _quantity = quantity > 0 ? quantity : 1;
                                  });
                                },
                                placeholder: const Text('1'),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Select<String>(
                                value: _selectedUnit,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedUnit = newValue;
                                    });
                                  }
                                },
                                placeholder: const Text('Chọn đơn vị'),
                                itemBuilder: (context, item) => Text(item),
                                popup: const SelectPopup(
                                  items: SelectItemList(
                                    children: [
                                      SelectItemButton(value: 'cái', child: Text('cái')),
                                      SelectItemButton(value: 'gói', child: Text('gói')),
                                      SelectItemButton(value: 'hộp', child: Text('hộp')),
                                      SelectItemButton(value: 'chai', child: Text('chai')),
                                      SelectItemButton(value: 'kg', child: Text('kg')),
                                      SelectItemButton(value: 'g', child: Text('g')),
                                      SelectItemButton(value: 'lít', child: Text('lít')),
                                      SelectItemButton(value: 'ml', child: Text('ml')),
                                      SelectItemButton(value: 'lon', child: Text('lon')),
                                      SelectItemButton(value: 'túi', child: Text('túi')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    _nameController.dispose();
    _nameFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
