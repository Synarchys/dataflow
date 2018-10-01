
import unittest

import json, tables , sugar
import dataflow

var df = createFlow[JsonNode]("myFlow", {"option1": "value1"}.toTable)
var stringFlow = createFlow[string]("stringFlow")

echo $df
echo $stringFlow

var d = DataContainer[JsonNode](id: "1", contents: %*{"name": "asdqwe"})

proc changes[T](d: DataContainer[T]){.nimcall.} =
  echo " There are changes: " & $d

let subsID = df.subscribe(changes)

echo "Subscriber ID: " & subsID

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
let res = df.unsubscribe(subsID)
echo res
