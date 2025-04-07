<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'expenses';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
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
    $category_id = isset($_GET['expense_category_id']) ? intval($_GET['expense_category_id']) : null;


    $baseColumns = "e.id, e.cargo_id, e.expense_category_id, e.title, e.amount, e.receipt_image, e.description, e.expense_date";
    $joins = "
        LEFT JOIN cargos c ON e.cargo_id = c.id
        LEFT JOIN expense_categories ec ON e.expense_category_id = ec.id
    ";
    $joinedColumns = ", c.origin, c.destination, ec.name as category_name";

    $sql = "SELECT $baseColumns $joinedColumns FROM $table e $joins";
    $whereClauses = [];
    $params = [];
    $types = "";

    if ($id) {
        $whereClauses[] = "e.id = ?"; $params[] = $id; $types .= "i";
    } elseif ($cargo_id) {
        $whereClauses[] = "e.cargo_id = ?"; $params[] = $cargo_id; $types .= "i";
    } elseif ($category_id) {
        $whereClauses[] = "e.expense_category_id = ?"; $params[] = $category_id; $types .= "i";
    }
    // Add more filters...

    if (!empty($whereClauses)) {
        $sql .= " WHERE " . implode(" AND ", $whereClauses);
    }

    $sql .= " ORDER BY e.expense_date DESC, e.id DESC";


    if ($id && empty($whereClauses)) {
        $sql = "SELECT $baseColumns $joinedColumns FROM $table e $joins WHERE e.id = ? ORDER BY e.expense_date DESC, e.id DESC";
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
             http_response_code(404); echo json_encode(["message" => "Expense not found."]);
        } else {
             $allData = $result->fetch_all(MYSQLI_ASSOC);
             http_response_code(200); echo json_encode($allData);
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error retrieving expenses: " . $stmt->error]);
    }
    $stmt->close();
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    $required = ['cargo_id', 'expense_category_id', 'title', 'amount'];
    foreach ($required as $field) {
        if (!isset($data[$field]) || ($data[$field] === '' && $field !== 'description' && $field !== 'receipt_image')) {
             http_response_code(400); echo json_encode(["message" => "Missing required field: " . $field]); return;
        }
    }

    // Validate Foreign Keys
     if (!checkForeignKeyExists($conn, 'cargos', $data['cargo_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid cargo_id."]); return;
     }
     if (!checkForeignKeyExists($conn, 'expense_categories', $data['expense_category_id'])) {
         http_response_code(400); echo json_encode(["message" => "Invalid expense_category_id."]); return;
     }

    // Sanitize inputs
    $cargo_id = filter_var($data['cargo_id'], FILTER_VALIDATE_INT);
    $expense_category_id = filter_var($data['expense_category_id'], FILTER_VALIDATE_INT);
    $title = sanitize($conn, $data['title']);
    $amount = filter_var($data['amount'], FILTER_VALIDATE_FLOAT);
    $receipt_image = isset($data['receipt_image']) ? sanitize($conn, $data['receipt_image']) : null;
    $description = isset($data['description']) ? sanitize($conn, $data['description']) : null;
    $expense_date = isset($data['expense_date']) ? sanitize($conn, $data['expense_date']) : date('Y-m-d H:i:s');

    if ($amount === false || $amount < 0) {
         http_response_code(400); echo json_encode(["message" => "Invalid amount."]); return;
    }
    // Add date validation if needed

    $sql = "INSERT INTO $table (cargo_id, expense_category_id, title, amount, receipt_image, description, expense_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Types: i=int, s=string, d=double
    $types = "iisdsss";
    $stmt->bind_param($types,
        $cargo_id, $expense_category_id, $title, $amount,
        $receipt_image, $description, $expense_date
    );

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Expense created successfully.", "id" => $newId]);
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error creating expense: " . $stmt->error]);
         error_log("Expense Creation Error: " . $stmt->error);
    }
    $stmt->close();
}

// UPDATE (PUT)
function handlePut($conn, $table) {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    if (!$id) { http_response_code(400); echo json_encode(["message" => "Missing ID for update."]); return; }

    $data = json_decode(file_get_contents('php://input'), true);
    if (empty($data)) { http_response_code(400); echo json_encode(["message" => "No data provided for update."]); return; }

    $setClauses = [];
    $params = [];
    $types = "";

     $foreignKeyChecks = [
        'cargo_id' => 'cargos',
        'expense_category_id' => 'expense_categories'
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
        else if (array_key_exists($key, $data) && in_array($key, ['title', 'receipt_image', 'description', 'expense_date'])) {
             // Add specific date validation for expense_date?
             $sanitizedValue = sanitize($conn, $value);
             $type = 's';
        }

        if ($type) {
             $setClauses[] = "`$key` = ?"; $params[] = $sanitizedValue; $types .= $type;
        } else { error_log("Skipping update for unhandled expense field: " . $key); }
     }


    if (empty($setClauses)) { http_response_code(400); echo json_encode(["message" => "No valid fields provided for update."]); return; }

    $sql = "UPDATE $table SET " . implode(", ", $setClauses) . " WHERE id = ?";
    $types .= "i"; $params[] = $id;

    $stmt = $conn->prepare($sql);
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200); echo json_encode(["message" => "Expense updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id); $checkStmt->execute(); $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) { http_response_code(404); echo json_encode(["message" => "Expense not found for update."]); }
             else { http_response_code(200); echo json_encode(["message" => "Expense found, but no changes were made."]); }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating expense: " . $stmt->error]);
        error_log("Expense Update Error: " . $stmt->error);
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
        if ($stmt->affected_rows > 0) { http_response_code(200); echo json_encode(["message" => "Expense deleted successfully."]); }
        else { http_response_code(404); echo json_encode(["message" => "Expense not found for delete."]); }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error deleting expense: " . $stmt->error]);
        error_log("Expense Deletion Error: " . $stmt->error);
    }
    $stmt->close();
}
?> 