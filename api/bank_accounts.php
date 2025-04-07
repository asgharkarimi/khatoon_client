<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'bank_accounts';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
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

    if ($id) {
        $sql = "SELECT * FROM $table WHERE id = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($data = $result->fetch_assoc()) {
                http_response_code(200);
                echo json_encode($data);
            } else {
                http_response_code(404);
                echo json_encode(["message" => "Bank account not found."]);
            }
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error executing statement: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        $sql = "SELECT * FROM $table ORDER BY bank_name ASC, account_holder_name ASC";
        $result = $conn->query($sql);
        if ($result) {
            $allData = $result->fetch_all(MYSQLI_ASSOC);
            http_response_code(200);
            echo json_encode($allData);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error retrieving bank accounts: " . $conn->error]);
        }
    }
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    if (empty($data['bank_name']) || empty($data['account_holder_name'])) {
        http_response_code(400);
        echo json_encode(["message" => "Missing required fields: bank_name and/or account_holder_name"]);
        return;
    }

    $bank_name = sanitize($conn, $data['bank_name']);
    $account_holder_name = sanitize($conn, $data['account_holder_name']);
    $card_number = isset($data['card_number']) ? sanitize($conn, $data['card_number']) : null;
    $iban = isset($data['iban']) ? sanitize($conn, $data['iban']) : null;

    // Basic validation for card/iban format (can be improved)
    if ($card_number && !preg_match('/^[0-9]{16,19}$/', preg_replace('/\s+/', '', $card_number))) {
        //http_response_code(400); echo json_encode(["message" => "Invalid card number format."]); return;
        // Allow flexibility for now, log potential issue
        error_log("Potential invalid card number format received: " . $card_number);
    }
     if ($iban && !preg_match('/^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$/', preg_replace('/\s+/', '', $iban))) {
        //http_response_code(400); echo json_encode(["message" => "Invalid IBAN format."]); return;
        error_log("Potential invalid IBAN format received: " . $iban);
    }


    $sql = "INSERT INTO $table (bank_name, account_holder_name, card_number, iban) VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("ssss", $bank_name, $account_holder_name, $card_number, $iban);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Bank account created successfully.", "id" => $newId]);
    } else {
        if ($conn->errno == 1062) { // Duplicate entry
             $error_message = "Duplicate entry.";
             if (strpos($stmt->error, 'card_number') !== false) $error_message = "Duplicate card number.";
             if (strpos($stmt->error, 'iban') !== false) $error_message = "Duplicate IBAN.";
             http_response_code(409);
             echo json_encode(["message" => $error_message]);
        } else {
             http_response_code(500);
             echo json_encode(["message" => "Error creating bank account: " . $stmt->error]);
        }
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

    if (isset($data['bank_name'])) {
        $setClauses[] = "bank_name = ?";
        $params[] = sanitize($conn, $data['bank_name']);
        $types .= "s";
    }
    if (isset($data['account_holder_name'])) {
        $setClauses[] = "account_holder_name = ?";
        $params[] = sanitize($conn, $data['account_holder_name']);
        $types .= "s";
    }
    if (array_key_exists('card_number', $data)) { // Use array_key_exists to allow setting to NULL
        $card_number = $data['card_number'] === null ? null : sanitize($conn, $data['card_number']);
        if ($card_number && !preg_match('/^[0-9]{16,19}$/', preg_replace('/\s+/', '', $card_number))) {
             error_log("Potential invalid card number format received for update: " . $card_number);
        }
        $setClauses[] = "card_number = ?";
        $params[] = $card_number;
        $types .= "s";
    }
    if (array_key_exists('iban', $data)) {
        $iban = $data['iban'] === null ? null : sanitize($conn, $data['iban']);
         if ($iban && !preg_match('/^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$/', preg_replace('/\s+/', '', $iban))) {
            error_log("Potential invalid IBAN format received for update: " . $iban);
        }
        $setClauses[] = "iban = ?";
        $params[] = $iban;
        $types .= "s";
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
            echo json_encode(["message" => "Bank account updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404);
                  echo json_encode(["message" => "Bank account not found for update."]);
             } else {
                  http_response_code(200);
                  echo json_encode(["message" => "Bank account found, but no changes were made."]);
             }
             $checkStmt->close();
        }
    } else {
         if ($conn->errno == 1062) {
              $error_message = "Update failed due to duplicate entry.";
              if (strpos($stmt->error, 'card_number') !== false) $error_message = "Duplicate card number.";
              if (strpos($stmt->error, 'iban') !== false) $error_message = "Duplicate IBAN.";
             http_response_code(409);
             echo json_encode(["message" => $error_message]);
         } else {
            http_response_code(500);
            echo json_encode(["message" => "Error updating bank account: " . $stmt->error]);
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
            echo json_encode(["message" => "Bank account deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Bank account not found for delete."]);
        }
    } else {
        if ($conn->errno == 1451) { // Foreign key constraint fails
             http_response_code(409);
             echo json_encode(["message" => "Cannot delete bank account because it is referenced by other data (e.g., drivers, payments, receivables). Consider setting related foreign keys to NULL instead."]);
             // Alternatively, implement logic to set FKs to NULL first
             /*
             // Example: Set FKs in drivers to NULL before deleting bank account
             $updateDriversSql = "UPDATE drivers SET bank_account_id = NULL WHERE bank_account_id = ?";
             $updateStmt = $conn->prepare($updateDriversSql);
             $updateStmt->bind_param("i", $id);
             $updateStmt->execute();
             $updateStmt->close();
             // Repeat for payments, receivables etc. if ON DELETE SET NULL is not used or supported
             // Then attempt delete again... handle potential race conditions if needed.
             */
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting bank account: " . $stmt->error]);
        }
    }
    $stmt->close();
}
?> 