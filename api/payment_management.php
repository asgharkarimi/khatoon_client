<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'payment_management';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    // Allow more flexibility for 'payer_details' if needed, otherwise strip tags
    return mysqli_real_escape_string($conn, strip_tags($data));
}

// Helper function to check if a foreign key exists (ensure this is available)
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
     if ($foreignId === null || $foreignId === false || $foreignId <= 0) return false;
    $checkSql = "SELECT id FROM `$foreignTable` WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
     if (!$checkStmt) { error_log("Error preparing FK check for $foreignTable: " . $conn->error); return false; }
    $checkStmt->bind_param("i", $foreignId);
     if (!$checkStmt->execute()) { error_log("Error executing FK check for $foreignTable: " . $checkStmt->error); $checkStmt->close(); return false; }
    $checkResult = $checkStmt->get_result();
    $exists = $checkResult->num_rows > 0;
    $checkStmt->close();
    return $exists;
}

// --- Request Handling ---

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

// --- Function Definitions ---

// READ (GET)
function handleGet($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    $cargo_id = isset($_GET['cargo_id']) ? intval($_GET['cargo_id']) : null;

    $baseColumns = "pm.id, pm.cargo_id, pm.payment_type_id, pm.payer_details, pm.amount, pm.card_transfer_receipt_image, pm.check_image, pm.check_due_date, pm.transaction_date";
    $joins = "
        LEFT JOIN cargos c ON pm.cargo_id = c.id
        LEFT JOIN payment_types pt ON pm.payment_type_id = pt.id
    ";
    $joinedColumns = ", c.origin, c.destination, pt.name as payment_type_name";

    $sql = "SELECT $baseColumns $joinedColumns FROM $table pm $joins";
    $whereClauses = [];
    $params = [];
    $types = "";

    if ($id) {
        $whereClauses[] = "pm.id = ?"; $params[] = $id; $types .= "i";
    } elseif ($cargo_id) {
        $whereClauses[] = "pm.cargo_id = ?"; $params[] = $cargo_id; $types .= "i";
    }
    // Add more filters...

    if (!empty($whereClauses)) {
        $sql .= " WHERE " . implode(" AND ", $whereClauses);
    }

    $sql .= " ORDER BY pm.transaction_date DESC, pm.id DESC";

     if ($id && empty($whereClauses)) {
         $sql = "SELECT $baseColumns $joinedColumns FROM $table pm $joins WHERE pm.id = ? ORDER BY pm.transaction_date DESC, pm.id DESC";
         $stmt = $conn->prepare($sql);
         if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
         $stmt->bind_param("i", $id);
    } elseif(!empty($params)) {
         $stmt = $conn->prepare($sql);
         if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
         $stmt->bind_param($types, ...$params);
    } else {
         $stmt = $conn->prepare($sql);
         if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    }

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        if ($id && $result->num_rows > 0) {
             $data = $result->fetch_assoc();
             http_response_code(200); echo json_encode($data);
        } elseif ($id) {
             http_response_code(404); echo json_encode(["message" => "Payment management record not found."]);
        } else {
             $allData = $result->fetch_all(MYSQLI_ASSOC);
             http_response_code(200); echo json_encode($allData);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error retrieving payment management records: " . $stmt->error]);
    }
    $stmt->close();
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    $required = ['cargo_id', 'payment_type_id', 'amount']; // payer_details might be optional
    foreach ($required as $field) {
         if (!isset($data[$field]) || ($data[$field] === '' && $field !== 'payer_details')) { // Allow empty payer_details maybe?
            http_response_code(400); echo json_encode(["message" => "Missing required field: " . $field]); return;
        }
    }

     // Validate Foreign Keys
     if (!checkForeignKeyExists($conn, 'cargos', $data['cargo_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid cargo_id."]); return;
     }
     if (!checkForeignKeyExists($conn, 'payment_types', $data['payment_type_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid payment_type_id."]); return;
     }

    // Sanitize inputs
    $cargo_id = filter_var($data['cargo_id'], FILTER_VALIDATE_INT);
    $payment_type_id = filter_var($data['payment_type_id'], FILTER_VALIDATE_INT);
    $payer_details = isset($data['payer_details']) ? sanitize($conn, $data['payer_details']) : null;
    $amount = filter_var($data['amount'], FILTER_VALIDATE_FLOAT);
    $card_transfer_receipt_image = isset($data['card_transfer_receipt_image']) ? sanitize($conn, $data['card_transfer_receipt_image']) : null;
    $check_image = isset($data['check_image']) ? sanitize($conn, $data['check_image']) : null;
    $check_due_date = isset($data['check_due_date']) ? sanitize($conn, $data['check_due_date']) : null; // Expect YYYY-MM-DD
    $transaction_date = isset($data['transaction_date']) ? sanitize($conn, $data['transaction_date']) : date('Y-m-d H:i:s');

    if ($amount === false || $amount < 0) {
         http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return;
    }
    // Add date validation if needed (check_due_date, transaction_date)


    $sql = "INSERT INTO $table (cargo_id, payment_type_id, payer_details, amount, card_transfer_receipt_image, check_image, check_due_date, transaction_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Types: i=int, s=string, d=double
    $types = "iisdssss";
    $stmt->bind_param($types,
        $cargo_id, $payment_type_id, $payer_details, $amount,
        $card_transfer_receipt_image, $check_image, $check_due_date, $transaction_date
        );

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Payment management record created successfully.", "id" => $newId]);
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error creating payment management record: " . $stmt->error]);
         error_log("Payment Management Creation Error: " . $stmt->error);
    }
    $stmt->close();
}

// UPDATE (PUT)
function handlePut($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) {
        http_response_code(400); echo json_encode(["message" => "Missing ID for update."]); return;
    }

    $data = json_decode(file_get_contents('php://input'), true);
     if (empty($data)) { http_response_code(400); echo json_encode(["message" => "No data provided for update."]); return; }

    $setClauses = [];
    $params = [];
    $types = "";

    $foreignKeyChecks = [
        'cargo_id' => 'cargos',
        'payment_type_id' => 'payment_types'
     ];

     foreach($data as $key => $value) {
        $sanitizedValue = null; $type = '';
        if ($key === 'id') continue;

        if (array_key_exists($key, $foreignKeyChecks)) {
             $fkTable = $foreignKeyChecks[$key];
             $fkId = filter_var($value, FILTER_VALIDATE_INT);
             if ($fkId === false || !checkForeignKeyExists($conn, $fkTable, $fkId)) {
                 http_response_code(400); echo json_encode(["message" => "Invalid ID for $key."]); return;
             }
             $sanitizedValue = $fkId; $type = 'i';
        }
        else if ($key === 'amount') {
             $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT);
             if ($sanitizedValue === false || $sanitizedValue < 0) { http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return; }
             $type = 'd';
        }
        // Use array_key_exists for fields that can be set to null or empty string
        else if (array_key_exists($key, $data) && in_array($key, ['payer_details', 'card_transfer_receipt_image', 'check_image', 'check_due_date', 'transaction_date'])) {
             // Add specific date validation?
             $sanitizedValue = sanitize($conn, $value);
             $type = 's';
        }

        if ($type) {
             $setClauses[] = "`$key` = ?"; $params[] = $sanitizedValue; $types .= $type;
        } else { error_log("Skipping update for unhandled payment management field: " . $key); }
     }

    if (empty($setClauses)) { http_response_code(400); echo json_encode(["message" => "No valid fields provided for update."]); return; }

    $sql = "UPDATE $table SET " . implode(", ", $setClauses) . " WHERE id = ?";
    $types .= "i"; $params[] = $id;

    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200); echo json_encode(["message" => "Payment management record updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id); $checkStmt->execute(); $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) { http_response_code(404); echo json_encode(["message" => "Record not found for update."]); }
             else { http_response_code(200); echo json_encode(["message" => "Record found, but no changes were made."]); }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating payment management record: " . $stmt->error]);
        error_log("Payment Management Update Error: " . $stmt->error);
    }
    $stmt->close();
}

// DELETE
function handleDelete($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) { http_response_code(400); echo json_encode(["message" => "Missing ID for delete."]); return; }

    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) { http_response_code(200); echo json_encode(["message" => "Payment management record deleted successfully."]); }
        else { http_response_code(404); echo json_encode(["message" => "Record not found for delete."]); }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error deleting payment management record: " . $stmt->error]);
        error_log("Payment Management Deletion Error: " . $stmt->error);
    }
    $stmt->close();
}
?> 