<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>
<title>Iambic, Are You?</title>
<link rel="stylesheet" href="/foundation/stylesheets/app.css"/>
<link rel="stylesheet" href="/css/font-awesome/css/font-awesome.min.css">
<script type="text/javascript" src="/scripts/vendor/jquery-2.0.3.js"></script>
<script src="/foundation/bower_components/foundation/js/vendor/custom.modernizr.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>


<style type="text/css">
.footer-bar{
	width: 100%;
	height: 32px;
	position: fixed;
	bottom: 0px;
	background-color: lightgray;
	z-index: 900;
}

#announcement {
    position: relative;
    /*padding-top: 25px;*/
    margin: 0;
    /*background: url(/assets/coverphoto_900x300.png) no-repeat center center scroll;*/
    background: url(/assets/web_banner.jpg) no-repeat center center scroll;
    -webkit-background-size: cover;
    -moz-background-size: cover;
    -o-background-size: cover;
    background-size: cover;
    height: 320px;
    border: 0;
    overflow: auto;
    /*background-color: #E5E5E5;*/
}

.center-wrap {
  position: relative;
  width: 100%;
}

.center-piece {
    position: relative;
    top:300px;
    margin: 0px auto;
    text-align: center;
    background: rgba(0, 0, 0, 0);
    z-index: 10;
}

.center-logo {
    position: relative;
    top:-250px;
    right:5px;
    margin: 0px auto;
    text-align: center;
    background: rgba(0, 0, 0, 0);
    z-index: 50;
}

#game-name{
	position: relative;
	top:-275px;
}

#badge{
	position: relative;
	right: 12px;
}

</style>

</head>

<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-60684498-1', 'auto');
  ga('send', 'pageview');

</script>

<body>


<div id="announcement">

</div>

<div class='center-logo'>
	<div class="center-wrap">
	<img src="/assets/shakespeare.png" width="400">
	</div>
</div>
	
<div id="game-name" class="small-12 small-centered medium-8 medium-centered columns text-center">
	<br>
	<h1 class="subheader"><b>iambic, are you?</b></h1>
	<br>
	<br>
	<div id="badge">
		<object data="/assets/Download_on_the_App_Store_Badge_US-UK_135x40.svg" 
			type="image/svg+xml"  class="logo"> 
		</object>
	</div>

</div>



<div class="footer-bar">
	<h6 class="subheader"><a href="http://migacollabs.com">Miga Col.labs LLC</a> - <a href="/assets/privacypolicy.html">Privacy Policy</a></h6>
</div>



<script src="/foundation/bower_components/foundation/js/foundation.js"></script>




<script>
	$(document).foundation();
</script>



</body>


</html>