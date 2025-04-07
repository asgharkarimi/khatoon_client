<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'receivables';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
}

// Helper function to check if a foreign key exists (ensure this is available)
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
     if ($foreignId === null) return true; // Allow NULLable foreign keys (like bank_account_id)
    if ($foreignId === false || $foreignId <= 0) return false; // Invalid ID format
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
    $customer_id = isset($_GET['customer_id']) ? intval($_GET['customer_id']) : null;

    $baseColumns = "r.id, r.cargo_id, r.amount, r.customer_id, r.bank_account_id, r.receipt_image, r.received_date";
    $joins = "
        LEFT JOIN cargos c ON r.cargo_id = c.id
        LEFT JOIN customers cust ON r.customer_id = cust.id
        LEFT JOIN bank_accounts ba ON r.bank_account_id = ba.id
    ";
    $joinedColumns = ", c.origin, c.destination, CONCAT(cust.first_name, ' ', cust.last_name) as customer_name, cust.phone_number as customer_phone, ba.bank_name, ba.account_holder_name as bank_account_holder";

    $sql = "SELECT $baseColumns $joinedColumns FROM $table r $joins";
    $whereClauses = [];
    $params = [];
    $types = "";

    if ($id) {
        $whereClauses[] = "r.id = ?"; $params[] = $id; $types .= "i";
    } elseif ($cargo_id) {
        $whereClauses[] = "r.cargo_id = ?"; $params[] = $cargo_id; $types .= "i";
    } elseif ($customer_id) {
         $whereClauses[] = "r.customer_id = ?"; $params[] = $customer_id; $types .= "i";
    }
    // Add more filters...

    if (!empty($whereClauses)) {
        $sql .= " WHERE " . implode(" AND ", $whereClauses);
    }

    $sql .= " ORDER BY r.received_date DESC, r.id DESC";

    if ($id && empty($whereClauses)) {
         $sql = "SELECT $baseColumns $joinedColumns FROM $table r $joins WHERE r.id = ? ORDER BY r.received_date DESC, r.id DESC";
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
             http_response_code(200);
             echo json_encode($data);
        } elseif ($id) {
             http_response_code(404);
             echo json_encode(["message" => "Receivable not found."]);
        } else {
             $allData = $result->fetch_all(MYSQLI_ASSOC);
             http_response_code(200);
             echo json_encode($allData);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error retrieving receivables: " . $stmt->error]);
    }
    $stmt->close();
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    $required = ['cargo_id', 'amount', 'customer_id'];
    foreach ($required as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            http_response_code(400); echo json_encode(["message" => "Missing required field: " . $field]); return;
        }
    }

     // Validate Foreign Keys
     if (!checkForeignKeyExists($conn, 'cargos', $data['cargo_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid cargo_id."]); return;
     }
     if (!checkForeignKeyExists($conn, 'customers', $data['customer_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid customer_id."]); return;
     }
     if (isset($data['bank_account_id']) && !checkForeignKeyExists($conn, 'bank_accounts', $data['bank_account_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid bank_account_id."]); return;
     }

    // Sanitize inputs
    $cargo_id = filter_var($data['cargo_id'], FILTER_VALIDATE_INT);
    $amount = filter_var($data['amount'], FILTER_VALIDATE_FLOAT);
    $customer_id = filter_var($data['customer_id'], FILTER_VALIDATE_INT);
    $bank_account_id = isset($data['bank_account_id']) ? filter_var($data['bank_account_id'], FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE) : null;
    $receipt_image = isset($data['receipt_image']) ? sanitize($conn, $data['receipt_image']) : null;
    $received_date = isset($data['received_date']) ? sanitize($conn, $data['received_date']) : date('Y-m-d H:i:s');

    if ($amount === false || $amount < 0) {
         http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return;
    }
    // Add date validation if needed

    $sql = "INSERT INTO $table (cargo_id, amount, customer_id, bank_account_id, receipt_image, received_date)
            VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Types: i=int, d=double, s=string
    $types = "idiiss";
    $stmt->bind_param($types, $cargo_id, $amount, $customer_id, $bank_account_id, $receipt_image, $received_date);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Receivable recorded successfully.", "id" => $newId]);
         // Optional: Update cargo's customer_payment_status_id if this receivable clears the balance? Needs business logic.
         // Example: Check total received vs price * weight, update cargos table if fully paid.
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error recording receivable: " . $stmt->error]);
         error_log("Receivable Creation Error: " . $stmt->error);
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
    if (empty($data)) {
         http_response_code(400); echo json_encode(["message" => "No data provided for update."]); return;
    }

    $setClauses = [];
    $params = [];
    $types = "";

    $foreignKeyChecks = [
        'cargo_id' => 'cargos',
        'customer_id' => 'customers',
        'bank_account_id' => 'bank_accounts'
     ];

     foreach($data as $key => $value) {
        $sanitizedValue = null;
        $type = '';
        if ($key === 'id') continue;

        if (array_key_exists($key, $foreignKeyChecks)) {
             $fkTable = $foreignKeyChecks[$key];
             $fkId = filter_var($value, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
              if (($fkId !== null && $fkId !== false && !checkForeignKeyExists($conn, $fkTable, $fkId)) || ($fkId === false && $value !== null)) {
                 http_response_code(400); echo json_encode(["message" => "Invalid ID for $key."]); return;
             }
             $sanitizedValue = $fkId;
             $type = 'i';
        }
        else if ($key === 'amount') {
             $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT);
             if ($sanitizedValue === false || $sanitizedValue < 0) { http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return; }
             $type = 'd';
        } else if (in_array($key, ['receipt_image', 'received_date'])) {
             $sanitizedValue = sanitize($conn, $value);
             $type = 's';
        }

        if ($type) {
             $setClauses[] = "`$key` = ?";
             $params[] = $sanitizedValue;
             $types .= $type;
         } else {
              error_log("Skipping update for unhandled or invalid receivable field: " . $key);
         }
     }

    if (empty($setClauses)) {
         http_response_code(400); echo json_encode(["message" => "No valid fields provided for update."]); return;
    }

    $sql = "UPDATE $table SET " . implode(", ", $setClauses) . " WHERE id = ?";
    $types .= "i";
    $params[] = $id;

    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Receivable updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404); echo json_encode(["message" => "Receivable not found for update."]);
             } else {
                  http_response_code(200); echo json_encode(["message" => "Receivable found, but no changes were made."]);
             }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating receivable: " . $stmt->error]);
        error_log("Receivable Update Error: " . $stmt->error);
    }
    $stmt->close();
}

// DELETE
function handleDelete($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) {
        http_response_code(400); echo json_encode(["message" => "Missing ID for delete."]); return;
    }

    // Direct delete usually safe unless other tables reference receivable IDs.

    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Receivable deleted successfully."]);
             // Optional: Re-evaluate cargo's customer_payment_status_id? Needs business logic.
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Receivable not found for delete."]);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error deleting receivable: " . $stmt->error]);
        error_log("Receivable Deletion Error: " . $stmt->error);
    }
    $stmt->close();
}
?> 