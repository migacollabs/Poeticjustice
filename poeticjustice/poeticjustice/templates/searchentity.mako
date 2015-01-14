<!DOCTYPE html>
<html>
<head>
	<script src="http://code.jquery.com/jquery-1.9.1.js"></script>
</head>
<body>
	<form action="/m/search/" id="searchForm">
		<input type="text" name="model_name" placeholder="Model..." />
		<br>
		<input type="text" name="search_query" placeholder="Query..." size="64"/>
		<input type="submit" value="Search" />
	</form>
	
	<!-- the result of the search will be rendered inside this div -->
	<div id="result"></div>
 
<script>

/* attach a submit handler to the form */
$("#searchForm").submit(function(event) {
 
	/* stop form from submitting normally */
	event.preventDefault();
 
	/* get some values from elements on the page: */
	var $form = $(this),
		term = $form.find('input[name="model_name"]').val(),
		term2 = $form.find('input[name="search_query"]').val(),
		url = $form.attr('action');
 
	/* Send the data using post */
	var posting = $.post( url, { model_name: term, search_query: term2 } );
 
	/* Put the results in a div */
	posting.done(function( data ) {
		$( "#result" ).empty().append("<br><br><b>Results</b><hr>");
		for ( var k in data ){
			if (data.hasOwnProperty(k)){
				//alert(k + " -> " + data[k]);
				if (k == 'results'){
					//alert(data.results.length);
					for(var i=0;i<data.results.length;i++){
						var entity_data = data.results[i]
						for(var r in entity_data){
							if(r == 'id'){
								var id_ = entity_data[r]
								var a = document.createElement('a');
								var linkText = document.createTextNode(r);
								a.appendChild(linkText);
								a.href = "/_a/viewentity/"+"User/id="+id_;
								$( "#result" ).append("<a>" + a + "</a><br>");
							}
							else{
								$( "#result" ).append( r + " " + entity_data[r] + "<br>");
							}
						}
						$( "#result" ).append("<br><br>");
					}
				}
			}
		};
	});

	posting.fail(function(data){
		$( "#result" ).empty().append("<br><br><hr>");
		$( "#result" ).append('Error or no results');
	});

});
</script>
 
</body>
</html>