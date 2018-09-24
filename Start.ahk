#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Keep the script running until the user exits it.
#SingleInstance
SetTitleMatchMode, 2


; Call Python script to save currently listed symbols to text file

Run, %A_ScriptDir%\Resources\Python\GetSymbols.pyw "%A_ScriptDir%"
SetTimer, GetSymbols, 180000

; Included GUI manipulation classes, credit https://github.com/AHK-just-me

#Include, %A_ScriptDir%\Resources\AHK\Class_CtlColors.ahk   
#Include, %A_ScriptDir%\Resources\AHK\Class_OD_Colors.ahk
#Include, %A_ScriptDir%\Resources\AHK\Class_ImageButton.ahk 

; Included AES encryption class, credit https://gist.github.com/jNizM

#Include, %A_ScriptDir%\Resources\AHK\Encrypt.ahk

; Check if connection settings are present, if not present settings dialog

IfExist, %A_ScriptDir%\Resources\Text\hashes.txt
  FirstRun = 0
Else
  FirstRun = 1

if (FirstRun = 0)
  goto decryptgui

; Connection settings GUI

GuiWidth  = 700
GuiTitle  = Connection Settings

Gui,New, +AlwaysOnTop -Caption

; Titlebar
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 +0x4 ,
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 hwndTitleBar Backgroundtrans +0x200 gGuiMove
              ,  % " " GuiTitle
CtlColors.Attach(TitleBar, "0E121C", "E8B342")

Gui, Color, 151A28, 1A2132
Gui, Font, s8, Verdana
Gui, Font, cBCBDC0

Gui, Font, % (FontOptions := "s8"), % (FontName := "Verdana")
OD_Colors.SetItemHeight(FontOptions, FontName)

Gui, Add, Text, x10 y42,  Binance API Key:  
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndPublicKeyHnwd x185 y40 w500  vKey

Gui, Add, Text, x10 y72,  Binance API Secret:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndPrivateKeyHnwd x185 y70 w500 vSecret

Gui, Add, Text, x10 y102,  Telegram API Key:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTKeyHnwd x185 y100 w250 vTKey

Gui, Add, Text, x10 y132,  Telegram Conversation ID:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTIDHnwd x185 y130 Limit30 w250 vTID

Gui, Add, Text, x10 y162,  Encryption Password:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndPassHnwd x185 y160 Limit30 Password w250 vPass

Gui, Add, Text, x10 y192,  Repeat Password:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndPass2Hnwd x185 y190 Limit30 Password w250 vPass2

GUI, Add, Checkbox, -E0x200 hwndTestCheck x270 y230  vTestCheck gTestCheck , Enable Trade Mode

GUI, Add, Checkbox, -E0x200 hwndTelegramCheck x270 y260  vTelegramCheck gTestCheck , Enable Telegram


Gui, Add, Button, x200 y300 w240 h28 Default gSetAPI hwndAPISubmitButton, Submit
Opt1 := [0, 0xFFFF007A, 0xFFFF007A, "White"]             ; normal background & text colors
Opt2 := {2: 0xE5006D, 3: 0xE5006D, 4: "White"}           ; hot background & text colors 
Opt3 := {4: "Black"}                                     ; pressed text color
If !ImageButton.Create(APISubmitButton, Opt1, Opt2, Opt3)
  MsgBox, 0, ImageButton Error Btn2, % ImageButton.LastError

Gui,show, w%GuiWidth%,Binance API connection

Gosub, TestCheck

;GuiControl, Hide, Enable Trade Mode

return

TestCheck:

; Disable/enable fields based on checkbox status

Gui, Submit, NoHide

if (TestCheck = 0)
{
      GuiControl, Disable, Key
      GuiControl, Disable, Secret
      GuiControl, Disable, Pass
      GuiControl, Disable, Pass2
      CtlColors.Change(PublicKeyHnwd, "151A28" , "BCBDC0")
      CtlColors.Change(PrivateKeyHnwd, "151A28" , "BCBDC0")
      CtlColors.Change(PassHnwd, "151A28" , "BCBDC0")
      CtlColors.Change(Pass2Hnwd, "151A28" , "BCBDC0")
}else
{
      GuiControl, Enable, Key
      GuiControl, Enable, Secret
      GuiControl, Enable, Pass
      GuiControl, Enable, Pass2
      CtlColors.Change(PublicKeyHnwd, "1A2132" , "BCBDC0")
      CtlColors.Change(PrivateKeyHnwd, "1A2132" , "BCBDC0")
      CtlColors.Change(PassHnwd, "1A2132" , "BCBDC0")
      CtlColors.Change(Pass2Hnwd, "1A2132" , "BCBDC0")
      
}

if (TelegramCheck = 0)
{
      GuiControl, Disable, TKey
      GuiControl, Disable, TID
      CtlColors.Change(TKeyHnwd, "151A28" , "BCBDC0")
      CtlColors.Change(TIDHnwd, "151A28" , "BCBDC0")
      if (TestCheck = 0){
      GuiControl, Disable, Pass
      GuiControl, Disable, Pass2      
      CtlColors.Change(PassHnwd, "151A28" , "BCBDC0")
      CtlColors.Change(Pass2Hnwd, "151A28" , "BCBDC0")
    }
}else
{
      GuiControl, Enable, TKey
      GuiControl, Enable, TID
      CtlColors.Change(TKeyHnwd, "1A2132" , "BCBDC0")
      CtlColors.Change(TIDHnwd, "1A2132" , "BCBDC0")
      if (TestCheck = 0){
      GuiControl, Enable, Pass
      GuiControl, Enable, Pass2     
      CtlColors.Change(PassHnwd, "1A2132" , "BCBDC0")
      CtlColors.Change(Pass2Hnwd, "1A2132" , "BCBDC0")   
      }  
}
return

SetAPI:

; Validate input

Gui, Submit,Nohide

KeyLength := StrLen(Key)
SecretLength := StrLen(Secret)

ErrorVal = 0

if (TestCheck = 1){

    if (KeyLength = 64)
    {
       CtlColors.Change(PublicKeyHnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(PublicKeyHnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }

    if (SecretLength = 64)
    {
      CtlColors.Change(PrivateKeyHnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(PrivateKeyHnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }

    If Pass = %Pass2%
      PassMatch = 1

    if (Pass != "" and PassMatch = 1)
    {       
       CtlColors.Change(PassHnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(PassHnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }

    if (Pass2 != "" and PassMatch = 1)
    {
      CtlColors.Change(Pass2Hnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(Pass2Hnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }
}Else
{
  Key = empty
  Secret = empty
}

if (TelegramCheck = 1){

    if (TKey != "")
    {
       CtlColors.Change(TKeyHnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(TkeyHnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }

    if (TID != "")
    {
      CtlColors.Change(TIDHnwd, "1A2132" , "BCBDC0")
    }Else
    {
      CtlColors.Change(TIDHnwd, "661515" , "BCBDC0")
      ErrorVal = 1
    }
}Else
{
  TKey = empty
  TID = empty
}

; If validation succesful AES encrypt values, write hashes to file and continue to main gui

if (ErrorVal = 0)
{   
  if (TestCheck = 1 or TelegramCheck = 1){
    KeyEncrypted := AES.Encrypt(Key, Pass, 256)
    SecretEncrypted := AES.Encrypt(Secret, Pass, 256)
    TKeyEncrypted := AES.Encrypt(TKey, Pass, 256)
    TIDEncrypted := AES.Encrypt(TID, Pass, 256)
     
    FileAppend, %KeyEncrypted%`n, %A_ScriptDir%\Resources\Text\hashes.txt
    FileAppend, %SecretEncrypted%`n, %A_ScriptDir%\Resources\Text\hashes.txt
    FileAppend, %TKeyEncrypted%`n, %A_ScriptDir%\Resources\Text\hashes.txt
    FileAppend, %TIDEncrypted%`n, %A_ScriptDir%\Resources\Text\hashes.txt
  }

  Gui, Destroy
  goto main

}Else
{
  return
}

; API key dectyption gui

decryptgui:

GuiWidth  = 360
GuiTitle  = Connection Settings

Gui,New, +AlwaysOnTop -Caption

; Titlebar
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 +0x4 ,
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 hwndTitleBar Backgroundtrans +0x200 gGuiMove
              ,  % " " GuiTitle
CtlColors.Attach(TitleBar, "0E121C", "E8B342")

Gui, Color, 151A28, 1A2132
Gui, Font, s8, Verdana
Gui, Font, cBCBDC0

Gui, Font, % (FontOptions := "s8"), % (FontName := "Verdana")
OD_Colors.SetItemHeight(FontOptions, FontName)

Gui, Add, Text, x10 y42,  Decrypt Password:  
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndPassDecryptHnwd x140 y40 w200 Password vPassDecrypt

Gui, Add, Button, x110 y80 w140 h28 Default gSetPass hwndPassSubmitButton, Submit
Opt1 := [0, 0xFFFF007A, 0xFFFF007A, "White"]             ; normal background & text colors
Opt2 := {2: 0xE5006D, 3: 0xE5006D, 4: "White"}           ; hot background & text colors 
Opt3 := {4: "Black"}                                     ; pressed text color
If !ImageButton.Create(PassSubmitButton, Opt1, Opt2, Opt3)
  MsgBox, 0, ImageButton Error Btn2, % ImageButton.LastError

Gui,show, w%GuiWidth%,%GuiTitle%

return

SetPass:

; Try to decrypt keys using provided password

Gui,Submit,NoHide

FileReadLine, KeyEncrypted, %A_ScriptDir%\Resources\Text\hashes.txt, 1
FileReadLine, SecretEncrypted, %A_ScriptDir%\Resources\Text\hashes.txt, 2
FileReadLine, TKeyEncrypted, %A_ScriptDir%\Resources\Text\hashes.txt, 3
FileReadLine, TIDEncrypted, %A_ScriptDir%\Resources\Text\hashes.txt, 4


Key := AES.Decrypt(KeyEncrypted, PassDecrypt, 256)
Secret := AES.Decrypt(SecretEncrypted, PassDecrypt, 256)
TKey := AES.Decrypt(TKeyEncrypted, PassDecrypt, 256)
TID := AES.Decrypt(TIDEncrypted, PassDecrypt, 256)  

; Unsuccesful decryption will result in random unicode characters so we can check success by checking if first decrypted key is alphanumeric

if Key is not alnum
{
  CtlColors.Change(PassDecryptHnwd, "661515" , "BCBDC0")
  return
}Else{
  
  TestCheck = 1 ; disable main gui test mode
  Gui, Destroy
  goto main

}

return


main:

; Create GUI

GuiWidth  = 270
GuiTitle  = Advanced Trading Options

Gui,New, +AlwaysOnTop -Caption

; Titlebar
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 +0x4 ,
Gui, Add, Text,  x0 y0 w%GuiWidth% h30 hwndTitleBar Backgroundtrans +0x200 gGuiMove
              ,  % " " GuiTitle
CtlColors.Attach(TitleBar, "0E121C", "E8B342")

Gui, Color, 151A28, 1A2132
Gui, Font, s10, Verdana
Gui, Font, cBCBDC0

Gui, Font, % (FontOptions := "s10"), % (FontName := "Verdana")
OD_Colors.SetItemHeight(FontOptions, FontName)

Gui, Add, Text, x10 y40, Order Type:
Gui, Add, DDL, x120 y40 w130 h100 vType +border Choose1 hwndDropdown1 gSetType -E0x200 +0x0210 R5, ---|Trailing Stop|Stop-Market|Stop-HiLo|Trailing HiLo
OD_Colors.Attach(Dropdown1, {T: 0xBCBDC0, B: 0x1A2132})

Gui, Add, Text, x10 y70,  Symbol:  
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndSymbolHnwd x120 y70 w130 Uppercase vSymbol

Gui, Add, Text, x10 y100,  Amount:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndAmountHnwd x120 y100 w130 vAmount

Gui, Add, Text, x10 y131 vStartPriceLabel,  Start Price:
GUI, Add, Checkbox, -E0x200 hwndStartCheck x97 y134 w13 h13 vStartCheck gSetCheck, %A_Space%
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndStartPriceHnwd x120 y130 w130 Limit10 vStartPrice

Gui, Add, Text, x10 y160 vStopPriceLabel,  Stop Price:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndStopPriceHnwd x120 y160 w130 Limit10 vStopPrice

Gui, Add, Text, x10 y190,  Trail `%:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTrailPercentageHnwd x120 y190 w130 Limit2 vTrailPercentage ; changed size limit to 2 should be no need for more than 99% trail

Gui, Add, Text, x10 y220,  Ratio:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTrailRatioHnwd x120 y220 w130 Limit4 vTrailRatio, 0 ; changed size limit to 4 to enable negative decimal values

Gui, Add, Text, x10 y250,  Confirmations:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndConfirmationsHnwd x120 y250 w130 Number Limit2 vConfirmations

Gui, Add, Text, x10 y280, Mode :
if (TestCheck = 1)
  Gui, Add, DDL, x120 y280 w130 h100 vMode +border Choose1 hwndDropdown2 gSetReset -E0x200 +0x0210, ---|Real|Test|Reset
if (TestCheck = 0)
  Gui, Add, DDL, x120 y280 w130 h100 vMode +border Choose1 hwndDropdown2 gSetReset -E0x200 +0x0210, ---|Test
OD_Colors.Attach(Dropdown2, {T: 0xBCBDC0, B: 0x1A2132})

Gui, Add, Text, x10 y310,  Entry Price:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndEntryPriceHnwd x120 y310 w130 Limit10 vEntryPrice, 

Gui, Add, Button, x10 y355 w240 h28 Default gExecuteOrder hwndSubmitButton, Execute
Opt1 := [0, 0xFFFF007A, 0xFFFF007A, "White"]             ; normal background & text colors
Opt2 := {2: 0xE5006D, 3: 0xE5006D, 4: "White"}           ; hot background & text colors 
Opt3 := {4: "Black"}                                     ; pressed text color
If !ImageButton.Create(SubmitButton, Opt1, Opt2, Opt3)
  MsgBox, 0, ImageButton Error Btn2, % ImageButton.LastError

Gui,show, w270,Advanced Trading Options

Gosub, SetType ; Disable controls on startup
Gosub, SetReset ; Disable Entry Price control on startup
return


GuiClose:
ExitApp

GuiMove: 
PostMessage, 0xA1, 2,,, A ; Titlebar drag/move
Return 

ExecuteOrder:

; Validate input on Submit

Gui, Submit, NoHide

ErrorVal = 0

if (Type = "---") ; if Type is not set no further validation needed
{
  return
}

; Validate input

if(!ValidateInput("AmountHnwd", "Amount", "Edit2"))
   ErrorVal = 1
if(!ValidateInput("StartPriceHnwd", "StartPrice", "Edit3"))
   ErrorVal = 1
if(!ValidateInput("StopPriceHnwd", "StopPrice", "Edit4"))
   ErrorVal = 1
if(!ValidateInput("TrailPercentageHnwd", "TrailPercentage", "Edit5"))
   ErrorVal = 1
if(!ValidateInput("TrailRatioHnwd", "TrailRatio", "Edit6"))
   ErrorVal = 1
if(!ValidateInput("ConfirmationsHnwd", "Confirmations", "Edit7"))
   ErrorVal = 1
if(!ValidateInput("EntryPriceHnwd", "EntryPrice", "Edit8"))
   ErrorVal = 1

; Check if Symbol not empty, if not check against currently listed symbols

if (Symbol = "")
{
  CtlColors.Change(SymbolHnwd, "661515" , "BCBDC0")
  ErrorVal = 1
}Else
{
    Loop, Read, %A_ScriptDir%\Resources\Text\Symbols.txt
    {        
        ;MsgBox, %A_LoopReadLine% %Symbol%
        if (Symbol = A_LoopReadLine)
        {
          CtlColors.Change(SymbolHnwd, "1A2132" , "BCBDC0")
          x = 0
          break    
        }
        Else
        {
          x = 1    
        }      
    }

    if (x = 1){
        CtlColors.Change(SymbolHnwd, "661515" , "BCBDC0")
        ErrorVal = 1       
      }
}

if (Mode = "---"){
  OD_Colors.Attach(Dropdown2, {T: 0xBCBDC0, B: 0x661515})
  ErrorVal = 1
}
Else
  OD_Colors.Attach(Dropdown2, {T: 0xBCBDC0, B: 0x1A2132})


if (ErrorVal != 1)
{
  ; Set optional fields to 0 if empty, otherwise trader will error on parameters received

  if (StartPrice = "")
    StartPrice = 0
  if (StopPrice = "")
    StopPrice = 0
  if (TrailPercentage = "")
    TrailPercentage = 0
  if (TrailRatio = "")
    TrailRatio = 0
  if (EntryPrice = "")
    EntryPrice = 0


  ; Call python trader with parameters from GUI input

  Run, %A_ScriptDir%\Resources\Python\trader.py "%Type%" %Symbol% %Amount% %StartPrice% %StopPrice% %TrailPercentage% %TrailRatio% %Confirmations% %Mode% %Key% %Secret% %TKey% %TID% %EntryPrice%
  GuiControl, ChooseString, Mode, --- ; Resetting Mode selection so every trade execution is conscious action
  Sleep, 1000
  WinWaitActive , %Symbol%,,10 ; Wait for trader console window to be launched then set it to always on top
  if ErrorLevel
{
  return
}
else   
  WinSet, AlwaysOnTop, On , A
  WinSet, Style, -0x40000, A

  return
}

return

; Function to check numeric fields

ValidateInput(hnwd,var,classNN){
  
  GuiControlGet, Value, , %var%  
  ControlGet, isEnabled, Enabled,, %classNN%

  if(isEnabled = 1)   
  {
    If Value Is Not Number
      {
        CtlColors.Change(%hnwd%, "661515" , "BCBDC0")
        x = 0
      }
      else
      {
        CtlColors.Change(%hnwd%, "1A2132" , "BCBDC0")
        x = 1
      }
    
  }Else
    x = 1

if(x = 1)
  return True
Else
  return false

}

SetReset:

Gui, Submit, NoHide

if (Mode = "Reset")
{
  if (Type != "---")
    GuiControl, Enable, Edit8
}
Else
{
    GuiControl, Disable, Edit8
    ControlSetText, Edit8,
}

return

; Subroutine to show/hide fields based on order type selection, reset form if no order type selected

SetType:

; Enable/disable fields based on order type selection 

Gui, Submit, NoHide

Control, uncheck,, Button1

ResetControls("Dropdown1", "ComboBox1")
ResetControls("SymbolHnwd", "Edit1")
ResetControls("AmountHnwd", "Edit2")
ResetControls("StartPriceHnwd", "Edit3")
ResetControls("StopPriceHnwd", "Edit4")
ResetControls("TrailPercentageHnwd", "Edit5")
ResetControls("TrailRatioHnwd", "Edit6")
ResetControls("ConfirmationsHnwd", "Edit7")
ResetControls("Dropdown1", "ComboBox2")

OD_Colors.Attach(Dropdown1, {T: 0xBCBDC0, B: 0x1A2132})
OD_Colors.Attach(Dropdown2, {T: 0xBCBDC0, B: 0x1A2132})

GuiControl, Disable, Symbol
GuiControl, Disable, Amount
GuiControl, Disable, StartPrice
GuiControl, Hide, StartCheck
GuiControl, Disable, StopPrice
GuiControl, Disable, TrailPercentage
GuiControl, Disable, TrailRatio
GuiControl, Disable, Confirmations
GuiControl, Disable, EntryPrice
ControlSetText, Edit6,
ControlSetText, Edit8,

if (Type = "Trailing Stop")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Show, StartCheck
  GuiControl, Enable, TrailPercentage
  GuiControl, Enable, TrailRatio
  GuiControl, Enable, Confirmations
  ControlSetText, Edit6, 0
  GuiControl,, StartPriceLabel, Start Price:
  GuiControl,, StopPriceLabel, Stop Price:
}

if (Type = "Stop-Market")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Enable, StopPrice
  GuiControl, Enable, Confirmations
  GuiControl,, StartPriceLabel, Start Price:
  GuiControl,, StopPriceLabel, Stop Price:
}

if (Type = "Stop-HiLo")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Enable, StartPrice
  GuiControl, Enable, StopPrice  
  GuiControl, Enable, Confirmations
  GuiControl,, StartPriceLabel, High:
  GuiControl,, StopPriceLabel, Low:
}

if (Type = "Trailing HiLo")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Enable, StartPrice
  GuiControl, Enable, StopPrice
  GuiControl, Enable, TrailPercentage
  GuiControl, Enable, TrailRatio 
  GuiControl, Enable, Confirmations
  GuiControl,, StartPriceLabel, High: 
  GuiControl,, StopPriceLabel, Low:
  ControlSetText, Edit6, 0
}

return

; function to show/hide Start Price control based on checkbox state

SetCheck:
Gui, Submit, NoHide

if (StartCheck = 1)
{
      GuiControl, Enable, StartPrice
      CtlColors.Change(StartPriceHnwd, "1A2132" , "BCBDC0")
}else
{
      CtlColors.Change(StartPriceHnwd, "151A28" , "BCBDC0")
      GuiControl, Disable, StartPrice
      ControlSetText, Button1,  
      ControlSetText, Edit3,    
}
return

; function to reset control contents and backgroud color

ResetControls(hnwd, classNN){
  
    CtlColors.Detach(%hnwd%)
    ControlSetText,%classNN%,
  
}

GetSymbols: ; run hidden python script to retrieve symbols currently listed on Binance

Run, %A_ScriptDir%\Resources\Python\GetSymbols.pyw "%A_ScriptDir%"

return

; When 

~LButton::
if (A_PriorHotkey <> "~LButton" or A_TimeSincePriorHotkey > 400)
{
    KeyWait, LButton
    return
}

IfWinExist, ahk_exe Binance.exe
{
  IfWinActive, Advanced Trading Options
  {

    WinGetText, WinText, ahk_exe Binance.exe

    Needle = $

    Loop, parse, WinText, `n,
    {
        
      IfInString, A_LoopField, %Needle%
      {
        StringSplit, CurrentPrice, A_LoopField, %A_Space% 

        ControlGet, StartActive, Enabled,,Edit3
        ControlGet, StopActive, Enabled,,Edit4
        ControlGet, EntryActive, Enabled,,Edit8
        if (StartActive){
          ControlSetText, Edit3, , Advanced Trading Options
          ControlSend, Edit3, %CurrentPrice1%, Advanced Trading Options
        }
        if (StopActive){
          ControlSetText, Edit4, , Advanced Trading Options
          ControlSend, Edit4, %CurrentPrice1%, Advanced Trading Options
        }
        if (EntryActive){
          ControlSetText, Edit8, , Advanced Trading Options
          ControlSend, Edit8, %CurrentPrice1%, Advanced Trading Options
        }
        break
      }
    }

    Needle = BTC

    Loop, parse, WinText, `n,
    {   
      IfInString, A_LoopField, %Needle%
      {
        StringSplit, Symbol, A_LoopField,/
        ControlGet, SymbolActive, Enabled,,Edit1
        if (SymbolActive){
          ControlSetText, Edit1, , Advanced Trading Options
          ControlSend, Edit1, %Symbol1%%Symbol2%, Advanced Trading Options
        }
        break
      }
    }
  }
}
return

