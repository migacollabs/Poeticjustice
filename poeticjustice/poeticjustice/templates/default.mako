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
    top:-200px;
    /*right:15px;*/
    margin: 0px auto;
    text-align: center;
    background: rgba(0, 0, 0, 0);
    z-index: 50;
}

#game-name{
	position: relative;
	top:-200px;
	/*right:-10px;*/
}

#badge{
	position: relative;
	/*right: 15px;*/
}

#left-taglines{
	position: absolute;
	left: 50px;
	top: 350px;
	z-index: 100;
}

#right-taglines{
	position: absolute;
	right: 50px;
	top: 350px;
	z-index: 100;
	text-align: right;
}

#tag-lines{
	top:-150px;
}

#features{
	top:-100px;
	background-color: lightgray;
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
	<img src="/assets/shakespeare.png" width="280">
	</div>
</div>

<!-- <div id="left-taglines">
	<h4 class="subheader">Tap a Topic<br>Start a Verse</h4>
	<p>&nbsp</p>
	<p>&nbsp</p>
	<h4 class="subheader">Play with just<br>Friends or Open it up<br>to the World!</h4>
</div> -->
	
<div id="game-name" class="small-12 small-centered medium-8 medium-centered columns text-center">
	<br>
	<h1 class="subheader">&nbsp&nbsp&nbsp<b>iambic, are you?</b></h1>
	<br>
	<br>
	<div id="badge">
		<object data="/assets/Download_on_the_App_Store_Badge_US-UK_135x40.svg" 
			type="image/svg+xml"  class="logo"> 
		</object>
	</div>
</div>

<!-- <div id="right-taglines">
	<h4 class="subheader">Everybody gets 4 lines<br>make them count!</h4>
	<p>&nbsp</p>
	<p>&nbsp</p>
	<h4 class="subheader">Be weird, be unique!<br>Get a Gold Star or your<br>rhymes were weak!</h4>
</div> -->

<div id="tag-lines" class="small-9 small-centered columns text-center">
	<h4 class="subheader">Tap a Topic, Start a Verse</h4>
	<h4 class="subheader">Everybody gets 4 lines, so make them count!</h4>
	<h4 class="subheader">Play with just Friends or Open it up to the World!</h4>
	<h4 class="subheader">Be weird, be unique! Get a Gold Star or your rhymes were weak!</h4>
</div>


<div id="features" class="small-9 small-centered columns text-center">
	<p>&nbsp</p>
	<h2 class="subheader">Join the fun in a turn-based social game of poetry</h2>
	<h3 class="subheader">Test your wit and knowledge against friends or make new friends</h3>
	<p>&nbsp</p>
	<h3 class="subheader">
	* Supports 2-4 players<br>
	* Player scores and favorites<br>
	* Supports unlimited friends<br>
	* Play against anyone or friends<br>
	* 64 topics for inspiration<br>
	* 7 levels<br>
	* Player avatars<br>
	* No passwords<br>
	* Supports multiple devices per player<br>
	* Supports creative usernames that can be changed at any time<br>
	* Learn about poetry<br>
	* Global and Friend leaderboards<br>
	* Share your creative writing skills<br>
	* Just have fun!!
	</h3>
	<p>&nbsp</p>
</div>





<div class="footer-bar">
	<h6 class="subheader">&nbsp<a href="http://migacollabs.com">Miga Col.labs LLC</a> - <a href="/assets/privacypolicy.html">Privacy Policy</a></h6>
</div>



<script src="/foundation/bower_components/foundation/js/foundation.js"></script>




<script>
	$(document).foundation();
</script>



</body>


</html>