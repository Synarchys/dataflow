# imu dataflow manager
import json, tables, strformat, typetraits

type
  CallStatus* = object
    flowId*: string
    docId*: string
    error*: bool
    code*: int
    message*: string
  ChangeCB* = proc(s:CallStatus)
  DataContainer*[T] = ref object
    id*: string  
    content*: T
    status*: CallStatus
  DataFlow*[T] = ref object
    id: string
    options: Table[string, string]
    documents: Table[string, T]
    subscribers: seq[ChangeCB]

proc createFlow*[T](id: string, options: Table[string, string]): DataFlow[T] =
  result = DataFlow[T](id: id, options: options)
  result.documents = initTable[string, T]()
  result.subscribers = newSeq[proc(s: CallStatus)]()
  
proc `$`*[T](flow: DataFlow[T]): string =
  let typename = T.name
  result = fmt"""FlowType: {typename}, ID: {flow.id}"""
  #result.add("\n")
  #implement options printing section

proc `$`*[T](d:DataContainer[T]): string =
  let typename = T.name
  result = fmt"DataType: {typename}, ID: {d.id}, Error: {d.status.error}, Code: {d.status.code}, Message: {d.status.message}  "

proc callSubscribers[T](flow: DataFlow[T], s: CallStatus) =
  for cb in flow.subscribers:
    cb(s)
    
proc put*[T](flow: DataFlow[T], doc: var DataContainer[T], cb: proc(d: DataContainer[T])) = 
  if flow.documents.hasKey(doc.id):
    flow.documents[doc.id] = doc.content
    doc.status = CallStatus(code: 0, message: "changed")
  else:
    flow.documents.add(doc.id, doc.content)
    doc.status = CallStatus(code: 201, message: "inserted", docId: doc.id)
  flow.callSubscribers(doc.status)
  cb(doc)
  
proc seek*[T](flow: DataFlow[T], id: string, cb: proc(d: DataContainer[T])) =
  var d = DataContainer[T]()
  if flow.documents.hasKey(id):
    d.content = flow.documents[id]
    d.id = id
    d.status = CallStatus(code: 200,message: "ok", docId: id)
  else:
    d.status = CallStatus(error: true, code: 404, message: "Document not found", docId: id)
  cb(d)

proc evict*[T](flow: DataFlow[T], id: string, cb: proc(d: DataContainer[T])) =
  var d = DataContainer[T](id:id)
  if flow.documents.hasKey(id):
    flow.documents.del(id)
    d.status = CallStatus(code: 0, message: "deleted", docId: id, flowId: flow.id)
  else:
    d.id = id
    d.status = CallStatus(error: true, code: 404, message: "Document not found", docId: id)

proc subscribe*[T](flow: DataFlow[T], cb: proc(id: string)) =
  var d = DataContainer[T]()
  flow.subscribers.add(cb)
    
    
  
