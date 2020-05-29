# kitbash_xp11
A standalone lua scripts that appends an existing x-plane 11 object with the contents of a second object.

Requires Lua 5.1 or later available at www.luadist.org

Directions:
kitbash.lua allows you to append an x-plane 11 obj8 object onto an existing obj8 file.  It's
of particular use for developers who want to add manipulators to an existing object without
having to re-animate an entire model.  It can also be use to incorporate things like the avitab
tablet into an aircraft cockpit object.

The easy way to use it is to make a backup of the cockpit object first (we'll call it target.obj)
and have the object you want to append (we'll call that gizmos.obj) then open your command
window, navigate to the folder and type: kitbash.lua
You'll get all the directions you need from there.

Warnings: 
It is important that the gizmos.obj file has already been uv mapped to the same texture of
target.obj.  If you don't know what that even means, you need to rethink using this script.