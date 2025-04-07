<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'cargo_types';

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
        // Get single record
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
                echo json_encode(["message" => "Record not found."]);
            }
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error executing statement: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        // Get all records
        $sql = "SELECT * FROM $table ORDER BY name ASC"; // Order alphabetically
        $result = $conn->query($sql);
        if ($result) {
            $allData = $result->fetch_all(MYSQLI_ASSOC);
            http_response_code(200);
            echo json_encode($allData);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error retrieving records: " . $conn->error]);
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

    $sql = "INSERT INTO $table (name) VALUES (?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("s", $name);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Record created successfully.", "id" => $newId]);
    } else {
        if ($conn->errno == 1062) { // Duplicate entry for name (UNIQUE constraint)
             http_response_code(409);
             echo json_encode(["message" => "Duplicate entry for name."]);
        } else {
             http_response_code(500);
             echo json_encode(["message" => "Error creating record: " . $stmt->error]);
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
    if (empty($data) || !isset($data['name'])) {
         http_response_code(400);
         echo json_encode(["message" => "Missing or invalid data provided for update (requires 'name')."]);
         return;
    }

    $name = sanitize($conn, $data['name']);

    $sql = "UPDATE $table SET name = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("si", $name, $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Record updated successfully."]);
        } else {
            $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
            $checkStmt->bind_param("i", $id);
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            if ($checkResult->num_rows === 0) {
                 http_response_code(404);
                 echo json_encode(["message" => "Record not found for update."]);
            } else {
                 http_response_code(200);
                 echo json_encode(["message" => "Record found, but no changes were made."]);
            }
            $checkStmt->close();
        }
    } else {
         if ($conn->errno == 1062) {
             http_response_code(409);
             echo json_encode(["message" => "Update failed due to duplicate entry for name."]);
         } else {
            http_response_code(500);
            echo json_encode(["message" => "Error updating record: " . $stmt->error]);
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
            echo json_encode(["message" => "Record deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Record not found for delete."]);
        }
    } else {
         if ($conn->errno == 1451) { // Foreign key constraint fails
             http_response_code(409);
             echo json_encode(["message" => "Cannot delete record because it is referenced by other data (e.g., in cargos table)."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting record: " . $stmt->error]);
        }
    }
    $stmt->close();
}
?> 