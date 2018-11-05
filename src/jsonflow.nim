# imu dataflow manager
## Json dataFlow
## This module implements a Obserer/Observable patern for data transmition
## and application state.
## It wors on the javascript and native targets.
## It mantains a table of documents indexed by id whiche can be inserted,
## modified or deleted.
## When there is a change all subscribers will be called.

import json, times, tables, strformat

when defined(js):
  import uuidjs
  
else:
  import uuids # https://github.com/pragmagic/uuids

type
  JsonFlow = ref object
    ## The Flow needs an id which generally is an UUID but can be any valid string
    id: string
    options: Table[string, string]
    documents: Table[string, JsonNode]
    subscribers: Table[string, proc(d: JsonNode)]
  
proc createFlow*(id: string,
                 options: Table[string, string] = initTable[string, string]()
                ): JsonFlow =
  ## Creates a new flow given an ID and a table of options.
  ## the options  
  result = JsonFlow(id: id, options: options)
  result.documents = initTable[string, JsonNode]()
  result.subscribers = initTable[string, proc(d: JsonNode)]()

proc `$`*(flow: JsonFlow): string =
  result = fmt"""ID: {flow.id}, Size: {$flow.documents.len}"""
  result &= fmt""", Subscribers: {$flow.subscribers.len}""" 
  for k, v in flow.options.pairs:
    result &= fmt""", Options: [{k}: {v}]"""

proc callSubscribers(flow: JsonFlow, d: JsonNode) =
  for id, cb in flow.subscribers.pairs:
    cb(d)

proc subscribe*(flow: var JsonFlow, cb: proc(d: JsonNode)): string  =
  result = $genUUID()
  flow.subscribers.add(result, cb)

proc unsubscribe*(flow: var JsonFlow, id: string): string =
  if flow.subscribers.hasKey(id):
    flow.subscribers.del(id)
    return "ok"
  return "not found"

proc default_cb(r: JsonNode) =
  discard
  
proc send*(flow: JsonFlow, d: JsonNode, cb: proc(d: JsonNode) = default_cb) = 
  if flow.documents.hasKey(d["id"].getStr()):
    flow.documents[d["id"].getStr()] = d
    d["code"] = %202
    d["message"] = %"changed"
    d["flowId"] = %flow.id
  else:
    flow.documents.add(d["id"].getStr(), d)
    d["code"] = %202
    d["message"] = %"inserted"
    d["flowId"] = %flow.id
  flow.callSubscribers(d)
  cb(d)

proc sendData*(f: JsonFlow, data: JsonNode, cb: proc(dd: JsonNode)) =
  f.send(data, proc(dcc: JsonNode) =
               cb(dcc))
  
proc seek*(flow: JsonFlow, id: string, cb: proc(d: JsonNode)) =
  var d = newJObject()
  if flow.documents.hasKey(id):
    d = flow.documents[id]
    d["id"] = %id
    d["code"] = % 200
    d["message"] = % "ok"
    d["flowId"] = % flow.id
  else:
    d["error"] = % true
    d["code"] =  % 404
    d["message"] = % "Document not found"
    d["flowId"] =  % flow.id
  cb(d)

proc evict*(flow: JsonFlow, id: string, cb: proc(d: JsonNode)) =
  var d = %*{"id":id}
  if flow.documents.hasKey(id):
    flow.documents.del(id)
    d["code"] = % 200
    d["message"] = % "deleted"
    d["id"] = % id
    d["flowId"] = % flow.id
  else:
    d["id"] = %id
    d["error"] = %true
    d["code"] = %404
    d["message"] = %"Document not found"
    d["flowId"] = %flow.id
  flow.callSubscribers(d)
  cb(d)

