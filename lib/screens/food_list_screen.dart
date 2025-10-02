import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'add_edit_food_screen.dart';
import 'tag_management_screen.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  _FoodListScreenState createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();
  List<FoodItem> _foodItems = [];
  List<FoodItem> _filteredItems = [];
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';
  bool _isLoading = true;

  final List<String> _filterOptions = ['Tất cả', 'Còn tươi', 'Sắp hết hạn', 'Đã hết hạn'];

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _databaseService.getAllFoodItems();
      setState(() {
        _foodItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading food items: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _foodItems.where((item) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) || item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

        // Status filter
        final matchesFilter = _selectedFilter == 'Tất cả' || (_selectedFilter == 'Còn tươi' && !item.isExpired && !item.isExpiringSoon) || (_selectedFilter == 'Sắp hết hạn' && item.isExpiringSoon && !item.isExpired) || (_selectedFilter == 'Đã hết hạn' && item.isExpired);

        return matchesSearch && matchesFilter;
      }).toList();

      // Sort by expiry date
      _filteredItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    });
  }

  Color _getStatusColor(FoodItem item) {
    if (item.isExpired) {
      return Colors.red;
    } else if (item.isExpiringSoon) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText(FoodItem item) {
    if (item.isExpired) {
      return 'Đã hết hạn';
    } else if (item.isExpiringSoon) {
      return 'Sắp hết hạn';
    } else {
      return 'Còn tươi';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  NavigationItem _buildNavItem(String label, IconData icon) {
    return NavigationItem(
      style: const ButtonStyle.muted(density: ButtonDensity.icon),
      selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.icon),
      label: Text(label),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('GreenBite'),
          subtitle: const Text('Quản lý thực phẩm'),
          trailing: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () async {
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const TagManagementScreen()));
                if (result == true) {
                  _loadFoodItems();
                }
              },
              child: const Icon(Icons.label, color: Colors.red),
            ),
            const Gap(8),

            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () async {
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AddEditFoodScreen()));
                if (result == true) {
                  _loadFoodItems();
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const Divider(),
      ],
      footers: [
        const Divider(),
        NavigationBar(
          labelType: NavigationLabelType.all,
          onSelected: (i) {
            setState(() {
              _selectedIndex = i;
            });
          },
          index: _selectedIndex,
          children: [_buildNavItem('Danh sách', Icons.list), _buildNavItem('Thống kê', Icons.analytics), _buildNavItem('Cài đặt', Icons.settings)],
        ),
      ],
      child: _selectedIndex == 0 ? _buildFoodListTab() : _buildPlaceholderTab(),
    );
  }

  Widget _buildFoodListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Field
              TextField(
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                placeholder: const Text('Tìm kiếm thực phẩm...'),
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
              ),
              const Gap(12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        style: isSelected ? const ButtonStyle.primary() : const ButtonStyle.outline(),
                        onPressed: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _applyFilters();
                        },
                        child: Text(filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Food Items List
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.restaurant, size: 64), Gap(16), const Text('Chưa có thực phẩm nào'), Gap(8), Text('Thêm thực phẩm đầu tiên của bạn!')]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => AddEditFoodScreen(foodItem: item)));
                            if (result == true) {
                              _loadFoodItems();
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Image, Title, and Action Button
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    // Larger Image with Status Border
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 2),
                                      ),
                                      child: item.imagePath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.file(
                                                File(item.imagePath!),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(Icons.restaurant, size: 32, color: _getStatusColor(item));
                                                },
                                              ),
                                            )
                                          : Icon(Icons.restaurant, size: 32, color: _getStatusColor(item)),
                                    ),
                                    const Gap(16),

                                    // Title and Status
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name).large().bold(),
                                          const Gap(6),
                                          // Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: _getStatusColor(item), borderRadius: BorderRadius.circular(16)),
                                            child: Text(
                                              _getStatusText(item),
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const Gap(8),
                                          // Expiry Date
                                          Row(
                                            children: [
                                              Icon(Icons.schedule, size: 16, color: _getStatusColor(item)),
                                              const Gap(4),
                                              Text(
                                                'Hết hạn: ${_formatDate(item.expiryDate)}',
                                                style: TextStyle(color: _getStatusColor(item), fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Button
                                    GhostButton(
                                      density: ButtonDensity.icon,
                                      onPressed: () {
                                        showDropdown(
                                          modal: false,
                                          anchorAlignment: Alignment.topRight,
                                          context: context,
                                          builder: (context) {
                                            return DropdownMenu(
                                              children: [
                                                MenuButton(
                                                  leading: const Icon(Icons.edit, size: 18),
                                                  onPressed: (context) async {
                                                    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => AddEditFoodScreen(foodItem: item)));
                                                    if (result == true) {
                                                      _loadFoodItems();
                                                    }
                                                  },
                                                  child: const Text('Chỉnh sửa'),
                                                ),
                                                MenuButton(
                                                  leading: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                  onPressed: (context) async {
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Xác nhận xóa'),
                                                        content: Text('Bạn có chắc chắn muốn xóa "${item.name}"?'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirmed == true) {
                                                      await _databaseService.deleteFoodItem(item.id);
                                                      _loadFoodItems();
                                                    }
                                                  },
                                                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Icon(Icons.more_vert),
                                    ),
                                  ],
                                ),
                              ),

                              // Description Section
                              if (item.description != null && item.description!.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                                    child: Text(item.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
                                  ),
                                ),
                                const Gap(12),
                              ],

                              // Tags Section
                              if (item.tags.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Gap(6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: item.tags.map((tag) {
                                          return Chip(
                                            style: const ButtonStyle.outline(),
                                            child: Text(tag, style: const TextStyle(fontSize: 12)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Gap(16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab() {
    String tabName = _selectedIndex == 1 ? 'Thống kê' : 'Cài đặt';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_selectedIndex == 1 ? Icons.analytics : Icons.settings, size: 64, color: Colors.black.withValues(alpha: 0.3)),
          const Gap(16),
          Text('$tabName').large(),
          const Gap(8),
          const Text('Sẽ được phát triển trong tương lai').muted(),
        ],
      ),
    );
  }
}
