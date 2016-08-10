<?php
require_once('config.php');

$levelData = json_decode( file_get_contents( "levels.json" ), true );
$saveLevelData = false;
$response = array();
$structureSize = 3; // same as "Game.structureSize" in game

if (!empty($_GET)) {
    
    if (isset($_GET["getnextlevelid"])) {
        $response["nextLevelId"] = $levelData["nextLevelId"]++;
        $saveLevelData = true;
    }

    if (isset($_GET["getlevels"])) {
        $response["levels"] = $levelData["levels"];
    }

    if (isset($_GET["getplayerdata"])) {
        $secret_key = $_GET["getplayerdata"];
        $usersById = json_decode( file_get_contents( $twitterUsersPath ), true );
        foreach ($usersById as $id => $user) {
            if ($user["secret_key"] == $secret_key) {
                $response = $user;
                $response["id"] = $id;
                break;
            }
        }

        if (empty($response)) {
            $response["error"] = "Secret key not found !";
        }
    }

    $response["method"] = "GET"; // 09/08/14 put at the end of the block so that if(empty($response)) actually returns true no player data has been found
}

if (!empty($_POST)) {
    if (isset($_POST["action"]) && $_POST["action"] == "publishlevel") {
        $webLevel = $_POST;
        $level = array(
            "name" => $webLevel["name"],
            "creatorId" => $webLevel["creatorId"],
            "creatorName" => $webLevel["creatorName"],
            "creationTimestamp" => $webLevel["creationTimestamp"],
            "silhouettes" => array(array(),array()),
            "structureData" => array(), // block ids by location
        );

        // reconstruct silhouettes data
        for ($i=0; $i < 2; $i++) {
            $luaI = $i+1;
            for ($j=0; $j < 7; $j++) {
                $luaJ = $j+1;

                if (isset($webLevel["s".$luaI."l".$luaJ]))
                    $level["silhouettes"][$i][$j] = $webLevel["s".$luaI."l".$luaJ];
            }
        }

        // reconstruct structure data
        for ($x=-$structureSize; $x <= $structureSize; $x++) { 
            for ($y=-$structureSize; $y <= $structureSize; $y++) { 
                for ($z=-$structureSize; $z <= $structureSize; $z++) { 
                    if (isset($webLevel[$x."_".$y."_".$z])) {
                        $level["structureData"][$x."_".$y."_".$z] = $webLevel[$x."_".$y."_".$z];
                    }
                }
            }
        }

        if (isset($webLevel["id"])) {
            $level["id"] = $webLevel["id"];
            foreach ($levelData["levels"] as $i => $_level) {
                if ($_level["id"] == $level["id"]) {
                    $levelData["levels"][$i] = $level;
                    break;
                }
            }
            $response["isNewEntry"] = false;

        } else {
            $level["id"] = $levelData["nextLevelId"]++;
            $levelData["levels"][] = $level;            
            $response["isNewEntry"] = true;
        }

        $response["id"] = $level["id"];
        $saveLevelData = true;
    }

    $response["method"] = "POST";
}


if ($saveLevelData) {
    file_put_contents( "levels.json", json_encode( $levelData ) );
}

if (empty($response)) {
    $response["error"] = "Empty response, probably due to a bad resquest.";
}
if (!empty($response)) {
    // $response["error"] = "Empty response, probably due to a bad resquest.";
    // $response["GET"] = $_GET;
    echo json_encode( $response );
}
