<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width"/>
    <title>Login</title>

    <link rel="stylesheet" href="/foundation/stylesheets/app.css"/>
    <link rel="stylesheet" href="/css/font-awesome/css/font-awesome.min.css">

    <script type="text/javascript" src="/scripts/vendor/jquery-2.0.3.js"></script>
    <script src="/foundation/bower_components/foundation/js/vendor/custom.modernizr.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
</head>
<body>


<div class="small-12 small-centered medium-8 medium-centered columns text-center">
    <h1 class="subheader">Poetic Justice App!</h1>
</div>


<p>&nbsp</p>


<div class="small-10 small-centered medium-6 medium-centered  large-3 large-centered columns text-center">
    <div class="row">
        <form id="signin-form" data-abide method="POST">
            <div class="row">

                ${
                    pymf.add_input(
                        "text", 
                        name_="user_name", 
                        id_="user-name",
                        placeholder="Pick a Screen name",
                        required=True, 
                        pattern="alphanumeric"
                    )
                }
                <small class="error">Your Screen Name will be public</small>

                ${
                    pymf.add_input(
                        "text", 
                        name_="login", 
                        id_="login",
                        placeholder="Enter Your Email Address",
                        required=True, 
                        pattern="email"
                    )
                }
                <small class="error">A valid email address is required</small>

                <input type="hidden" name="country_code" value="USA" />
                <input type="hidden" name="form.submitted" value="true" />
                <input type="hidden" name="device_token" value="BROWSER_DEVICE_TOKEN" />

                <a href="#" id="login-btn" class="button small success radius expand">Login!</a>

            </div>
        </form>
    </div>
</div>


<script src="/foundation/bower_components/foundation/js/foundation.js"></script>


<script>
    $(document).foundation();
</script>


<script type="text/javascript">

$("#login-btn").click(function(event){

    console.log("login-btn clicked");

    event.preventDefault();
    var form = $("#signin-form");

    console.log(form)
    
    var result;

    data = form.serializeArray();
    
    $.ajax({
        type: 'POST',
        url: '/login',
        data: data,
        success: function(data) {
            result = data.results[0]
            return window.location.href = "/u/verses";
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

