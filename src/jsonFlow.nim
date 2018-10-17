# imu dataflow manager
import json, times, tables, strformat

import ./dataflow

when defined(js):
  import uuidjs
  
else:
  import uuids # https://github.com/pragmagic/uuids

type
  JsonFlow = ref object
    id: string
    options: Table[string, string]
    documents: Table[string, JsonNode]
    subscribers: Table[string, proc(d: JsonNode)]
  
proc createFlow*(id: string, options: Table[string, string] = initTable[string, string]()): JsonFlow =
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
  
proc send*(flow: JsonFlow, d: JsonNode, cb: proc(d: JsonNode)) = 
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

