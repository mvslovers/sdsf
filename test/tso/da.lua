-- test/tso/da.lua -- DA, the address spaces as on IBM's SDSF V1R2: the title,
-- the heading, the rows by ASID; the test's own TSO user and the waiting
-- batch job ZSWA (submitted by mbt/init.lua) are there, the idle
-- initiators only with DA ALL.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

-- the rows: name, step, procstep, type, position
local function rows(t)
  local list = {}
  for l in t:text():gmatch("[^\n]*") do
    local name = l:match("^    (%S+)")
    if name and #l > 44 then
      list[#list + 1] = { name = name, type = l:sub(32, 35):gsub("%s+$", ""),
                          pos = l:sub(45, 47):gsub("%s+$", ""), line = l }
    end
  end
  return list
end

local function find(list, name, typ)
  for _, r in ipairs(list) do
    if r.name == name and (typ == nil or r.type == typ) then return r end
  end
end

local function body(t)
  t:type("DA"):enter()
  t:expect("SDSF DA ")
  print(t:text())
  local s = t:screen()
  -- the title and the heading in the columns of IBM's SDSF V1R2
  if not s[1]:find("^ SDSF DA %S+ +PAGING +%d+%.%d%d SIO +%d+%.%d%d CPU +%d+%.%d%d%%") then
    error("the title is not as in IBM's SDSF V1R2: " .. s[1])
  end
  if s[3] ~= " NP JOBNAME  STEPNAME PROCSTEP TYPE JNUM  C POS DP PGN REAL PAGING   SIO   CPU%" then
    error("the heading is not as in IBM's SDSF V1R2: " .. s[3])
  end
  local list = rows(t)
  for _ = 1, 5 do
    if find(list, "IBMUSER", "TSU") and find(list, "ZSWA", "JOB") then break end
    t:pf(8)
    for _, r in ipairs(rows(t)) do list[#list + 1] = r end
  end
  if not find(list, "IBMUSER", "TSU") then error("the test's TSO user is not listed") end
  local job = find(list, "ZSWA", "JOB")
  if not job then error("the waiting batch job ZSWA is not listed") end
  if not job.line:find("^    ZSWA     RUN ") then error("ZSWA's step is not RUN: " .. job.line) end
  -- the rates: 0.00 on the first display, over the interval after Enter;
  -- this TSO session itself uses CPU in between
  t:enter()
  local cpu = tonumber(t:screen()[1]:match("CPU +(%d+%.%d%d)%%"))
  print(t:screen()[1])
  if not cpu or cpu <= 0 then error("no CPU busy over the interval: " .. t:screen()[1]) end
  local me = t:text():match("\n    IBMUSER [^\n]*")
  print(me)
  if not me or not me:find("%d+%.%d%d$") then error("no CPU% for the TSO user") end
  -- a TSO user's PROCSTEP is the terminal (as in IBM's SDSF V1R2), from the TSB
  if not me:find("^\n    IBMUSER  %S+ +%S+ +TSU") then
    error("no terminal as PROCSTEP of the TSO user: " .. me)
  end

  -- ? : the columns in the other order, both pages as in IBM's SDSF V1R2; ? back
  t:type("?"):enter()
  if t:screen()[3] ~= " NP JOBNAME  STEPNAME PROCSTEP TYPE JNUM  C ASID EXCP-CNT   CPU-TIME  REAL  PAGI" then
    print(t:text()); error("? on DA is not as in IBM's SDSF V1R2: " .. t:screen()[3])
  end
  t:pf(11)
  if t:screen()[3] ~= " NP JOBNAME ID EXCP-CNT   CPU-TIME  REAL  PAGING   SIO   CPU%  DP POS SR PGN DMN" then
    print(t:text()); error("? and PF11 on DA are not as in IBM's SDSF V1R2: " .. t:screen()[3])
  end
  t:pf(10)
  t:type("?"):enter()

  -- PF11: the right part, JOBNAME stays, as in IBM's SDSF V1R2; PF10 back
  t:pf(11)
  s = t:screen()
  if s[3] ~= " NP JOBNAME OS DP PGN REAL PAGING   SIO   CPU%  ASID EXCP-CNT   CPU-TIME  SR DMN" then
    print(t:text()); error("the right heading is not as in IBM's SDSF V1R2: " .. s[3])
  end
  print(t:text())
  if not t:text():find("\n    %*MASTER%* S FF +%d+ +[%d.]+ +[%d.]+ +[%d.]+ +1 +[%d,]+ +%d+%.%d%d") then
    error("the right part of *MASTER* is not as expected")
  end
  t:pf(11)
  if t:screen()[3] ~= s[3] then error("a second PF11 moved again") end
  t:pf(10)
  if t:screen()[3] ~= " NP JOBNAME  STEPNAME PROCSTEP TYPE JNUM  C POS DP PGN REAL PAGING   SIO   CPU%" then
    print(t:text()); error("PF10 did not come back")
  end
  -- an idle initiator: no type, no number
  local idle = "\n    INIT     INIT     IEFPROC  +[ONI][UN/][TS ]"
  if t:text():find(idle) then print(t:text()); error("an idle initiator without ALL") end
  t:type("TOP"):enter()
  t:type("DA ALL"):enter()
  local seen = false
  for _ = 1, 5 do
    if t:text():find(idle) then seen = true; break end
    t:pf(8)
  end
  if not seen then print(t:text()); error("DA ALL shows no idle initiator") end
  -- S on the waiting job shows its output, ? its data sets; END comes back
  local function select(t, name, action)
    local n = 0
    for l in t:text():gmatch("[^\n]*") do
      n = n + 1
      if l:find("^    " .. name .. " ") then
        for _ = 1, n - 2 do t:tab() end
        t:type(action):enter()
        return
      end
    end
    print(t:text()); error(name .. " is not on the screen")
  end
  t:type("DA OJOB"):enter()
  select(t, "ZSWA", "S")
  t:expect("SDSF OUTPUT DISPLAY ZSWA")
  t:pf(3)
  t:expect("SDSF DA ")
  select(t, "ZSWA", "?")
  t:expect("JOB DATA SET DISPLAY")
  has(t, "JESMSGLG")
  t:pf(3)
  t:expect("SDSF DA ")

  -- the parameters: only jobs; no TSO users; only swapped in (N/S counts
  -- as in); an idle initiator added to the rest
  local function types(t)
    local seen = {}
    for l in t:text():gmatch("[^\n]*") do
      if l:find("^    %S") and #l > 44 then
        local ty = l:sub(32, 35):gsub("%s+$", "")
        seen[ty] = true
        seen["pos:" .. l:sub(45, 47):gsub("%s+$", "")] = true
      end
    end
    return seen
  end
  t:type("DA OJOB"):enter()
  local x = types(t)
  if x.STC or x.TSU or not x.JOB then print(t:text()); error("DA OJOB is not only the jobs") end
  t:type("DA NOTSU"):enter()
  x = types(t)
  if x.TSU or not x.STC then print(t:text()); error("DA NOTSU shows a TSO user") end
  t:type("DA OIN"):enter()
  x = types(t)
  if x["pos:OUT"] then print(t:text()); error("DA OIN shows an address space that is out") end
  t:type("DA OINIT"):enter()
  if not t:text():find(idle) then print(t:text()); error("DA OINIT shows no idle initiator") end
  x = types(t)
  if x.STC or x.TSU or x.JOB then print(t:text()); error("DA OINIT shows more than initiators") end
  t:type("DA XYZ"):enter()
  has(t, "PARM INVALID")
  t:tab(); t:tab()
  t:type(string.rep(" ", 20)):enter()
  t:type("DA ALL OUT"):enter()
  has(t, "PARM INVALID")
  t:tab(); t:tab()
  t:type(string.rep(" ", 20)):enter()
  t:type("DA"):enter()
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
