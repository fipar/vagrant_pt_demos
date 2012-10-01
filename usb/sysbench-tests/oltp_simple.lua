pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

function thread_init(thread_id)
   set_vars()

end

function event(thread_id)
   local table_name
   -- table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)
   table_name = "sbtest".. thread_id+1
   val = sb_rand(1, oltp_table_size)
   -- print ("Value " .. table_name .. " id:" .. val .. "\n") 
   rs = db_query("SELECT c FROM ".. table_name .." WHERE id=" .. val)
end
