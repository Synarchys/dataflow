import json, tables , sugar
import dataflow

let df = createFlow[JsonNode]("myFlow", {"option1": "value1"}.toTable)
echo $df
var d = DataContainer[JsonNode](id: "1", content: %*{"name": "asdqwe"})

df.put(d, proc(e:DataContainer[JsonNode]) = echo $e)

proc changes(id: string) =
  echo " there are changes"
  df.seek(id, proc(e:DataContainer[JsonNode]) = echo $e)

df.subscribe(changes)


df.seek("1", proc(e:DataContainer[JsonNode]) = echo $e)
df.seek("2", proc(e:DataContainer[JsonNode]) = echo $e)
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
