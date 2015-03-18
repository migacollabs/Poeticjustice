<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>

<link rel="icon" 
      type="image/png" 
      href="/assets/favicon.png" />

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
    height: 150px;
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
    top:50px;
    margin: 0px auto;
    text-align: center;
    background: rgba(0, 0, 0, 0);
    z-index: 10;
}

.center-logo {
    position: relative;
    top:-100px;
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
  <a href="/"><img src="/assets/shakespeare.png" width="128"></a>
  </div>
</div>

<div class="small-12 small-centered columns text-center">
  <h5 class="subheader">&copy; 2015 Miga Col.labs LLC</h5>
</div>

<div class="small-12 small-centered columns text-center">
  <h5 class="subheader">Game design, Programming - Larry Johnson, Mat Mathews</h5>
  <h5 class="subheader">Marketing - Doran Bastin</h5>
  <h5 class="subheader">Creative Producer - Pamela Mathews</h5>
  <h5 class="subheader">Graphic Design - Jeff Churchill</h5>
</div>

<div class="small-6 small-centered columns text-center">
  <hr>
  <h5 class="subheader">Icon design - <a href="https://www.iconfinder.com/krasnoyarsk">Krasnoyarsk</a>, 
    <a href="http://www.doublejdesign.co.uk">Double-J Design</a></h5>
  <h6 class="subheader"><a href="http://creativecommons.org/licenses/by/3.0/">Icon License</a></h6>

</div>



<div class="footer-bar">
  <h6 class="subheader">&nbsp<a href="http://migacollabs.com">Miga Col.labs LLC</a> - 
    <a href="/assets/privacypolicy.html">Privacy Policy</a> - <a href="/credits">About</a></h6>
</div>


<script src="/foundation/bower_components/foundation/js/foundation.js"></script>




<script>
	$(document).foundation();
</script>



</body>


</html>