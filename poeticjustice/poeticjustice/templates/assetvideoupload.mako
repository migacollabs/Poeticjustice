<!DOCTYPE html>
<!--[if IE 8]> 				 <html class="no-js lt-ie9" lang="en" > <![endif]-->
<!--[if gt IE 8]><!-->
<html class="no-js" lang="en"> <!--<![endif]-->

<body>

	<form enctype="multipart/form-data" action="/up/up-video" accept-charset="utf-8" method="POST">
        <table>
            <thead>
            <tr>
                <th width="200">File</th>
                <th width="200">Name</th>
                <th width="200">Description</th>
            </tr>
            </thead>
            <tbody>
		        <tr>
		            <td><h5 class="subheader">
		                <input
		                    type="file"
		                    name="file"
		                >
		            </h5></td>
		            <td><h5 class="subheader">
		                <input
		                    type="text"
		                    name="name"
		                >
		            </h5></td>
		            <td><h5 class="subheader">
		                <input
		                    type="text"
		                    name="description"
		                >
		            </h5></td>
		        </tr>
            <tr>
                <td>
                    <input type='hidden', name='override_method', value="POST">
                </td>
            </tr>
            <tr>
            	<td>
            		<input type="hidden" name="access_token" value="xj9kv8bp7yg6fw5mu4cl3dr2hs1nioatezq0">
            	</td>
            </tr>
            </tbody>
        </table>
        <input type="submit" value="submit" class="button expand">
    </form>

</body>

</html>