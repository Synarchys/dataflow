
## A PostgreSQL  automatic JSON CRUD library
## 

import db_postgres, os, json, times, strutils, tables, uri, sequtils, sugar
import strformat 
import webcontext 

var pg: DbConn
var db_schema: seq[DBTable]


type
  DBColumn* = object
    ## Column description
    name*: string
    ctype*: string
  DBTable* = object
    ## Table description
    name*: string 
    columns*: seq[DBColumn]
    

proc get_columns*(db_name, db_table: string): seq[DBColumn] =
  ## Gets a seq of DBColumn for the given table
  result = @[]
  let rows = pg.getAllRows(sql"""
     select
      column_name, data_type
     from
       information_schema.columns
     where
       table_catalog = ?
       and table_name = ?
       and table_schema = 'public'
    """, db_name, db_table)
  #echo "Columns:\n"
  for r in rows:
    #echo $r 
    result.add(DBColumn(name:r[0], ctype:r[1]))
  #echo "Columns: "
  #echo result


proc get_tables*(db_name: string): seq[DBTable] =
  ## Gets the tables with its columns from a given database
  result = @[]
  let rows = pg.getAllRows(sql"""
   select
    table_name
   from
     information_schema.tables
   where
     table_catalog = ? 
     and table_schema = 'public'
     and table_type = 'BASE TABLE';
  """, db_name)
  for r in rows:
    let cols = get_columns(db_name, r[0])
    result.add(DBTable(name:r[0], columns:cols))
  #echo "Tables: "  
  #echo result
  #db_schema = result  
  


proc initAutoPg*(c: DbConn, schema_name: string) =
  ## Init autopg with a valid connection to the database and a database name.
  ## The conection thould have permission to read "information_schema.tables"
  ## and "information_schema.columns" for the given catalog
  pg = c
  db_schema = get_tables(schema_name)


proc get_data*(db_table: string, ctx: WebContext): JsonNode =
  ## Returns data from a table in JSON format, it takes key/values from
  ## WebContext to generate the query.
  ## At this time only equality is tested.
  #echo $ctx.request.paramTable
  var whereClause = ""
  if ctx.request.paramTable.len > 0 :
    whereClause = " where "
    #echo "\nparams:\n"
    for key, value in ctx.request.paramTable:
      let val = decodeUrl(value)
      #echo key & " --> " & val
      whereClause.add(key & " = '" & val & "' and ")
    whereClause.delete(whereClause.len - 4, whereClause.len - 1)
  #echo "whereClause: " & whereClause
  var statement = "select to_json(k) from (select array_to_json(array_agg(row_to_json(j))) as " & db_table & " from (select * from " & db_table & whereClause & " ) j) k"
  #echo " Select Statement: " & statement
  let rows = pg.getAllRows(sql(statement))
  #echo "\n====== rows: \n" & $rows & "\n=========\n"
  if rows[0].len > 0:
    result = parseJson($rows[0][0])
  else:
    result = %*{"message": "No rows found"}

               
proc post_data*(db_table: string, d: JsonNode): JsonNode =
  ## Inserts JSON data to a given table.
  ## It receives an array of records to be inserted
  ## If the column is not present in the given json, a NULL value is inserted
  ## Fields that does not correspond to any column is discarded
  ## Fields are converted to the database type before insertion.
  if d.kind == JObject:
    for k, v in d:
      let data = v
      let tables = db_schema.filter do (t:DBTable) -> bool : t.name == db_table
      var columns: seq[DBColumn]
      if tables.len > 0:
        columns = tables[0].columns
      else:
        result = %*{"error_message":"invalid table"}
      var values = ""
      for item in data:
        values = values & " ("
        for c in columns:
          #echo "Column name: " & c.name & " || type: " & c.ctype
          var qt = "'"
          if not item.haskey(c.name) or item[c.name].kind == JNull:
            values = values & " null " & ", "
          else: 
            case c.ctype:
              of "int":
                values = values & $item[c.name].getInt() & ", "
              of "smallint":
                values = values & $item[c.name].getInt() & ", "
              of "boolean":
                values = values & $item[c.name].getBool() & ", "
              of "numeric":
                values = values & $item[c.name].getFloat & ", "
              else: 
                values = values & qt & item[c.name].getStr() & qt & ", "
        values.delete(values.len - 1, values.len)
        values = values & " ), "
      values.delete(values.len - 1, values.len)  
      var statement = "INSERT INTO " & db_table & " ("
      for c in columns:
        statement = statement & c.name & ", "
      statement.delete(statement.len - 1, statement.len)
      statement = statement & ") VALUES " & values 
      pg.exec(sql(statement))
      result = %*{ "inserted": data.len}


proc delete_data*(db_table: string, ctx: WebContext): JsonNode =
  ## Deletes items from a table.
  ## it uses key/values from context tu generate the query
  ## if no key/values are present, all data is deleted
  var statement = "DELETE FROM " & db_table 
  var whereStmt = ""
  if ctx.request.paramList.len > 0:
    statement.add " WHERE id IN ("
    for id in ctx.request.paramList:
      statement.add dbQuote(id) & ", "
    statement.delete(statement.len - 1 , statement.len)
    statement.add ")"
  #echo "DELETE Statement: " & statement
  pg.exec(sql(statement))
  result = %*{"deleted": ctx.request.paramList.len}


proc put_data*(db_table: string, d: JsonNode): JsonNode =
  ## Updates records on a given table with a JSON object.
  ## It receives an array of records to be updated
  ## If the column is not present in the given json, a NULL value is inserted
  ## Fields that does not correspond to any column is discarded
  ## Fields are converted to the database type before insertion.
  if d.kind == JObject:
    for k, v in d:
      let data = v
      let tables = db_schema.filter do (t:DBTable) -> bool : t.name == db_table
      var columns: seq[DBColumn]
      if tables.len > 0:
        columns = tables[0].columns
      else:
        result = %*{"error_message":"invalid table"}
      var setClause: string 
      var statement: string 
      for item in data:
        setClause = ""
        statement = ""
        for c in columns:
          #echo "Column name: " & c.name & " || type: " & c.ctype
          var qt = "'"
          if not item.haskey(c.name) or item[c.name].kind == JNull:
            setClause = setClause & c.name & " =  null " & ", "
          else:
            setClause = setClause & c.name & " = " 
            case c.ctype:
              of "int":
                setClause = setClause & $item[c.name].getInt() & ", "
              of "smallint":
                setClause = setClause & $item[c.name].getInt() & ", "
              of "boolean":
                setClause = setClause & $item[c.name].getBool() & ", "
              of "numeric":
                setClause = setClause & $item[c.name].getFloat & ", "
              else: 
                setClause = setClause & dbQuote(item[c.name].getStr()) & ", "
                
        setClause.delete(setClause.len - 1, setClause.len)
        var statement = "UPDATE " & db_table & " SET " & setClause & " WHERE id =  " & dbQuote(item["id"].getStr())
        #echo "Statement: " & statement   
        pg.exec(sql(statement))
        result = %*{ "updated": data.len}               
