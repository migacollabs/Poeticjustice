<!DOCTYPE HTML>

<html>
	<head>
		<title>
			JWPlayer Reponsive Video
		</title>
		<script type="text/javascript" src="/player/jwplayer.js"></script>
		<style type="text/css">
			html, body {
				height: 99%;
				width: 100%;
				padding: 0;
				margin: 0;
			}
			#player {
				height: 100%;
				width: 100%;
				padding: 0;
			}
		</style>
	</head>
	<body>
	<div id="player">
	</div>
		<script type="text/javascript">
			jwplayer("player").setup({
				file: "${v}",
				height: "100%",
				width: "100%",
				stretching: "exactfit",
                aspectratio: "16:9"
			});
		</script>
	</body>
</html>
