<?php

session_start();
require_once('config.php');
require_once('twitteroauth/twitteroauth.php');

$oUser = null; // object user

/* Get user access tokens out of the session. */
if (isset($_SESSION['access_token'])) {
	$access_token = $_SESSION['access_token'];

	/* Create a TwitterOauth object with consumer/user tokens. */
	$connection = new TwitterOAuth(CONSUMER_KEY, CONSUMER_SECRET, $access_token['oauth_token'], $access_token['oauth_token_secret']);

	/* If method is set change API call made. Test is called by default. */
	$oUser = $connection->get('account/verify_credentials');

	if (property_exists($oUser, "errors"))
		$oUser = null;
}

// by this time, if $oUser is an object, the user is signed in to its twitter accout.

$usersById = json_decode( file_get_contents( $twitterUsersPath ), true );
foreach ($usersById as $id => $user) {
	$usersById[$id]["id"] = $id;
}

// check if twitter user is know :
$aUser = null; // array user

if ($oUser !== null) {
	$userId = $oUser->id_str;

	if (!isset($usersById[$userId])) {
		$usersById[$userId] = array(
			"name" => "",
			"screen_name" => "", // @ScreenName
			"secret_key" => "",
		);
	}

	$aUser = $usersById[$userId];

	// update the file when users change their name or screen name (or when it's the first time the user connects)
	if ($aUser["name"] != $oUser->name || $aUser["screen_name"] != $oUser->screen_name) {
		
		$aUser["name"] = $oUser->name;
		$aUser["screen_name"] = $oUser->screen_name;

		if ($aUser["secret_key"] == "") {
			$key = md5( time() . $oUser->screen_name . mt_rand(-999999,999999) );
			$oUser->secret_key = $key;
			$aUser["secret_key"] = $key;
		}

		file_put_contents($twitterUsersPath, json_encode($usersById));
	}
} 

$levelData = json_decode( file_get_contents( "levels.json" ), true );
?>
<!DOCTYPE html>
<html>
  <head>
	<meta charset="utf-8" />
	<meta property="og:image" content="Screenshot.png" />
	<title>CraftStudio Web player</title>
	<style>
	  *{font-family:'Source Sans Pro',sans-serif;-moz-box-sizing:border-box;box-sizing:border-box;text-align: center}
	  body{text-align:center;background:#f2f0ee;margin:0;color:#67615d;cursor:default;-moz-user-select:none;-webkit-user-select:none;user-select:none}
	  a{text-decoration:none;color:#1d7097;cursor:pointer;}
	  a img{border:none}
	  a:hover{color:#0a2532}
	  
	  #Page{width:1002px;padding:20px;background:#f7f6f5;position:relative;z-index:2;margin:0 auto;border-left:1px solid #c0b6ae;border-right:1px solid #c0b6ae;min-height:800px;cursor:auto;-moz-user-select:auto;-webkit-user-select:auto;user-select:auto}
	  #Page p,#Page ul{margin:20px 80px;text-align:justify;font-size:20px}
	  
	  #PlayerIframe{margin:0 auto;border:0;padding:0;margin:0}
	  
	  #AssetTopBar{font-weight:bold;font-size:18px;margin:10px 60px;text-align:left;}
	  #AssetTopBar a{color:#c0b5ae}
	  #AssetTopBar a:hover{color:#67615d}
	  #AssetMadeWithCraftStudio{text-align:right;display:block;float:right}
	  #AssetMadeWithCraftStudio:before{vertical-align:middle;content:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAN1wAADdcBQiibeAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAFrSURBVDiN3ZVNSwJRFIbfY9eS6MtBoigUzcAWFa0jdBu1iVqEPyCK/sLMYpjxJ4TQNoiKok3RtojWQZsEQ2kIpBZiH5t06rRSJtOZsVx1lofnPJx7zr1cYma0M4QbSFGUDTBvASA7TtN18rgRapqWBtEmAMfjuBK2InUtrEmZt+0YAQBElAQw3oTJMvMuAMiyHCKiVTcdNpMhGg77AUBVVQ8R7QDod+ywGhenx42YwPnJYcIsl2dBNGfJP4N5D0RrsGzf1Qyfii9JEKm1BNElA9NaKrVevyhH4XvF7MzkjGUAHQA+wCwLIRK6rt8DP7fveLFvMnfzFdOUvEIUY5Hg0aDUd5VYXPm0MpqmpRVFgaMw91CYKL2+zQz09lxPxaJnXV5RBhCPhEKTecN4ZOYDq9RR2O3zlcaCI/uR0eFbaz5vGBIAqVGNrXAo4C8AKNgx9dHSS/kfwm8zjC8s/VlY7TD7i9qGNdTuL+AL2p5yg/wm62IAAAAASUVORK5CYII=);margin-right:5px}
	  #AssetGoFullscreen{text-align:left}
	  #AssetGoFullscreen:before{vertical-align:middle;content:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAN1wAADdcBQiibeAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAADOSURBVDiN1ZRNEoMwCIUfmd7LHkzGOHgxT/a6aG3zA+oim7IzgQ8kD4QkRtoDAHSefarIama5PFLVDHLx3G3bJIWpHBgAmFmGyBqF+UCR3YM10P0+kJxUNQR+fnu6BpZZycWDdj1sKk3FxWpmz6o/DdSBdTGpuMjAddMbWBcjkQ6PylzZOOffPKOFHetwNFBVc/TKZ5JKh1MbBHIJX9mR1PH9rrBwOJvVyoIYIflbDiJ7NQF3lkMR0y+HCxjg6LQZwX9bDjX03nJobPikvABpL7k3fb4xGwAAAABJRU5ErkJggg==);margin-right:5px}
	  
	  #AssetMetadata{font-size:24px;font-weight:bold;color:#c0b5ae;margin:0 60px 60px 60px}
	  #AssetInfo{float:left;}
	  #AssetInfo .AssetName{display:inline-block;color:#67615d;font-size:36px;max-width:350px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
	  #AssetInfo .AssetType{display:inline-block;text-transform:uppercase}
	  #AssetAuthorInfo{float:right;}
	  #AssetAuthorInfo .AssetBy{display:inline-block;text-transform:uppercase}
	  #AssetAuthorInfo .AssetAuthor{display:inline-block;color:#67615d;font-size:36px;max-width:300px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
	  #AssetDescription{clear:both}
	</style>
	<script>
	  function goFullscreen()
	  {
		elem = document.getElementById('PlayerIframe');
		elem.requestFullscreen = elem.requestFullscreen || elem.webkitRequestFullscreen || elem.mozRequestFullscreen || elem.mozRequestFullScreen;
		elem.requestFullscreen();
		elem.focus()
	  }

	  var G = null;

	  // called from the first callback of CSPlayer.RunGame() in player.html
	  function OnPlayerLoaded( g ) {
		G = g;
		
<?php if ($aUser): ?>
		// called from [Log In/Start] in the Lua code 
		G.str.JS.str.js_OnGameStarts = function() {
			console.log("js on start");
			G.str.JS.str.lua_SetPlayerData(
				'<?php echo $aUser["id"]; ?>',
				'<?php echo $aUser["name"]; ?>',
				'<?php echo $aUser["screen_name"]; ?>',
				'<?php echo $aUser["secret_key"]; ?>'
			);
		}
<?php endif; ?>        
	  } // end OnPlayerLoaded
	</script>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>

  </head>
  <body>
	<div id="Page">


	  <div id="AssetTopBar">
		<a id="AssetGoFullscreen" onclick="goFullscreen()">Go fullscreen</a>
		<a id="AssetMadeWithCraftStudio" href="http://craftstud.io/" target="_blank">Made with CraftStudio</a>
	  </div>
	  <iframe id="PlayerIframe" src="player.html" width="840" height="500"></iframe>
	  
	  <div id="AssetMetadata">
		<div id="AssetInfo">
		  <div class="AssetName">Game name</div>
		  <div class="AssetType">game</div>
		</div>
		<div id="AssetAuthorInfo">
		  <div class="AssetBy">by</div>
		  
		  <a class="AssetAuthor">Author</a>
		</div>
	  </div>
	  
	  <div id="AssetDescription">
		<p>(Game description)</p>
	  </div>

<?php if ($oUser): ?>
	You are connected as <a href="https://twitter.com/<?php echo $oUser->screen_name; ?>"><?php echo $oUser->name; ?></a>. <br>
	Your secret key is <?php echo $aUser["secret_key"]; ?>
<?php else: ?>
	<a href="redirect.php"><img src="images/lighter.png" alt="Sign in with Twitter"/></a>
<?php endif; ?>
	</div>
	<script type="text/javascript">
		$(document).ready( function() {
			// console.log("ready");
			
		} )
	</script>
  </body>
</html>