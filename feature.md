Ok, mình sẽ viết cho bạn một **tài liệu mô tả chi tiết tính năng (Feature Specification)** cho app Flutter này.

---

# 📘 Tài liệu mô tả tính năng – Ứng dụng Quản lý Thực phẩm (Food Reminder)

## 🎯 Mục tiêu

Ứng dụng giúp người dùng quản lý thực phẩm/đồ ăn trong gia đình, lưu lại thông tin hạn sử dụng, nhận nhắc nhở khi gần hết hạn, và hỗ trợ nhập liệu nhanh bằng OCR.

---

## 🖥️ Các màn hình

### 1. **Onboarding**

* Giới thiệu ngắn gọn về ứng dụng (chức năng chính: quản lý thực phẩm, nhắc nhở, OCR).
* Hiển thị hình minh họa, slide hướng dẫn (3–4 trang).
* Nút “Bắt đầu sử dụng” → chuyển sang màn hình nhập/danh sách.

---

### 2. **Nhập thực phẩm (Add/Edit Item)**

* **Trường thông tin cần nhập:**

  * Ảnh thực phẩm (chụp bằng camera hoặc chọn từ thư viện).
  * Tên thực phẩm (bắt buộc).
  * Ngày hết hạn (date picker).
  * Mô tả ngắn (tùy chọn).
  * Tags (danh mục, ví dụ: “Rau”, “Thịt”, “Đồ uống”, cho phép người dùng tự thêm tag mới).
* **Chức năng OCR:**

  * Chụp ảnh nhãn sản phẩm, hóa đơn.
  * Ứng dụng tự nhận diện chữ (tên sản phẩm, ngày hết hạn) và gợi ý điền sẵn.
* **CRUD:**

  * Thêm mới.
  * Chỉnh sửa.
  * Xóa.

---

### 3. **Danh sách thực phẩm (Expiry List)**

* Hiển thị toàn bộ thực phẩm trong cơ sở dữ liệu (Isar).
* Danh sách được sắp xếp mặc định theo ngày hết hạn (từ gần nhất → xa nhất).
* **Phân loại trực quan:**

  * **Hết hạn** (highlight đỏ).
  * **Sắp hết hạn (≤3 ngày)** (highlight vàng).
  * **Còn hạn lâu** (bình thường).
* **Tìm kiếm:** theo tên thực phẩm.
* **Lọc theo Tags:** chỉ hiển thị các item thuộc 1 nhóm (VD: chỉ xem “Rau” hoặc “Đồ uống”).
* **Chỉnh sửa/Xóa:** thao tác trực tiếp từ danh sách.

---

## 🔔 Tính năng bổ sung

* **Thông báo nhắc nhở:**

  * Gửi thông báo push/local trước 1–3 ngày khi thực phẩm sắp hết hạn.
  * Gửi ngay khi thực phẩm đã hết hạn.
* **Tùy chỉnh người dùng:** cho phép chọn khoảng thời gian muốn được nhắc nhở (1 ngày, 3 ngày, 5 ngày).
* **Thống kê đơn giản:** (nếu có thời gian) hiển thị số lượng thực phẩm đã hết hạn, sắp hết hạn.

---

## 🗄️ Dữ liệu lưu trữ

* Lưu toàn bộ dữ liệu trong **Isar Database** (offline-first, không cần internet).
* Các trường dữ liệu chính:

  * `id`
  * `name`
  * `description`
  * `imagePath`
  * `expiryDate`
  * `tags`
  * `createdAt`

---

## 📑 Quy trình sử dụng mẫu

1. Người dùng mở app lần đầu → xem Onboarding → Bắt đầu.
2. Người dùng thêm thực phẩm mới bằng cách nhập tay hoặc dùng OCR.
3. Danh sách hiển thị thực phẩm với ngày hết hạn rõ ràng.
4. Khi gần đến ngày hết hạn, app gửi thông báo nhắc nhở.
5. Người dùng có thể tìm kiếm, lọc theo tag, chỉnh sửa hoặc xóa.

---

## 🚀 Hướng mở rộng

* Đồng bộ dữ liệu nhiều thiết bị (Isar Sync hoặc custom sync).
* Xuất danh sách ra file Excel/CSV.
* Chia sẻ danh sách cho người khác (gia đình, bạn cùng nhà).
* Gợi ý công thức nấu ăn từ thực phẩm sắp hết hạn.

---

Bạn có muốn mình viết thêm **User Flow Diagram** (sơ đồ luồng người dùng) để hình dung rõ hành trình sử dụng app không?
