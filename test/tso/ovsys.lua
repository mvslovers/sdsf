-- test/tso/ovsys.lua -- overtyping on PR, INIT and DA, as in
-- IBM's SDSF V1R2: PR SFORM ($TPRTn,F=), SCLASS ($TPRTn,Q=), SEP ($TPRTn,S=, on
-- the first PF11 page), SFCB ($TPRTn,C=) and SDEST1 ($TPRTn,R=), INIT CLASSES ($TIn,classes), DA PGN (E name,
-- PERFORM=n). The title says COMMAND ISSUED, the row shows the new value
-- after the next Enter (DA: the RESET is looked for in the log). A value
-- that is no class or no number is refused with the value kept and nothing
-- sent. Every value is put back at once: PRINTER3, the
-- last initiator and this session's PGN are as they were at the end.
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function rowof(t, pat)
  local s = t:screen()
  for r = 4, #s do if s[r]:find(pat) then return r end end
end

-- the input fields of row r other than NP, as screen columns
local function stops(t, r)
  local out, seen = {}, {}
  for _ = 1, 200 do
    t:tab()
    local cr, cc = t:cursor()
    local k = cr .. "," .. cc
    if seen[k] then break end
    seen[k] = true
    if cr == r and cc > 5 then out[#out + 1] = cc end
  end
  table.sort(out)
  return out
end

local function goto_field(t, r, c)
  for _ = 1, 200 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == r and cc == c then return end
  end
  error("no field at " .. r .. "," .. c)
end

local function value(t, r, c, len)
  local v = t:screen()[r]:sub(c, c + len - 1):gsub("%z", " ")
  return (v:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- overtype the field at screen column c of the row matching pat (typed
-- from column at, the start of its input field, with lead in front),
-- check the title and the row after Enter
local function ov(t, pat, c, len, new, what, at, lead)
  local r = rowof(t, pat)
  want(r, "no row " .. pat, t)
  goto_field(t, r, at or c)
  t:type((lead or "") .. new .. string.rep(" ", len - #new)):enter()
  want(t:screen()[1]:find("COMMAND ISSUED", 1, true), what .. ": " .. t:screen()[1], t)
  t:enter()
  r = rowof(t, pat)
  want(value(t, r, c, len) == new, what .. ": the row shows " .. value(t, r, c, len), t)
end

local function body(t)
  -- PR: PRINTER3's SFORM, SCLASS and, a page to the right, SEP
  t:type("PR"):enter()
  t:expect("SDSF PRINTER DISPLAY")
  local r = rowof(t, "PRINTER3")
  want(r, "no PRINTER3", t)
  -- SFORM and SCLASS are one input field (Wally ISPF), read apart
  local st = stops(t, r)
  want(st[1] == 25 and #st == 1, "PR fields at " .. table.concat(st, ","), t)
  local form, class = value(t, r, 25, 4), value(t, r, 30, 15)
  local lead = form .. string.rep(" ", 5 - #form)
  ov(t, "PRINTER3", 25, 4, "ZZZ", "PR SFORM")
  ov(t, "PRINTER3", 25, 4, form, "PR SFORM back")
  ov(t, "PRINTER3", 30, 15, class .. "K", "PR SCLASS", 25, lead)
  ov(t, "PRINTER3", 30, 15, class, "PR SCLASS back", 25, lead)
  t:pf(11)
  r = rowof(t, "PRINTER3")
  st = stops(t, r)
  want(#st >= 1, "no SEP field after PF11", t)
  local sep = value(t, r, st[1], 3)
  ov(t, "PRINTER3", st[1], 3, sep == "YES" and "NO" or "YES", "PR SEP")
  ov(t, "PRINTER3", st[1], 3, sep, "PR SEP back")
  -- SFCB ($TPRTn,C=) and SDEST1 ($TPRTn,R=), further right
  for _, f in ipairs({ { "SFCB", 4, "8" }, { "SDEST1", 8, "U1" } }) do
    for _ = 1, 6 do
      if t:screen()[3]:find(" " .. f[1] .. " ", 1, true) then break end
      t:pf(11)
    end
    local h = t:screen()[3]:find(" " .. f[1] .. " ", 1, true)
    want(h, "no page with " .. f[1], t)
    r = rowof(t, "PRINTER3")
    local c
    for _, x in ipairs(stops(t, r)) do if x == h + 1 then c = x end end
    want(c, "no input field under " .. f[1], t)
    local old = value(t, r, c, f[2])
    ov(t, "PRINTER3", c, f[2], f[3], "PR " .. f[1])
    ov(t, "PRINTER3", c, f[2], old, "PR " .. f[1] .. " back")
  end
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")

  -- INIT: the classes of the last initiator; a value that is no class
  t:type("INIT"):enter()
  t:expect("SDSF INITIATOR DISPLAY")
  local s, last = t:screen(), nil
  for i = 4, #s do if s[i]:match("^%s+%d+ %u") then last = i end end
  want(last, "no initiator", t)
  local id = s[last]:match("^%s+(%d+) ")
  local pat = "^%s+" .. id .. " "
  local cls = value(t, last, 19, 8)
  -- JES2 4.1 keeps five classes at most (it says OK to more and drops them)
  local more = #cls < 5 and cls .. "Z" or cls:sub(1, #cls - 1) .. "Z"
  ov(t, pat, 19, 8, more, "INIT CLASSES")
  ov(t, pat, 19, 8, cls, "INIT CLASSES back")
  goto_field(t, last, 19)
  t:type("A$      "):enter()
  want(t:screen()[1]:find("INVALID CLASS", 1, true), "A$ is taken: " .. t:screen()[1], t)
  want(value(t, last, 19, 8) == "A$", "the value typed is gone", t)
  goto_field(t, last, 19)
  t:type(cls .. string.rep(" ", 8 - #cls)):enter()
  t:enter()
  want(value(t, rowof(t, pat), 19, 8) == cls, "INIT classes not back", t)
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")

  -- DA: this session's PGN
  t:type("DA"):enter()
  t:expect("SDSF DA")
  r = rowof(t, " IBMUSER .* TSU ")
  want(r, "this session is not on DA", t)
  st = stops(t, r)
  want(#st >= 1, "no PGN field", t)
  -- (MVS may move a TSO user to another group by itself, so the command
  -- is looked for in the log, not the row; the session ends with the test)
  local pgn = value(t, r, st[1], 3)
  local other = pgn == "1" and "2" or "1"
  goto_field(t, r, st[1])
  t:type(other .. "  "):enter()
  want(t:screen()[1]:find("COMMAND ISSUED", 1, true), "DA PGN: " .. t:screen()[1], t)
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  t:type("BOTTOM"):enter()
  t:enter()
  want(t:text():find("E IBMUSER,PERFORM=" .. other, 1, true), "no RESET in the log", t)
  -- a PGN that is no number: refused, nothing sent
  t:pf(3)
  t:type("DA"):enter()
  t:expect("SDSF DA")
  r = rowof(t, " IBMUSER .* TSU ")
  goto_field(t, r, st[1])
  t:type("X  "):enter()
  want(t:screen()[1]:find("FIELD NOT NUMERIC", 1, true), "DA PGN X: " .. t:screen()[1], t)
  goto_field(t, r, st[1])
  t:type(pgn .. string.rep(" ", 3 - #pgn)):enter()
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
  if not ok then print(err); print(t:text()) end
  for _ = 1, 4 do
    if t:text():find("Primary Option Menu", 1, true) then break end
    t:pf(3)
  end
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
