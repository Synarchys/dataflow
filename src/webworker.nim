
import jsffi

## A simple wrapper over web worker
## https://developer.mozilla.org/en-US/docs/Web/API/Worker
proc postMessage(d: JsObject) {. importc: "postMessage" .}
proc newWorker(f: cstring): JsObject {.importcpp: "new Worker(@)".}
