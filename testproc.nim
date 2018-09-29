type
  Data*[T] = object
    contents: T
    subscribers: seq[proc(d: T)]

proc createData*[T](t: typedesc[T], c: T): Data[T] = 
  result = Data[T]()
  result.contents = c
  result.subscribers = @[]
  
proc addSubscriber*[T](d: var Data[T], cb: proc(d:T)) =
  d.subscribers.add(cb)

proc callSubscribers[T](d: T) =
  for n in d.subscribers:
    n(d.contents)

var dd = createData(string, "data")
proc print[T](d: T) =
  echo $d

dd.addSubscriber(print)

dd.callSubscribers()
