-- ฐานข้อมูลสำหรับระบบ Klonglens
-- Database Schema for Klonglens Rental System

CREATE DATABASE IF NOT EXISTS klonglens_db;
USE klonglens_db;

-- ตารางผู้ใช้
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    date_of_birth DATE,
    profile_image VARCHAR(500),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active'
);

-- ตารางหมวดหมู่สินค้า
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image VARCHAR(500),
    parent_id INT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- ตารางยี่ห้อ
CREATE TABLE brands (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo VARCHAR(500),
    description TEXT,
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ตารางสินค้า
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    
    -- ราคา
    purchase_price DECIMAL(10,2) NOT NULL COMMENT 'ราคาซื้อ',
    daily_rate DECIMAL(10,2) NOT NULL COMMENT 'ค่าเช่าต่อวัน',
    weekly_rate DECIMAL(10,2) COMMENT 'ค่าเช่าต่อสัปดาห์',
    monthly_rate DECIMAL(10,2) COMMENT 'ค่าเช่าต่อเดือน',
    
    -- คลังสินค้า
    total_stock INT NOT NULL DEFAULT 0 COMMENT 'จำนวนทั้งหมด',
    available_stock INT NOT NULL DEFAULT 0 COMMENT 'จำนวนที่ให้เช่าได้',
    reserved_stock INT NOT NULL DEFAULT 0 COMMENT 'จำนวนที่จองไว้',
    
    -- ข้อมูลสเปค
    specifications JSON COMMENT 'ข้อมูลสเปคเป็น JSON',
    features JSON COMMENT 'ฟีเจอร์ต่างๆ เป็น JSON Array',
    
    -- รูปภาพ
    featured_image VARCHAR(500),
    gallery_images JSON COMMENT 'รูปภาพเพิ่มเติม',
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    
    -- สถานะ
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    weight DECIMAL(8,2) COMMENT 'น้ำหนัก (กก.)',
    dimensions VARCHAR(100) COMMENT 'ขนาด (กว้าง x ยาว x สูง)',
    
    -- การให้คะแนน
    rating_average DECIMAL(3,2) DEFAULT 0,
    rating_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (brand_id) REFERENCES brands(id),
    INDEX idx_category (category_id),
    INDEX idx_brand (brand_id),
    INDEX idx_active (is_active),
    INDEX idx_featured (is_featured)
);

-- ตารางการจอง
CREATE TABLE bookings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_number VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    
    -- วันที่
    rental_start_date DATE NOT NULL,
    rental_end_date DATE NOT NULL,
    pickup_date DATETIME,
    return_date DATETIME,
    
    -- ข้อมูลการส่ง
    delivery_method ENUM('pickup', 'delivery') NOT NULL,
    delivery_address TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    
    -- ราคา
    subtotal DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    
    -- สถานะ
    status ENUM('pending', 'confirmed', 'picked_up', 'returned', 'cancelled') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'refunded', 'failed') DEFAULT 'pending',
    
    -- หมายเหตุ
    notes TEXT,
    admin_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user (user_id),
    INDEX idx_dates (rental_start_date, rental_end_date),
    INDEX idx_status (status)
);

-- ตารางรายการสินค้าในการจอง
CREATE TABLE booking_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    daily_rate DECIMAL(10,2) NOT NULL,
    total_days INT NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    
    -- สถานะสินค้า
    condition_before TEXT COMMENT 'สภาพก่อนเช่า',
    condition_after TEXT COMMENT 'สภาพหลังคืน',
    damage_notes TEXT COMMENT 'หมายเหตุความเสียหาย',
    damage_fee DECIMAL(10,2) DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    INDEX idx_booking (booking_id),
    INDEX idx_product (product_id)
);

-- ตารางการชำระเงิน
CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    payment_method ENUM('credit_card', 'bank_transfer', 'promptpay', 'cash') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    transaction_id VARCHAR(255),
    gateway_response JSON,
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    INDEX idx_booking (booking_id),
    INDEX idx_status (status)
);

-- ตารางรีวิวและการให้คะแนน
CREATE TABLE reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    booking_id INT NULL COMMENT 'เชื่อมกับการจองที่เกิดขึ้นจริง',
    
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    review_text TEXT,
    
    -- รูปภาพรีวิว
    images JSON,
    
    -- ข้อมูลผู้ใช้ที่เป็นประโยชน์
    is_helpful_count INT DEFAULT 0,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    admin_response TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    
    INDEX idx_product (product_id),
    INDEX idx_user (user_id),
    INDEX idx_rating (rating),
    INDEX idx_status (status)
);

-- ตารางความช่วยเหลือของรีวิว
CREATE TABLE review_helpfulness (
    id INT PRIMARY KEY AUTO_INCREMENT,
    review_id INT NOT NULL,
    user_id INT NOT NULL,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY unique_user_review (review_id, user_id)
);

-- ตารางตะกร้าสินค้า (Shopping Cart)
CREATE TABLE cart_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    rental_start_date DATE,
    rental_end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id)
);

-- ตารางคูปองส่วนลด
CREATE TABLE coupons (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- ประเภทส่วนลด
    discount_type ENUM('fixed', 'percentage') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_amount DECIMAL(10,2) DEFAULT 0,
    maximum_discount DECIMAL(10,2) NULL,
    
    -- การใช้งาน
    usage_limit INT NULL COMMENT 'จำนวนครั้งที่ใช้ได้ทั้งหมด',
    usage_count INT DEFAULT 0 COMMENT 'จำนวนครั้งที่ใช้ไปแล้ว',
    per_user_limit INT DEFAULT 1 COMMENT 'จำนวนครั้งที่ผู้ใช้หนึ่งคนใช้ได้',
    
    -- วันที่
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_code (code),
    INDEX idx_dates (valid_from, valid_until),
    INDEX idx_active (is_active)
);

-- ตารางการใช้คูปอง
CREATE TABLE coupon_usage (
    id INT PRIMARY KEY AUTO_INCREMENT,
    coupon_id INT NOT NULL,
    user_id INT NOT NULL,
    booking_id INT NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (coupon_id) REFERENCES coupons(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    INDEX idx_coupon (coupon_id),
    INDEX idx_user (user_id)
);

-- ตารางการตั้งค่าระบบ
CREATE TABLE system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ตารางล็อกการดำเนินการ
CREATE TABLE activity_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    data JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_created (created_at)
);

-- ข้อมูลเริ่มต้น

-- เพิ่มหมวดหมู่
INSERT INTO categories (name, slug, description) VALUES
('กล้อง', 'cameras', 'กล้องทุกประเภท'),
('เลนส์', 'lenses', 'เลนส์สำหรับกล้อง'),
('อุปกรณ์เสริม', 'accessories', 'อุปกรณ์เสริมสำหรับการถ่ายภาพ');

-- เพิ่มยี่ห้อ
INSERT INTO brands (name, slug, description) VALUES
('Canon', 'canon', 'Canon Inc. ผู้ผลิตอุปกรณ์ถ่ายภาพชั้นนำ'),
('Nikon', 'nikon', 'Nikon Corporation ผู้ผลิตกล้องและเลนส์คุณภาพสูง'),
('Sony', 'sony', 'Sony Corporation เทคโนโลยีกล้องขั้นสูง'),
('Manfrotto', 'manfrotto', 'อุปกรณ์เสริมสำหรับการถ่ายภาพ'),
('RODE', 'rode', 'อุปกรณ์บันทึกเสียงคุณภาพสูง'),
('Godox', 'godox', 'อุปกรณ์แสงไฟสำหรับการถ่ายภาพ');

-- เพิ่มการตั้งค่าระบบ
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('site_name', 'Klonglens', 'ชื่อเว็บไซต์'),
('site_description', 'เช่าอุปกรณ์ถ่ายภาพคุณภาพสูง', 'คำอธิบายเว็บไซต์'),
('delivery_fee', '100', 'ค่าจัดส่ง (บาท)'),
('free_delivery_minimum', '1000', 'จำนวนเงินขั้นต่ำสำหรับจัดส่งฟรี'),
('tax_rate', '7', 'อัตราภาษี (%)'),
('late_fee_per_day', '50', 'ค่าปรับล่าช้าต่อวัน (บาท)');

-- สร้าง Trigger สำหรับอัปเดตคะแนนเฉลี่ย
DELIMITER //

CREATE TRIGGER update_product_rating_after_review_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    UPDATE products 
    SET rating_average = (
        SELECT AVG(rating) 
        FROM reviews 
        WHERE product_id = NEW.product_id AND status = 'approved'
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE product_id = NEW.product_id AND status = 'approved'
    )
    WHERE id = NEW.product_id;
END//

CREATE TRIGGER update_product_rating_after_review_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    UPDATE products 
    SET rating_average = (
        SELECT AVG(rating) 
        FROM reviews 
        WHERE product_id = NEW.product_id AND status = 'approved'
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE product_id = NEW.product_id AND status = 'approved'
    )
    WHERE id = NEW.product_id;
END//

CREATE TRIGGER update_product_rating_after_review_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    UPDATE products 
    SET rating_average = (
        SELECT COALESCE(AVG(rating), 0) 
        FROM reviews 
        WHERE product_id = OLD.product_id AND status = 'approved'
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE product_id = OLD.product_id AND status = 'approved'
    )
    WHERE id = OLD.product_id;
END//

DELIMITER ;

-- สร้าง Index เพิ่มเติมเพื่อประสิทธิภาพ
CREATE INDEX idx_products_search ON products(name, is_active);
CREATE INDEX idx_bookings_dates_status ON bookings(rental_start_date, rental_end_date, status);
CREATE INDEX idx_reviews_product_status ON reviews(product_id, status, created_at);

-- View สำหรับดูข้อมูลสินค้าพร้อมข้อมูลที่เกี่ยวข้อง
CREATE VIEW product_details AS
SELECT 
    p.id,
    p.sku,
    p.name,
    p.slug,
    p.description,
    p.daily_rate,
    p.weekly_rate,
    p.monthly_rate,
    p.available_stock,
    p.featured_image,
    p.rating_average,
    p.rating_count,
    p.is_active,
    p.is_featured,
    c.name as category_name,
    c.slug as category_slug,
    b.name as brand_name,
    b.slug as brand_slug,
    p.specifications,
    p.features
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN brands b ON p.brand_id = b.id
WHERE p.is_active = TRUE;

-- View สำหรับดูข้อมูลการจองพร้อมรายละเอียด
CREATE VIEW booking_details AS
SELECT 
    b.id,
    b.booking_number,
    b.rental_start_date,
    b.rental_end_date,
    b.status,
    b.total_amount,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    COUNT(bi.id) as item_count
FROM bookings b
JOIN users u ON b.user_id = u.id
LEFT JOIN booking_items bi ON b.id = bi.booking_id
GROUP BY b.id;

COMMIT;