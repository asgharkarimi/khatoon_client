<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Log request details
error_log("Test upload request received: " . $_SERVER['REQUEST_METHOD']);
error_log("POST data: " . print_r($_POST, true));
error_log("FILES data: " . print_r($_FILES, true));

// Define upload directory
$upload_dir = 'uploads/';

// Create uploads directory if it doesn't exist
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
    error_log("Created upload directory: " . $upload_dir);
}

// Response array
$response = [
    'success' => false,
    'message' => '',
    'file_path' => null
];

try {
    // Check if file was uploaded successfully
    if (!isset($_FILES['image']) || $_FILES['image']['error'] != UPLOAD_ERR_OK) {
        $error_code = isset($_FILES['image']) ? $_FILES['image']['error'] : 'No file uploaded';
        throw new Exception('File upload failed with error code: ' . $error_code);
    }

    // Get file information
    $file_tmp_path = $_FILES['image']['tmp_name'];
    $file_name = $_FILES['image']['name'];
    $file_size = $_FILES['image']['size'];
    $file_type = $_FILES['image']['type'];
    
    // Optional test field parameter
    $test_field = isset($_POST['test_field']) ? $_POST['test_field'] : 'No test field provided';
    error_log("Test field: " . $test_field);

    // Get file extension
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    error_log("File extension: " . $file_ext);

    // Validate file extension
    $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif'];
    if (!in_array($file_ext, $allowed_extensions)) {
        throw new Exception('Invalid file type. Only JPG, JPEG, PNG, and GIF files are allowed.');
    }

    // Validate file size (max 5MB)
    $max_file_size = 5 * 1024 * 1024; // 5MB in bytes
    if ($file_size > $max_file_size) {
        throw new Exception('File size exceeds the maximum limit of 5MB.');
    }

    // Create a unique file name
    $new_file_name = 'test_' . time() . '_' . uniqid() . '.' . $file_ext;
    $file_path = $upload_dir . $new_file_name;
    error_log("Saving file to: " . $file_path);

    // Move uploaded file to destination directory
    if (!move_uploaded_file($file_tmp_path, $file_path)) {
        $error = error_get_last();
        throw new Exception('Failed to move uploaded file to destination directory. Error: ' . ($error ? $error['message'] : 'Unknown error'));
    }

    // Generate full URL for the uploaded file
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
    $host = $_SERVER['HTTP_HOST'];
    $file_url = $protocol . $host . dirname($_SERVER['REQUEST_URI']) . '/' . $file_path;
    error_log("File URL: " . $file_url);

    // Set success response
    $response['success'] = true;
    $response['message'] = 'Test file uploaded successfully. Test field: ' . $test_field;
    $response['file_path'] = $file_url;
    
    // Log successful upload
    error_log("Test file uploaded successfully: " . $file_path);

} catch (Exception $e) {
    // Set error response
    $response['success'] = false;
    $response['message'] = $e->getMessage();
    error_log("Test upload error: " . $e->getMessage());
}

// Return JSON response
echo json_encode($response);
?> 