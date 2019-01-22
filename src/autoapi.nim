## Automatic api generation example based on schema from auto_pg

import webcontext
import httpcore, json, db_common, tables, strutils
import auto_pg 

let schema_name = ""

proc auto_api*(ctx: WebContext): WebContext =
  result = ctx.copy()
  #echo "auto:\n" & $ctx
  let schema = get_tables(schema_name)
  var tables: seq[string] = @[]
  #var t: DBTable
  for t in schema:
    #echo "table:"
    #echo t.name
    tables.add(t.name)
  #echo "\ntables: " & $tables & "\n====\n"
  let tname = ctx.request.urlpath[1]
  if tname in tables:
#    echo "\n===Table name: \n" & ctx.request.urlpath[1] & "\n--------\n"
    #echo "ok"
    case ctx.request.reqMethod:
      of HttpGet:
        #echo "\nGET: " & ctx.request.body
        result.response.body = $get_data(tname, ctx)
        result.response.status = Http200
      of HttpPost:
        #echo "\nPOST: " & ctx.request.body
        #echo "Json Body: " & $parseJson(ctx.request.body)
        result.response.body = $post_data(tname, parseJson(ctx.request.body))
        result.response.status = Http200
      of HttpPut:
        #echo "\nPUT: " & ctx.request.body
        result.response.body = $put_data(tname, parseJson(ctx.request.body))
        result.response.status = Http200
      of HttpDelete:
        #echo "\nDELETE: " & ctx.request.body
        result.response.body = $delete_data(tname, ctx)
        result.response.status = Http200
      else:
        result.response.body = """{"error":"Method not found"}"""
        result.response.status = Http404 
  else:
    echo "404"
    result.response.body = """{"status":"OK", "code": 404, "message":"Not found"}"""
    result.response.status = Http404

  
