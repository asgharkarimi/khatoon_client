-- Table for Vehicles (ماشین)
CREATE TABLE vehicles (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    smart_card_number VARCHAR(100) UNIQUE,
    health_code VARCHAR(100)
);

-- Table for Cargo Types (نوع بار)
CREATE TABLE cargo_types (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Table for Customers (مشتری)
CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) UNIQUE
);

-- Table for Shipping Companies (شرکت باربری)
CREATE TABLE shipping_companies (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20)
);

-- Table for Bank Accounts (اطلاعات بانکی)
CREATE TABLE bank_accounts (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    bank_name VARCHAR(100) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    card_number VARCHAR(20) UNIQUE,
    iban VARCHAR(34) UNIQUE -- International Bank Account Number
);

-- Table for Payment Types (نوع پرداخت)
CREATE TABLE payment_types (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE -- e.g., 'Not Received', 'Cash', 'Check', 'Card Transfer', 'Bank Deposit'
);

-- Table for Drivers (راننده)
CREATE TABLE drivers (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- Store hashed password
    salary_percentage DECIMAL(5, 2), -- e.g., 10.50%
    bank_account_id INTEGER,
    national_id VARCHAR(20) UNIQUE,
    national_id_card_image VARCHAR(512), -- Path or URL to image
    driver_license_image VARCHAR(512), -- Path or URL to image
    driver_smart_card_image VARCHAR(512), -- Path or URL to image
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
);

-- Table for Cargo Selling Companies (شرکت فروشنده بار)
CREATE TABLE cargo_selling_companies (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20)
);

-- Table for Expense Categories (دسته بندی هزینه ها)
CREATE TABLE expense_categories (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Table for Cargos (بار)
CREATE TABLE cargos (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    cargo_type_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    shipping_company_id INTEGER NOT NULL,
    selling_company_id INTEGER NOT NULL,
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    loading_date TIMESTAMP NULL DEFAULT NULL,
    unloading_date TIMESTAMP NULL DEFAULT NULL,
    weight_tonnes DECIMAL(10, 3) NOT NULL,
    price_per_tonne DECIMAL(12, 2) NOT NULL,
    transport_cost_per_tonne DECIMAL(12, 2) NOT NULL,
    customer_payment_status_id INTEGER NOT NULL, -- Default should correspond to 'Not Received'
    seller_payment_status BOOLEAN DEFAULT FALSE, -- Paid to selling company status
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (cargo_type_id) REFERENCES cargo_types(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (shipping_company_id) REFERENCES shipping_companies(id),
    FOREIGN KEY (selling_company_id) REFERENCES cargo_selling_companies(id),
    FOREIGN KEY (customer_payment_status_id) REFERENCES payment_types(id)
    -- Note: Ensure the default value for customer_payment_status_id is set correctly,
    -- potentially via application logic or by querying the ID for 'Not Received' after inserting payment types.
);

-- Table for Payments (پرداخت ها - to selling companies)
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    cargo_id INTEGER NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    company_id INTEGER NOT NULL, -- Refers to cargo_selling_companies
    bank_account_id INTEGER, -- Account payment made from/to
    receipt_image VARCHAR(512), -- Path or URL to image
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cargo_id) REFERENCES cargos(id),
    FOREIGN KEY (company_id) REFERENCES cargo_selling_companies(id),
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
);

-- Table for Receivables (دریافتی ها - from customers)
CREATE TABLE receivables (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    cargo_id INTEGER NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    customer_id INTEGER NOT NULL,
    bank_account_id INTEGER, -- Account payment received into
    receipt_image VARCHAR(512), -- Path or URL to image
    received_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cargo_id) REFERENCES cargos(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
);

-- Table for Payment Management (مدیریت پرداختی ها - Detailed tracking)
CREATE TABLE payment_management (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    cargo_id INTEGER NOT NULL,
    payment_type_id INTEGER NOT NULL,
    payer_details TEXT, -- Details about who paid (e.g., 'System', 'Driver ID: 5')
    amount DECIMAL(12, 2) NOT NULL,
    card_transfer_receipt_image VARCHAR(512), -- Path or URL
    check_image VARCHAR(512), -- Path or URL
    check_due_date DATE,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cargo_id) REFERENCES cargos(id),
    FOREIGN KEY (payment_type_id) REFERENCES payment_types(id)
);

-- Table for Expenses (هزینه ها)
CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    cargo_id INTEGER NOT NULL,
    expense_category_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    receipt_image VARCHAR(512), -- Path or URL to image
    description TEXT, -- For details like bill of lading, tolls, fuel, tips, disinfection etc.
    expense_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cargo_id) REFERENCES cargos(id),
    FOREIGN KEY (expense_category_id) REFERENCES expense_categories(id)
);

-- Example: Insert default payment types
-- INSERT INTO payment_types (name) VALUES ('Not Received'), ('Cash'), ('Check'), ('Card Transfer'), ('Bank Deposit'); 