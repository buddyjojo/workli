@echo off

echo;
echo Welcome to worklipe
echo;
echo Mounting disk...
echo;
echo Note: may take some time for diskpart to start, please wait...
echo;

(
echo select disk 0
echo select partition 1
echo assign letter=A
exit
)  | diskpart

(
echo select disk 0
echo select partition 2
echo assign letter=B
exit
)  | diskpart


echo;
echo Creating proper boot entries and BCD...
echo;

rmdir /S /Q A:\EFI

rmdir /S /Q B:\EFI

bcdboot B:\Windows /s A: /f UEFI

echo;
echo Creating msr partition...
echo;

(
echo select disk 0
echo create partition msr size=16
exit
)  | diskpart

echo;
echo Coverting boot partition to an ESP one...
echo;

(
echo select disk 0
echo select partition 1
echo set id=C12A7328-F81F-11D2-BA4B-00A0C93EC93B override
exit
)  | diskpart

echo;
echo Restoring old winre...
echo;

del B:\Windows\System32\Recovery\winre.wim

copy B:\Windows\System32\Recovery\backup-winre.wim B:\Windows\System32\Recovery\winre.wim

echo;
echo Configuring finnished, rebooting...
echo;

:end
