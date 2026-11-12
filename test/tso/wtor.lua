-- test/tso/wtor.lua -- the outstanding replies at the end of the log, by
-- ACTION: as in IBM's SDSF V1R2 they follow its last line, newest first, each as a
-- log line with the routing codes in front.
-- It needs a job of its own waiting for a reply: test/jcl/zswa.jcl, which
-- runs ISFWTOR with PARM='SDSF WTOR AUTO' and ends when it is answered;
-- mbt/init.lua submits it before the TSO tests. The test answers it itself,
-- with /R nn on the log, and the reply goes away.
-- ACTION OFF shows none, any other setting this one (ISFWTOR asks with all
-- routing codes), the setting adds up and ? tells it; ACTION works on the
-- Status panel and on the menu as well. It leaves ACTION OFF.
local TEXT = "ISFWTOR SDSF WTOR AUTO"

local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

-- the reply of the test's job, among the replies: they follow the last line
-- of the log, right above BOTTOM OF DATA, each in the form of a log line
-- with a reply id; the line the WTOR left in the log itself is further up
local function shown(t)
  local lines = {}
  for l in t:text():gmatch("[^\n]*") do lines[#lines + 1] = l end
  for i = #lines, 1, -1 do
    if lines[i]:find("BOTTOM OF DATA", 1, true) then
      for k = i - 1, 1, -1 do
        local l = lines[k]
        if not l:find("^%x%x%x%x .- @%d%d ") then return nil end
        if l:find("@%d%d " .. TEXT) then return l end
      end
      return nil
    end
  end
end

-- the end of the log after a change: the screen itself stays, as in IBM's SDSF V1R2
local function bottom(t)
  t:type("BOTTOM"):enter()
end

local function body(t)
  t:type("ACTION OFF"):enter()
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  if shown(t) then print(t:text()); error("a reply under the log with ACTION OFF") end
  t:type("ACTION ?"):enter()
  has(t, "ACTION=OFF")

  t:type("ACTION ALL"):enter()
  bottom(t)
  print(t:text())
  local l = shown(t)
  if not l then print(t:text()); error("no reply under the log with ACTION ALL") end
  if not l:find("@%d%d " .. TEXT) then error("not as on the log: " .. l) end
  t:type("ACTION ?"):enter()
  has(t, "ACTION=ALL")

  -- a code of its own, then one more: they add up
  t:type("ACTION OFF"):enter()
  t:type("ACTION 1"):enter()
  bottom(t)
  if not shown(t) then print(t:text()); error("no reply with ACTION 1") end
  t:type("ACTION 2 3"):enter()
  t:type("ACTION ?"):enter()
  has(t, "ACTION=1,2,3")
  -- as in IBM's SDSF V1R2: a code beyond 16 and ACTION alone change nothing and
  -- say nothing; OFF does not go with other words
  t:type("ACTION 17"):enter()
  t:type("ACTION"):enter()
  t:type("ACTION ?"):enter()
  has(t, "ACTION=1,2,3")
  t:type("ACTION OFF 3"):enter()
  has(t, "PARM INVALID")
  local r, c = t:cursor()
  if (t:screen()[2] or ""):sub(c, c + 2) ~= "OFF" then
    print(t:text()); error("the cursor is not on OFF but at " .. r .. "," .. c)
  end
  t:tab(); t:tab()
  t:type(string.rep(" ", 20)):enter()

  -- on the Status panel too, and the setting stays
  t:type("ACTION OFF"):enter()
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  t:type("ACTION MVS"):enter()
  t:type("ACTION ?"):enter()
  has(t, "ACTION=1,2,3,4,5,6,7,8,9,10,11,12")
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  bottom(t)
  local row = shown(t)
  if not row then print(t:text()); error("no reply with ACTION MVS") end

  -- answered from here, it is gone
  local id = row:match("@(%d%d) ISFWTOR")
  t:type("/R " .. id .. ",SDSF TEST DONE"):enter()
  has(t, "COMMAND ISSUED")
  for _ = 1, 5 do
    if not shown(t) then break end
    t:enter()
    bottom(t)
  end
  if shown(t) then print(t:text()); error("the reply is still there after /R " .. id) end
  t:type("ACTION OFF"):enter()
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  t:type("ACTION ?"):enter()
  has(t, "ACTION=OFF")
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
