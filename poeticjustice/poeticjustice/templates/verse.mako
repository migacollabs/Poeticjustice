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
.footer{
	width: 100%;
	height: 32px;
	position: fixed;
	bottom: 0px;
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


<div class="small-12 small-centered medium-8 medium-centered columns text-center">
	<h1 class="subheader">Iambic, Are You?</h1>
</div>


<p>&nbsp</p>

<div class="small-12 medium-9  large-7 columns text-center">
	<div class="row">
		<h2 class="subheader">${title}</h2>
	</div>
	<div class="row">
		%for line in lines:
		<h3 class="subheader">${line}</h3>
		%endfor
	</div>
</div>


<div id="messages-reveal" class="reveal-modal medium" data-reveal>
	<h4 class="subheader" id="message-title"></h4>
	<hr>
	<h5 class="subheader" id="message-body"></h5>
	<a class="close-reveal-modal">&#215;</a>
</div>


<div class="footer">
	<h6 class="subheader">&nbsp&nbsp Miga Col.labs LLC - <a href="/assets/privacypolicy.html">Privacy Policy</a></h6>
</div>


<script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<!-- Test -->
<ins class="adsbygoogle"
     style="display:inline-block;width:300px;height:600px"
     data-ad-client="ca-pub-7917203112531608"
     data-ad-slot="3586881377"></ins>
<script>
(adsbygoogle = window.adsbygoogle || []).push({});
</script>



<script src="/foundation/bower_components/foundation/js/foundation.js"></script>





<script>
	$(document).foundation();
</script>


</body>
</html>



