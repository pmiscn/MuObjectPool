unit Mu.Console;

{
  Console Component
}

interface

{$I Catarinka.inc}

uses
{$IFDEF DXE2_OR_UP}
  Vcl.Forms, Vcl.Controls, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Menus, Vcl.Clipbrd, Vcl.Dialogs,
{$ELSE}
  Forms, Controls, SysUtils, Classes, Graphics, Menus, Clipbrd, Dialogs,
{$ENDIF}
  typinfo, qrbtree, Generics.Collections,
  Mu.ConsoleCore, Mu.StringLoop; // ;

type

  TMuConsoleOnScriptCommand = procedure(const Code: string) of object;

type
  TMuConsole = class(TCustomControl)
  private
    fConsole: TConsole;
    fCustomCommand: boolean;
    fCustomCommandState: Integer;
    fCustomHandler: string;
    // fHelpParser: TStringLoop;
    fOnScriptCommand: TMuConsoleOnScriptCommand;
    fPopupMenu: TPopupMenu;
    fProgDir: string;
    fPromptText: string;
    function GetLastCommand: string;
    procedure PopupMenuitemClick(Sender: TObject);
    procedure SetCustomHandler(s: string);
    procedure ConsoleBoot(Sender: TCustomConsole; var ABootFinished: boolean);
    procedure ConsoleCommandExecute(Sender: TCustomConsole; ACommand: String;
      var ACommandFinished: boolean);
    procedure ConsoleCommandKeyPress(Sender: TCustomConsole; var AKey: Char;
      var ATerminateCommand: boolean);
    procedure ConsoleGetPrompt(Sender: TCustomConsole;
      var APrompt, ADefaultText: string; var ADefaultCaretPos: Integer);
  protected
  public
    function PrintAvailableCommands(Sender: TCustomConsole): boolean;
    procedure Boot;
    procedure Clear;
    procedure ConsoleOutput(Enabled: boolean);
    // procedure LoadSettings(prefs: TCatPreferences);
    procedure WriteLn(ALine: string = '');
    procedure Write(ALine: string = '');
    procedure WriteVersion;
    procedure ResetPrompt;
    procedure ResetFull;
    procedure SetCurrentLine(s: string);
    procedure SetPrompt(s: string);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // properties
    property Console: TConsole read fConsole;
    property CustomHandler: string read fCustomHandler write SetCustomHandler;
    property LastCommand: string read GetLastCommand;
    property PromptText: string read fPromptText write fPromptText;
    property OnScriptCommand: TMuConsoleOnScriptCommand read fOnScriptCommand
      write fOnScriptCommand;
  end;

const
  CRLF = #13 + #10;

implementation

uses strutils;

procedure TMuConsole.SetCustomHandler(s: string);
begin
  if s = emptystr then
    fCustomHandler := emptystr
  else
    fCustomHandler := s + ' ';
end;

procedure TMuConsole.Boot;
begin
  fConsole.Boot;
end;

procedure TMuConsole.ConsoleCommandExecute(Sender: TCustomConsole;
  ACommand: String; var ACommandFinished: boolean);
begin
  fConsole.Writeln(ACommand);
end;

procedure TMuConsole.ConsoleCommandKeyPress(Sender: TCustomConsole;
  var AKey: Char; var ATerminateCommand: boolean);
begin
  if (fCustomCommand) then
  Begin
    if fCustomCommandState = 0 then
    begin // help command
      AKey := #0;
      if PrintAvailableCommands(Sender) = False then
      begin
        fCustomCommand := False;
        ATerminateCommand := true;
      end;
    end;
  end;
end;

function TMuConsole.PrintAvailableCommands(Sender: TCustomConsole): boolean;
var
  c: Integer;
const
  max = 20;
  { function RemoveHTML(s: string): string;
    begin
    s := replacestr(s, '&nbsp;&nbsp;', ' - ');
    // s := striphtml(s);
    result := s;
    end;
  }
begin
  result := False;
  { c := 0;
    while (fHelpParser.Found) do
    begin
    Inc(c);
    Sender.Writeln('   ' + RemoveHTML(fHelpParser.Current));
    result := true;
    if c = max then
    Sender.Writeln('Press any key to continue. . .');
    if c = max then
    exit;
    end;
    if c < max then
    result := False;
  }
end;

procedure TMuConsole.ConsoleGetPrompt(Sender: TCustomConsole;
  var APrompt, ADefaultText: string; var ADefaultCaretPos: Integer);
begin
  APrompt := fPromptText + '>';
end;

procedure TMuConsole.SetCurrentLine(s: string);
begin
  fConsole.CurrLine.Text := s;
  fConsole.CaretX := Length(s) + 1;
  fConsole.Invalidate;
end;

procedure TMuConsole.SetPrompt(s: string);
begin
  fPromptText := s;
  if s + '>' <> fConsole.LastPrompt then
    ResetPrompt;
end;

procedure TMuConsole.ResetPrompt;
begin
  fConsole.BeginExternalOutput;
  fConsole.EndExternalOutput;
end;

procedure TMuConsole.ResetFull;
begin
  fCustomHandler := emptystr;
  SetPrompt(emptystr);
  Clear;
  WriteVersion;
end;

procedure TMuConsole.ConsoleOutput(Enabled: boolean);
begin
  if Enabled = False then
  begin
    if fConsole.prompt = False then
      fConsole.EndExternalOutput;
  end;
end;

function TMuConsole.GetLastCommand: string;
begin
  result := fCustomHandler + fConsole.LastCommand;
end;

procedure TMuConsole.Clear;
begin
  fConsole.BeginExternalOutput;
  fConsole.Clear;
  fConsole.EndExternalOutput;
end;

procedure TMuConsole.PopupMenuitemClick(Sender: TObject);
begin
  case tmenuitem(Sender).Tag of
    1:
      Clear;
    2:
      fConsole.PasteFromClipboard;
  end;
end;

procedure TMuConsole.Write(ALine: string = '');
begin
  ALine := replacestr(ALine, #10, emptystr);
  if fConsole.prompt = true then
    fConsole.BeginExternalOutput;
  fConsole.Write(ALine);
  fConsole.Repaint;
  application.ProcessMessages;
end;

procedure TMuConsole.Writeln(ALine: string = '');
var
  slp: TStringLoop;
begin
  fConsole.BeginExternalOutput;
  try
    if fConsole.Lines.Count >= 1000 then
      fConsole.Clear;
    if fConsole.prompt = true then
      fConsole.BeginExternalOutput;
    if pos(CRLF, ALine) <> 0 then
    begin
      slp := TStringLoop.Create;
      slp.LoadFromString(ALine);
      while slp.Found do
        fConsole.Writeln(slp.Current);
      slp.free;
    end
    else
      fConsole.Writeln(ALine);
  finally
    fConsole.EndExternalOutput;
  end;
  application.ProcessMessages;
end;

procedure TMuConsole.WriteVersion;
begin
  if fConsole.prompt = true then
    fConsole.BeginExternalOutput;
  fConsole.Writeln('青岛庞城网络科技有限公司 命令行工具' + ' '); // + GetFileVersion(paramstr(0))
  fConsole.Writeln('输入“help”或者"?"查看命令列表.');
  fConsole.Writeln;
end;

procedure TMuConsole.ConsoleBoot(Sender: TCustomConsole;
  var ABootFinished: boolean);
begin
  WriteVersion;
end;

constructor TMuConsole.Create(AOwner: TComponent);
var
  mi: tmenuitem;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  fProgDir := extractfilepath(paramstr(0));
  // fHelpParser := TStringLoop.Create;
  fConsole := TConsole.Create(self);
  fConsole.Parent := self;
  fConsole.Align := alClient;
  fConsole.Font.Name := 'Fixedsys';
  fConsole.Color := 0; // $002D2D2D;
  fConsole.Font.Color := clWhite;
  fConsole.Font.Style := [];
  fConsole.OnBoot := ConsoleBoot;
  fConsole.OnCommandExecute := ConsoleCommandExecute;
  fConsole.OnCommandKeyPress := ConsoleCommandKeyPress;
  fConsole.OnGetPrompt := ConsoleGetPrompt;
  fPopupMenu := TPopupMenu.Create(self);
  fConsole.PopupMenu := fPopupMenu;
  mi := tmenuitem.Create(self);
  fPopupMenu.Items.Add(mi);
  mi.Caption := '&Clear';
  mi.Tag := 1;
  mi.OnClick := PopupMenuitemClick;
  mi := tmenuitem.Create(self);
  fPopupMenu.Items.Add(mi);
  mi.Caption := '-';
  mi.OnClick := PopupMenuitemClick;
  mi := tmenuitem.Create(self);
  fPopupMenu.Items.Add(mi);
  mi.Caption := '&Paste';
  mi.Tag := 2;
  mi.OnClick := PopupMenuitemClick;
end;

destructor TMuConsole.Destroy;
begin
  fPopupMenu.free;
  // fHelpParser.free;
  fConsole.free;
  inherited Destroy;
end;

initialization

finalization

end.
