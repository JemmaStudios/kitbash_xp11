--[[
    KITBASH.LUA
    ver 1.1.0
    2020-May-07

    Distributed under CC BY-NC-SA 4.0 
    https://creativecommons.org/licenses/by-nc-sa/4.0/

    Author:
        Jemma Studios
        Jeffory J. Beckers

    Syntax:
        kitbash.lua "target.obj" "new_gizmos.obj"
    
    Usage:
        kitbash.lua allows X-plane 11 artists and developers to merge the parts and animations from
        new_gizmos.obj into the target.obj file.  It's of particular use when you wish to ADD new elements
        into an existing cockpit object.  It is important that all texture mapping for new_gizmos.obj has
        been completed and mapped to the TEXTURE file of the target.obj prior to running kitbash.lua.

        Essentially, it adds the individual vertices, indexes, and animations from new_gizmos.obj to
        the end of each appropriate section of target.obj.  (VTs at the end of the target.obj VT section,
        IDXs at the end of the target.obj IDX section, etc.)  It also adjust the vertex index numbers in
        each new IDX or IDX10 line added.  It also adjusts the TRIS indexes of each new ANIM added.

        It would be a REALLY good idea to backup the target.obj before running kitbash.lua in case anything
        goes horribly pear shaped.  Remember, any time you try to kitbash, you can break things.

    
]]

local   verString = "ver. 1.1.0"

function print_syntax (errCode, wrongString)
    --[[
        Usage:
            when ever you want the syntax of this script to be displayed

        Returns:
            Nothing but what is printed

        Arguments:
            errCode: let's us know if we need to print an error with the syntax
                0:  it's all good
                1:  An invalid number of arguments was sent
                2:  An invalid switch was sent
                3:  An .obj filename was not sent.
            wrongString: something to help the user figure out how they screwed up.
        Variables:
            nope.
    ]]
    if errCode==1 then
        print ("An invalid number of arguments were provided.\n")
    elseif errCode==2 then
        print ("'"..wrongString.."' is not a valid switch.\n")
    elseif errCode==3 then
        print ("'"..wrongString.."' is not a valid .obj filename. (Must include .obj)\n")
    end
    print ("Usage: KITBASH.LUA <optional switches> target.obj new_gizmo.obj")
    print ("Optional Switches\n\t-s\t<Print summary upon completion.>")
    os.exit()
end

function check_switch(t_arg)
    --[[
        Usage:
            checks the t_arg string to verify it's a valid switch for kitbash
        
        Returns:
            An integer based on the switch as follows:
            0   Not a valid switch
            1   The -s switch was sent

        Arguments:
            t_arg       STRING      The command line argument we're checking
        
        Variables:
            fChar       STRING      First character of t_arg
            swChar      STRING      The second character of t_arg (hopefully a valid switch)
    ]]
    local fChar = t_arg:sub(1,1) -- fChar is the first character of t_arg
    local swChar = t_arg:sub(2,2) -- swChar is the second character of t_arg

    if fChar == "-" then -- if fChar is a dash then at least we're starting off well
        if swChar == "s" then -- swChar is an 's' then that's the summary switch!
            return 1
        else -- we only have 1 switch so we'll fail anything else
        end
    else -- if fChar is not a dash it's not a switch
        return 0
    end
end

function check_obj_file(fName)
    --[[
        Usage:
            Verifies fName has an .obj extension
        
        Returns:
            0   if fName not a string ending with .obj
            1   if fName a string ending with .obj
        
        Arguments:
            fName       STRING      hopefully a string with an OBJ8 filename

        Variables:
            tString     STRING      used to parse substrings.
            n           INT         return value
    ]]
    
    local tString = string.upper(fName:sub(-4)) -- get's the last four chars of fName in all upper case
    if tString == '.OBJ' then -- well, at least they didn't screw that up
        n = 1
    else
        n = 0
    end
    return n
end

function load_obj_file(fName)
    --[[
        parameters:
            fName = name of an obj8 file

        local variables:
            current_file:   file object of fName
            current_lines:  the table with each line of text from fName

        functionality:
        Opens an OBJ and reads all the lines of text into a table and returns that table.

    ]]
    -- open fName and read in the lines
    local current_file = assert(io.open(fName, "r"))
    io.input(current_file)
    local current_lines = {} -- the table for the obj text of the current aircraft
    for line in io.lines() do -- load each line of the obj text
        table.insert(current_lines, line)
    end
    io.close(current_file) -- we have the data now, so we can close this file.
    return current_lines
end

function write_obj_file(fName, tLines)
    --[[
        parameters:
            fName   STRING  name of an obj8 file
            tLines  TABLE   of lines to be written to obj8 file

        functionality:
        Opens an OBJ file and overwrites it with the new tLines

    ]]
    
    local i                                                 -- an index we'll use later
    local current_file = assert(io.open(fName, "w"))        -- file object of fName
    io.output(current_file)

    for i, line in ipairs(tLines) do -- load each line of the obj text
        current_file:write (line.."\n")
    end
    io.close(current_file) -- we have the data now, so we can close this file.
    return current_lines
end

function get_objInfo (tLines)
    --[[
        Usage:
            parses through the tLines table and pulls the VT and TRIS count and other
            information about the obj file that populated tLines

        Parameters:
            tLines          TABLE       a table comprised of each line read from an OBJ8 file
        
        Local Variables:
            stillWorking    BOOLEAN     Are we still digging through the file looking for what we need?
            i               INT         current line number
            tInfo           TABLE       index table that'll hold the obj info
            tmpL            STRING      temporary string we use to decipher the content of each line.
            tW              STRING      a temporary word to load into tWords
            tWords          TABLE       when we break the temporary string into individual words/items
    ]]

    local stillWorking = true   -- we're working until we're done, duh.
    local i = 4                 -- we'll start on the fourth line of the file after a little bit of work below.
    local tInfo = {}            -- we'll add indices and data in a bit.
    local tWords = {}           -- we'll start with an empty table of words.
    local tmpL = ""             -- initialize a temp string

    tInfo["ver"] = tLines[2]    -- Line #2 has the OBJ version (we'll error check for 800 later)
    tInfo["type"] = tLines[3]   -- Line #3 had better be "OBJ"

    while stillWorking do       -- Let's go through the rest
        tmpL = tLines[i]        -- Load the line from the table
       -- print (tmpL) 
        if tmpL ~= nil then
            if string.match(tmpL,'POINT_COUNTS') == "POINT_COUNTS" then -- need point count data
                for tW in string.gmatch(tmpL, "%S+") do     -- break up the line
                    table.insert(tWords, tW)
                end
                tInfo["VTs"] = tWords[2]                    -- 2nd item should be the VT count
                tInfo["TRIS"] = tWords[5]                   -- last item is the TRIs count
            end
        else
            stillWorking = false
        end
        tWords = {}             -- reset the tWords table or it just gets really really big.
        i = i + 1               -- Let's not forget to increment the index so we don't read the same line over and over forever.
    end 
    return tInfo
end

function get_objHeader (tLines, tInfo, gInfo)
    --[[
        Usage:
            parses through the tLines table and outputs all the lines up to the POINT_COUNTS line
            then adds an adjusted POINTS_COUNT line with the sum of the target & gizmo VTs & TRIS

        Parameters:
            tLines          TABLE       comprised of each line read from a target OBJ8 file
            tInfo           TABLE       info (VT & TRIS) for the target OBJ8 file
            gInfo           TABLE       info (VT & TRIS) for the gizmo OBJ8 file
        
    ]]

    local stillWorking = true   -- we're working until we're done, duh.
    local i = 1                 -- we'll start at the top
    local hdrLines = {}         -- the list of new header lines we will generate
    local tWords = {}           -- we'll start with an empty table of words.
    local tmpL = ""             -- initialize a temp string
    local tW = ""               -- initialize another temp string
    local newVTs = tInfo["VTs"] + gInfo["VTs"]               -- sum of VTs from each object
    local newTRIS = tInfo["TRIS"] + gInfo["TRIS"]               -- sum of TRIS from each object

    while stillWorking do       -- Let's go through the rest
        tmpL = tLines[i]        -- Load the line from the table
       -- print (tmpL) 
        if tmpL ~= nil then
            if string.match(tmpL,'POINT_COUNTS') == "POINT_COUNTS" then -- we found the end of the header
                for tW in string.gmatch(tmpL, "%S+") do     -- break up the line
                    table.insert(tWords, tW)
                end
                -- now we'll change the new point counts to be the sum of both target+gizmo VTs & target+gizmo TRIS and default the rest
                hdrLines[i] = "POINT_COUNTS "..newVTs.." "..tWords[3].." "..tWords[4].." "..newTRIS
                stillWorking = false   -- and also we're done with the header so we'll move on
            else
                hdrLines[i] = tmpL     -- we haven't gotten to point count so we add the current line and move on
            end
        else
            stillWorking = false
        end
        tWords = {}             -- reset the tWords table or it just gets really really big.
        i = i + 1               -- Let's not forget to increment the index so we don't read the same line over and over forever.
    end 
    return hdrLines  -- send back the lines with the header information.
end

function get_objVTs (new_tLines, objLines)
    --[[
        Usage:
            parses through the tLines table and outputs

        Parameters:
            new_tLines          TABLE       of lines that will precede the new VT lines. In other words, what we'll append to
            objLines            TABLE       of lines that need to be parsed for all VT lines.
        
    ]]

    local stillWorking = true   -- we're working until we're done, duh.
    local i = 1                 -- we'll start at the top
    local tmpL = ""             -- initialize a temp string


    while stillWorking do       -- Let's go through the rest
        tmpL = objLines[i]        -- Load the line from the table
       -- print (tmpL) 
        if tmpL ~= nil then
            if string.match(tmpL,'VT') == "VT" then -- we found a VT line
                new_tLines[#new_tLines+1] = tmpL    -- so we'll append it to new_tLines
            end
        else
            stillWorking = false
        end
        i = i + 1               -- Let's not forget to increment the index so we don't read the same line over and over forever.
    end 
    return new_tLines -- send back the lines with the VTs added.
end

function get_objIDX (new_tLines, objLines, tInfo)
    --[[
        Usage:
            parses objLines and appends any IDX or IDX10 line to new_tLines and returns tLines. If tInfo is
            sent, then we are adding the Gizmo IDXs so we'll need to add the value of tInfo["VTs"] to each
            gizmo VTs value within the IDX/IDX10 line (if tInfo["VTs"]=4000 and we get an 'IDX 1000' line, our output must be 'IDX 5000')

        Parameters:
            new_tLines      TABLE   of lines that precede the new IDX lines.
            objLines        TABLE   of lines that will be parsed for IDX and IDX10 lines
            tInfo           TABLE   (optional) with target.obj information required if we are parsing the gizmos object only
    ]]

    tInfo = tInfo or 0          -- let's see if we get tInfo, if not we'll set it as a flag.

    local stillWorking = true   -- we're working until we're done, duh.
    local i = 1                 -- we'll start at the top of the objLines stack (I know it's not really a stack per se)
    local j = 1                 -- index for parsing IDX string
    local tmpL = ""             -- initialize a temp string
    local tWords = {}           -- we'll start with an empty table of words
    local tW = ""               -- initialize another temp string
    local tIDX = ""             -- initialize another temp string again

    while stillWorking do       -- Let's go through the rest
        tmpL = objLines[i]      -- Load the line from the table
       -- print (tmpL) 
        if tmpL ~= nil then
            if string.match(tmpL,'IDX') == "IDX" or string.match(tmpL,'IDX10') == "IDX10" then -- we found an IDX/IDX10 line
                if tInfo == 0 then                      -- if we didn't get tInfo then we're just appending as is
                    new_tLines[#new_tLines+1] = tmpL    
                else                                    -- looks like we have to deal with math again.
                    for tW in string.gmatch(tmpL, "%S+") do     -- break up the line
                        table.insert(tWords, tW)        -- create a table for each word/number in the line
                    end
                    tIDX = tWords[1]                    -- first item is going to be IDX or IDX10
                    for j=2, #tWords, 1 do
                        tIDX = tIDX .. "\t" .. (tWords[j]+tInfo["VTs"]) -- add target VT number to each gizmo VT reference
                    end
                    new_tLines[#new_tLines+1] = tIDX    -- and will append the modified line
                    tWords = {}                         -- reset tWords (you idiot.  That took me an hour to figure out, again.)
                end
            end
        else
            stillWorking = false
        end
        i = i + 1               -- Let's not forget to increment the index so we don't read the same line over and over forever.
    end 
    return new_tLines -- send back the lines with the VTs added.
    
end

function get_objFooter (new_tLines, objLines, tInfo)
    --[[
        Usage:
            parses objLines to past the last IDX line then appends all remaining lines to new_tLines then returns new_tLines.
            If tInfo is present we are parsing a gizmo object so each TRIS entry after IDX lines will get the value of
            tInfo["TRIS"] (if tInfo["TRIS"] = 14000 and a new ANIM section includes TRIS 10 36, it will be changed to TRIS 14010 36)

        Parameters:
            new_tLines      TABLE   of lines that precede the ANIM section of the obj file
            objLines        TABLE   of lines from an OBJ file
            tInfo           TABLE   (optional) containing VTs TRIs and other info about the target.obj file
    ]]

    tInfo = tInfo or 0          -- let's see if we get tInfo, if not we'll set it as a flag.

    local stillWorking = true   -- we're working until we're done, duh.
    local areWeThereYet = 0     -- We don't want to start processing lines until after we have finished all the IDX lines. (0-no IDX yet, 1 - we found the IDX section)
    local i = 1                 -- we'll start at the top of the objLines stack (I know it's not really a stack per se)
    local j, k                  -- indices for parsing TRIS string
    local tmpL = ""             -- initialize a temp string
    local tWords = {}           -- we'll start with an empty table of words
    local tW = ""               -- initialize another temp string
    local tIDX = ""             -- initialize another temp string again

    while stillWorking do       -- Let's go through the rest
        tmpL = objLines[i]      -- Load the line from the table
       -- print (tmpL) 
        if tmpL ~= nil then     -- we're not at the EOF yet.
            if string.match(tmpL,'IDX') == "IDX" or string.match(tmpL,'IDX10') == "IDX10" then -- we found an IDX/IDX10 line
                areWeThereYet = 1                       -- we need to know that we got to the IDX section.
            elseif areWeThereYet == 1 then              
                -- We only get here if we are past all the IDX/IDX10 lines
                if tInfo == 0 then                      -- if we didn't get tInfo then we're just appending as is
                    new_tLines[#new_tLines+1] = tmpL    
                else                      
                    if string.match(tmpL,'TRIS') == "TRIS"  then -- we found a TRIS line
                            -- looks like we have to deal with math again.
                        for tW in string.gmatch(tmpL, "%S+") do     -- break up the line
                            table.insert(tWords, tW)        -- create a table for each word/number in the line
                        end  -- for
                        -- since these lines may be indented we need to capture all the chars in front of the TRIS keyword
                        j, k = string.find(tmpL,'TRIS')
                        --[[The line format is 'TRIS [TRIS index] [no of TRIS]' so we only need to change the
                            [TRIS index] for the gizmo line by adding the value of tInfo["TRIS"]  ]]
                        tIDX = string.sub(tmpL, 1, k) .. "\t" .. (tWords[2]+tInfo["TRIS"]) .. "\t" .. tWords[3]                  
                        new_tLines[#new_tLines+1] = tIDX    -- and will append the modified line
                        tWords = {}                         -- reset tWords (you idiot.  That took me an hour to figure out, again.)
                    else   -- not TRIS
                        new_tLines[#new_tLines+1] = tmpL    -- Not a TRIS line so we append it unaltered.
                    end     -- TRIS if
                end         -- tInfo if 
            end             -- stringmatch IDX if
        else
            stillWorking = false
        end         -- tmpL NIL if
        i = i + 1               -- Let's not forget to increment the index so we don't read the same line over and over forever.
    end         -- while stillWorking
    return new_tLines -- send back the lines with the VTs added.
    
end   -- getObjFooter

function print_objInfo (objInfo)
    --[[
        Usage:
            Prints the contents of the objInfo table
    ]]
    local i = ""
    local c = ""
    for i,c in pairs(objInfo) do
        print("[\""..i.."\"]:\t"..c)
    end
end

function print_lines (tLines)
    --[[
        Usage:
            outputs each line of tLines
    ]]
    local i = ""
    local l = ""
    for i, l in ipairs(tLines) do print (l) end
end

-- Set up Error Constants so this will be easier to read
local Err_Invalid_Num_Args = 1          -- An invalid number of command line arguments was sent.
local Err_Invalid_Switch_Sent = 2       -- An invalid switch was sent in the command line arguments.
local Err_Invalid_OBJ_File = 3          -- An invalid OBJ file name.

-- Set up variables

local wantsSummary = 0          -- defaults to non summary mode
local num_args = #arg           -- number of command line arguments sent
local target_fName              -- Name of target.obj file
local gizmo_fName               -- Name of new_gizmos.obj file
local target_lines = {}         -- Table with each line of the original target.obj file
local gizmo_lines = {}          -- Table with each line of the new_gizmos.obj file
local new_lines = {}            -- Table with each line of the kitbashed obj files
local target_objInfo={}         -- Table with VT and TRIS info for target.obj
local gizmo_objInfo={}          -- Table with VT and TRIS info for new_gizmos.obj
local new_target_lines = {}     -- Table used to build the final.obj

-- Print a syntax message if no parameters are set, or error out if an invalid number of arguments were sent

if num_args == 0 then 
    print_syntax () 
elseif num_args == 1 or num_args > 3 then 
    print_syntax (Err_Invalid_Num_Args)
end 

-- We  only have 2 or 3 arguments then (that's good!)

if num_args == 3 then
    if check_switch (arg[1]) == 1 then -- with three arguments the first better be a valid switch and the other 2 args should be .obj filenames
        wantsSummary = 1 -- let's track the stats then
        if check_obj_file(arg[2]) ~= 1 then-- will check if target.obj looks goofy
            print_syntax(Err_Invalid_OBJ_File, arg[2]) -- error exit if so
        else
            target_fName = arg[2] -- else set the target filename
        end
        if check_obj_file(arg[3]) ~= 1 then -- will check if new_gizmos.obj argument is borked
            print_syntax(Err_Invalid_OBJ_File, arg[3]) -- error exit if so
        else
            gizmo_fName = arg[3] -- else set the new_gizmos filename
        end
    else  
        print_syntax(Err_Invalid_Switch_Sent, arg[1]) -- We'll let them know that whatever switch they think they sent is not a switch
    end
else
    if check_obj_file(arg[1]) ~= 1 then-- will check if target.obj looks goofy
        print_syntax(Err_Invalid_OBJ_File, arg[1]) -- error exit if so
    else
        target_fName = arg[1] -- else set the target filename
    end
    if check_obj_file(arg[2]) ~= 1 then -- will check if new_gizmos.obj argument is borked
        print_syntax(Err_Invalid_OBJ_File, arg[2]) -- error exit if so
    else
        gizmo_fName = arg[2] -- else set the new_gizmos filename
    end
end

-- Let's double check that they absolutely positively want to do this
io.stdout:write ("This will overwrite "..target_fName..". Do you have a backup and do you want to continue? (Type Y to continue, anything else with cancel.): ")
if string.upper(string.sub(io.stdin:read(),1,1)) ~= "Y" then 
    print ("\nKITBASH.LUA stopped by user before anything could be broken. (Probably very wise.)")
    os.exit() 
end

--[[I know I've let milliseconds go by while we read in command line arguments, but I have no idea how long someone will take to type Y or N, so I'm not counting it
    for benchmarking purposes.  So tough.]]
local timeStamp = os.time()     -- Load up the current date and time for reporting.
local startTime = os.clock()    -- for benchmarking

-- Read in target.obj
target_lines = load_obj_file (target_fName)

-- Read in new_gizmos.obj
gizmo_lines = load_obj_file (gizmo_fName)

-- Get the original VT & TRIS count from target.obj
target_objInfo = get_objInfo (target_lines)

-- Calculate the VT & TRIS count from new_gizmos.obj
gizmo_objInfo = get_objInfo (gizmo_lines)

-- Write the header to new_target_lines which also updates the new vts & tris count
new_target_lines = get_objHeader (target_lines, target_objInfo, gizmo_objInfo)

-- Write the original target.obj VT's
new_target_lines[#new_target_lines+1] = "\n# Original VTs from "..target_fName.." below by KITBASH.LUA\n" -- add a little message
new_target_lines = get_objVTs (new_target_lines, target_lines)

-- Append the new_gizmo VTs to target.obj

new_target_lines[#new_target_lines+1] = "\n# New VTs from "..gizmo_fName.." added below by KITBASH.LUA\n" -- add a little message
new_target_lines = get_objVTs (new_target_lines, gizmo_lines)

-- Write the original target.obj IDX

new_target_lines[#new_target_lines+1] = "\n# Original IDX/IDX10s from "..target_fName.." below by KITBASH.LUA\n" -- add a little message
new_target_lines = get_objIDX (new_target_lines, target_lines)

--[[ Read each IDX (or IDX10 line) from new_gizmos and add the original VT count from target.obj
and add to each IDX ref of new_gizmos ]]

new_target_lines[#new_target_lines+1] = "\n# New IDXs from "..gizmo_fName.." added below by KITBASH.LUA\n" -- add a little message
new_target_lines = get_objIDX (new_target_lines, gizmo_lines, target_objInfo)

-- Write the original target ANIM lines and other footer information.

new_target_lines[#new_target_lines+1] = "\n# Original ANIM section from "..target_fName.." below by KITBASH.LUA\n" -- add a little message
new_target_lines = get_objFooter (new_target_lines, target_lines)

-- Appended updated new_gizmo.obj ANIM lines to target.obj

new_target_lines[#new_target_lines+1] = "\n# New ANIM section from "..gizmo_fName.." below by KITBASH.LUA" -- add a little message
new_target_lines[#new_target_lines+1] = "\n\tATTR_draw_enable"
new_target_lines = get_objFooter (new_target_lines, gizmo_lines, target_objInfo)

new_target_lines[#new_target_lines+1] = "\n# This file was kitbashed using KITBASH.LUA " .. verString .. " on " .. os.date("%x %X", timeStamp)
new_target_lines[#new_target_lines+1] = "# Donations gratefully accepted at http://paypal.me/jemmastudios"
-- Save the new file and button things up.

write_obj_file (target_fName, new_target_lines)

-- print_lines (new_target_lines)


-- Print out summary.  Maybe something cool about original and new Vt counts, etc.
print ("Finished kitbashing! (So much easier than text editing!)")
if wantsSummary == 1 then -- print out a bunch of stuff that hopefully looks cool
    print ("Target File:\t\t\t\t"..target_fName)
    print ("No of lines in original Target File:\t"..#target_lines)
    print ("No of VTs in original Target File:\t"..target_objInfo["VTs"])
    print ("No of TRIs in original Target File:\t"..target_objInfo["TRIS"])
    print ()
    print ("Gizmo File:\t\t\t\t"..gizmo_fName)
    print ("No of lines in Gizmo File:\t\t"..#gizmo_lines)
    print ("No of VTs added from Gizmo File:\t"..gizmo_objInfo["VTs"])
    print ("No of TRIs added from Gizmo File:\t"..gizmo_objInfo["TRIS"])
    print ()
    print ("No of new lines in "..target_fName..":\t"..#new_target_lines)
    print ("No of new VTS in "..target_fName..":\t"..target_objInfo["VTs"]+gizmo_objInfo["VTs"])
    print ("No of new TRIS in "..target_fName..":\t"..target_objInfo["TRIS"]+gizmo_objInfo["TRIS"])
    print ()
    print ("Completed in " .. os.clock()-startTime .. " seconds.")
end