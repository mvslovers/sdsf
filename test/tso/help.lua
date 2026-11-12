-- test/tso/help.lua -- the help and the tutorial: the Help key, HELP
-- and TUTOR reach the driver of isfhelp.c from the menu and from the
-- panels; a topic number, Enter, the Left and Up keys, T and I move through
-- the panels; an SDSF command is refused there; the End key goes back to
-- the SDSF panel the help came from. Every subject of the index and every
-- panel of the tutorial is there (no PANEL NOT FOUND). Needs the ISFH*,
-- ISFK*, ISFX* and ISFT* panels in the ISPPLIB concatenation (mbt run
-- panels).
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function lacks(t, text)
  if t:text():find(text, 1, true) then
    print(t:text())
    error("on the screen: " .. text)
  end
end

-- the help of a panel, and back to it
local function panel_help(t, cmd, title, help)
  t:type(cmd):enter()
  t:expect(title)
  t:pf(1)
  t:expect(help)
  lacks(t, "NO HELP FOR THIS PANEL YET")
  t:pf(3)
  t:expect(title)
  lacks(t, "HELP:")
end

-- every subject of an index page: shown, then back with the Left key
local function index_page(t, title, n)
  for i = 1, n do
    t:type(tostring(i)):enter()
    lacks(t, "PANEL NOT FOUND")
    lacks(t, "INVALID OPTION")
    lacks(t, title)
    t:pf(10)
    t:expect(title)
  end
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("SDSF PRIMARY OPTION MENU")

  -- the Help key on the menu: the menu's help
  t:pf(1)
  t:expect("HELP: SDSF Primary Option Menu")
  -- a topic number, then Enter, the Left key and the Up key
  t:type("6"):enter()
  t:expect("HELP: Status Panel")
  t:enter()
  t:expect("the ST Command")
  t:pf(10)
  t:expect("HELP: Status Panel")
  lacks(t, "the ST Command")
  t:pf(7)
  t:expect("SDSF Table of Contents")
  -- I, Enter to the next page of the index, T
  t:type("I"):enter()
  t:expect("HELP: Index -- A to D")
  index_page(t, "Index -- A to D", 16)
  t:enter()
  t:expect("HELP: Index -- D to I")
  index_page(t, "Index -- D to I", 15)
  t:type("7"):enter()
  t:expect("Using Help and the Tutorial")
  t:pf(10)
  t:enter()
  t:expect("HELP: Index -- J to O")
  index_page(t, "Index -- J to O", 17)
  t:enter()
  t:expect("HELP: Index -- P")
  index_page(t, "Index -- P", 5)
  t:enter()
  t:expect("HELP: Index -- R to Z")
  index_page(t, "Index -- R to Z", 15)
  t:type("T"):enter()
  t:expect("SDSF Table of Contents")
  -- the commands of every panel, and a topic of them
  t:type("12"):enter()
  t:expect("HELP: Commands on Every Panel")
  t:type("5"):enter()
  t:expect("HELP: Commands -- FIND")
  t:enter()
  t:expect("HELP: Commands -- FIND, more")
  t:type("T"):enter()
  -- the messages, all six pages
  t:type("15"):enter()
  t:expect("HELP: Messages -- A to C")
  for _, p in ipairs({ "C to I", "I to J", "L to N", "N to P", "P to Z" }) do
    t:enter()
    t:expect("HELP: Messages -- " .. p)
  end
  t:enter()
  t:expect("SDSF Table of Contents")
  -- an SDSF command is no good here
  t:type("ST"):enter()
  t:expect("INVALID OPTION")
  has(t, "SDSF Table of Contents")
  -- the End key: back on the menu
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  lacks(t, "HELP:")

  -- on ST: the Help key gives ST's help, END goes back to ST
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:pf(1)
  t:expect("HELP: Status Panel")
  t:type("2"):enter()
  t:expect("Action Characters")
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY")
  lacks(t, "HELP:")
  -- HELP typed is the help, not H with class ELP
  t:type("HELP"):enter()
  t:expect("HELP: Status Panel")
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY")
  lacks(t, "HELD OUTPUT")

  -- the help of the other panels
  panel_help(t, "DA", "SDSF DA", "HELP: DA Panel")
  panel_help(t, "I", "SDSF INPUT QUEUE DISPLAY", "HELP: Input Queue Panel")
  panel_help(t, "O", "SDSF OUTPUT", "HELP: Output Queue Panel")
  panel_help(t, "H", "SDSF HELD OUTPUT DISPLAY", "HELP: Held Output Panel")
  panel_help(t, "PR", "SDSF PRINTER DISPLAY", "HELP: Printer Panel")
  panel_help(t, "INIT", "SDSF INITIATOR DISPLAY", "HELP: Initiator Panel")
  panel_help(t, "LOG", "SDSF SYSLOG", "HELP: System Log Panel")

  -- TUTOR: the tutorial's list of parts; Enter goes through all of them.
  -- On the panels with an SDSF panel to try, the answer is typed: in the
  -- NP column (HN, one tab from the command line) or on the command line.
  t:type("TUTOR"):enter()
  t:expect("TUTORIAL: SDSF")
  t:enter()
  local walk = {
    "TUTORIAL: Using the Tutorial",
    "TUTORIAL: The SDSF Panels",
    "TUTORIAL: The SDSF Panels, a List",
    "TUTORIAL: Following a Job",
    { "TUTORIAL: Following a Job, the Status Panel", "?" },
    "TUTORIAL: Following a Job, its Data Sets",
    { "TUTORIAL: Looking at Output", "S" },
    "TUTORIAL: Looking at Output, the Data Set",
    "TUTORIAL: Looking at Output, FIND and PRINT",
    "TUTORIAL: Acting on Jobs",
    { "TUTORIAL: Acting on Jobs, Holding a Job", "H" },
    "TUTORIAL: Acting on Jobs, Held",
    "TUTORIAL: Showing Fewer Jobs",
    { "TUTORIAL: Showing Fewer Jobs, Classes", "STA", true },
    "TUTORIAL: Showing Fewer Jobs, Class A",
    "TUTORIAL: Summary",
  }
  for _, w in ipairs(walk) do
    if type(w) == "table" then
      t:expect(w[1])
      if not w[3] then
        t:tab()
      end
      t:type(w[2]):enter()
    else
      t:expect(w)
      t:enter()
    end
    lacks(t, "PANEL NOT FOUND")
    lacks(t, "INVALID OPTION")
  end
  -- after the summary: the list of parts again
  t:expect("TUTORIAL: SDSF")
  -- a wrong answer in the NP column
  t:type("3"):enter()
  t:enter()
  t:expect("TUTORIAL: Following a Job, the Status Panel")
  t:tab()
  t:type("X"):enter()
  t:expect("INVALID OPTION")
  has(t, "TUTORIAL: Following a Job, the Status Panel")
  t:pf(3)
  t:expect("SDSF SYSLOG")

  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
end
