<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'vehicles';

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
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(["message" => "Error preparing statement: " . $conn->error]);
            return;
        }
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
        $sql = "SELECT * FROM $table ORDER BY id DESC"; // Example ordering
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

    // Basic Validation
    if (empty($data['name'])) {
        http_response_code(400);
        echo json_encode(["message" => "Missing required field: name"]);
        return;
    }

    // Sanitize inputs
    $name = sanitize($conn, $data['name']);
    $smart_card = isset($data['smart_card_number']) ? sanitize($conn, $data['smart_card_number']) : null;
    $health_code = isset($data['health_code']) ? sanitize($conn, $data['health_code']) : null;

    $sql = "INSERT INTO $table (name, smart_card_number, health_code) VALUES (?, ?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(["message" => "Error preparing statement: " . $conn->error]);
        return;
    }
    // Use 's' for string, 'i' for integer, 'd' for double, 'b' for blob
    $stmt->bind_param("sss", $name, $smart_card, $health_code);

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201); // Created
        echo json_encode(["message" => "Record created successfully.", "id" => $newId]);
    } else {
        // Check for duplicate entry if unique constraint fails (example for smart_card_number)
        if ($conn->errno == 1062) { // Error code for Duplicate entry
             http_response_code(409); // Conflict
             echo json_encode(["message" => "Duplicate entry for smart_card_number."]);
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
    if (empty($data)) {
         http_response_code(400);
         echo json_encode(["message" => "No data provided for update."]);
         return;
    }

    // Build the SET part of the SQL query dynamically
    $setClauses = [];
    $params = [];
    $types = "";

    // Sanitize and add fields to update
    if (isset($data['name'])) {
        $setClauses[] = "name = ?";
        $params[] = sanitize($conn, $data['name']);
        $types .= "s";
    }
    if (isset($data['smart_card_number'])) {
        $setClauses[] = "smart_card_number = ?";
        $params[] = sanitize($conn, $data['smart_card_number']);
        $types .= "s";
    }
     if (isset($data['health_code'])) {
        $setClauses[] = "health_code = ?";
        $params[] = sanitize($conn, $data['health_code']);
        $types .= "s";
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

    // Dynamically bind parameters
    $stmt->bind_param($types, ...$params); // Splat operator (...) for variable number of args

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Record updated successfully."]);
        } else {
            // Check if the record actually existed before declaring not found vs no change
            $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
            $checkStmt->bind_param("i", $id);
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            if ($checkResult->num_rows === 0) {
                 http_response_code(404);
                 echo json_encode(["message" => "Record not found for update."]);
            } else {
                 http_response_code(200); // Or 304 Not Modified if precise
                 echo json_encode(["message" => "Record found, but no changes were made."]);
            }
            $checkStmt->close();
        }
    } else {
         // Check for duplicate entry if unique constraint fails
         if ($conn->errno == 1062) {
             http_response_code(409);
             echo json_encode(["message" => "Update failed due to duplicate entry (e.g., smart_card_number)."]);
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

    // Optional: Check for dependencies in other tables before deleting if necessary
    // e.g., Check if vehicle_id exists in 'cargos' table

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
            http_response_code(200); // Some use 204 No Content
            echo json_encode(["message" => "Record deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Record not found for delete."]);
        }
    } else {
        // Handle potential foreign key constraint errors if applicable
        if ($conn->errno == 1451) { // Foreign key constraint fails
             http_response_code(409); // Conflict
             echo json_encode(["message" => "Cannot delete record because it is referenced by other data (e.g., in cargos table)."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting record: " . $stmt->error]);
        }
    }
    $stmt->close();
}
?> 