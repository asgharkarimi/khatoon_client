<?php
include 'db_connect.php'; // Establishes $conn

$method = $_SERVER['REQUEST_METHOD'];
$table = 'cargos';

// Basic Input Sanitization Helper
function sanitize($conn, $data) {
    if ($data === null) return null;
    return mysqli_real_escape_string($conn, htmlspecialchars(strip_tags($data)));
}

// Helper function to check if a foreign key exists (Copy from drivers.php or include shared functions file)
function checkForeignKeyExists($conn, $foreignTable, $foreignId) {
    if ($foreignId === null || $foreignId === false || $foreignId <= 0) return false; // Foreign keys must be positive integers
    $checkSql = "SELECT id FROM `$foreignTable` WHERE id = ?"; // Use backticks for table names
    $checkStmt = $conn->prepare($checkSql);
     if (!$checkStmt) {
        error_log("Error preparing foreign key check statement for $foreignTable: " . $conn->error);
        return false; // Assume invalid on error
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

// Helper to get default payment status ID (e.g., 'Not Received')
function getDefaultPaymentStatusId($conn) {
    $sql = "SELECT id FROM payment_types WHERE name = 'Not Received' LIMIT 1";
    $result = $conn->query($sql);
    if ($result && $row = $result->fetch_assoc()) {
        return (int)$row['id'];
    }
    // Fallback or error - maybe insert 'Not Received' if it doesn't exist?
    error_log("Default payment type 'Not Received' not found. Please ensure it exists.");
    // Fallback to a low ID like 1, assuming it might be the default, but this is risky.
    // Or return null and make customer_payment_status_id nullable or handle error upstream.
    return 1; // Or null if the column allows it and you handle the error
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

    // Updated base columns to include the new fields
    $baseColumns = "c.id, c.vehicle_id, c.driver_id, c.cargo_type_id, c.customer_id, c.shipping_company_id, c.selling_company_id, c.origin, c.destination, c.loading_date, c.unloading_date, c.weight_tonnes, c.price_per_tonne, c.transport_cost_per_tonne, c.customer_payment_status_id, c.seller_payment_status, c.waybill_amount, c.waybill_image, c.customer_bank_account_id";

    // Join with related tables to get names/details instead of just IDs
    $joins = "
        LEFT JOIN vehicles v ON c.vehicle_id = v.id
        LEFT JOIN drivers d ON c.driver_id = d.id
        LEFT JOIN cargo_types ct ON c.cargo_type_id = ct.id
        LEFT JOIN customers cust ON c.customer_id = cust.id
        LEFT JOIN shipping_companies sc ON c.shipping_company_id = sc.id
        LEFT JOIN cargo_selling_companies csc ON c.selling_company_id = csc.id
        LEFT JOIN payment_types pt ON c.customer_payment_status_id = pt.id
        LEFT JOIN bank_accounts ba ON c.customer_bank_account_id = ba.id
    ";
    
    // Updated joined columns to include driver salary percentage and added calculated field for driver income
    $joinedColumns = ", v.name as vehicle_name, v.smart_card_number as vehicle_smart_card, CONCAT(d.first_name, ' ', d.last_name) as driver_name, d.phone_number as driver_phone, d.salary_percentage as driver_salary_percentage, ct.name as cargo_type_name, CONCAT(cust.first_name, ' ', cust.last_name) as customer_name, cust.phone_number as customer_phone, sc.name as shipping_company_name, csc.name as selling_company_name, pt.name as customer_payment_status_name, CONCAT(ba.bank_name, ' - ', ba.account_holder_name) as customer_bank_account_name";

    // Add calculated field for driver income
    $calculatedFields = ", CASE 
        WHEN d.salary_percentage IS NOT NULL THEN
            CASE 
                WHEN c.waybill_amount IS NOT NULL AND c.waybill_amount > 0 
                THEN ((c.weight_tonnes * c.transport_cost_per_tonne) - c.waybill_amount) * (d.salary_percentage / 100)
                ELSE (c.weight_tonnes * c.transport_cost_per_tonne * d.salary_percentage / 100)
            END
        ELSE NULL
    END as driver_income";
    
    // Add calculated field for total payment amount (weight * price per tonne)
    $calculatedFields .= ", (c.weight_tonnes * c.price_per_tonne) as total_payment_amount";

    if ($id) {
        // Get single record with details
        $sql = "SELECT $baseColumns $joinedColumns $calculatedFields FROM $table c $joins WHERE c.id = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($data = $result->fetch_assoc()) {
                // Convert boolean to actual boolean if needed by client
                 $data['seller_payment_status'] = (bool)$data['seller_payment_status'];
                http_response_code(200);
                echo json_encode($data);
            } else {
                http_response_code(404);
                echo json_encode(["message" => "Cargo not found."]);
            }
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error executing statement: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        // Get all records with details (consider pagination)
         $sql = "SELECT $baseColumns $joinedColumns $calculatedFields FROM $table c $joins ORDER BY c.loading_date DESC, c.id DESC"; // Example order
        $result = $conn->query($sql);
        if ($result) {
            $allData = [];
            while($row = $result->fetch_assoc()){
                 $row['seller_payment_status'] = (bool)$row['seller_payment_status'];
                 $allData[] = $row;
            }
            http_response_code(200);
            echo json_encode($allData);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error retrieving cargos: " . $conn->error]);
        }
    }
}

// CREATE (POST)
function handlePost($conn, $table) {
    $data = json_decode(file_get_contents('php://input'), true);

    // Required fields validation (adjust as per your business logic)
    $required = [
        'vehicle_id', 'driver_id', 'cargo_type_id', 'customer_id',
        'shipping_company_id', 'selling_company_id', 'origin', 'destination',
        'weight_tonnes', 'price_per_tonne', 'transport_cost_per_tonne'
        // customer_payment_status_id will default, seller_payment_status defaults in DB
    ];
    foreach ($required as $field) {
        // Use array_key_exists for numeric fields that could be 0
        if (!array_key_exists($field, $data) || $data[$field] === '' || $data[$field] === null) {
             // Exception for potentially zero values if they are valid (e.g., weight?) adjust check if needed.
             if (!($field == 'weight_tonnes' && $data[$field] === 0)) {
                http_response_code(400);
                echo json_encode(["message" => "Missing required field: " . $field]);
                return;
             }
        }
    }

     // Validate Foreign Keys exist
     $foreignKeys = [
         'vehicles' => $data['vehicle_id'],
         'drivers' => $data['driver_id'],
         'cargo_types' => $data['cargo_type_id'],
         'customers' => $data['customer_id'],
         'shipping_companies' => $data['shipping_company_id'],
         'cargo_selling_companies' => $data['selling_company_id']
     ];
     foreach ($foreignKeys as $fkTable => $fkId) {
        if (!checkForeignKeyExists($conn, $fkTable, $fkId)) {
             http_response_code(400);
             echo json_encode(["message" => "Invalid ID for $fkTable: Record does not exist."]);
             return;
         }
     }

    // Sanitize inputs
    $vehicle_id = filter_var($data['vehicle_id'], FILTER_VALIDATE_INT);
    $driver_id = filter_var($data['driver_id'], FILTER_VALIDATE_INT);
    $cargo_type_id = filter_var($data['cargo_type_id'], FILTER_VALIDATE_INT);
    $customer_id = filter_var($data['customer_id'], FILTER_VALIDATE_INT);
    $shipping_company_id = filter_var($data['shipping_company_id'], FILTER_VALIDATE_INT);
    $selling_company_id = filter_var($data['selling_company_id'], FILTER_VALIDATE_INT);
    $origin = sanitize($conn, $data['origin']);
    $destination = sanitize($conn, $data['destination']);
    $loading_date = isset($data['loading_date']) ? sanitize($conn, $data['loading_date']) : null; // Expect YYYY-MM-DD HH:MM:SS format ideally
    $unloading_date = isset($data['unloading_date']) ? sanitize($conn, $data['unloading_date']) : null;
    $weight_tonnes = filter_var($data['weight_tonnes'], FILTER_VALIDATE_FLOAT);
    $price_per_tonne = filter_var($data['price_per_tonne'], FILTER_VALIDATE_FLOAT);
    $transport_cost_per_tonne = filter_var($data['transport_cost_per_tonne'], FILTER_VALIDATE_FLOAT);
    $customer_payment_status_id = isset($data['customer_payment_status_id'])
                                  ? filter_var($data['customer_payment_status_id'], FILTER_VALIDATE_INT)
                                  : getDefaultPaymentStatusId($conn); // Default 'Not Received'
    $seller_payment_status = isset($data['seller_payment_status']) ? filter_var($data['seller_payment_status'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) : false; // Default false

    // Add the new fields to sanitization
    $waybill_amount = isset($data['waybill_amount']) ? filter_var($data['waybill_amount'], FILTER_VALIDATE_FLOAT, FILTER_NULL_ON_FAILURE) : null;
    $waybill_image = isset($data['waybill_image']) ? sanitize($conn, $data['waybill_image']) : null;
    $customer_bank_account_id = isset($data['customer_bank_account_id']) ? filter_var($data['customer_bank_account_id'], FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE) : null;
    
    // Validate customer_bank_account_id if provided
    if ($customer_bank_account_id !== null && !checkForeignKeyExists($conn, 'bank_accounts', $customer_bank_account_id)) {
        http_response_code(400);
        echo json_encode(["message" => "Invalid customer_bank_account_id: Bank account does not exist."]);
        return;
    }
    
    // Validate payment status ID if provided
    if (isset($data['customer_payment_status_id']) && !checkForeignKeyExists($conn, 'payment_types', $customer_payment_status_id)) {
        http_response_code(400);
        echo json_encode(["message" => "Invalid customer_payment_status_id: Payment type does not exist."]);
        return;
    }
    // Further validation e.g., dates format, numeric ranges if needed


    $sql = "INSERT INTO $table (vehicle_id, driver_id, cargo_type_id, customer_id, shipping_company_id, selling_company_id, origin, destination, loading_date, unloading_date, weight_tonnes, price_per_tonne, transport_cost_per_tonne, customer_payment_status_id, seller_payment_status, waybill_amount, waybill_image, customer_bank_account_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($sql);
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    // Update types and bind_param
    $types = "iiiiiiisssddiiidsi"; // Added 'dsi' for waybill_amount (double), waybill_image (string), customer_bank_account_id (integer)
    $stmt->bind_param($types,
        $vehicle_id, $driver_id, $cargo_type_id, $customer_id, $shipping_company_id,
        $selling_company_id, $origin, $destination, $loading_date, $unloading_date,
        $weight_tonnes, $price_per_tonne, $transport_cost_per_tonne,
        $customer_payment_status_id, $seller_payment_status, $waybill_amount,
        $waybill_image, $customer_bank_account_id
    );

    if ($stmt->execute()) {
        $newId = $conn->insert_id;
        http_response_code(201);
        echo json_encode(["message" => "Cargo created successfully.", "id" => $newId]);
    } else {
         http_response_code(500);
         echo json_encode(["message" => "Error creating cargo: " . $stmt->error]);
         error_log("Cargo Creation Error: " . $stmt->error); // Log detailed error
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
         'vehicle_id' => 'vehicles', 'driver_id' => 'drivers', 'cargo_type_id' => 'cargo_types',
         'customer_id' => 'customers', 'shipping_company_id' => 'shipping_companies',
         'selling_company_id' => 'cargo_selling_companies', 'customer_payment_status_id' => 'payment_types',
         'customer_bank_account_id' => 'bank_accounts'
    ];

    foreach($data as $key => $value) {
        $sanitizedValue = null;
        $type = '';

        // Skip ID field
        if ($key === 'id') continue;

        // Check foreign keys first
         if (array_key_exists($key, $foreignKeyChecks)) {
             $fkTable = $foreignKeyChecks[$key];
             $fkId = filter_var($value, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
             if ($fkId !== null && $fkId !== false) { // Only check if ID is valid integer
                  if (!checkForeignKeyExists($conn, $fkTable, $fkId)) {
                     http_response_code(400);
                     echo json_encode(["message" => "Invalid ID for $key: Record in $fkTable does not exist."]);
                     return;
                  }
                  $sanitizedValue = $fkId;
                  $type = 'i';
             } else if ($value === null) { // Allow setting FK to null if column allows
                  $sanitizedValue = null;
                  $type = 'i'; // Still bind as integer for null
             } else {
                  http_response_code(400); echo json_encode(["message" => "Invalid non-integer ID provided for $key."]); return;
             }
         }
        // Handle specific types
        else if (in_array($key, ['weight_tonnes', 'price_per_tonne', 'transport_cost_per_tonne'])) {
             $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT, FILTER_NULL_ON_FAILURE);
             $type = 'd';
         } else if ($key === 'seller_payment_status') {
             $sanitizedValue = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
             $type = 'i'; // Bind boolean as integer (0 or 1)
         } else if (in_array($key, ['loading_date', 'unloading_date'])) {
             // Add date validation if needed: e.g., DateTime::createFromFormat('Y-m-d H:i:s', $value)
             $sanitizedValue = sanitize($conn, $value); // Assume correct format or null
             $type = 's';
         } else if (in_array($key, ['origin', 'destination'])) {
              $sanitizedValue = sanitize($conn, $value);
              $type = 's';
         }
        // Handle the new fields
        else if ($key === 'waybill_amount') {
            $sanitizedValue = filter_var($value, FILTER_VALIDATE_FLOAT, FILTER_NULL_ON_FAILURE);
            $type = 'd';
        } else if ($key === 'waybill_image') {
            $sanitizedValue = sanitize($conn, $value);
            $type = 's';
        }
         // Add other specific field handlers here if necessary

         // If a type was determined, add to update query
         if ($type) {
             $setClauses[] = "`$key` = ?"; // Use backticks
             $params[] = $sanitizedValue;
             $types .= $type;
         } else {
             error_log("Skipping update for unhandled or invalid field: " . $key);
         }
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
     if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }

    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Cargo updated successfully."]);
        } else {
             $checkStmt = $conn->prepare("SELECT id FROM $table WHERE id = ?");
             $checkStmt->bind_param("i", $id);
             $checkStmt->execute();
             $checkResult = $checkStmt->get_result();
             if ($checkResult->num_rows === 0) {
                  http_response_code(404);
                  echo json_encode(["message" => "Cargo not found for update."]);
             } else {
                  http_response_code(200);
                  echo json_encode(["message" => "Cargo found, but no changes were made (or invalid data type resulted in no change)."]);
             }
             $checkStmt->close();
        }
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error updating cargo: " . $stmt->error]);
        error_log("Cargo Update Error: " . $stmt->error); // Log detailed error

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

     // IMPORTANT: Check dependencies before deleting a cargo
     // A cargo might be referenced in payments, receivables, payment_management, expenses
     $dependencies = ['payments', 'receivables', 'payment_management', 'expenses'];
     foreach ($dependencies as $depTable) {
         $checkSql = "SELECT id FROM `$depTable` WHERE cargo_id = ? LIMIT 1";
         $checkStmt = $conn->prepare($checkSql);
         if ($checkStmt) {
             $checkStmt->bind_param("i", $id);
             if ($checkStmt->execute()) {
                 $checkResult = $checkStmt->get_result();
                 if ($checkResult->num_rows > 0) {
                     http_response_code(409); // Conflict
                     echo json_encode(["message" => "Cannot delete cargo because it is referenced in the '$depTable' table. Delete related records first."]);
                     $checkStmt->close();
                     return; // Stop deletion
                 }
             } else {
                  error_log("Error checking dependency in $depTable for cargo $id: " . $checkStmt->error);
                  // Decide if you want to proceed or stop on error
             }
             $checkStmt->close();
         } else {
              error_log("Error preparing dependency check for $depTable: " . $conn->error);
              // Decide if you want to proceed or stop on error
         }
     }


    $sql = "DELETE FROM $table WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) { http_response_code(500); echo json_encode(["message" => "Error preparing statement: " . $conn->error]); return; }
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200); // Or 204 No Content
            echo json_encode(["message" => "Cargo deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Cargo not found for delete."]);
        }
    } else {
        // This specific error code might not be hit due to manual checks above, but keep for robustness
        if ($conn->errno == 1451) {
             http_response_code(409);
             echo json_encode(["message" => "Cannot delete cargo due to foreign key constraints (should have been caught by dependency check)."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting cargo: " . $stmt->error]);
            error_log("Cargo Deletion Error: " . $stmt->error);
        }
    }
    $stmt->close();
}
?> 