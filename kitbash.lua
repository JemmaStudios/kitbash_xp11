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
]]

-- Read in command line parameters

-- Print a syntax message if no parameters are set

-- Print error message if improper number of args were sent

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