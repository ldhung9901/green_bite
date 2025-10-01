# Green Bite - Food Management App

## 📘 Mô tả dự án

Green Bite là ứng dụng quản lý thực phẩm được xây dựng bằng Flutter và sử dụng Shadcn Flutter UI components. Ứng dụng giúp người dùng theo dõi thực phẩm trong gia đình, nhận cảnh báo khi sắp hết hạn.

## ✅ Tính năng đã triển khai

### 1. **Onboarding Screen**
- 4 slide giới thiệu ứng dụng
- Navigation với page indicators
- Sử dụng Shadcn components (AppBar, Buttons)
- Giới thiệu các tính năng chính: quản lý thực phẩm, nhắc nhở, OCR

### 2. **Food List Screen** 
- Giao diện chính với Shadcn Scaffold
- Navigation bar với 3 tab (Danh sách, Thống kê, Cài đặt)  
- Placeholder cho danh sách thực phẩm (sẵn sàng tích hợp dữ liệu)
- Button thêm thực phẩm mới

### 3. **Add/Edit Food Screen**
- Placeholder screen với thông báo "đang phát triển"
- Navigation back button
- Sẵn sàng mở rộng thêm form fields

### 4. **Data Layer**
- **FoodItem Model**: Complete Isar model với các trường:
  - `id`, `name`, `description`, `imagePath` 
  - `expiryDate`, `tags`, `createdAt`
  - Helper methods: `isExpired`, `isExpiringSoon`, `daysUntilExpiry`
- **DatabaseService**: CRUD operations service với:
  - Insert, update, delete food items
  - Search và filter functions
  - Statistics và unique tags
  - Sort by expiry date

## 🛠️ Tech Stack

- **Flutter**: Framework chính
- **Shadcn Flutter**: UI components library
- **Isar**: NoSQL database (offline-first)
- **Path Provider**: File path management
- **Image Picker**: Camera và gallery integration (đã cài đặt)
- **Flutter Local Notifications**: Cảnh báo hết hạn (đã cài đặt)

## 📦 Dependencies

```yaml
dependencies:
  shadcn_flutter: ^0.0.44
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.1
  image_picker: ^1.0.7
  flutter_local_notifications: ^17.0.0

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.8
```

## 🚀 Cách chạy dự án

```bash
# Clone repo và cài đặt dependencies
flutter pub get

# Generate Isar schema
dart run build_runner build

# Chạy ứng dụng
flutter run
```

## 📱 Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point, ShadcnApp setup
├── models/
│   └── food_item.dart          # Isar model cho thực phẩm
├── services/
│   └── database_service.dart   # Database operations
└── screens/
    ├── onboarding_screen.dart  # 4-slide giới thiệu
    ├── food_list_screen.dart   # Màn hình chính
    └── add_edit_food_screen.dart # Form thêm/sửa
```

## 🔄 Tính năng tiếp theo

### 🎯 Ready to implement (Infrastructure đã sẵn sàng):

1. **Hoàn thiện Add/Edit Form**:
   - Image picker integration
   - Date picker cho expiry date
   - Tags input với autocomplete
   - Form validation

2. **Food List với Database**:
   - Load và display food items từ Isar
   - Color-coded expiry status (đỏ/vàng/xanh)
   - Search và filter by tags
   - Swipe to delete/edit

3. **Local Notifications**:
   - Background notification service
   - Schedule alerts 1-3 ngày trước hết hạn
   - Settings cho notification preferences

4. **OCR Integration**:
   - Google ML Kit text recognition
   - Auto-fill từ ảnh nhãn sản phẩm

### 🎨 UI Enhancements:
- Statistics dashboard
- Dark/light theme toggle  
- Improved animations
- Pull-to-refresh

## 🧪 Testing

App đã pass Flutter analyzer với chỉ info-level warnings (private types in public API). Không có error nào.

```bash
flutter analyze  # ✅ Passed
```

## 📋 Current Status

- ✅ Project structure & dependencies
- ✅ Shadcn UI integration
- ✅ Database schema & services  
- ✅ Navigation flow (Onboarding → Food List → Add/Edit)
- ✅ Placeholder screens với proper styling
- ⏳ Form implementation (next milestone)
- ⏳ Notifications setup (next milestone)

**Ready for feature development!** 🚀
