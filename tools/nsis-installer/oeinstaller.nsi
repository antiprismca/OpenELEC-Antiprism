VIProductVersion "1.0.0.0"
VIAddVersionKey ProductName "OpenELEC-Antiprism USB Stick Creator"
VIAddVersionKey Comments "A bootable OpenElec-Antiprism Installer Stick creation tool."
VIAddVersionKey CompanyName "OpenELEC"
VIAddVersionKey LegalCopyright "OpenELEC"
VIAddVersionKey FileDescription "OpenELEC-Antiprism USB Stick Creator"
VIAddVersionKey FileVersion "1.0"
VIAddVersionKey ProductVersion "1.0"
VIAddVersionKey InternalName "OpenELEC-Antiprism USB Stick Creator"

!define PRODUCT_NAME "OpenELEC-Antiprism USB Stick Creator"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "OpenELEC"
!define PRODUCT_WEB_SITE "http://openelec.tv"
BrandingText " "

Var "DRIVE_LETTER"
Var "DRIVE_NAME"

!include "MUI.nsh"
!include LogicLib.nsh
!include FileFunc.nsh
!insertmacro GetDrives

!define GENERIC_READ 0x80000000
!define GENERIC_WRITE 0x40000000
!define FILE_SHARE_READ 0x00000001
!define FILE_SHARE_WRITE 0x00000002
!define OPEN_EXISTING 3
!define INVALID_HANDLE_VALUE -1
!define MAXLEN_VOLUME_GUID 51
!define IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS 0x00560000
!define EXTENTS_BUFFER_SIZE 512

!define DRIVELIST_PREFIX "=DRIVELIST="
!define MOUNTED_PREFIX "=MOUNTED="
!define LOG_FILE "installer-log.txt"
!define ANTIPRISM_FMT "3rdparty\format\antiprism-fmt.exe"

!define MUI_ICON "openelec.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Welcome to the OpenELEC-Antiprism USB Stick Creator"
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the creation of an OpenELEC USB Installer Stick.\n\nPlease read the following pages carefully."
!insertmacro MUI_PAGE_WELCOME

!define MUI_PAGE_HEADER_TEXT "License Agreement"
!define MUI_PAGE_HEADER_SUBTEXT "Please review the GPLv2 license below before using the OpenELEC-Antiprism USB Stick Creator"
!define MUI_LICENSEPAGE_TEXT_BOTTOM "If you accept the GPL license terms, click Continue."
!define MUI_LICENSEPAGE_BUTTON "Continue"
!insertmacro MUI_PAGE_LICENSE "gpl-2.0.txt"

Name "${PRODUCT_NAME}"
OutFile 'create_installstick.exe'
ShowInstDetails show
AllowRootDirInstall true
RequestExecutionLevel admin

Page Custom CustomCreate CustomLeave
!define MUI_PAGE_HEADER_TEXT "Preparing USB Stick"
!define MUI_PAGE_HEADER_SUBTEXT "Please wait..."
!insertmacro MUI_PAGE_INSTFILES

# http://nsis.sourceforge.net/Simple_write_text_to_file
# This is a simple function to write a piece of text to a file. This will write to the end always.
Function WriteToFile
  Exch $0 ;file to write to
  Exch
  Exch $1 ;text to write

  FileOpen $0 $0 a      #open file
  FileSeek $0 0 END     #go to end
  FileWrite $0 $1       #write to file
  FileWrite $0 '$\r$\n' #write crlf
  FileClose $0

  Pop $1
  Pop $0
FunctionEnd

!macro WriteToFile NewLine File String
  !if `${NewLine}` == true
  Push `${String}$\r$\n`
  !else
  Push `${String}`
  !endif
  Push `${File}`
  Call WriteToFile
!macroend
!define WriteToFile `!insertmacro WriteToFile false`
!define WriteLineToFile `!insertmacro WriteToFile true`

!macro RunProg CMDLINE
!define ID ${__LINE__}
  ${WriteToFile} '${LOG_FILE}' '> ${CMDLINE}'
  nsExec::ExecToStack `"$R0" /c ${CMDLINE}`
  pop $0
  pop $R2
  StrCmp $0 "0" exit_${ID}
  ${WriteToFile} '${LOG_FILE}' '$R2'
  DetailPrint "ERROR CODE: $0, MSG: $R2"
  goto abort
exit_${ID}:
  ${WriteToFile} '${LOG_FILE}' '$R2'
  nop
!undef ID
!macroend

Section "oeusbstart"
  ExpandEnvStrings $R0 %COMSPEC%

  DetailPrint "- Formatting USB Device $DRIVE_NAME ..."
  nsExec::ExecToStack '"$R0" /c ${ANTIPRISM_FMT} FORMAT "$DRIVE_NAME" LIVESYSTEM 614400 FS_FAT32 DT_SYSLINUX_V6 2>>${LOG_FILE}'
  pop $0
  pop $1
  StrCmp $0 "0" 0 abort
  StrLen $0 ${MOUNTED_PREFIX}
  StrCpy $2 $1 $0
  
  StrCmpS $2 ${MOUNTED_PREFIX} 0 abort
  StrCpy '$DRIVE_LETTER' $1 "" $0
  StrCpy '$INSTDIR' '$DRIVE_LETTER'
  DetailPrint "- USB device is mounted on $DRIVE_LETTER"
  
  DetailPrint "- Copying System Files ..."
  !insertmacro RunProg "copy /y target\KERNEL $DRIVE_LETTER"
  !insertmacro RunProg "copy /y target\KERNEL.md5 $DRIVE_LETTER"
  !insertmacro RunProg "copy /y target\SYSTEM $DRIVE_LETTER"
  !insertmacro RunProg "copy /y target\SYSTEM.md5 $DRIVE_LETTER"

  DetailPrint "- Copying Configuration Files ..."
#  !insertmacro RunProg "copy Autorun.inf $DRIVE_LETTER"
  !insertmacro RunProg "copy /y openelec.ico $DRIVE_LETTER"
  !insertmacro RunProg "copy /y CHANGELOG $DRIVE_LETTER"
  !insertmacro RunProg "copy /y INSTALL $DRIVE_LETTER"
  !insertmacro RunProg "copy /y README.md $DRIVE_LETTER"
  !insertmacro RunProg "copy /y RELEASE $DRIVE_LETTER"

  DetailPrint "- Copying menu files..."
  !insertmacro RunProg "copy /y 3rdparty\syslinux\com32\*.* $DRIVE_LETTER"
  
  DetailPrint "- Creating Bootloader configuration ..."
  Delete '$DRIVE_LETTER\syslinux.cfg'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'DEFAULT menu.c32'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'PROMPT 0'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'MENU TITLE OpenELEC-Antiprism Live Stick'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' ' '
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'LABEL livestorage'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  MENU LABEL ^Live Storage (use storage on live stick)'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  KERNEL /KERNEL'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  APPEND boot=LABEL=LIVESYSTEM disk=FLASH xbmc quiet tty'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' ' '
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'LABEL storage'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  MENU LABEL ^Storage (use your local storage - may be dangerous)'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  KERNEL /KERNEL'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  APPEND boot=LABEL=LIVESYSTEM disk=LABEL=Storage quiet tty'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' ' '
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' 'LABEL installer'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  MENU LABEL ^Install Antiprism on your local storage'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  KERNEL /KERNEL'
  ${WriteToFile} '$DRIVE_LETTER\syslinux.cfg' '  APPEND boot=LABEL=LIVESYSTEM installer quiet tty'
  goto ok
  
abort:
  DetailPrint "ERROR. See ${LOG_FILE}"
  Abort
  
ok:
  nop
SectionEnd

Function CustomCreate
!insertmacro MUI_HEADER_TEXT "USB Stick Selection Screen" "Important: Make sure that the correct device is selected."
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Settings' 'NumFields' '7'

  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Type' 'Label'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Left' '5'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Top' '5'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Right' '-6'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Bottom' '15'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 1' 'Text' \
    'Select drive for Installation (*** ALL DATA WILL BE REMOVED ***):'

  Delete "${LOG_FILE}"
  ExpandEnvStrings $R0 %COMSPEC%
  nsExec::ExecToStack '"$R0" /c "${ANTIPRISM_FMT}" LIST 2>>${LOG_FILE}'
  pop $0
  pop $R0
  
  StrCmp $0 "0" 0 nodrives
  
  StrLen $0 ${DRIVELIST_PREFIX}
  StrCpy $1 $R0 $0
  
  StrCmpS $1 ${DRIVELIST_PREFIX} 0 nodrives
  StrCpy $R0 $R0 "" $0
  
  GetDlgItem $1 $HWNDPARENT 1
  ${If} $R0 == ""
    EnableWindow $1 0
  ${Else}
    EnableWindow $1 1
  ${EndIf}

nodrives:
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'Type' 'DropList'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'Left' '30'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'Top' '20'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'Right' '-31'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'Bottom' '30'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'State' '*** SELECT DRIVE ***'
  WriteIniStr '$PLUGINSDIR\custom.ini' 'Field 2' 'ListItems' '*** SELECT DRIVE ***|$R0'

  push $0
  InstallOptions::Dialog '$PLUGINSDIR\custom.ini'
  pop $0
  pop $0
FunctionEnd

Function CustomLeave
  ReadIniStr $0 '$PLUGINSDIR\custom.ini' 'Field 2' 'State'
  StrCpy '$DRIVE_NAME' '$0'
  ReadIniStr $0 '$PLUGINSDIR\custom.ini' 'Field 3' 'State'
FunctionEnd

!define MUI_FINISHPAGE_TITLE "OpenELEC-Antiprism USB Stick Successfully Created"
!define MUI_FINISHPAGE_TEXT "An OpenELEC-Antiprism USB Installer Stick has been created on the device $DRIVE_LETTER.\n\nPlease boot your HTPC off this USB stick and follow the on-screen instructions."
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!define MUI_PAGE_CUSTOMFUNCTION_SHOW "FinishShow"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

Function FinishShow
  GetDlgItem $0 $HWNDPARENT 3
  ShowWindow $0 0
  GetDlgItem $0 $HWNDPARENT 1
  SendMessage $0 ${WM_SETTEXT} 0 "STR:Finish"
FunctionEnd

Function .onInit
  InitPluginsDir
  GetTempFileName $0
  Rename $0 '$PLUGINSDIR\custom.ini'
FunctionEnd

!define sysGetDiskFreeSpaceEx 'kernel32::GetDiskFreeSpaceExA(t, *l, *l, *l) i'
; $0 - Path to check (can be a drive 'C:' or a full path 'C:\Windows')
; $1 - Return value, free space in kb
 
function FreeDiskSpace
  System::Call '${sysGetDiskFreeSpaceEx}(r0,.,,.r1)'
  System::Int64Op $1 / 1024
  Pop $1
functionend

