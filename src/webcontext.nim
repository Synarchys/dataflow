
## A web context protocol that encapsulates the request and response

import httpcore, strutils, uri, asynchttpserver, tables

type    
  WRequest* = ref object
    ## Request encapsulation protocol
    hostname*, body*: string
    protocol*: tuple[orig: string, major, minor: int]
    reqMethod*: HttpMethod
    headers*: HttpHeaders
    url*: Uri
    urlpath*: seq[string]
    paramList*: seq[string]
    paramTable*: Table[string, string]
    
    
  WResponse* = ref object
    ## Response encapsulation Protocol
    status*: HttpCode
    headers*: HttpHeaders
    body*: string
    
  WebContext* = ref object
    request*: WRequest
    response*: WResponse


proc createWebContext*(r: Request): WebContext =
  ## Creates and encapsulates a new WebContext from a
  ## Request   
  result = new WebContext
  var req = new WRequest
  var res  = new WResponse
  req.body = r.body 
  req.hostname = r.hostname
  req.reqMethod = r.reqMethod
  req.url = r.url
  req.headers = r.headers
  req.protocol = r.protocol
  res.status = Http200
  res.headers = r.headers
  res.body = ""
  req.paramList = @[]
  req.paramTable = initTable[string, string]()
  let bpath = split($req.url, "?")
  if bpath.len > 0:
    req.urlpath = split(bpath[0], "/")
    req.urlpath.delete(0)
  else: 
    req.urlpath = @[]
  if bpath.len > 1:
    let params = split(bpath[1], "&")
    for p in params:
      if p.contains("="):
        let line = p.split("=")
        req.paramTable[line[0]] = line[1]
      else:
        req.paramList.add(p)
  
  result.request = req
  result.response = res
    

proc `$`*(r: WRequest): string =
  #echo "url: " & $r.url
  #echo "headers: " & $r.headers
  result = "hostname: " & r.hostname & " , method: " & $r.reqMethod &
    " , url: " & $r.url & " , headers: " & $r.headers &
    " , protocol" & $r.protocol & " , urlpath: " & $r.urlpath &
    " , paramList: " & $r.paramList &
    " , paramTable: " & $r.paramTable &
    " , body: " & $r.body
    

proc `$`*(r: WResponse): string =
  result = "status: " & $r.status & " ,headers: " & $r.headers &
    " , body: " & r.body

proc `$`*(c: WebContext): string =
  result = "WebContext: \nRequest: " & $c.request & "\nResponse: " & $c.response 


proc copy*(c: WebContext): WebContext =
  result = new WebContext
  var
    req = c.request
    res = c.response
  result.request = req
  result.response = res
  
