<?php
// send_fcm_notification.php
// Usage: POST title, body, topic (optional, default: 'all')

$serverKey = 'YOUR_SERVER_KEY_HERE'; // Replace with your Firebase Cloud Messaging server key

$title = $_POST['title'] ?? 'New News!';
$body = $_POST['body'] ?? 'Check out the latest news.';
$topic = $_POST['topic'] ?? 'all'; // Default topic is 'all'

$notification = [
    'title' => $title,
    'body' => $body,
    'sound' => 'default',
];

$data = [
    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
    'status' => 'done',
];

$fields = [
    'to' => '/topics/' . $topic,
    'notification' => $notification,
    'data' => $data,
];

$headers = [
    'Authorization: key=' . $serverKey,
    'Content-Type: application/json',
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));

$result = curl_exec($ch);
if ($result === FALSE) {
    die('FCM Send Error: ' . curl_error($ch));
}
curl_close($ch);
echo $result;
