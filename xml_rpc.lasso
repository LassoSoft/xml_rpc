[
/*
local:'sample'="<?xml version='1.0' ?>
<methodCall>
<methodName>method_TestNormal</methodName>
<params>
<param><value><string>This Is A test</string></value></param>
<param><value><int>234</int></value></param>
<param><value><double>234.000000</double></value></param>
<param><value><dateTime.iso8601>19691231T16:00:00</dateTime.iso8601></value></param>
<param><value><base64>VGVzdGluZyBCYXNlNjQ= </base64></value></param>
</params>
</methodCall>";

local:'sample2'='<?xml version='1.0' ?>
<methodResponse>
<params>
<param><value><array><data><value><struct><member><name>Reason</name>
<value><string>Whew!!!</string></value></member>
<member>
<name>Rubadubdub</name>
<value><string>Inmytub</string></value>
</member></struct></value></data></array></value></param>
<param><value><array><data><value>
<string>This Is A test</string></value>
<value><string>One</string></value><value><string>Two</string></value>
<value><string>Three and four</string></value></data></array></value></param>
<param><value><boolean>1</boolean></value></param>
<param><value><int>234</int></value></param>
<param><value><string>This Is A test</string></value></param>
<param><value><double>234.000000</double></value></param>
<param><value><dateTime.iso8601>19691231T16:00:00</dateTime></value></param>
<param><value><base64>VGVzdGluZyBCYXNlNjQ= </base64></value></param>
</params></methodResponse>';
*/

define base64 => type {
    // for use within xml_rpc. signifies type of data
    parent string
}

define XMLRPC_ExConverter(type) => {
    local(ret=bytes)
    match(#type->type)
        case('string')
            #ret->importString('<string>');
            #ret->importString(#type)//->encodeHtml)
            #ret->importString('</string>');
        case('bytes')
            #ret->importString('<base64>');
            #ret->importString(encode_base64(#type));
            #ret->importString('</base64>');
        case('base64')
            #ret->importString('<base64>');
            #ret->importString(#type);
            #ret->importString('</base64>');
        case('integer')
            #ret->importString('<int>');
            #ret->importString(string(#type));
            #ret->importString('</int>');
        case('boolean')
            #ret->importString('<boolean>');
            #ret->importString(string(#type));
            #ret->importString('</boolean>');
        case('date')
            #ret->importString('<dateTime.iso8601>');
            #ret->importString(#type->format('%Y%m%dT%H:%M:%S'))
            #ret->importString('</dateTime.iso8601>');
        case('decimal')
            #ret->importString('<double>');
            #ret->importString(string(#type));
            #ret->importString('</double>');
        case('array')
            #ret->importString('<array>');
            #ret->importString('<data>');
            iterate(#type, local('i'));
                #ret->importString('<value>');
                #ret->append(XMLRPC_ExConverter(#i));
                #ret->importString('</value>');
            /iterate;
            #ret->importString('</data>');
            #ret->importString('</array>');
        case('map')
            #ret->importString('<struct>');
            iterate(#type, local('i'));
                #ret->importString('<member>');
                #ret->importString('<name>');
                #ret->importString(#i->first);
                #ret->importString('</name>');
                #ret->importString('<value>');
                #ret->importAs(XMLRPC_ExConverter(#i->second), 'BINARY');
                #ret->importString('</value>');
                #ret->importString('</member>');
            /iterate;
            #ret->importString('</struct>');
        case('pair')
            #ret->importString('<struct>');
            #ret->importString('<member>');
            #ret->importString('<name>');
            #ret->importString("first");
            #ret->importString('</name>');
            #ret->importString('<value>');
            #ret->importAs(XMLRPC_ExConverter(#type->first), 'BINARY');
            #ret->importString('</value>');
            #ret->importString('</member>');

            #ret->importString('<member>');
            #ret->importString('<name>');
            #ret->importString("second");
            #ret->importString('</name>');
            #ret->importString('<value>');
            #ret->importAs(XMLRPC_ExConverter(#type->second), 'BINARY');
            #ret->importString('</value>');
            #ret->importString('</member>');
            #ret->importString('</struct>');
        case('null')
            #ret->importString('<string/>');
    /match
    return #ret
}

define XMLRPC_XMLInConverter(xml) => {
    match(#xml->nodeName)
        case('string')
            return #xml->contents
        case('base64')
            return decode_base64(#xml->contents);
        case('int')
            return integer(#xml->contents);
        case('double')
            return decimal(#xml->contents);
        case('boolean')
            return boolean(#xml->contents);
        case('dateTime.iso8601')
            return date(#xml->contents, -format='%Y%m%dT%H:%M:%S')
        case('array')
            local('ret'=array);
            local('values' = #xml->extract('data/value/*'));
            iterate(#values, local('i'));
                if(#i->nodetype == 'ELEMENT_NODE');
                    #ret->insert(XMLRPC_XMLInConverter(#i))
                else;
                    #ret->insert(string(#i->contents))
                /if;
            /iterate;
            return #ret;
        case('struct')
            local('ret'=map);
            iterate( #xml->children, local( 'member'));
                local( 'nm' = null);
                local( 'vl' = null);
                iterate( #member->children, local( 'child'));
                    if( (#child->nodetype == 'ELEMENT_NODE') && (#child->name == 'name'));
                        local( 'nm' = #child->contents);
                    else( (#child->nodetype == 'ELEMENT_NODE') && (#child->name == 'value'));
                        iterate( #child->extract('*'), local( 'value'));
                            if( #value->nodetype == 'ELEMENT_NODE');
                                local( 'vl' = XMLRPC_XMLInConverter(#value));
                            else;
                                local( 'vl' = string(#value->contents));
                            /if;
                            loop_abort;
                        /iterate;
                    /if;
                /iterate;
                if( #nm != null && #vl != null);
                    #ret->insert( #nm=#vl);
                /if;
            /iterate;
            return #ret;
        case;
            log_warning( 'XML-RPC: Unknown Type (' + #xml + ')');
    /match;
}

define XMLRPC_InConverter(bytes::bytes) => {
    local('xml'=xml(#bytes));
    return XMLRPC_XMLInConverter(#xml)
}

define xml_rpc => type {
    data private params=array,
        private method=string

    public onCreate(params=void) => {

        if (#params->isa(::trait_forEach))
            with p in #params
            do .params->insert(#p)
        else (#params->isa(::string) && #params !>> '<')
            .params->insert(string(#params))
        else (#params)
            error_code = 0
            error_msg = ''
            local(xml)
            protect => {
                handle_error => {
                    .params->insert(string(#params))
                    return;
                }
                #xml = xml(#params)
            }
            local('mname' = #xml->extractOne('/methodCall/methodName'));
            self->'method' = #mname->contents;

            local('xmlparams' = #xml->extract('/methodCall/params/param/value/*'));
            iterate(#xmlparams, local('i'));
                local( 'j' = bytes);
                #j->importstring( #i);
                self->'params'->insert(XMLRPC_InConverter(#j, 'UTF-8'))
            /iterate;
        /if;
    }

    public getparams() => {
        return self->'params'
    }

    public getmethod() => {
        return self->'method'
    }

    public response(-full=false, -fault=false) => {
        local('ret'='<?xml version=\'1.0\' ?><methodResponse>');
        if (!#fault)
            #ret += '<params>';
            iterate(self->'params', local('i'));
                #ret += "<param><value>";
                #ret += XMLRPC_ExConverter(#i);
                #ret += "</value></param>";
            /iterate;
            #ret += '</params>';
        else;
            #ret += '<fault>';
            local('code'=0, 'string'=string);
            iterate(self->'params', local('i'));
                if(#i->isa('pair'));
                    if(#i->first == '-faultcode');
                        #code = integer(#i->second);
                    else(#i->first == '-faultstring');
                        #string = string(#i->second);
                    /if;
                /if;
            /iterate;
            fail_if(!#code || !#string, -1, 'Both a -faultcode and -fault string must be provided as parameters.');

            #ret +=  '<value>
                     <struct>
                        <member>
                           <name>faultCode</name>
                           <value>' + XMLRPC_ExConverter(#code)+ '</value>
                           </member>
                        <member>
                           <name>faultString</name>
                           <value>' +XMLRPC_ExConverter(#string)+ '</value>
                           </member>
                        </struct>
                     </value>';

            #ret += '</fault>';
        /if;
        #ret += '</methodResponse>';

        if (#full)
            return 'HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: ' #ret->size '\r\n\r\n' #ret;
        /if;
        return #ret;
    }

    public call(-uri, -method) => {
        self->'method' = #method;

        local('req' = "<?xml version='1.0' ?><methodCall><methodName>" +#method+ "</methodName><params>");
        iterate(self->'params', local('i'));
            #req += "<param><value>";
            #req += XMLRPC_ExConverter(#i);
            #req += "</value></param>";
        /iterate;

        return #req


        #req += "</params></methodCall>";
        local('result' = include_url(#uri, -postparams=#req, -SendMIMEHeaders=array('Content-Type'='text/xml','User-Agent'='Lasso Professional ' + Lasso_Version(-LassoVersion))));
        fail_if(!#result, -1, 'Received no response from server.');

        // clear out params
        self->'params'->removeAll;
        local('xml' = xml(#result));
        local('xmlparams' = #xml->extract('/methodResponse/params/param/value/*'));

        iterate(#xmlparams, local('i'));
            if (#i->nodetype == 'ELEMENT_NODE');
                local('bytes' = bytes);
                #bytes->importString(#i->asString)
                self->'params'->insert(XMLRPC_InConverter(#bytes))
            else;
                self->'params'->insert(string(#i))
            /if;
        /iterate;
        return self->'params';
    }
}

define xml_rpccall(params = void, method = void, host = void, url = void, uri = void, ...) => {
    local(myparams = null)
    local(return = null)
    if(local_defined('uri'))
        local(myhost = #uri)
    else(local_defined('url'))
        local(myhost = #url)
    else(local_defined('host'))
        local(myhost = #host)
    else
        local(myhost = 'http://127.0.0.1/Lasso/RPC.LassoApp')
    /if
    if(local_defined('method'))
        local(mymethod = #method)
    else
        local(mymethod = 'test.echo')
    /if
    if(local_defined('params'))
        if(#params->isa('array'))
            #myparams = #params
        else
            #myparams = array + #params
        /if
    else
        #myparams = array
    /if
    error_seterrorcode(0)
    error_seterrormessage('')
    protect
        local(return = xml_rpc(#myparams)->call(-uri = local(myhost), -method = #mymethod))
        handle_error
            return
        /handle_error
    /protect
    if(#return == array)
        return
    else(#return->type == 'array' && #return->size == 1)
        return #return->get(1)
    else
        return #return
    /if
}

//local(p = array(array('3.5','php:1.11','4304158399',389,'m7WgOLk0iKtKe2oi1HStqg==', 2,2)))
//XML_RPC(#p)->call('http://beta-test.kreditor.se:4567','get_addresses')

//var: 'kreditorarray' = array(array('3.5','php:1.11','4304158399',389,'m7WgOLk0iKtKe2oi1HStqg==', 2,2));

//XMLRPC_ExConverter($kreditorarray)

//var: 'test' = (XML_RPCCall: -Host='http://beta-test.kreditor.se:4567', -Method='get_addresses', -Params=$kreditorarray);
//var: 'test';
]