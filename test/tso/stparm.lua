-- test/tso/stparm.lua -- ST with a name and with classes, and PREFIX: * for
-- any characters, % for one; PREFIX applies together with the name of ST, PREFIX ?
-- shows it on the command line, PREFIX alone shows all jobs again. It leaves
-- PREFIX unset.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

-- the jobs on the screen: name and type
local function jobs(t)
  local list, after = {}, false
  for l in t:text():gmatch("[^\n]*") do
    if after then
      local name, typ = l:match("^    (%S+)%s+(%u%u%u) ")
      if name then list[#list + 1] = { name = name, type = typ } end
    end
    if l:find("NP JOBNAME", 1, true) then after = true end
  end
  return list
end

-- every job on the screen passes, and there is one at least
local function all(t, what, ok)
  local list = jobs(t)
  if #list == 0 then print(t:text()); error(what .. ": no job on the list") end
  for _, j in ipairs(list) do
    if not ok(j) then print(t:text()); error(what .. ": " .. j.name .. " " .. j.type) end
  end
end

local function body(t)
  t:type("PREFIX"):enter()
  -- from the menu, with a name
  t:type("ST IBMUSER"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  print(t:text())
  all(t, "ST IBMUSER", function(j) return j.name == "IBMUSER" end)
  t:type("ST IBM*"):enter()
  all(t, "ST IBM*", function(j) return j.name:sub(1, 3) == "IBM" end)
  t:type("ST %NIT"):enter()
  all(t, "ST %NIT", function(j) return j.name == "INIT" end)
  t:type("ST *"):enter()
  local n = #jobs(t)
  -- classes: batch jobs of class A only, none from the print queue (as
  -- as in IBM's SDSF V1R2); there may be none at all
  t:type("STA"):enter()
  has(t, "SDSF STATUS DISPLAY CLASS A")
  print(t:text())
  for _, j in ipairs(jobs(t)) do
    if j.type ~= "JOB" then error("STA: " .. j.name .. " " .. j.type) end
  end
  if t:text():find(" PRINT ", 1, true) then error("STA listed the print queue") end
  t:type("ST ABCDEFGHI"):enter()
  has(t, "PARM INVALID")
  t:type("            "):enter()

  -- PREFIX goes before the name of ST; ST alone ends the classes
  t:type("ST"):enter()
  has(t, "SDSF STATUS DISPLAY ALL CLASSES")
  t:type("PREFIX INIT"):enter()
  all(t, "PREFIX INIT", function(j) return j.name == "INIT" end)
  -- both apply, as in IBM's SDSF V1R2: no job is INIT and IBMUSER
  t:type("ST IBMUSER"):enter()
  if #jobs(t) ~= 0 then print(t:text()); error("PREFIX INIT and ST IBMUSER listed jobs") end
  has(t, "LINE 0-0 (0)")
  t:type("ST"):enter()
  all(t, "PREFIX INIT, ST", function(j) return j.name == "INIT" end)
  t:type("PREFIX ?"):enter()
  has(t, "INPUT ===> PREFIX INIT * %")
  -- typed over the line ? left there, all of it
  t:type("PREFIX                    "):enter()
  t:type("ST"):enter()
  if #jobs(t) < n then error("PREFIX alone did not show all jobs again") end
  t:type("PREFIX ?"):enter()
  -- none set reads as *, as in IBM's SDSF V1R2
  has(t, "INPUT ===> PREFIX * * %")
  t:type("      "):enter()
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("COMMAND INPUT")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
