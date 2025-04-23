<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'driver_payments';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
}

// Check if a foreign key exists
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
    if ($foreignId === null || $foreignId === false || $foreignId <= 0) return false;
    $checkSql = "SELECT id FROM `$foreignTable` WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
    if (!$checkStmt) {
        error_log("Error preparing foreign key check statement for $foreignTable: " . $conn->error);
        return false;
    }
    $checkStmt->bind_param("i", $foreignId);
    if (!$checkStmt->execute()) {
        error_log("Error executing foreign key check statement for $foreignTable: " . $checkStmt->error);
        $checkStmt->close();
        return false;
    }
    $checkResult = $checkStmt->get_result();
    $exists = $checkResult->num_rows > 0;
    $checkStmt->close();
    return $exists;
}

// Request Handling
switch ($method) {
    case 'GET':
        handleGet($conn, $table);
        break;
    case 'POST':
        handlePost($conn, $table);
        break;
    case 'PUT':
        handlePut($conn, $table);
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

// Get driver salary payments
function handleGet($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    $cargo_id = isset($_GET['cargo_id']) ? intval($_GET['cargo_id']) : null;
    $driver_id = isset($_GET['driver_id']) ? intval($_GET['driver_id']) : null;

    $baseColumns = "dp.id, dp.cargo_id, dp.driver_id, dp.amount, dp.payment_date, dp.receipt_image, dp.bank_account_id, dp.notes";
    $joins = "
        LEFT JOIN cargos c ON dp.cargo_id = c.id
        LEFT JOIN drivers d ON dp.driver_id = d.id
        LEFT JOIN bank_accounts ba ON dp.bank_account_id = ba.id
    ";
    $joinedColumns = ", c.origin, c.destination, c.loading_date, c.weight_tonnes, 
                     CONCAT(d.first_name, ' ', d.last_name) as driver_name, d.phone_number as driver_phone,
                     CONCAT(ba.bank_name, ' - ', ba.account_holder_name) as bank_account_name";

    $sql = "SELECT $baseColumns $joinedColumns FROM $table dp $joins";
    $whereClauses = [];
    $params = [];
    $types = "";

    if ($id) {
        $whereClauses[] = "dp.id = ?"; 
        $params[] = $id; 
        $types .= "i";
    }
    if ($cargo_id) {
        $whereClauses[] = "dp.cargo_id = ?"; 
        $params[] = $cargo_id; 
        $types .= "i";
    }
    if ($driver_id) {
        $whereClauses[] = "dp.driver_id = ?"; 
        $params[] = $driver_id; 
        $types .= "i";
    }

    if (!empty($whereClauses)) {
        $sql .= " WHERE " . implode(" AND ", $whereClauses);
    }

    $sql .= " ORDER BY dp.payment_date DESC, dp.id DESC";

    if (!empty($params)) {
        $stmt = $conn->prepare($sql);
        if (!$stmt) { 
            http_response_code(500); 
            echo json_encode(["message" => "Error preparing statement: " . $conn->error]); 
            return; 
        }
        $stmt->bind_param($types, ...$params);
    } else {
        $stmt = $conn->prepare($sql);
        if (!$stmt) { 
            http_response_code(500); 
            echo json_encode(["message" => "Error preparing statement: " . $conn->error]); 
            return; 
        }
    }

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        http_response_code(200);
        echo json_encode($data);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error executing query: " . $stmt->error]);
    }
    $stmt->close();
}

// Create new driver salary payment
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    // Required fields validation
    $required = ['cargo_id', 'driver_id', 'amount', 'payment_date'];
    foreach ($required as $field) {
        if (!array_key_exists($field, $data) || $data[$field] === '' || $data[$field] === null) {
            http_response_code(400);
            echo json_encode(["message" => "Missing required field: " . $field]);
            return;
        }
    }

    // Validate Foreign Keys exist
    $foreignKeys = [
        'cargos' => $data['cargo_id'],
        'drivers' => $data['driver_id']
    ];
    
    if (isset($data['bank_account_id']) && $data['bank_account_id']) {
        $foreignKeys['bank_accounts'] = $data['bank_account_id'];
    }
    
    foreach ($foreignKeys as $fkTable => $fkId) {
        if (!checkForeignKeyExists($conn, $fkTable, $fkId)) {
            http_response_code(400);
            echo json_encode(["message" => "Invalid ID for $fkTable: Record does not exist."]);
            return;
        }
    }

    // Sanitize and prepare data
    $cargo_id = filter_var($data['cargo_id'], FILTER_VALIDATE_INT);
    $driver_id = filter_var($data['driver_id'], FILTER_VALIDATE_INT);
    $amount = filter_var($data['amount'], FILTER_VALIDATE_FLOAT);
    $payment_date = sanitize($conn, $data['payment_date']);
    $receipt_image = isset($data['receipt_image']) ? sanitize($conn, $data['receipt_image']) : null;
    $bank_account_id = isset($data['bank_account_id']) ? filter_var($data['bank_account_id'], FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE) : null;
    $notes = isset($data['notes']) ? sanitize($conn, $data['notes']) : null;

    $sql = "INSERT INTO $table (cargo_id, driver_id, amount, payment_date, receipt_image, bank_account_id, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($sql);
    if (!$stmt) { 
        http_response_code(500); 
        echo json_encode(["message" => "Error preparing statement: " . $conn->error]); 
        return; 
    }

    $types = "iidssis"; // int, int, double, string, string, int, string
    $stmt->bind_param($types, $cargo_id, $driver_id, $amount, $payment_date, $receipt_image, $bank_account_id, $notes);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode([
            "message" => "Driver payment created successfully.", 
            "id" => $newId,
            "paid" => true
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error creating driver payment: " . $stmt->error]);
        error_log("Driver Payment Creation Error: " . $stmt->error);
    }
    $stmt->close();
}

// Update driver salary payment
function handlePut($conn, $table) {
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

    // Fields that can be updated
    $allowedFields = [
        'cargo_id' => 'i',
        'driver_id' => 'i',
        'amount' => 'd',
        'payment_date' => 's',
        'receipt_image' => 's',
        'bank_account_id' => 'i',
        'notes' => 's'
    ];

    // Add foreign key checks
    $foreignKeyChecks = [
        'cargo_id' => 'cargos',
        'driver_id' => 'drivers',
        'bank_account_id' => 'bank_accounts'
    ];

    foreach ($data as $key => $value) {
        if (!array_key_exists($key, $allowedFields)) continue;

        $type = $allowedFields[$key];
        
        // Check foreign keys
        if (array_key_exists($key, $foreignKeyChecks) && $value !== null) {
            $fkTable = $foreignKeyChecks[$key];
            $fkId = filter_var($value, FILTER_VALIDATE_INT);
            if (!checkForeignKeyExists($conn, $fkTable, $fkId)) {
                http_response_code(400);
                echo json_encode(["message" => "Invalid ID for $key: Record in $fkTable does not exist."]);
                return;
            }
        }

        // Sanitize based on type
        switch ($type) {
            case 'i':
                $sanitizedValue = filter_var($value, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
                break;
            case 'd':
                $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT, FILTER_NULL_ON_FAILURE);
                break;
            case 's':
                $sanitizedValue = sanitize($conn, $value);
                break;
            default:
                continue 2; // Skip this field
        }

        $setClauses[] = "`$key` = ?";
        $params[] = $sanitizedValue;
        $types .= $type;
    }

    if (empty($setClauses)) {
        http_response_code(400);
        echo json_encode(["message" => "No valid fields provided for update."]);
        return;
    }

    $sql = "UPDATE $table SET " . implode(", ", $setClauses) . " WHERE id = ?";
    $types .= "i"; // Add type for the ID
    $params[] = $id; // Add the ID itself

    $stmt = $conn->prepare($sql);
    if (!$stmt) { 
        http_response_code(500); 
        echo json_encode(["message" => "Error preparing statement: " . $conn->error]); 
        return; 
    }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Driver payment updated successfully."]);
        } else {
            $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
            $checkStmt->bind_param("i", $id);
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            if ($checkResult->num_rows === 0) {
                http_response_code(404);
                echo json_encode(["message" => "Driver payment not found for update."]);
            } else {
                http_response_code(200);
                echo json_encode(["message" => "Driver payment found, but no changes were made."]);
            }
            $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating driver payment: " . $stmt->error]);
        error_log("Driver Payment Update Error: " . $stmt->error);
    }
    $stmt->close();
}

// Delete driver salary payment
function handleDelete($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(["message" => "Missing ID for delete."]);
        return;
    }

    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { 
        http_response_code(500); 
        echo json_encode(["message" => "Error preparing statement: " . $conn->error]); 
        return; 
    }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Driver payment deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Driver payment not found for delete."]);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error deleting driver payment: " . $stmt->error]);
        error_log("Driver Payment Deletion Error: " . $stmt->error);
    }
    $stmt->close();
}
?> 