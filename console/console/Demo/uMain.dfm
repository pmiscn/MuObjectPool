object fMain: TfMain
  Left = 300
  Top = 357
  Width = 586
  Height = 304
  ActiveControl = Console
  Caption = 'TConsole Demo Application [http://www.elsdoerfer.net]'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg 2'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Console: TConsole
    Left = 0
    Top = 0
    Width = 578
    Height = 275
    AutoUseInsertMode = True
    InsertMode = True
    InsertCaret = ctHorizontalLine
    OverwriteCaret = ctHalfBlock
    BorderSize = 3
    ExtraLineSpacing = 0
    OnBoot = ConsoleBoot
    OnCommandExecute = ConsoleCommandExecute
    OnGetPrompt = ConsoleGetPrompt
    OnCommandKeyPress = ConsoleCommandKeyPress
    OnPromptKeyPress = ConsolePromptKeyPress
    Align = alClient
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentColor = False
    TabOrder = 0
    TabStop = False
  end
end
