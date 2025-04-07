<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'payments';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
}

// Helper function to check if a foreign key exists
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
     if ($foreignId === null) return true; // Allow NULLable foreign keys
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

    $baseColumns = "p.id, p.cargo_id, p.amount, p.company_id, p.bank_account_id, p.receipt_image, p.payment_date";
    $joins = "
        LEFT JOIN cargos c ON p.cargo_id = c.id
        LEFT JOIN cargo_selling_companies csc ON p.company_id = csc.id
        LEFT JOIN bank_accounts ba ON p.bank_account_id = ba.id
    ";
    $joinedColumns = ", c.origin, c.destination, csc.name as company_name, ba.bank_name, ba.account_holder_name as bank_account_holder";

    $sql = "SELECT $baseColumns $joinedColumns FROM $table p $joins";
    $whereClauses = [];
    $params = [];
    $types = "";

    if ($id) {
        $whereClauses[] = "p.id = ?";
        $params[] = $id;
        $types .= "i";
    } elseif ($cargo_id) {
        // Example: Filter payments by cargo_id
        $whereClauses[] = "p.cargo_id = ?";
        $params[] = $cargo_id;
        $types .= "i";
    }
    // Add more filters as needed (e.g., by company_id, date range)

    if (!empty($whereClauses)) {
        $sql .= " WHERE " . implode(" AND ", $whereClauses);
    }

    $sql .= " ORDER BY p.payment_date DESC, p.id DESC"; // Example order

    if ($id && empty($whereClauses)) { // If only single ID requested but wasn't added above
         $sql = "SELECT $baseColumns $joinedColumns FROM $table p $joins WHERE p.id = ? ORDER BY p.payment_date DESC, p.id DESC";
         $stmt = $conn->prepare($sql);
         if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
         $stmt->bind_param("i", $id);
    } elseif(!empty($params)) {
         $stmt = $conn->prepare($sql);
         if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
         $stmt->bind_param($types, ...$params);
    } else {
         // No specific ID or filter, get all (potentially many results!)
         $stmt = $conn->prepare($sql); // No bind needed
          if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    }


    if ($stmt->execute()) {
        $result = $stmt->get_result();
        if ($id && $result->num_rows > 0) { // Single record expected
             $data = $result->fetch_assoc();
             http_response_code(200);
             echo json_encode($data);
        } elseif ($id) { // Single record requested but not found
             http_response_code(404);
             echo json_encode(["message" => "Payment not found."]);
        } else { // Multiple records (or filtered records)
             $allData = $result->fetch_all(MYSQLI_ASSOC);
             http_response_code(200);
             echo json_encode($allData);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error retrieving payments: " . $stmt->error]);
    }
    $stmt->close();

}


// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    $required = ['cargo_id', 'amount', 'company_id'];
    foreach ($required as $field) {
        if (!isset($data[$field]) || $data[$field] === '') { // Amount can be 0? Check business logic
            http_response_code(400);
            echo json_encode(["message" => "Missing required field: " . $field]);
            return;
        }
    }

     // Validate Foreign Keys
     if (!checkForeignKeyExists($conn, 'cargos', $data['cargo_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid cargo_id."]); return;
     }
      if (!checkForeignKeyExists($conn, 'cargo_selling_companies', $data['company_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid company_id."]); return;
     }
     if (isset($data['bank_account_id']) && !checkForeignKeyExists($conn, 'bank_accounts', $data['bank_account_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid bank_account_id."]); return;
     }

    // Sanitize inputs
    $cargo_id = filter_var($data['cargo_id'], FILTER_VALIDATE_INT);
    $amount = filter_var($data['amount'], FILTER_VALIDATE_FLOAT);
    $company_id = filter_var($data['company_id'], FILTER_VALIDATE_INT);
    $bank_account_id = isset($data['bank_account_id']) ? filter_var($data['bank_account_id'], FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE) : null;
    $receipt_image = isset($data['receipt_image']) ? sanitize($conn, $data['receipt_image']) : null;
    $payment_date = isset($data['payment_date']) ? sanitize($conn, $data['payment_date']) : date('Y-m-d H:i:s'); // Default to now

    if ($amount === false || $amount < 0) { // Check amount validation
         http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return;
    }
     // Add date validation if needed


    $sql = "INSERT INTO $table (cargo_id, amount, company_id, bank_account_id, receipt_image, payment_date)
            VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Types: i = integer, d = double, s = string
    $types = "idiiss";
    $stmt->bind_param($types, $cargo_id, $amount, $company_id, $bank_account_id, $receipt_image, $payment_date);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Payment recorded successfully.", "id" => $newId]);
         // Optional: Update cargo's seller_payment_status if this payment clears the balance? Needs business logic.
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error recording payment: " . $stmt->error]);
         error_log("Payment Creation Error: " . $stmt->error);
    }
    $stmt->close();
}

// UPDATE (PUT)
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

    // Add fields to update, including foreign key checks
    $foreignKeyChecks = [
        'cargo_id' => 'cargos',
        'company_id' => 'cargo_selling_companies',
        'bank_account_id' => 'bank_accounts'
     ];

     foreach($data as $key => $value) {
        $sanitizedValue = null;
        $type = '';

        if ($key === 'id') continue;

        if (array_key_exists($key, $foreignKeyChecks)) {
             $fkTable = $foreignKeyChecks[$key];
             $fkId = filter_var($value, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
             // Check if FK exists, allowing null for bank_account_id
             if (($fkId !== null && $fkId !== false && !checkForeignKeyExists($conn, $fkTable, $fkId)) || ($fkId === false && $value !== null))
             {
                 http_response_code(400); echo json_encode(["message" => "Invalid ID for $key."]); return;
             }
             $sanitizedValue = $fkId; // Can be null if bank_account_id
             $type = 'i';
        }
        else if ($key === 'amount') {
             $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT);
              if ($sanitizedValue === false || $sanitizedValue < 0) { http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return; }
             $type = 'd';
        } else if (in_array($key, ['receipt_image', 'payment_date'])) {
             // Add date validation if needed for payment_date
             $sanitizedValue = sanitize($conn, $value);
             $type = 's';
        }

         if ($type) {
             $setClauses[] = "`$key` = ?";
             $params[] = $sanitizedValue;
             $types .= $type;
         } else {
              error_log("Skipping update for unhandled or invalid payment field: " . $key);
         }
     }


    if (empty($setClauses)) {
         http_response_code(400);
         echo json_encode(["message" => "No valid fields provided for update."]);
         return;
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
            echo json_encode(["message" => "Payment updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404);
                  echo json_encode(["message" => "Payment not found for update."]);
             } else {
                  http_response_code(200);
                  echo json_encode(["message" => "Payment found, but no changes were made."]);
             }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating payment: " . $stmt->error]);
        error_log("Payment Update Error: " . $stmt->error);
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

    // No typical dependencies from other main tables TO payments, so direct delete is usually safe
    // unless you have audit logs or similar pointing to payment IDs.

    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Payment deleted successfully."]);
             // Optional: Re-evaluate cargo's seller_payment_status? Needs business logic.
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Payment not found for delete."]);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error deleting payment: " . $stmt->error]);
        error_log("Payment Deletion Error: " . $stmt->error);
    }
    $stmt->close();
}
?> 