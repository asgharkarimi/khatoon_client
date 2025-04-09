<?php
// Only set headers if running in a web server context
if (php_sapi_name() !== 'cli') {
    header("Content-Type: application/json; charset=UTF-8");
    header("Access-Control-Allow-Origin: *"); // Allow requests from any origin (adjust for production)
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

    // Handle preflight OPTIONS request
    if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
        exit(0);
    }
}

// --- IMPORTANT: Replace with your actual database credentials ---
$servername = "localhost"; // or your db host
$username = "root";        // your db username
$password = "";            // your db password
$dbname = "khatoonbar_db"; // your database name
// -------------------------------------------------------------

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    if (php_sapi_name() === 'cli') {
        echo "Database connection failed: " . $conn->connect_error . "\n";
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Database connection failed: " . $conn->connect_error]);
    }
    exit();
}

// Create database if it doesn't exist
$sql = "CREATE DATABASE IF NOT EXISTS $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
if (!$conn->query($sql)) {
    if (php_sapi_name() === 'cli') {
        echo "Error creating database: " . $conn->error . "\n";
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error creating database: " . $conn->error]);
    }
    $conn->close();
    exit();
}

// Select the database
$conn->select_db($dbname);

// Set charset to UTF8
if (!$conn->set_charset("utf8mb4")) {
    if (php_sapi_name() === 'cli') {
        echo "Error setting character set: " . $conn->error . "\n";
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error setting character set: " . $conn->error]);
    }
    $conn->close();
    exit();
}

// Optional: Function to close connection (can be called at the end of scripts)
function closeDbConnection($connection) {
    $connection->close();
}

// Optional: Run schema if tables don't exist (Basic Check)
function initializeDatabase($connection, $schemaFile) {
    $tablesToCheck = [
        'vehicles', 'cargo_types', 'customers', 'shipping_companies', 'bank_accounts',
        'payment_types', 'drivers', 'cargo_selling_companies', 'expense_categories',
        'cargos', 'payments', 'receivables', 'payment_management', 'expenses'
    ];
    $firstTable = $tablesToCheck[0];
    $checkTableSql = "SHOW TABLES LIKE '$firstTable'";
    $result = $connection->query($checkTableSql);

    if ($result && $result->num_rows == 0) {
        // Tables likely don't exist, try to run schema
        $schemaSql = file_get_contents($schemaFile);
        if ($schemaSql === false) {
            error_log("Failed to read schema file: " . $schemaFile);
            return false; // Indicate failure
        }
        // Execute multi-query requires careful handling
        if ($connection->multi_query($schemaSql)) {
            do {
                // Store first result set generated by query
                if ($result = $connection->store_result()) {
                    $result->free();
                }
                // If more results exists and connection is alive
            } while ($connection->more_results() && $connection->next_result());
            error_log("Database schema initialized successfully from: " . $schemaFile);
            return true; // Indicate success
        } else {
            error_log("Error initializing database schema: " . $connection->error);
            return false; // Indicate failure
        }
    } elseif (!$result) {
        error_log("Error checking for tables: " . $connection->error);
        return false; // Indicate failure
    }
    // Tables likely exist or check failed but not necessarily an initialization error
    return true;
}

// Attempt to initialize DB - Call this only once needed, perhaps in a setup script
// or cautiously here. Be careful with multi_query.
// initializeDatabase($conn, __DIR__ . '/schema.sql');

?> 