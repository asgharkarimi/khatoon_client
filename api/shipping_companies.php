<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'shipping_companies';

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
                echo json_encode(["message" => "Shipping company not found."]);
            }
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error executing statement: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        $sql = "SELECT * FROM $table ORDER BY name ASC";
        $result = $conn->query($sql);
        if ($result) {
            $allData = $result->fetch_all(MYSQLI_ASSOC);
            http_response_code(200);
            echo json_encode($allData);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error retrieving shipping companies: " . $conn->error]);
        }
    }
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    if (empty($data['name'])) {
        http_response_code(400);
        echo json_encode(["message" => "Missing required field: name"]);
        return;
    }

    $name = sanitize($conn, $data['name']);
    $phone_number = isset($data['phone_number']) ? sanitize($conn, $data['phone_number']) : null;

    $sql = "INSERT INTO $table (name, phone_number) VALUES (?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("ss", $name, $phone_number);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Shipping company created successfully.", "id" => $newId]);
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error creating shipping company: " . $stmt->error]);
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

    if (isset($data['name'])) {
        $setClauses[] = "name = ?";
        $params[] = sanitize($conn, $data['name']);
        $types .= "s";
    }
    if (isset($data['phone_number'])) {
        $setClauses[] = "phone_number = ?";
        $params[] = sanitize($conn, $data['phone_number']);
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
            echo json_encode(["message" => "Shipping company updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404);
                  echo json_encode(["message" => "Shipping company not found for update."]);
             } else {
                  http_response_code(200);
                  echo json_encode(["message" => "Shipping company found, but no changes were made."]);
             }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating shipping company: " . $stmt->error]);
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
            echo json_encode(["message" => "Shipping company deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Shipping company not found for delete."]);
        }
    } else {
         if ($conn->errno == 1451) { // Foreign key constraint fails
             http_response_code(409);
             echo json_encode(["message" => "Cannot delete shipping company because it is referenced by other data (e.g., in cargos table)."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting shipping company: " . $stmt->error]);
        }
    }
    $stmt->close();
}
?> 