[
// This file is your custom xml_rpc response.
if(Client_PostArgs) => {^
    local(myRPC = XML_RPC(Client_POSTArgs))
//    local(myMethod = #myRPC->GetMethod)
//    local(myParams = #myRPC->GetParams)
//    local(response = #myMethod)
//    local(myRPC = XML_RPC(#response))
    #myrpc->response(-full=false, -fault=false)
^}
]
