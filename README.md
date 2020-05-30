# kitbash_xp11
A standalone lua script that appends an existing x-plane 11 object with the contents of a second object.

Requires Lua 5.1 or later available at https://github.com/rjpcomputing/luaforwindows/releases

Directions:
kitbash.lua allows you to append an x-plane 11 obj8 object onto an existing obj8 file.  It's
of particular use for developers who want to add manipulators to an existing object without
having to re-animate an entire model.  It can also be use to incorporate things like the avitab
tablet into an aircraft cockpit object.

The easy way to use it is to make a backup of the cockpit object first (we'll call it target.obj)
and have the object you want to append (we'll call that gizmos.obj) then open your command
window, navigate to the folder and...
Windows users type: kitbash.lua
Linux users type: lua kitbash.lua

You'll get all the directions you need from there.

Example:
Included in the archive is example_gizmo.obj which adds lights and manipulators to x-plane 11
Columbia 400 G1000 Com buttons panel.  You can copy example_gizmo.obj to your Columbia 400
folder.  Backup c400_cockpit.obj and then run 'kitbash.lua -s c400_cockpit.obj example_gizmo.obj'
You'll also need to replace the Columbia 400/cockpit/-PANELS-/PANEL.png file with the file in 
this archive, so the indicator lights display.

Warnings: 
It is important that the gizmos.obj file has already been uv mapped to the same texture of
target.obj.  If you don't know what that even means, you need to rethink using this script.

Donations:
I'm donating this work to the x-Plane 11 community under the GNU General Public License v3.0
(see License).  If you are compelled to donate cash in return, that would be great. I'm happy
to accept whatever disposable income you have at https://www.paypal.me/jemmastudios
Thanks in advance. - Jeffory

Support:
E-mail me at jemmasimulations@gmail.com
Join our discord!! https://discord.gg/xpEnWXA