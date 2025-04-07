<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Log request details
$request_log = "REQUEST METHOD: " . $_SERVER['REQUEST_METHOD'] . "\n";
$request_log .= "REQUEST HEADERS: " . print_r(getallheaders(), true) . "\n";
$request_log .= "POST VARIABLES: " . print_r($_POST, true) . "\n";
$request_log .= "FILES VARIABLES: " . print_r($_FILES, true) . "\n";

// Write to error log
error_log($request_log);

// Define upload directory
$upload_dir = 'uploads/test/';

// Create uploads directory if it doesn't exist
if (!file_exists($upload_dir)) {
    if (!mkdir($upload_dir, 0777, true)) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create directory',
            'error' => error_get_last()
        ]);
        exit;
    }
}

// Response array
$response = [
    'success' => false,
    'message' => '',
    'file_path' => null,
    'debug_info' => []
];

// Add debug info
$response['debug_info']['server'] = $_SERVER;
$response['debug_info']['post'] = $_POST;
$response['debug_info']['files'] = $_FILES;

try {
    // Check if this is a POST request
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        $response['message'] = 'Only POST method is allowed';
        echo json_encode($response);
        exit;
    }

    // Check if file was uploaded
    if (!isset($_FILES['image'])) {
        $response['message'] = 'No file uploaded with key "image"';
        echo json_encode($response);
        exit;
    }

    // Check for upload errors
    if ($_FILES['image']['error'] != UPLOAD_ERR_OK) {
        $upload_errors = [
            UPLOAD_ERR_INI_SIZE => 'The uploaded file exceeds the upload_max_filesize directive in php.ini',
            UPLOAD_ERR_FORM_SIZE => 'The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form',
            UPLOAD_ERR_PARTIAL => 'The uploaded file was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing a temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'A PHP extension stopped the file upload'
        ];
        
        $error_code = $_FILES['image']['error'];
        $error_message = isset($upload_errors[$error_code]) ? $upload_errors[$error_code] : 'Unknown upload error';
        
        $response['message'] = 'File upload failed: ' . $error_message;
        $response['error_code'] = $error_code;
        echo json_encode($response);
        exit;
    }

    // Get file information
    $file_tmp_path = $_FILES['image']['tmp_name'];
    $file_name = $_FILES['image']['name'];
    $file_size = $_FILES['image']['size'];
    $file_type = $_FILES['image']['type'];
    
    // Create a new filename
    $new_file_name = 'test_' . time() . '_' . str_replace(' ', '_', $file_name);
    $file_path = $upload_dir . $new_file_name;

    // Move the file
    if (!move_uploaded_file($file_tmp_path, $file_path)) {
        $response['message'] = 'Error moving uploaded file';
        $response['error'] = error_get_last();
        echo json_encode($response);
        exit;
    }

    // Build the file URL
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
    $host = $_SERVER['HTTP_HOST'];
    $file_url = $protocol . $host . dirname($_SERVER['REQUEST_URI']) . '/' . $file_path;

    // Success response
    $response['success'] = true;
    $response['message'] = 'File uploaded successfully';
    $response['file_path'] = $file_url;
    $response['file_name'] = $new_file_name;
    $response['file_size'] = $file_size;
    $response['file_type'] = $file_type;

} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Exception: ' . $e->getMessage();
    $response['trace'] = $e->getTraceAsString();
}

// Return JSON response
echo json_encode($response);
?> 