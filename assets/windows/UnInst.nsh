/*

NSIS Uninstaller Data
Copyright 2014 Aleksandr Ivankiv

Modified by the ButterFlight Team project to let it be used out of the uninstall section
*/

;--------------------------------

!ifndef UNINST_INCLUDED
!define UNINST_INCLUDED

!verbose push
!verbose 3

!ifndef UNINST_VERBOSE
  !define UNINST_VERBOSE 3
!endif

!verbose ${UNINST_VERBOSE}

;--------------------------------
;Header files required by Uninstaller Data

!include "FileFunc.nsh"
!include "TextFunc.nsh"

;--------------------------------
;Variables

Var List
Var Log
Var Tmp
Var UNINST_DAT
Var UNINST_EXE
Var UNINST_DEL_FILE

;--------------------------------
;Default language strings

!define UNINST_EXCLUDE_ERROR_DEFAULT "Error creating an exclusion list."
!define UNINST_DATA_ERROR_DEFAULT "Error creating the uninstaller data: $\r$\nCannot find an exclusion list."
!define UNINST_DAT_NOT_FOUND_DEFAULT "$UNINST_DAT not found, unable to perform uninstall. Manually delete files."
!define UNINST_DAT_MISSING_DEFAULT "$UNINST_DAT is missing, some elements could not be removed. These can be removed manually."
!define UNINST_DEL_FILE_DEFAULT "Delete File"

;--------------------------------
;Language strings macro

!macro SETSTRING NAME

  !ifndef "${NAME}"
    !ifdef UNINST_LOCALIZE
      !define "${NAME}" "$(${NAME})"
    !else
      !define "${NAME}" "${${NAME}_DEFAULT}"
    !endif
  !endif

!macroend

;--------------------------------
;Initialization macro

!macro UNINST_INIT

  ;Default settings
  !ifndef UninstName
    !define UninstName "Uninstall"
  !endif
  !ifndef UninstHeader
    !define UninstHeader "=========== Uninstaller Data please do not edit this file ==========="
  !endif
  !insertmacro SETSTRING "UNINST_EXCLUDE_ERROR"
  !insertmacro SETSTRING "UNINST_DATA_ERROR"
  !insertmacro SETSTRING "UNINST_DAT_NOT_FOUND"
  !insertmacro SETSTRING "UNINST_DAT_MISSING"
  !insertmacro SETSTRING "UNINST_DEL_FILE"
  StrCpy $UNINST_DEL_FILE "${UNINST_DEL_FILE}"
  StrCpy $UNINST_DAT "$OUTDIR\${UninstName}.dat"
  StrCpy $UNINST_EXE "$OUTDIR\${UninstName}.exe"

!macroend

;--------------------------------
;Change name of file

!macro UNINST_NAME Name

  !ifdef UninstName
    !undef UninstName
    !define UninstName "${Name}"
  !else
    !define UninstName "${Name}"
  !endif
  !insertmacro UNINST_INIT

!macroend

;--------------------------------
;Create an exclusion list

!macro UNINSTALLER_DATA_BEGIN

  !insertmacro UNINST_EXCLUDE

!macroend

!macro UNINST_EXCLUDE

  !verbose push
  !verbose ${UNINST_VERBOSE}

  !insertmacro UNINST_INIT

  StrCmp "$PLUGINSDIR" "" 0 +2
    InitPluginsDir

  GetTempFileName $Tmp $PLUGINSDIR

  IfErrors 0 UninstExclude
    !ifndef UNINST_ERROR
      !define UNINST_ERROR
      MessageBox MB_OK|MB_ICONEXCLAMATION "${UNINST_EXCLUDE_ERROR}" /SD IDOK
      Goto +3
    !endif

  UninstExclude:
    FileOpen $List "$Tmp" w
    ${Locate} "$OUTDIR" "/L=FD" "${ExcludeList_Func_CallBack}"
    FileClose $List

  !verbose pop

!macroend

!macro UNINST_FUNCTION_EXCLUDELIST

  Function ExcludeList

    FileWrite $List "$R9$\r$\n"
    Push $0

  FunctionEnd

!macroend

!ifndef ExcludeList_Func_CallBack
  !insertmacro UNINST_FUNCTION_EXCLUDELIST
  !define ExcludeList_Func_CallBack "ExcludeList"
!endif

;----------------------------------------------------------------
;Write Uninstaller Data

!macro UNINSTALLER_DATA_END

  !insertmacro UNINST_DATA

!macroend

!macro UNINST_DATA

  !verbose push
  !verbose ${UNINST_VERBOSE}

  !insertmacro UNINST_INIT

  IfFileExists "$Tmp" UninstData
    !ifndef UNINST_ERROR
      !define UNINST_ERROR
      ${GetFileName} "$UNINST_DAT" $R0
      MessageBox MB_OK|MB_ICONEXCLAMATION "${UNINST_DATA_ERROR}" /SD IDOK
    !endif
    Goto DoneUninstData

  UninstData:
    FileOpen $Log "$UNINST_DAT" a
    FileOpen $List "$Tmp" r

    FileRead $Log $1
    IfErrors 0 +2
    FileWrite $Log "${UninstHeader}$\r$\n"

    ${Locate} "$OUTDIR" "/L=FD" "${UninstallData_Func_CallBack}"

    FileClose $List
    FileClose $Log

  DoneUninstData:
    StrCpy $Tmp ""

  !verbose pop

!macroend

!macro UNINST_FUNCTION_UNINSTDATA

  Function UninstallData

    StrCmp $R9 $UNINST_DAT Done

    FileSeek $List 0 SET

    LoopReadList:
      FileRead $List $1 ${NSIS_MAX_STRLEN}
      IfErrors DoneReadList

      ${TrimNewLines} $1 $R0
      StrCmp $R0 $R9 Done

    Goto LoopReadList

    DoneReadList:
      FileSeek $Log 0 SET

      LoopReadLog:
        FileRead $Log $1 ${NSIS_MAX_STRLEN}
        IfErrors DoneReadLog

        ${TrimNewLines} $1 $R0
        StrCmp $R0 $R9 Done

      Goto LoopReadLog

      DoneReadLog:
        FileSeek $Log 0 END
        FileWrite $Log "$R9$\r$\n"

    Done:
      Push $0

  FunctionEnd

!macroend

!ifndef UninstallData_Func_CallBack
  !insertmacro UNINST_FUNCTION_UNINSTDATA
  !define UninstallData_Func_CallBack "UninstallData"
!endif

;----------------------------------------------------------------
;Uninstall Files

!macro INST_DELETE Path Name
  !insertmacro UNINST_DELETE_MULTIPLE ${Path} ${Name} ""
!macroend

!macro UNINST_DELETE Path Name
  !insertmacro UNINST_DELETE_MULTIPLE ${Path} ${Name} "un."
!macroend

!macro UNINST_DELETE_MULTIPLE Path Name un

  !verbose push
  !verbose ${UNINST_VERBOSE}

  !if "${Path}" == ""
    StrCpy $OUTDIR "$INSTDIR"
  !else
    StrCpy $OUTDIR "${Path}"
  !endif
  !if "${Name}" == ""
    !insertmacro UNINST_NAME "Uninstall"
  !else
    !insertmacro UNINST_NAME "${Name}"
  !endif

  !insertmacro UNINST_INIT

  IfFileExists "$UNINST_DAT" +3
    !ifdef UNINST_TERMINATE
      MessageBox MB_OK|MB_ICONSTOP "${UNINST_DAT_NOT_FOUND}" /SD IDOK
      Quit
    !else
      MessageBox MB_OK|MB_ICONEXCLAMATION "${UNINST_DAT_MISSING}" /SD IDOK
      StrCpy $0 "error"
    !endif

  ${If} $0 != "error"

    FileOpen $Log "$UNINST_DAT" r
      Call ${un}DeleteList
    FileClose $Log

    Delete "$UNINST_DAT"

    !ifdef UNINST_INTERACTIVE
      ${Locate} "$OUTDIR" "/L=F" "${un.InterActive_Func_CallBack}"
      ${Locate} "$OUTDIR" "/L=DE" "${un.InterActive_Func_CallBack}"
    !else
      Call ${un}InterActive
    !endif

  ${Else}
    StrCpy $0 ""
  ${EndIf}

  Delete "$UNINST_EXE"
  RMDir $OUTDIR
  ClearErrors

  !verbose pop

!macroend

!macro UNINST_FUNCTION_DELETE un

  Function ${un}DeleteList

    LoopReadFile:
      FileRead $Log $1 ${NSIS_MAX_STRLEN}
      IfErrors DoneReadFile

      ${TrimNewLines} $1 $R0

      IfFileExists $R0\*.* +3
      IfFileExists $R0 0 +2
      Delete $R0

    Goto LoopReadFile

    DoneReadFile:
      FileSeek $Log 0 SET

    LoopReadDIR:
      FileRead $Log $1 ${NSIS_MAX_STRLEN}
      IfErrors DoneReadDIR

      ${TrimNewLines} $1 $R0

      IfFileExists $R0\*.* 0 +3
      RMDir $R0
      ClearErrors

    Goto LoopReadDIR

    DoneReadDIR:

  FunctionEnd

!macroend

!insertmacro UNINST_FUNCTION_DELETE ""
!insertmacro UNINST_FUNCTION_DELETE "un."

!macro UNINST_FUNCTION_INTERACTIVE un

  Function ${un}InterActive

    StrCmp $R9 "" +8
    IfFileExists $R9\*.* 0 +3
      RMDir $R9
      Goto +4
    StrCmp $R9 $UNINST_EXE +3
      MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "$UNINST_DEL_FILE '$R9'?" /SD IDNO IDNO +2
      Delete $R9
    Push $0

  FunctionEnd

!macroend

!ifndef un.InterActive_Func_CallBack
  !insertmacro UNINST_FUNCTION_INTERACTIVE "un."
  !define un.InterActive_Func_CallBack "un.InterActive"
!endif

!ifndef InterActive_Func_CallBack
  !insertmacro UNINST_FUNCTION_INTERACTIVE ""
  !define InterActive_Func_CallBack "InterActive"
!endif

!verbose pop

!endif
