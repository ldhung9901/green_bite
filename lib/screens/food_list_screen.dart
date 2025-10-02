import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'add_edit_food_screen.dart';
import 'tag_management_screen.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
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
      style: const ButtonStyle.muted(density: ButtonDensity.compact),
      selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.compact),
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
          subtitle: const Text('Tủ bếp của bạn'),
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
          children: [_buildNavItem('Tủ bếp', LucideIcons.apple), _buildNavItem('Thực đơn', Icons.restaurant)],
        ),
      ],
      child: _selectedIndex == 0 ? _buildFoodListTab() : _buildRecipeTab(),
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
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
                                      ),
                                      child: item.imagePath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.file(
                                                File(item.imagePath!),
                                                width: 60,
                                                height: 60,
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
                                          Text(item.name).base().bold(),
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
                                          // Quantity and Expiry Date
                                          Row(
                                            children: [
                                              Text('${item.quantity} ${item.unit}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                              const Gap(12),
                                            ],
                                          ),
                                          const Gap(6),
                                          Row(
                                            children: [
                                              Icon(Icons.schedule, size: 16, color: _getStatusColor(item)),
                                              const Gap(4),
                                              Text(
                                                '${_formatDate(item.expiryDate)}',
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

  Widget _buildRecipeTab() {
    final recipes = Recipe.getDemoRecipes();

    return Column(
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Icon(Icons.restaurant_menu, size: 24), const Gap(8), const Text('Công thức nấu ăn').base().bold()]),
              const Gap(8),
              const Text('Gợi ý những món ngon từ nguyên liệu có sẵn').small.muted(),
            ],
          ),
        ),

        // Recipe categories filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tất cả', 'Món chính', 'Món khai vị', 'Canh/Súp', 'Salad', 'Bánh mì', 'Đồ uống'].map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    style: category == 'Tất cả' ? const ButtonStyle.primary() : const ButtonStyle.outline(),
                    onPressed: () {
                      // TODO: Implement filtering
                    },
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const Gap(16),

        // Recipes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  child: GestureDetector(
                    onTap: () {
                      _showRecipeDetail(recipe);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe header with image placeholder
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Row(
                            children: [
                              // Recipe image placeholder
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.restaurant_menu, size: 32, color: Colors.orange),
                              ),
                              const Gap(16),

                              // Recipe info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(recipe.name).large().bold(),
                                    const Gap(6),
                                    Text(recipe.description, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const Gap(8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                          child: Text(
                                            recipe.category,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange),
                                          ),
                                        ),
                                        const Gap(8),
                                        Icon(Icons.access_time, size: 14),
                                        const Gap(4),
                                        Text(recipe.cookingTime, style: TextStyle(fontSize: 12)),
                                        const Gap(8),
                                        Icon(Icons.signal_cellular_alt, size: 14),
                                        const Gap(4),
                                        Text(recipe.difficulty, style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        // Tags
                        if (recipe.tags.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: recipe.tags.take(3).map((tag) {
                                return Chip(
                                  style: const ButtonStyle.outline(),
                                  child: Text(tag, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            ),
                          ),
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

  void _showRecipeDetail(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe.name).large().bold(),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // Limit height to 60% of screen
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recipe info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        recipe.category,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange),
                      ),
                    ),
                    const Gap(12),
                    Icon(Icons.access_time, size: 16),
                    const Gap(4),
                    Text(recipe.cookingTime),
                    const Gap(12),
                    Icon(Icons.signal_cellular_alt, size: 16),
                    const Gap(4),
                    Text(recipe.difficulty),
                  ],
                ),
                const Gap(16),

                // Description
                Text(recipe.description, style: const TextStyle(fontSize: 14)),
                const Gap(20),

                // Ingredients
                const Text('Nguyên liệu:').bold(),
                const Gap(8),
                ...recipe.ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(ingredient)),
                      ],
                    ),
                  ),
                ),
                const Gap(20),

                // Instructions
                const Text('Cách làm:').bold(),
                const Gap(8),
                ...recipe.instructions.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final instruction = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text(
                              index.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(child: Text(instruction)),
                      ],
                    ),
                  );
                }),

                // Tags
                if (recipe.tags.isNotEmpty) ...[
                  const Gap(20),
                  const Text('Tags:').bold(),
                  const Gap(8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.tags.map((tag) {
                      return Chip(
                        style: const ButtonStyle.outline(),
                        child: Text(tag, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }
}
