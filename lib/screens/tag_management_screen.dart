import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  _TagManagementScreenState createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Tag> _tags = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tags = await _databaseService.getAllTags();
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tags: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTags(String query) async {
    if (query.isEmpty) {
      _loadTags();
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final tags = await _databaseService.searchTags(query);
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching tags: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddEditTagDialog({Tag? tag}) async {
    final isEditing = tag != null;
    final nameController = TextEditingController(text: tag?.name ?? '');
    final descriptionController = TextEditingController(text: tag?.description ?? '');
    String? selectedColor = tag?.color;

    final colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'];

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(20),
                TextField(controller: nameController, placeholder: const Text('Tên danh mục *'), maxLength: 50, textInputAction: TextInputAction.next, onSubmitted: (_) => FocusScope.of(context).nextFocus()),
                const Gap(16),
                TextField(controller: descriptionController, placeholder: const Text('Mô tả (tùy chọn)'), maxLength: 200, textInputAction: TextInputAction.done, onSubmitted: (_) => FocusScope.of(context).unfocus()),
                const Gap(16),
                const Text('Màu sắc (tùy chọn)').small(),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = isSelected ? null : color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                if (selectedColor != null) ...[
                  const Gap(8),
                  OutlineButton(
                    onPressed: () {
                      setDialogState(() {
                        selectedColor = null;
                      });
                    },
                    child: const Text('Xóa màu'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlineButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          PrimaryButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              try {
                if (isEditing) {
                  final updatedTag = Tag()
                    ..id = tag.id
                    ..name = name
                    ..description = descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim()
                    ..color = selectedColor
                    ..createdAt = tag.createdAt;
                  await _databaseService.updateTag(updatedTag);
                } else {
                  final newTag = Tag()
                    ..name = name
                    ..description = descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim()
                    ..color = selectedColor
                    ..createdAt = DateTime.now();
                  await _databaseService.insertTag(newTag);
                }
                Navigator.of(context).pop(true);
              } catch (e) {
                print('Error saving tag: $e');
              }
            },
            child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );

    // Reload tags if changes were made
    if (mounted) {
      _loadTags();
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "${tag.name}"?'),
        actions: [
          OutlineButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          DestructiveButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteTag(tag.id);
        _loadTags();
      } catch (e) {
        print('Error deleting tag: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Quản lý danh mục'),
          leading: [OutlineButton(density: ButtonDensity.icon, onPressed: () => Navigator.of(context).pop(), child: const Icon(Icons.arrow_back))],
          trailing: [OutlineButton(density: ButtonDensity.icon, onPressed: () => _showAddEditTagDialog(), child: const Icon(Icons.add))],
        ),
        const Divider(),
      ],
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(textInputAction: TextInputAction.done, onSubmitted: (_) => FocusScope.of(context).unfocus(), placeholder: const Text('Tìm kiếm danh mục...'), leading: const Icon(Icons.search), onChanged: _searchTags),
          ),

          // Tags list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.label_outline, size: 48),
                        const Gap(16),
                        Text(_searchQuery.isEmpty ? 'Chưa có danh mục nào' : 'Không tìm thấy danh mục').muted(),
                        const Gap(8),
                        if (_searchQuery.isEmpty) SecondaryButton(onPressed: () => _showAddEditTagDialog(), child: const Text('Thêm danh mục đầu tiên')),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _tags.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Leading icon/color
                            tag.hasColor
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(color: Color(int.parse(tag.color!.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(12)),
                                  )
                                : const Icon(Icons.label_outline),
                            const Gap(16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tag.name).large(),
                                  if (tag.description != null) ...[const Gap(4), Text(tag.description!).muted()],
                                ],
                              ),
                            ),

                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlineButton(
                                  density: ButtonDensity.icon,
                                  onPressed: () => _showAddEditTagDialog(tag: tag),
                                  child: const Icon(Icons.edit, size: 16),
                                ),
                                const Gap(8),
                                OutlineButton(density: ButtonDensity.icon, onPressed: () => _deleteTag(tag), child: const Icon(Icons.delete, size: 16)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
