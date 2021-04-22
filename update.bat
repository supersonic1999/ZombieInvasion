@echo off 

set /p conf="Are you sure you want to push this update to the workshop?: (Y/N)"
if %conf% == Y goto executecode
if %conf% == y goto executecode
GOTO end
	
:executecode
"D:\steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder "." -out "zombieinvasion.gma"
set /p id="Change Notes: "
"D:\steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -addon "zombieinvasion.gma" -id "179517028" -changes "%id%"

:end
pause