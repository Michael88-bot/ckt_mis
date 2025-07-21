<?php
// send_fcm_notification_v1.php
// Usage: POST title, body, topic (optional, default: 'all')
// Requires: composer require google/auth

require __DIR__ . '/vendor/autoload.php';

use Google\Auth\Credentials\ServiceAccountCredentials;

$serviceAccountFile = __DIR__ . '/ckt-mis-4f57f-860f61b2a66e.json'; // Path to your downloaded JSON key
$projectId = 'ckt-mis-4f57f';

$title = $_POST['title'] ?? 'New News!';
$body = $_POST['body'] ?? 'Check out the latest news.';
$topic = $_POST['topic'] ?? 'all';

// Get OAuth2 access token using ServiceAccountCredentials (recommended)
$scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
$credentials = new ServiceAccountCredentials($scopes, $serviceAccountFile);
$tokenArray = $credentials->fetchAuthToken();
if (!isset($tokenArray['access_token'])) {
    die('Error: Unable to fetch access token.');
}
$token = $tokenArray['access_token'];

// Prepare notification
$message = [
    'message' => [
        'topic' => $topic,
        'notification' => [
            'title' => $title,
            'body' => $body,
        ],
        'data' => [
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'status' => 'done',
        ],
    ],
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "https://fcm.googleapis.com/v1/projects/$projectId/messages:send");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $token",
    'Content-Type: application/json',
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
$result = curl_exec($ch);
if ($result === FALSE) {
    error_log('FCM Send Error: ' . curl_error($ch));
    die('FCM Send Error: ' . curl_error($ch));
}
curl_close($ch);
echo $result;
