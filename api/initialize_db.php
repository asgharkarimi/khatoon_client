<?php
// Include database connection
require_once 'db_connect.php';

// Initialize the database schema
$result = initializeDatabase($conn, __DIR__ . '/schema.sql');

if ($result) {
    echo "Database schema initialized successfully!";
    
    // Insert default payment types if they don't exist
    $checkPaymentTypes = "SELECT COUNT(*) as count FROM payment_types";
    $result = $conn->query($checkPaymentTypes);
    $row = $result->fetch_assoc();
    
    if ($row['count'] == 0) {
        // Insert default payment types
        $insertPaymentTypes = "INSERT INTO payment_types (name) VALUES 
            ('Not Received'), 
            ('Cash'), 
            ('Check'), 
            ('Card Transfer'), 
            ('Bank Deposit')";
        
        if ($conn->query($insertPaymentTypes)) {
            echo "<br>Default payment types inserted successfully!";
        } else {
            echo "<br>Error inserting default payment types: " . $conn->error;
        }
    } else {
        echo "<br>Default payment types already exist.";
    }
} else {
    echo "Error initializing database schema.";
}

// Close the connection
closeDbConnection($conn);
?> 