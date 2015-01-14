<!doctype html>
<html>
<head>
	<meta charset="utf-8"/>
	<meta name="viewport" content="width=device-width"/>

	<link rel="icon" 
				type="image/png" 
				href="/assets/mividio_house_bug_small.png" />

	<title>New User</title>

	<link rel="stylesheet" href="/foundation/stylesheets/app.css"/>
	<link rel="stylesheet" href="/css/font-awesome/css/font-awesome.min.css">

	<script type="text/javascript" src="/scripts/vendor/jquery-2.0.3.js"></script>
	<script src="/foundation/bower_components/foundation/js/vendor/custom.modernizr.js"></script>
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
</head>

<style>
.ribbon-wrapper-green {
	width: 85px;
	height: 88px;
	overflow: hidden;
	position: absolute;
	top: -3px;
	right: -3px;
}

.ribbon-green {
	font: bold 13px Sans-Serif;
	color: #333;
	text-align: center;
	text-shadow: rgba(255,255,255,0.5) 0px 1px 0px;
	-webkit-transform: rotate(45deg);
	-moz-transform:    rotate(45deg);
	-ms-transform:     rotate(45deg);
	-o-transform:      rotate(45deg);
	position: relative;
	padding: 7px 0;
	left: -5px;
	top: 15px;
	width: 120px;
	background-color: #BFDC7A;
	background-image: -webkit-gradient(linear, left top, left bottom, from(#BFDC7A), to(#8EBF45)); 
	background-image: -webkit-linear-gradient(top, #BFDC7A, #8EBF45); 
	background-image:    -moz-linear-gradient(top, #BFDC7A, #8EBF45); 
	background-image:     -ms-linear-gradient(top, #BFDC7A, #8EBF45); 
	background-image:      -o-linear-gradient(top, #BFDC7A, #8EBF45); 
	color: #6a6340;
	-webkit-box-shadow: 0px 0px 3px rgba(0,0,0,0.3);
	-moz-box-shadow:    0px 0px 3px rgba(0,0,0,0.3);
	box-shadow:         0px 0px 3px rgba(0,0,0,0.3);
}

.ribbon-green:before, .ribbon-green:after {
	content: "";
	border-top:   3px solid #6e8900;   
	border-left:  3px solid transparent;
	border-right: 3px solid transparent;
	position:absolute;
	bottom: -3px;
}

.ribbon-green:before {
	left: 0;
}
.ribbon-green:after {
	right: 0;
}

</style>


<body>

<div class="small-12 small-centered medium-8 medium-centered columns text-center">
	<h1 class="subheader">Poetic Justice App!</h1>
</div>

<p>&nbsp</p>

<div class="small-10 small-centered medium-6 medium-centered  large-3 large-centered columns text-center">
	<div class="row">
		<form id="signup-form" data-abide method="POST">
			<div class="row">

				${
					pymf.add_input(
						"text", 
						name_="email_address", 
						id_="email_address",
						placeholder="Enter Your Email Address",
						required=True, 
						pattern="email"
					)
				}
				<small class="error">A valid email address is required</small>

				<input type="hidden" name="country_code" value="USA" />

				<a href="#" id="create-new-user-btn" class="button small success radius expand">Start!</a>

			</div>
		</form>
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


<script type="text/javascript">
function checkForm(){

	// var x = document.forms["signup-form"]["first_name"].value;
	// if (x == null || x == "") {
	// 		alert("First name required");
	// 		return false;
	// }

	// var x = document.forms["signup-form"]["last_name"].value;
	// if (x == null || x == "") {
	// 		alert("Last name required");
	// 		return false;
	// }

	var x = document.forms["signup-form"]["email_address"].value;
		re = /[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4}/;
		if(!re.test(x)){
			$("#signup-form input[name=email_address]").val("INVALID EMAIL");
			$("#signup-form input[name=email_address]").focus();
			return false;
		}

	return true;
}


$("#create-new-user-btn").click(function(event){

	console.log("create-new-user-btn clicked");

	event.preventDefault();
	var form = $("#signup-form");

	console.log(form)
	
	if(checkForm()==false){
		return false;
	}
	var result;

	data = form.serializeArray();
	
	$.ajax({
		type: 'POST',
		url: '/u/new',
		data: data,
		success: function(data) {
			result = data.results[0]
			return window.location.href = "/u/";
		},
		error: function(jqXHR, textStatus, errorThrown){
			if(jqXHR.status==409){
					$("#message-title").html("Error");
					$("#message-body").html("This account already exists. Please log in normally.");
					$("#messages-reveal").foundation('reveal', 'open');
			}else if(jqXHR.status==422){
					$("#message-title").html("Error");
					$("#message-body").html(jqXHR.responseText);
					$("#messages-reveal").foundation('reveal', 'open');
			}else{
					$("#forgot").show("fast");
			}
		},
		complete: function(){
			$("#loading-gif").html("");
		}
	});
});
</script>

</body>
</html>

<%namespace name="pymf" file="modelfuncs.mako"/>



