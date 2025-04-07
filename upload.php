<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Define upload directory
$upload_dir = 'uploads/';

// Create uploads directory if it doesn't exist
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
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
        throw new Exception('File upload failed with error code: ' . $_FILES['image']['error']);
    }

    // Get file information
    $file_tmp_path = $_FILES['image']['tmp_name'];
    $file_name = $_FILES['image']['name'];
    $file_size = $_FILES['image']['size'];
    $file_type = $_FILES['image']['type'];
    
    // Optional image type parameter
    $image_type = isset($_POST['image_type']) ? $_POST['image_type'] : 'unknown';

    // Get file extension
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

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
    $new_file_name = time() . '_' . $image_type . '_' . uniqid() . '.' . $file_ext;
    $file_path = $upload_dir . $new_file_name;

    // Move uploaded file to destination directory
    if (!move_uploaded_file($file_tmp_path, $file_path)) {
        throw new Exception('Failed to move uploaded file to destination directory.');
    }

    // Generate full URL for the uploaded file
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
    $host = $_SERVER['HTTP_HOST'];
    $file_url = $protocol . $host . dirname($_SERVER['REQUEST_URI']) . '/' . $file_path;

    // Set success response
    $response['success'] = true;
    $response['message'] = 'File uploaded successfully.';
    $response['file_path'] = $file_url;
    
    // Log successful upload
    error_log("File uploaded successfully: " . $file_path);

} catch (Exception $e) {
    // Set error response
    $response['success'] = false;
    $response['message'] = $e->getMessage();
    error_log("Upload error: " . $e->getMessage());
}

// Return JSON response
echo json_encode($response);
?> 