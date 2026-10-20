SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS listings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  type ENUM('Nhà','Đất','Căn hộ') NOT NULL,
  city VARCHAR(100) NOT NULL,
  address VARCHAR(255) NOT NULL,
  price DECIMAL(15,0) NOT NULL,
  area DECIMAL(8,2) NOT NULL,
  description TEXT,
  owner_name VARCHAR(100) NOT NULL,
  owner_phone VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contacts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO listings (title,type,city,address,price,area,description,owner_name,owner_phone) VALUES
('Nhà phố 3 tầng gần trung tâm','Nhà','Thái Nguyên','Phan Đình Phùng, TP Thái Nguyên',3500000000,80,'Nhà mới xây, sổ đỏ chính chủ, gần chợ và trường học.','Nguyễn Văn A','0901000001'),
('Đất nền mặt đường 5m','Đất','Thái Nguyên','Xã Quyết Thắng, TP Thái Nguyên',1200000000,100,'Đất thổ cư 100%, đường ô tô tránh nhau.','Trần Thị B','0901000002'),
('Căn hộ 2 phòng ngủ full nội thất','Căn hộ','Hà Nội','Cầu Giấy, Hà Nội',2800000000,65,'Tầng 12, view thoáng, đầy đủ tiện ích.','Lê Văn C','0901000003'),
('Nhà cấp 4 sân vườn','Nhà','Hà Nội','Đông Anh, Hà Nội',2100000000,120,'Sân vườn rộng, phù hợp nghỉ dưỡng.','Phạm Thị D','0901000004'),
('Đất vườn view hồ','Đất','Đà Nẵng','Hòa Vang, Đà Nẵng',1800000000,300,'View hồ, không khí trong lành.','Hoàng Văn E','0901000005'),
('Căn hộ studio trung tâm','Căn hộ','TP.HCM','Quận 1, TP.HCM',2500000000,40,'Gần các tiện ích, cho thuê tốt.','Vũ Thị F','0901000006');
