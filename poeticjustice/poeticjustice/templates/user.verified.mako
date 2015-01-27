<!doctype html>
<html>
<head>

    <title>Poetic Justice App - Verified</title>

    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width"/>

    <link rel="icon" 
          type="image/png" 
          href="/assets/Conversation.png" />

    <link rel="stylesheet" href="/foundation/stylesheets/app.css"/>

    <script src="/foundation/bower_components/foundation/js/vendor/custom.modernizr.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>

    <link href='http://fonts.googleapis.com/css?family=Open+Sans:300,400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=OpenSans">

</head>

<body>

<div class="small-12 columns">
  <div class="row" style="padding-top: 24px;">   
    <div class="small-6 small-centered columns">

      <h2 class="subheader">New Player</h2>

      <hr>

			% if verified:

				<h5>Email verified! Please launch Poetic Justice App and sign in!</h5>

			% else:

				<h5>New account not verified</h5>

			% endif

    </div>
  </div>
</div>


<script src="/foundation/bower_components/foundation/js/foundation.js"></script>

<script>
    $(document).foundation();
</script>


</body>

<p class="bottom"></p>

</html>

