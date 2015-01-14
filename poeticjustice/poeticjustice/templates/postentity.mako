<!DOCTYPE html>
<!--[if IE 8]> 				 <html class="no-js lt-ie9" lang="en" > <![endif]-->
<!--[if gt IE 8]><!-->
<html class="no-js" lang="en"> <!--<![endif]-->

<html>

    <%namespace name="modelfuncs", file="modelfuncs.mako"/>

<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width"/>

    <title>Create new ${model_name}</title>

    <link rel="stylesheet" href="/pyaellacss/app.css"/>
    <script src="/pyaellascripts/vendor/custom.modernizr.js"></script>
</head>

<body>

<br>

<div class="panel row">
    <div><h2 class="subheader">Create new Pyaella ${model_name} Entity</h2></div>
    ${modelfuncs.model_form(model_name, model, ordered_fields, entity, 'POST', '60%', '0', 'submit', 'submit')}
</div>

<script>
    document.write('<script src=' +
            ('__proto__' in {} ? '/pyaellascripts/vendor/zepto' : '/pyaellascripts/vendor/jquery') +
            '.js><\/script>')
</script>

<script src="/pyaellascripts/foundation/foundation.js"></script>
<script src="/pyaellascripts/foundation/foundation.alerts.js"></script>
<script src="/pyaellascripts/foundation/foundation.clearing.js"></script>
<script src="/pyaellascripts/foundation/foundation.cookie.js"></script>
<script src="/pyaellascripts/foundation/foundation.dropdown.js"></script>
<script src="/pyaellascripts/foundation/foundation.forms.js"></script>
<script src="/pyaellascripts/foundation/foundation.interchange.js"></script>
<script src="/pyaellascripts/foundation/foundation.joyride.js"></script>
<script src="/pyaellascripts/foundation/foundation.magellan.js"></script>
<script src="/pyaellascripts/foundation/foundation.orbit.js"></script>
<script src="/pyaellascripts/foundation/foundation.placeholder.js"></script>
<script src="/pyaellascripts/foundation/foundation.reveal.js"></script>
<script src="/pyaellascripts/foundation/foundation.section.js"></script>
<script src="/pyaellascripts/foundation/foundation.tooltips.js"></script>
<script src="/pyaellascripts/foundation/foundation.topbar.js"></script>

<script>
    $(document).foundation();
</script>

</body>

</html>