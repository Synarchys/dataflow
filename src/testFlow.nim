
import unittest

import json, tables , sugar
import dataflow

var df = createFlow[JsonNode]("myFlow", {"option1": "value1"}.toTable)
echo $df
var d = DataContainer[JsonNode](id: "1", contents: %*{"name": "asdqwe"})

proc changes(d: DataContainer[JsonNode]){.nimcall.} =
  echo " There are changes: " & $d

df.subscribe(changes)

df.put(d, proc(d: DataContainer[JsonNode]) = echo $d)
df.seek("1", proc(e:DataContainer[JsonNode]) =
  echo $e
)

echo df
df.seek("2",
        proc(e:DataContainer[JsonNode]) =
          echo $e
)
echo df
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
echo df
df.evict("1", proc(e:DataContainer[JsonNode]) = echo $e)
echo df
