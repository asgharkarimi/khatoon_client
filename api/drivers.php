<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'drivers';

// Password Hashing Options
$options = [
    'cost' => 12, // Adjust cost factor as needed for security/performance balance
];

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    // Allow specific HTML tags if needed for some fields, otherwise strip all
    return mysqli_real_escape_string($conn, strip_tags($data)); // Stricter: remove all HTML
}
// Special sanitizer for password (no htmlspecialchars)
function sanitizePassword($data) {
     if ($data === null) return null;
     return trim($data); // Just trim whitespace
}

// --- Request Handling ---

switch ($method) {
    case 'GET':
        handleGet($conn, $table);
        break;
    case 'POST':
        handlePost($conn, $table, $options);
        break;
    case 'PUT':
        handlePut($conn, $table, $options);
        break;
    case 'DELETE':
        handleDelete($conn, $table);
        break;
    default:
        http_response_code(405);
        echo json_encode(["message" => "Method Not Allowed"]);
        break;
}

closeDbConnection($conn);

// --- Function Definitions ---

// READ (GET)
function handleGet($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;

    // Decide which columns to select (exclude password_hash by default)
    $columns = "id, first_name, last_name, phone_number, salary_percentage, bank_account_id, national_id, national_id_card_image, driver_license_image, driver_smart_card_image";

    if ($id) {
        $sql = "SELECT $columns FROM $table WHERE id = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($data = $result->fetch_assoc()) {
                // Optionally join bank account details
                if ($data['bank_account_id']) {
                   $bankSql = "SELECT bank_name, account_holder_name, card_number, iban FROM bank_accounts WHERE id = ?";
                   $bankStmt = $conn->prepare($bankSql);
                   $bankStmt->bind_param("i", $data['bank_account_id']);
                   if($bankStmt->execute()){
                       $bankResult = $bankStmt->get_result();
                       $data['bank_account_details'] = $bankResult->fetch_assoc() ?: null;
                   } else {
                        error_log("Error fetching bank details for driver $id: " . $bankStmt->error);
                        $data['bank_account_details'] = null;
                   }
                   $bankStmt->close();
                } else {
                    $data['bank_account_details'] = null;
                }
                http_response_code(200);
                echo json_encode($data);
            } else {
                http_response_code(404);
                echo json_encode(["message" => "Driver not found."]);
            }
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error executing statement: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        // Get all records (consider pagination for large datasets)
        $sql = "SELECT $columns FROM $table ORDER BY last_name ASC, first_name ASC";
        $result = $conn->query($sql);
        if ($result) {
            $allData = $result->fetch_all(MYSQLI_ASSOC);
             // Optionally enrich with bank details here too if needed, but can be slow for many drivers
            http_response_code(200);
            echo json_encode($allData);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error retrieving drivers: " . $conn->error]);
        }
    }
}

// CREATE (POST)
function handlePost($conn, $table, $options) {
    $data = json_decode(file_get_contents('php://input'), true);

    // Required fields validation
    $required = ['first_name', 'last_name', 'password']; // Add others if needed (e.g., phone?)
    foreach ($required as $field) {
        if (empty($data[$field])) {
            http_response_code(400);
            echo json_encode(["message" => "Missing required field: " . $field]);
            return;
        }
    }

    // Sanitize inputs
    $first_name = sanitize($conn, $data['first_name']);
    $last_name = sanitize($conn, $data['last_name']);
    $phone_number = isset($data['phone_number']) ? sanitize($conn, $data['phone_number']) : null;
    $password_plain = sanitizePassword($data['password']); // Sanitize password differently
    $salary_percentage = isset($data['salary_percentage']) ? filter_var($data['salary_percentage'], FILTER_VALIDATE_FLOAT) : null;
    $bank_account_id = isset($data['bank_account_id']) ? filter_var($data['bank_account_id'], FILTER_VALIDATE_INT) : null;
    $national_id = isset($data['national_id']) ? sanitize($conn, $data['national_id']) : null;
    $national_id_card_image = isset($data['national_id_card_image']) ? sanitize($conn, $data['national_id_card_image']) : null; // Assuming path/URL
    $driver_license_image = isset($data['driver_license_image']) ? sanitize($conn, $data['driver_license_image']) : null;
    $driver_smart_card_image = isset($data['driver_smart_card_image']) ? sanitize($conn, $data['driver_smart_card_image']) : null;

     // Validate foreign keys if provided
    if ($bank_account_id && !checkForeignKeyExists($conn, 'bank_accounts', $bank_account_id)) {
         http_response_code(400);
         echo json_encode(["message" => "Invalid bank_account_id: Account does not exist."]);
         return;
    }

    // Hash the password
    $password_hash = password_hash($password_plain, PASSWORD_BCRYPT, $options);
    if ($password_hash === false) {
         http_response_code(500);
         echo json_encode(["message" => "Error hashing password."]);
         return;
    }

    $sql = "INSERT INTO $table (first_name, last_name, phone_number, password_hash, salary_percentage, bank_account_id, national_id, national_id_card_image, driver_license_image, driver_smart_card_image)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Define types: s=string, d=double, i=integer
    $types = "ssssdissss";
    $stmt->bind_param($types,
        $first_name,
        $last_name,
        $phone_number,
        $password_hash,
        $salary_percentage,
        $bank_account_id,
        $national_id,
        $national_id_card_image,
        $driver_license_image,
        $driver_smart_card_image
    );

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Driver created successfully.", "id" => $newId]);
    } else {
        if ($conn->errno == 1062) { // Duplicate entry
             $error_message = "Duplicate entry.";
             if (strpos($stmt->error, 'phone_number') !== false) $error_message = "Duplicate phone number.";
             if (strpos($stmt->error, 'national_id') !== false) $error_message = "Duplicate national ID.";
             http_response_code(409);
             echo json_encode(["message" => $error_message]);
        } else {
             http_response_code(500);
             echo json_encode(["message" => "Error creating driver: " . $stmt->error]);
        }
    }
    $stmt->close();
}

// UPDATE (PUT)
function handlePut($conn, $table, $options) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(["message" => "Missing ID for update."]);
        return;
    }

    $data = json_decode(file_get_contents('php://input'), true);
    if (empty($data)) {
         http_response_code(400);
         echo json_encode(["message" => "No data provided for update."]);
         return;
    }

    $setClauses = [];
    $params = [];
    $types = "";

    // Sanitize and add fields to update
     if (isset($data['first_name'])) { $setClauses[] = "first_name = ?"; $params[] = sanitize($conn, $data['first_name']); $types .= "s"; }
     if (isset($data['last_name'])) { $setClauses[] = "last_name = ?"; $params[] = sanitize($conn, $data['last_name']); $types .= "s"; }
     if (array_key_exists('phone_number', $data)) { $setClauses[] = "phone_number = ?"; $params[] = sanitize($conn, $data['phone_number']); $types .= "s"; } // Allow null
     if (isset($data['password'])) {
         $password_plain = sanitizePassword($data['password']);
         $password_hash = password_hash($password_plain, PASSWORD_BCRYPT, $options);
         if($password_hash === false){ http_response_code(500); echo json_encode(["message" => "Error hashing password for update."]); return;}
         $setClauses[] = "password_hash = ?"; $params[] = $password_hash; $types .= "s";
     }
     if (array_key_exists('salary_percentage', $data)) { $setClauses[] = "salary_percentage = ?"; $params[] = filter_var($data['salary_percentage'], FILTER_VALIDATE_FLOAT, FILTER_NULL_ON_FAILURE); $types .= "d"; }
     if (array_key_exists('bank_account_id', $data)) {
        $bank_id = filter_var($data['bank_account_id'], FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
         if ($bank_id !== null && $bank_id !== false && !checkForeignKeyExists($conn, 'bank_accounts', $bank_id)) {
             http_response_code(400); echo json_encode(["message" => "Invalid bank_account_id: Account does not exist."]); return;
         }
         $setClauses[] = "bank_account_id = ?"; $params[] = $bank_id; $types .= "i";
     }
     if (array_key_exists('national_id', $data)) { $setClauses[] = "national_id = ?"; $params[] = sanitize($conn, $data['national_id']); $types .= "s"; }
     if (array_key_exists('national_id_card_image', $data)) { $setClauses[] = "national_id_card_image = ?"; $params[] = sanitize($conn, $data['national_id_card_image']); $types .= "s"; }
     if (array_key_exists('driver_license_image', $data)) { $setClauses[] = "driver_license_image = ?"; $params[] = sanitize($conn, $data['driver_license_image']); $types .= "s"; }
     if (array_key_exists('driver_smart_card_image', $data)) { $setClauses[] = "driver_smart_card_image = ?"; $params[] = sanitize($conn, $data['driver_smart_card_image']); $types .= "s"; }


    if (empty($setClauses)) {
         http_response_code(400);
         echo json_encode(["message" => "No valid fields provided for update."]);
         return;
    }

    $sql = "UPDATE $table SET " . implode(", ", $setClauses) . " WHERE id = ?";
    $types .= "i"; // Add type for the ID
    $params[] = $id; // Add the ID itself

    $stmt = $conn->prepare($sql);
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Driver updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404);
                  echo json_encode(["message" => "Driver not found for update."]);
             } else {
                  http_response_code(200);
                  echo json_encode(["message" => "Driver found, but no changes were made."]);
             }
             $checkStmt->close();
        }
    } else {
         if ($conn->errno == 1062) {
              $error_message = "Update failed due to duplicate entry.";
              if (strpos($stmt->error, 'phone_number') !== false) $error_message = "Duplicate phone number.";
              if (strpos($stmt->error, 'national_id') !== false) $error_message = "Duplicate national ID.";
             http_response_code(409);
             echo json_encode(["message" => $error_message]);
         } else {
            http_response_code(500);
            echo json_encode(["message" => "Error updating driver: " . $stmt->error]);
         }
    }
    $stmt->close();
}

// DELETE
function handleDelete($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(["message" => "Missing ID for delete."]);
        return;
    }

    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Driver deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Driver not found for delete."]);
        }
    } else {
         if ($conn->errno == 1451) { // Foreign key constraint fails
             http_response_code(409);
             echo json_encode(["message" => "Cannot delete driver because they are referenced by other data (e.g., in cargos table)."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting driver: " . $stmt->error]);
        }
    }
    $stmt->close();
}

// Helper function to check if a foreign key exists
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
    if ($foreignId === null || $foreignId === false) return true; // Allow NULL or invalid filter values (which result in false)
    $checkSql = "SELECT id FROM $foreignTable WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
     if (!$checkStmt) {
        error_log("Error preparing foreign key check statement: " . $conn->error);
        return false; // Assume invalid on error
     }
    $checkStmt->bind_param("i", $foreignId);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    $exists = $checkResult->num_rows > 0;
    $checkStmt->close();
    return $exists;
}

?> 