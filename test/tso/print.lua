-- test/tso/print.lua -- PRINT, as in IBM's SDSF V1R2: PRINT OPEN
-- opens a SYSOUT file (a second time PRINT ALREADY OPEN), PRINT first last
-- writes those lines of the log in pages (n PAGES PRINTED, the log then
-- shows the first one) or of a job's output (n LINES PRINTED), PRINT alone
-- on an output all of it, PRINT CLOSE closes with the count. Without OPEN
-- the first PRINT opens one. PRINT CLOSE with none open says PRINT NOT
-- OPENED, a wrong word PARM INVALID, the cursor on the word. The print
-- files go to the session's own SYSOUT.
local function title_has(t, text)
  if not t:screen()[1]:find(text, 1, true) then
    print(t:text()); error("the title does not say " .. text .. ": " .. t:screen()[1])
  end
end

local function cursor_at(t, r, c, what)
  local cr, cc = t:cursor()
  if cr ~= r or cc ~= c then print(t:text()); error(what .. ": the cursor is at " .. cr .. "," .. cc) end
end

-- a command on a clean command line: one that was refused stays there
local function cmd(t, c)
  for _ = 1, 90 do
    local r, cc = t:cursor()
    if r == 2 and cc == 21 then break end
    t:tab()
  end
  t:type(c .. string.rep(" ", 40 - #c)):enter()
end

local function body(t)
  cmd(t, "LOG")
  t:expect("SDSF SYSLOG")
  cmd(t, "PRINT CLOSE")
  title_has(t, "PRINT NOT OPENED")
  cursor_at(t, 2, 27, "PRINT NOT OPENED")
  cmd(t, "PRINT OPEN")
  title_has(t, " PRINT OPENED")
  cmd(t, "PRINT OPEN")
  title_has(t, "PRINT ALREADY OPEN")
  cursor_at(t, 2, 27, "PRINT ALREADY OPEN")
  cmd(t, "PRINT 1 5")
  title_has(t, "         1 PAGES PRINTED")
  if not t:screen()[1]:find("LINE       1 ", 1, true) then
    print(t:text()); error("the log does not show line 1 after PRINT 1 5")
  end
  cmd(t, "PRINT X Y")
  title_has(t, "PARM INVALID")
  cursor_at(t, 2, 27, "PRINT X Y")
  cmd(t, "PRINT 3 2")
  title_has(t, "1 PAGES PRINTED")
  cmd(t, "PRINT CLOSE")
  title_has(t, "PRINT CLOSED      6 LINE")
  -- PRINT alone on the log opens, a range on a list is refused
  cmd(t, "PRINT")
  title_has(t, " PRINT OPENED")
  cmd(t, "PRINT CLOSE")
  title_has(t, "PRINT CLOSED      0 LINE")

  -- a job's output, all of it, into a file of class X opened by PRINT OPEN
  cmd(t, "ST")
  t:expect("SDSF STATUS DISPLAY")
  cmd(t, "PRINT 1 2")
  title_has(t, "PARM INVALID")
  cursor_at(t, 2, 27, "PRINT 1 2 on ST")
  cmd(t, "PRE ZSWA")
  local s, row = t:screen(), nil
  for r = 4, #s do if s[r]:find(" PRINT ", 1, true) then row = r; break end end
  if not row then print(t:text()); error("no ZSWA on the print queue") end
  for _ = 1, 80 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == row and cc == 2 then break end
  end
  t:type("S"):enter()
  t:expect("SDSF OUTPUT DISPLAY")
  -- a line whose first character is not blank: the print file must have
  -- it whole (the first character was taken for the carriage control)
  local needle
  for r = 5, #t:screen() do
    local l = t:screen()[r]
    if l:sub(1, 1):match("%S") and not l:find("*****", 1, true) then
      needle = l:sub(1, 30):gsub("%s+$", "")
      break
    end
  end
  if not needle then print(t:text()); error("no line to look for in the print file") end
  cmd(t, "PRINT OPEN X")
  title_has(t, " PRINT OPENED")
  cmd(t, "PRINT")
  local n = t:screen()[1]:match("(%d+) LINES PRINTED")
  if not n or tonumber(n) < 5 then print(t:text()); error("the output was not printed") end
  cmd(t, "PRINT CLOSE")
  title_has(t, string.format("PRINT CLOSED %6d LINE", tonumber(n)))
  t:pf(3)
  -- the print file, read back: the last data set of this TSO session
  cmd(t, "PRE IBMUSER")
  s, row = t:screen(), nil
  for r = 4, #s do
    if s[r]:find(" TSU ", 1, true) and s[r]:find("EXECUTION", 1, true) then row = r; break end
  end
  if not row then print(t:text()); error("this TSO session is not on ST") end
  for _ = 1, 80 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == row and cc == 2 then break end
  end
  t:type("?"):enter()
  t:expect("SDSF JOB DATA SET DISPLAY")
  s, row = t:screen(), nil
  for r = 4, #s do if s[r]:match("^%s+%S") then row = r end end
  if not row then print(t:text()); error("no print file among the data sets") end
  for _ = 1, 80 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == row and cc == 2 then break end
  end
  t:type("S"):enter()
  t:expect("SDSF OUTPUT DISPLAY")
  if not t:text():find(needle, 1, true) then
    print(t:text()); error("the print file does not have the line whole: " .. needle)
  end
  t:pf(3)
  t:pf(3)
  cmd(t, "PRE")
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("SDSF PRIMARY OPTION MENU")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
