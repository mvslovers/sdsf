-- test/tso/inits.lua -- INIT, the initiators, as on IBM's SDSF V1R2: from the
-- answer of JES2 to $DI; the title, the heading, an inactive initiator and
-- the active one that runs ZSWA (submitted by mbt/init.lua, waiting for its
-- reply), with its step and address space.
local function body(t)
  t:type("INIT"):enter()
  t:expect("SDSF INITIATOR DISPLAY")
  print(t:text())
  local s = t:screen()
  if s[1]:sub(1, 23) ~= " SDSF INITIATOR DISPLAY" or s[1]:sub(57, 60) ~= "LINE" then
    error("the title is not as in IBM's SDSF V1R2: " .. s[1])
  end
  if s[3] ~= " NP ID STATUS     CLASSES  JOB-NAME STEP-NAME PROC-STEP TYPE JNUM  C ASID" then
    error("the heading is not as in IBM's SDSF V1R2: " .. s[3])
  end
  -- ID up to 6, STATUS from 8, CLASSES from 19
  local inactive, zswa
  for _, l in ipairs(s) do
    if l:find("^ +%d+ INACTIVE   %u") and l:sub(8, 8) ~= " " then inactive = l end
    if l:find("^ +%d+ ACTIVE  ") and l:sub(28, 31) == "ZSWA" then zswa = l end
  end
  if not inactive then error("no inactive initiator in the columns of IBM's SDSF V1R2") end
  if not zswa then error("no active initiator with ZSWA") end
  -- STEP-NAME RUN, TYPE JOB, JNUM up to 66, class A, an ASID
  if zswa:sub(37, 39) ~= "RUN" or zswa:sub(57, 59) ~= "JOB"
     or not zswa:sub(62, 66):find("^ *%d+$") or zswa:sub(68, 68) ~= "A"
     or not zswa:sub(70, 73):find("^ *%d+$") then
    error("the row of ZSWA is not as in IBM's SDSF V1R2: " .. zswa)
  end
  t:type("INIT X"):enter()
  t:expect("TOO MANY PARMS")
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
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
