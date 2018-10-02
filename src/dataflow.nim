# imu dataflow manager
import json, tables, strformat, typetraits

when defined(js):
  proc genUUID*(): string =
    result = ""
    proc random(): float {.importc: "Math.random".}
    proc floor(n: float): int8 {.importcpp: "Math.floor(#)".} 
    for i in 0..36:
      const adigits = "0123456789abcdef"
      case i:
        of 8, 13, 18, 23:
          result &= "-"
        of 14:
          result &= "4"
        else:
          var r = random() * 16
          result &= adigits[floor(r)]  
else:
  import uuids # https://github.com/pragmagic/uuids


type
  DataContainer*[T] = ref object
    id*: string  
    flowId*: string
    contents*: T
    error*: bool
    code*: int
    message*: string
  DataFlow*[T] = ref object
    id: string
    options: Table[string, string]
    documents: Table[string, T]
    subscribers: Table[string, proc(d: DataContainer[T])]

proc createFlow*[T](id: string, options: Table[string, string] = initTable[string, string]()): DataFlow[T] =
  result = DataFlow[T](id: id, options: options)
  result.documents = initTable[string, T]()
  result.subscribers = initTable[string,proc(d: DataContainer[T])]()
  
proc `$`*[T](flow: DataFlow[T]): string =
  let typename = T.name
  result = fmt"""FlowType: {typename}, ID: {flow.id}, Size: {$flow.documents.len}"""
  result &= fmt""", Subscribers: {$flow.subscribers.len}""" 
  for k, v in flow.options.pairs:
    result &= fmt""", Options: [{k}: {v}]"""

proc `$`*[T](d:DataContainer[T]): string =
  let typename = T.name
  result = fmt"""DataType: {typename}, ID: {d.id}, Error: {$d.error}"""
  result &= fmt""", Code: {$d.code}, Message: {d.message}, Flow: d.flowId"""
  var dresp = " Data: no data" 
  if d.contents != nil:
    try:
      dresp = fmt""" Data: {$d.contents}"""
    except:
      dresp = " Data: unprintable"
  result &= dresp

proc callSubscribers[T](flow: DataFlow[T], d: DataContainer) =
  for id, cb in flow.subscribers.pairs:
    cb(d)
    
proc put*[T](flow: DataFlow[T], d: var DataContainer[T], cb: proc(d: DataContainer[T])) = 
  if flow.documents.hasKey(d.id):
    flow.documents[d.id] = d.contents
    d.code = 202
    d.message =  "changed"
    d.flowId = flow.id
  else:
    flow.documents.add(d.id, d.contents)
    d.code = 201
    d.message = "inserted"
    d.flowId = flow.id
  flow.callSubscribers(d)
  cb(d)
  
proc seek*[T](flow: DataFlow[T], id: string, cb: proc(d: DataContainer[T])) =
  var d = DataContainer[T]()
  if flow.documents.hasKey(id):
    d.contents = flow.documents[id]
    d.id = id
    d.code = 200
    d.message = "ok"
    d.flowId = flow.id
  else:
    d.error = true
    d.code =  404
    d.message = "Document not found"
    d.flowId =  flow.id
  cb(d)

proc evict*[T](flow: DataFlow[T], id: string, cb: proc(d: DataContainer[T])) =
  var d = DataContainer[T](id:id)
  if flow.documents.hasKey(id):
    flow.documents.del(id)
    d.code = 200
    d. message = "deleted"
    d.id = id
    d.flowId = flow.id
  else:
    d.id = id
    d.error = true
    d.code = 404
    d.message = "Document not found"
    d.flowId = flow.id
  flow.callSubscribers(d)
  cb(d)

proc subscribe*[T](flow: var DataFlow[T], cb: proc(d: DataContainer[T])): string  =
  result = $genUUID()
  flow.subscribers.add(result, cb)

proc unsubscribe*[T](flow: var DataFlow[T], id: string): string =
  if flow.subscribers.hasKey(id):
    flow.subscribers.del(id)
    return "ok"
  return "not found"
    
  
