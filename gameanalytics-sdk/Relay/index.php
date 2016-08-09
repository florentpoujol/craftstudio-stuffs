<?php 

function _log( $data ) {
    if (gettype($data) != "string"){
        $data = json_encode($data);
    }

    file_put_contents("log-".time()."_".generateRandomString().".txt", $data);
    return $data;
}

function generateRandomString($length = 10) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, strlen($characters) - 1)];
    }
    return $randomString;
}

if (!empty($_POST)) {
    $game_key = "your-game-key"; 
    $secret_key = "your-secret-key"; 
    $url = "http://api.gameanalytics.com/1";

    $fieldsByCategory = array(
        "design" => array("event_id", "value", "area", "x", "y", "z"),
        "business" => array("event_id", "currency", "amount", "area", "x", "y", "z"),
        "error" => array("message", "severity", "area", "x", "y", "z"),
        "user" => array(
            "gender",
            "birth_year",
            "friend_count",
            "facebook_id",
            "googleplus_id",
            "ios_id",
            "android_id",
            "adtruth_id",
            "platform",
            "device",
            "os_major",
            "os_minor",
            "install_publisher",
            "install_site",
            "install_campaign",
            "install_adgroup",
            "install_ad",
            "install_keyword"
        )
    );

    $eventBundle = $_POST;
    $category = $eventBundle["category"];
    $events = array();
    
    for ($i=1; $i <= $eventBundle["eventsCount"]; $i++) { 
        $events[$i-1] = array(
            "user_id" => $eventBundle["user_id"],
            "session_id" => $eventBundle["session_id"],
            "build" => $eventBundle["build"]
        );       
        foreach ($fieldsByCategory[$category] as $fieldName) {
            if ( isset( $eventBundle[$fieldName."_$i"] ) ) 
                $events[$i-1][$fieldName] = $eventBundle[$fieldName."_$i"];
        }
    }
    
    $json_message = json_encode($events); 
    _log($json_message);
    
    // Note :
    // values of type number in the original event (in CraftStudio) are now of type string in $eventBundle and thus in $json_message
    // it doesn't seems to cause issue with GA (it doesn't return a "bad request" error) as long as the value can still be inferred to its desired type (integer or float) on their side
    
    $authorization = md5($json_message . "" . $secret_key); 

    $ch = curl_init(); 
    $request_url = $url ."/". $game_key ."/". $category;

    curl_setopt($ch, CURLOPT_URL, $request_url); 

    curl_setopt($ch, CURLOPT_POST, true); 
    curl_setopt($ch, CURLOPT_POSTFIELDS, $json_message); 
    curl_setopt($ch, CURLOPT_HTTPHEADER, array("Authorization: ".$authorization)); 
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true); 
    curl_setopt($ch, CURLOPT_TIMEOUT, 10); 

    $result = curl_exec($ch);
    // result is JSON with status ok if the request was successful or just a string with an error message

    $arrayResult = json_decode($result, true);
    if ($arrayResult === null) { // $result is an error
        $arrayResult = array(
            "error" => $result,
            "request_url" => $request_url,
            "json_message" => $json_message
        );
    }
    
    $arrayResult["events"] = $events;
    $arrayResult["category"] = $category;
    $result = json_encode( $arrayResult );

    echo $result;
    curl_close($ch); 
}