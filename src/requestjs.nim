# copied from kajax / karax but extracted the redraw part.

type 
  Blob* = ref BlobObj
  BlobObj {.importc.} = object of RootObj
    size*: int
    `type`*: cstring

proc ajax*(meth, url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int; response: cstring);
          useBinary: bool = false,
          blob: Blob = nil) =
  proc contWrapper(httpStatus: int; response: cstring) =
    cont(httpStatus, response)
    

  type
    HttpRequest {.importc.} = ref object
    ThisObj {.importc.} = ref object
      readyState, status: int
      responseText, statusText: cstring

  proc setRequestHeader(r: HttpRequest; a, b: cstring) {.importcpp: "#.setRequestHeader(@)".}
  proc statechange(r: HttpRequest; cb: proc()) {.importcpp: "#.onreadystatechange = #".}
  proc send(r: HttpRequest; data: cstring) {.importcpp: "#.send(#)".}
  proc send(r: HttpRequest, data: Blob) {.importcpp: "#.send(#)".}
  proc open(r: HttpRequest; meth, url: cstring; async: bool) {.importcpp: "#.open(@)".}
  proc newRequest(): HttpRequest {.importcpp: "new XMLHttpRequest(@)".}

  var this {.importc: "this".}: ThisObj
  let ajax = newRequest()
  ajax.open(meth, url, true)
  for a, b in items(headers):
    ajax.setRequestHeader(a, b)
  ajax.statechange proc() =
    if this.readyState == 4:
      if this.status == 200:
        contWrapper(this.status, this.responseText)
      else:
        contWrapper(this.status, this.responseText)
  if useBinary:
    ajax.send(blob)
  else:
    ajax.send(data)

proc ajaxPost*(url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true) =
  ajax("POST", url, headers, data, cont)

proc ajaxPost*(url: cstring; headers: openarray[(cstring, cstring)];
          data: Blob;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true) =
  ajax("POST", url, headers, "", cont, true, data)

proc ajaxGet*(url: cstring; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true) =
  ajax("GET", url, headers, nil, cont)

proc ajaxPut*(url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true) =
  ajax("PUT", url, headers, data, cont)

proc ajaxDelete*(url: cstring; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true) =
  ajax("DELETE", url, headers, nil, cont)


proc toJson*[T](data: T): cstring {.importc: "JSON.stringify".}
proc fromJson*[T](blob: cstring): T {.importc: "JSON.parse".}
