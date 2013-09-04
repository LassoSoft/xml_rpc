[include('/xml_rpc.lasso')]<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>XML_RPC - Demo File</title>
</head>
<body>
<p>
The following text area contains the result of using <code>XML_RPCCall</code>.
</p>
<textarea rows="20" cols="80">[
XML_RPCCall(
    array('Hello World!'),
    'test.echo',
    ('http://'+server_name+'/xml_rpc_response.lasso'))
]</textarea>
<hr>
<p>
Use <code>XML_RPC</code> to create an instance of an <code>xml_rpc</code> type then use the following methods on the instance variable.
</p>
[local('x' = XML_RPC(array('Hello World!')))]
<h3>#x->getparams</h3>
<p>
[#x->getparams]
</p>

<h3>#x->call</h3>
<p>
Returns an array.  Once you have called <code>XML_RPC</code>, then you have <code>-&gt;getmethod</code> and <code>-&gt;response</code> methods available.
</p>
<p>
[#x->call(('http://'+server_name+'/xml_rpc_response.lasso'), 'test.echo')]
</p>

<h3>#x->getmethod</h3>
<p>
[#x->getmethod]
</p>

<h3>#x->response</h3>
<textarea rows="20" cols="80">[#x->response]</textarea>
</body>
</html>
