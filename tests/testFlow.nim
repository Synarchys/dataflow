# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, json, sugar, tables


import dataflow

proc changes(d: DataContainer[JsonNode]){.nimcall.} =
  echo " There are changes: " & $d


suite "DataFlow tests ":
  echo "run once before tests"
  var df = createFlow[JsonNode]("myFlow", {"option1": "value1"}.toTable)
  var d = DataContainer[JsonNode](id: "1", contents: %*{"name": "asdqwe"})
  

  setup:
    echo " before each test"
    df.subscribe(changes)
    var dc: DataContainer[JsonNode]

#  teardown:
#    echo "run after each test"
    
  test "put document to flow":
    df.put(d, proc(d: DataContainer[JsonNode]) =
                dc = d)
    check(dc.error == false) 

  test "retrieve document from flow":
    df.seek("1", proc(d: DataContainer[JsonNode]) =
                   dc = d
    )
    check(dc.error == false)

  test "remove document":
    df.evict("1", proc(d:DataContainer[JsonNode]) = echo $d)
