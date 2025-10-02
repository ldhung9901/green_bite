class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String cookingTime;
  final String difficulty;
  final String category;
  final String? imagePath;
  final List<String> tags;

  Recipe({required this.id, required this.name, required this.description, required this.ingredients, required this.instructions, required this.cookingTime, required this.difficulty, required this.category, this.imagePath, this.tags = const []});

  static List<Recipe> getDemoRecipes() {
    return [
      Recipe(id: '1', name: 'Gỏi cuốn tôm thịt', description: 'Món ăn nhẹ truyền thống Việt Nam với tôm tươi và thịt ba chỉ', ingredients: ['200g tôm sú', '150g thịt ba chỉ', '1 gói bánh tráng', 'Rau xà lách', 'Bún tươi', 'Rau thơm (húng quế, ngò)', 'Nước mắm', 'Đường', 'Chanh', 'Ớt'], instructions: ['Luộc tôm và thịt ba chỉ cho chín', 'Thái tôm đôi, thái thịt lát mỏng', 'Rửa sạch rau củ, để ráo nước', 'Trần bánh tráng qua nước ấm cho mềm', 'Đặt rau, bún, tôm, thịt lên bánh tráng rồi cuốn lại', 'Pha nước chấm từ nước mắm, đường, chanh, ớt', 'Thưởng thức với nước chấm'], cookingTime: '30 phút', difficulty: 'Dễ', category: 'Món khai vị', tags: ['Tôm', 'Thịt', 'Rau củ', 'Món cuốn']),
      Recipe(id: '2', name: 'Canh chua cá lóc', description: 'Món canh chua đậm đà hương vị miền Nam với cá lóc tươi', ingredients: ['500g cá lóc', '2 quả cà chua', '100g giá đỗ', '100g bạc hà', '50g me chua', '2 quả khế', 'Hành tím', 'Tỏi', 'Ớt', 'Ngò gai', 'Bột ngọt', 'Muối'], instructions: ['Rửa sạch cá, cắt khúc vừa ăn', 'Cà chua thái múi cau, khế thái lát', 'Phi thơm hành tím, tỏi', 'Cho me chua vào nấu lấy nước', 'Thêm cà chua, khế vào nấu', 'Cho cá vào nấu khoảng 10 phút', 'Nêm nếm vừa ăn, thêm giá đỗ và bạc hà', 'Rắc ngò gai lên trên'], cookingTime: '45 phút', difficulty: 'Trung bình', category: 'Canh/Súp', tags: ['Cá', 'Canh chua', 'Rau củ', 'Miền Nam']),
      Recipe(id: '3', name: 'Thịt kho tàu', description: 'Món thịt kho đậm đà với trứng cút, ăn với cơm trắng rất ngon', ingredients: ['500g thịt ba chỉ', '10 quả trứng cút', '2 tbsp nước mắm', '3 tbsp đường phèn', '1 can nước dừa', 'Hành tím', 'Tỏi', 'Ớt khô', 'Ngũ vị hương', 'Tiêu đen'], instructions: ['Thịt cắt miếng vừa ăn, ướp gia vị', 'Luộc trứng cút, bóc vỏ', 'Làm nước màu từ đường phèn', 'Phi thơm hành tím, tỏi', 'Cho thịt vào xào săn', 'Thêm nước dừa, nước màu', 'Niêu nhỏ lửa kho 1 tiếng', 'Cho trứng cút vào kho thêm 15 phút'], cookingTime: '90 phút', difficulty: 'Trung bình', category: 'Món chính', tags: ['Thịt', 'Trứng', 'Kho', 'Đậm đà']),
      Recipe(id: '4', name: 'Salad rau củ', description: 'Món salad tươi mát, giàu vitamin cho bữa ăn nhẹ', ingredients: ['1 quả dưa leo', '2 quả cà chua', '1 củ cà rốt', 'Rau xà lách', 'Hành tây', 'Dầu olive', 'Giấm balsamic', 'Muối', 'Tiêu', 'Mật ong'], instructions: ['Rửa sạch tất cả rau củ', 'Thái dưa leo, cà chua thành lát', 'Bào sợi cà rốt', 'Thái hành tây lát mỏng', 'Trộn tất cả rau củ trong tô lớn', 'Pha sốt từ dầu olive, giấm, mật ong', 'Rưới sốt lên salad và trộn đều', 'Để lạnh trước khi ăn'], cookingTime: '15 phút', difficulty: 'Dễ', category: 'Salad', tags: ['Rau củ', 'Healthy', 'Tươi mát', 'Ăn kiêng']),
      Recipe(id: '5', name: 'Bánh mì thịt nướng', description: 'Bánh mì Việt Nam với thịt nướng thơm lừng', ingredients: ['300g thịt vai heo', '4 ổ bánh mì', 'Pate', 'Rau cải', 'Dưa leo', 'Hành tây', 'Ngò rí', 'Tương ớt', 'Tương đen', 'Đường', 'Nước mắm'], instructions: ['Thái thịt thành miếng mỏng, ướp gia vị', 'Nướng thịt trên chảo đến chín vàng', 'Cắt dọc bánh mì, phết pate', 'Thái dưa leo, hành tây lát mỏng', 'Nhồi thịt nướng vào bánh mì', 'Thêm rau cải, dưa leo, hành tây', 'Rưới tương ớt theo khẩu vị', 'Rắc ngò rí lên trên'], cookingTime: '40 phút', difficulty: 'Trung bình', category: 'Bánh mì', tags: ['Thịt nướng', 'Bánh mì', 'Đường phố', 'Nhanh gọn']),
      Recipe(id: '6', name: 'Sinh tố xoài', description: 'Thức uống mát lạnh từ xoài chín ngọt tự nhiên', ingredients: ['2 quả xoài chín', '200ml sữa tươi', '2 tbsp đường', '1 cup đá viên', 'Lá bạc hà (trang trí)'], instructions: ['Gọt vỏ xoài, cắt miếng', 'Cho xoài vào máy xay sinh tố', 'Thêm sữa tươi và đường', 'Cho đá viên vào xay nhuyễn', 'Đổ ra ly, trang trí lá bạc hà', 'Thưởng thức ngay'], cookingTime: '10 phút', difficulty: 'Dễ', category: 'Đồ uống', tags: ['Xoài', 'Sinh tố', 'Mát lạnh', 'Tráng miệng']),
    ];
  }
}
