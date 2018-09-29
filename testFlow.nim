import json, tables , sugar
import dataflow

var df = createFlow[JsonNode]("myFlow", {"option1": "value1"}.toTable)
echo $df
var d = DataContainer[JsonNode](id: "1", content: %*{"name": "asdqwe"})

df.put(d, proc(d: DataContainer[JsonNode]) = echo $d)

proc changes(d: DataContainer[JsonNode]){.nimcall.} =
  echo " there are changes"
  echo $d
  #df.seek(id, proc(e:DataContainer[JsonNode]) = echo $e)

df.subscribe(changes)

df.seek("1", proc(e:DataContainer[JsonNode]) = echo $e)
df.seek("2", proc(e:DataContainer[JsonNode]) = echo $e)
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
