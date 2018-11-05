import jsffi

## A simple wrapper over the web socket implementation on the browser
## https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
proc newWebSocket*(url, protocol: cstring): JsObject {.importcpp: "new WebSocket(@)".}
