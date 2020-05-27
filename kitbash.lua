--[[
    KITBASH.LUA
    ver 1.0.0
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

    Variables:
        new_TRIS        INT         Number of TRIs in new_gizmos.obj
        new_VT          INT         Number of VTs in new_gizmos.obj
        num_args        INT         Number of command line arguments sent
        orig_TRIS       INT         Number of original TRIs in target.obj
        orig_VT         INT         Number of original VTs in target.obj
        target_fName    STRING      Name of target.obj file
        gizmo_fName     STRING      Name of new_gizmos.obj file

    Functions:
        print_syntax()      Prints the syntax message
        check_switch()      Checks if an argument is a valid switch
        check_obj_file()    Checks if argument if valid obj file name
        load_obj_file()     Reads the obj file into a table
]]

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
        ver 1.0.0
        2020-APR-25
        
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

function print_objInfo (objInfo)
    --[[
        Usage:
            Prints the contents of the objInfo table
    ]]
    local i = ""
    local c = ""
    for i,c in pairs(objInfo) do
        print("["..i.."]:\t"..c)
    end
end

-- Set up Error Constants so this will be easier to read
local Err_Invalid_Num_Args = 1          -- An invalid number of command line arguments was sent.
local Err_Invalid_Switch_Sent = 2       -- An invalid switch was sent in the command line arguments.
local Err_Invalid_OBJ_File = 3          -- An invalid OBJ file name.

-- Set up variables

local wantsSummary = 0      -- defaults to non summary mode
local num_args = #arg       -- number of command line arguments sent
local target_fName          -- Name of target.obj file
local gizmo_fName           -- Name of new_gizmos.obj file
local target_lines = {}     -- Table with each line of the original target.obj file
local gizmo_lines = {}      -- Table with each line of the new_gizmos.obj file
local new_lines = {}        -- Table with each line of the kitbashed obj files
local target_objInfo={}     -- Table with VT and TRIS info for target.obj
local gizmo_objInfo={}      -- Table with VT and TRIS info for new_gizmos.obj

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

-- Check the files exist and error out if not.
print ("Target file: "..target_fName)
print ("Gizmo file: "..gizmo_fName)

-- Read in target.obj
target_lines = load_obj_file (target_fName)

-- Read in new_gizmos.obj
gizmo_lines = load_obj_file (gizmo_fName)

-- Get the original VT & TRIS count from target.obj
target_objInfo = get_objInfo (target_lines)
print("Target info:")
print_objInfo (target_objInfo)

-- Calculate the VT & TRIS count from new_gizmos.obj
gizmo_objInfo = get_objInfo (gizmo_lines)
print ("Gizmos info:")
print_objInfo(gizmo_objInfo)

-- Write the header to target.obj

-- Update the new VT & TRIS count

-- Write the original target.obj VT's

-- Append the new_gizmo VTs to target.obj

-- Write the original target.obj IDX

--[[ Read each IDX (or IDX10 line) from new_gizmos and add the original VT count from target.obj
and add to each IDX ref of new_gizmos ]]

-- Append updated new_gizmo.obj IDX (or IDX10) to target.obj

-- Read each ANIM line from new_gizmos.obj and add orig TRIS count from target.obj to each ref.

-- Appended updated new_gizmo.obj ANIM lines to target.obj

-- Close everything up.

-- Print out summary.  Maybe something cool about original and new Vt counts, etc.
