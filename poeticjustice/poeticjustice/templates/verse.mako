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
</head>


<body>


<div class="small-12 small-centered medium-8 medium-centered columns text-center">
	<h1 class="subheader">Iambic, Are You?</h1>
</div>


<p>&nbsp</p>

<div class="small-10 small-centered medium-6 medium-centered  large-3 large-centered columns text-center">
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


<script src="/foundation/bower_components/foundation/js/foundation.js"></script>


<script>
	$(document).foundation();
</script>


</body>
</html>




