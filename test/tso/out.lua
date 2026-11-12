-- test/tso/out.lua -- from the Status panel: ? lists the data sets of a job,
-- S on one of them shows its lines, END goes back one panel at a time; S on
-- a job shows all of them, and ST from below comes back to a fresh list.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

-- how many tabs from the command line to the NP of the first job on PRINT
-- the row of the first batch job on PRINT on this page
local function print_row(t)
  local s = t:screen()
  for r = 4, #s do
    if s[r]:find(" PRINT ", 1, true) then return r, s[r] end
  end
  error("no batch job on PRINT on this page")
end

-- Tab until the cursor is in NP of row r: a row has more fields than NP
-- (PRTY and DEST can be overtyped, as in IBM's SDSF V1R2)
local function to_np(t, r)
  for _ = 1, 80 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == r and cc == 2 then return end
  end
  error("NP of row " .. r .. " not reached")
end

local function select_job(t, action)
  local r, line = print_row(t)
  print("selecting: " .. line)
  to_np(t, r)
  t:type(action):enter()
end

local function body(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  while not t:text():find(" PRINT ", 1, true) do t:pf(8) end

  select_job(t, "?")
  t:expect("JOB DATA SET DISPLAY")
  print(t:text())
  has(t, "DDNAME")
  has(t, "JESMSGLG JES2")
  -- the columns right of DDNAME move, DDNAME stays
  t:pf(11)
  print(t:text())
  has(t, "-GRP-N")
  has(t, "PRMODE")
  has(t, "JESMSGLG")
  t:pf(11)
  print(t:text())
  has(t, "FLASH")
  t:pf(10); t:pf(10)
  has(t, "STEP-NAME")

  -- S on the first data set
  t:tab(); t:tab(); t:type("S"):enter()
  t:expect("SDSF OUTPUT DISPLAY")
  print(t:text())
  has(t, "TOP OF DATA")
  has(t, "COLUMNS  02-  81")
  -- one record is one line, as in IBM's SDSF V1R2: the JES2 of this system spaces
  -- after the title of the job log with the control byte alone, so no
  -- blank line follows it, and the page eject in front of it is no line
  if not t:text():find("TOP OF DATA[^\n]*\n *J E S 2   J O B   L O G[^\n]*\n[^\n]*%S") then
    print(t:text())
    error("the job log does not start with its title and a line of text")
  end
  -- the lines are protected: the first of them stays as it was when the
  -- scroll field is typed full; a key past it does not reach them
  t:tab(); t:type("PAGEX")
  local row = 0
  for l in t:text():gmatch("[^\n]+") do
    row = row + 1
    if row == 3 and not l:find("^%*%*%*") then
      print(t:text())
      error("typed into the output")
    end
  end
  t:enter()
  has(t, "SCROLL ===> PAGE")
  has(t, "\n****")     -- all of the first column of the first row is there
  t:type("  "):enter()
  t:pf(11)
  has(t, "COLUMNS  82- 161")
  t:pf(10)
  has(t, "COLUMNS  02-  81")
  t:type("BOTTOM"):enter()
  print(t:text())
  has(t, "BOTTOM OF DATA")
  t:type("TOP"):enter()
  has(t, "TOP OF DATA")
  -- a word in front of a scroll key is used for that scroll, and is gone
  t:type("M"):pf(8)
  has(t, "BOTTOM OF DATA")
  if t:text():find("INPUT ===> M", 1, true) then error("M stayed") end
  t:type("MAX"):pf(7)
  has(t, "TOP OF DATA")
  if t:text():find("INPUT ===> MAX", 1, true) then error("MAX stayed") end
  t:type("2"):pf(8)
  has(t, "LINE       2")
  t:type("XY"):pf(8)
  t:expect("INVALID SCROLL AMOUNT")
  t:type("  "):enter()
  t:type("TOP"):enter()
  t:pf(3)
  t:expect("JOB DATA SET DISPLAY")
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")

  -- S on the job: everything, in one
  select_job(t, "S")
  t:expect("SDSF OUTPUT DISPLAY")
  print(t:text())
  -- ST from below is a fresh list; END from there is the menu
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  -- as in IBM's SDSF V1R2, coming from the output
  has(t, "DATA SET DISPLAYED")
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
