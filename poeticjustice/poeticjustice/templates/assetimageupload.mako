<!DOCTYPE html>
<html>

<head>
<script>
    function supportMultiple() {
        //do I support input type=file/multiple
        var el = document.createElement("input");

        return ("multiple" in el);
    }

    function init() {
        if(supportMultiple()) {
            document.querySelector("#multipleFileLabel").setAttribute("style","");
        }
    }
</script>
</head>

<b> Multiple Upload with HTML5 <b>

<body onload="init()">

    <form action="/up/up-image-multi5" method="POST" enctype="multipart/form-data">

        Property Slide Show Id: <input type="number" name="property_slide_show_id"><br>
        Address: <input type="text" name="address"><br>
        Latitude: <input type="text" name="latitude"><br>
        Longitude: <input type="text" name="longitude"><br>

        <span id="multipleFileLabel" style="display:none">Multiple </span>File: <input type="file" name="files" multiple="multiple">

        <input type='hidden', name='override_method', value="POST">
        <input type="hidden" name="access_token" value="xj9kv8bp7yg6fw5mu4cl3dr2hs1nioatezq0">

        <br>
        <input type="submit">
    </form>

</body>

</html>
