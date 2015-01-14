<html>

<head>
<script type="text/javascript" src="/player/jwplayer.js" ></script>
</head>

<%def name="render_basic_player(name, elements)">

	<script>
	jwplayer("${name}").setup({
	    playlist: [
	    	% for element in elements:
	    		{
	    			file: "${elements[element]['file']}",
	    		}
	    	% endfor 
		]
	});
	</script>

</%def>

<div id="${name}">Loading the player ...</div>

${render_basic_player(name, elements)}

</html>