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
        new_TRIS    INT     Number of TRIs in new_gizmos.obj
        new_VT      INT     Number of VTs in new_gizmos.obj
        num_args    INT     Number of command line arguments sent
        orig_TRIS   INT     Number of original TRIs in target.obj
        orig_VT     INT     Number of original VTs in target.obj
    
    Functions:
        print_syntax()      Prints the syntax message
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
            wrongString: something to help the user figure out how they screwed up.
        Variables:
            Also, nope.
    ]]
    if errCode==1 then
        print ("An invalid number of arguments were provided.")
    elseif errCode==2 then
        print ("'"..wrongString.."' is not a valid switch.")
    end
        print ("Usage: KITBASH.LUA <optional switches> target.obj new_gizmo.obj")
        print ("Optional Switches\n\t-s\t<Print summary upon completion.>")
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

-- Set up Error Constants so this will be easier to read
local Err_Invalid_Num_Args = 1          -- An invalid number of command line arguments was sent.
local Err_Invalid_Switch_Sent = 2       -- An invalid switch was sent in the command line arguments.

-- Set up variables

local wantsSummary = 0    -- defaults to non summary mode
local num_args = #arg     -- number of command line arguments sent

-- Print a syntax message if no parameters are set, or error out if an invalid number of arguments were sent

if num_args == 0 then print_syntax () 
elseif num_args == 1 or num_args > 3 then print_syntax (Err_Invalid_Num_Args) end 

-- If there are three arguments the first should be a switch

if num_args == 3 then
    if check_switch (arg[1]) == 1 then wantsSummary = 1 else
        print_syntax(Err_Invalid_Switch_Sent, arg[1]) -- We'll let them know that whatever switch they think they sent is not a switch
    end
end

-- If there are two arguments let's check them for valid file extensions

-- Check the files exist and error out if not.

-- Read in target.obj

-- Write it out as target_KITSAFE.obj just in case the user didn't listen to me

-- Read in new_gizmos.obj

-- Calculate the original VT & TRIS count from target.obj

-- Calculate the VT & TRIS count from new_gizmos.obj

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