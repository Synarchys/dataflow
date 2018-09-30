# imu dataflow manager
import json, tables, strformat, typetraits

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
    subscribers: seq[proc(d: DataContainer[T])]

proc createFlow*[T](id: string, options: Table[string, string]): DataFlow[T] =
  result = DataFlow[T](id: id, options: options)
  result.documents = initTable[string, T]()
  result.subscribers = @[]
  
proc `$`*[T](flow: DataFlow[T]): string =
  let typename = T.name
  result = "FlowType: " & typename & ", ID: " & flow.id & ", Size: " & $flow.documents.len &
    ", Subscribers: " & $flow.subscribers.len 
  for k, v in flow.options.pairs:
    result &= ", Options: [" & k & ": " & v & "]"

proc `$`*[T](d:DataContainer[T]): string =
  let typename = T.name
  result = "DataType: " & typename & " ID: " & d.id & ", Error: " & $d.error & 
    ", Code: " & $d.code & ", Message: " & d.message & ", Flow: " & d.flowId
  var dresp = " Data: no data"
  if d.contents != nil:
    try:
      dresp = " Data: " & $d.contents
    except:
      dresp = " Data: unprintable"
  result &= dresp

proc callSubscribers[T](flow: DataFlow[T], d: DataContainer) =
  for cb in flow.subscribers:
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

proc subscribe*[T](flow: var DataFlow[T], cb: proc(d: DataContainer[T])) =
  flow.subscribers.add(cb)
    
    
  
