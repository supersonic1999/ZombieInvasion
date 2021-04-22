@echo off 

echo Are you sure you want to push this update to the workshop?
pause
"D:\steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder "." -out "zombieinvasion.gma"
"D:\steam\steamapps\common\GarrysMod\bin\gmad.exe" update -addon "zombieinvasion.gma" -id "179517028"
pause