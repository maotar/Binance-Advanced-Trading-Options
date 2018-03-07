#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Keep the script running until the user exits it.
#SingleInstance

; Call Python script to save currently listed symbols to text file

Run, %A_ScriptDir%\Resources\Python\GetSymbols.pyw "%A_ScriptDir%"
SetTimer, GetSymbols, 180000

; Included classes, credit https://github.com/AHK-just-me

#Include, %A_ScriptDir%\Resources\AHK\Class_CtlColors.ahk   
#Include, %A_ScriptDir%\Resources\AHK\Class_OD_Colors.ahk
#Include, %A_ScriptDir%\Resources\AHK\Class_ImageButton.ahk 

; Create GUI

GuiWidth  = 270
GuiTitle  = Advanced Trading Options

Gui, +AlwaysOnTop -Caption

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
Gui, Add, DDL, x120 y40 w130 h100 vType +border Choose1 hwndDropdown1 gSetType -E0x200 +0x0210, ---|Trailing Stop|Stop-Market
OD_Colors.Attach(Dropdown1, {T: 0xBCBDC0, B: 0x1A2132})

Gui, Add, Text, x10 y70,  Symbol:  
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndSymbolHnwd x120 y70 w130 Uppercase vSymbol

Gui, Add, Text, x10 y100,  Amount:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndAmountHnwd x120 y100 w130 vAmount

Gui, Add, Text, x10 y131,  Start Price:
GUI, Add, Checkbox, -E0x200 hwndStartCheck x97 y134 w13 h13 vStartCheck gSetCheck, %A_Space%
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndStartPriceHnwd x120 y130 w130 vStartPrice

Gui, Add, Text, x10 y160,  Stop Price:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndStopPriceHnwd x120 y160 w130 vStopPrice

Gui, Add, Text, x10 y190,  Trail `%:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTrailPercentageHnwd x120 y190 w130 Limit3 vTrailPercentage

Gui, Add, Text, x10 y220,  Ratio:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndTrailRatioHnwd x120 y220 w130 Limit3 vTrailRatio, 0

Gui, Add, Text, x10 y250,  Confirmations:
Gui, Add, Edit, +border cBCBDC0 -E0x200 hwndConfirmationsHnwd x120 y250 w130 Number Limit1 vConfirmations

Gui, Add, Text, x10 y280, Mode :
Gui, Add, DDL, x120 y280 w130 h100 vMode +border Choose1 hwndDropdown2  -E0x200 +0x0210, ---|Real|Test|Reset
OD_Colors.Attach(Dropdown2, {T: 0xBCBDC0, B: 0x1A2132})

Gui, Add, Button, x10 y325 w240 h28 Default gExecuteOrder hwndSubmitButton, Execute
Opt1 := [0, 0xFFFF007A, 0xFFFF007A, "White"]             ; normal background & text colors
Opt2 := {2: 0xE5006D, 3: 0xE5006D, 4: "White"}           ; hot background & text colors 
Opt3 := {4: "Black"}                                     ; pressed text color
If !ImageButton.Create(SubmitButton, Opt1, Opt2, Opt3)
  MsgBox, 0, ImageButton Error Btn2, % ImageButton.LastError

Gui,show, w270,Advanced Trading Options

Gosub, SetType ; Disable controls on startup
return



GuiClose:
ExitApp

GuiMove: 
PostMessage, 0xA1, 2,,, A ; Titlebar drag/move
Return 

ExecuteOrder:
Gui, Submit, NoHide

ErrorVal = 0

if (Type = "---") ; if Type is not set no validation needed
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

; Check if Symbol not empty, then check against currently listed symbols

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

  MsgBox, Executed
  ;Run, %A_ScriptDir%\Resources\Python\trader.py %Type% %Symbol% %Amount% %StartPrice% %StopPrice% %TrailPercentage% %TrailRatio% %Confirmations% %Mode% 
  GuiControl, ChooseString, Mode, --- ; Resetting Mode selection so every trade execution is conscious action
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

; Subroutine to show/hide fields based on order type selection, reset form if no order type selected

SetType:
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
ControlSetText, Edit6,

if (Type = "Trailing Stop")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Show, StartCheck
  GuiControl, Enable, TrailPercentage
  GuiControl, Enable, TrailRatio
  GuiControl, Enable, Confirmations
  ControlSetText, Edit6, 0
}

if (Type = "Stop-Market")
{
  GuiControl, Enable, Symbol
  GuiControl, Enable, Amount
  GuiControl, Enable, StopPrice
  GuiControl, Enable, Confirmations
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
}
return

; function to reset control contents and backgroud color

ResetControls(hnwd, classNN){
  
    CtlColors.Detach(%hnwd%)
    ControlSetText,%classNN%,
  
}

GetSymbols:

Run, %A_ScriptDir%\Resources\Python\GetSymbols.pyw "%A_ScriptDir%"

return