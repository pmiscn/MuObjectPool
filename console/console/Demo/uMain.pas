unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Console;

type
  (*
    This thread is used to demonstrate a command that needs much time
    and cannot finish at once.
  *)
  TWaitThread = class(TThread)
  private
    FOnTick: TNotifyEvent;
    FOnFinished: TNotifyEvent;
    procedure SetOnFinished(const Value: TNotifyEvent);
    procedure SetOnTick(const Value: TNotifyEvent);
  public
    procedure Execute; override;

    property OnTick: TNotifyEvent read FOnTick write SetOnTick;
    property OnFinished: TNotifyEvent read FOnFinished write SetOnFinished;
  end;

  TfMain = class(TForm)
    Console: TConsole;
    procedure ConsoleBoot(Sender: TCustomConsole;
      var ABootFinished: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ConsoleCommandKeyPress(Sender: TCustomConsole;
      var AKey: Char; var ATerminateCommand: boolean);
    procedure ConsoleCommandExecute(Sender: TCustomConsole;
      ACommand: String; var ACommandFinished: Boolean);
    procedure ConsoleGetPrompt(Sender: TCustomConsole; var APrompt,
      ADefaultText: String; var ADefaultCaretPos: Integer);
    procedure ConsolePromptKeyPress(Sender: TCustomConsole;
      var AKey: Char);
  protected
    procedure BootTickHandler(Sender: TObject);
    procedure BootFinishedHandler(Sender: TObject);
  private
    FBooting: boolean;
    FPrompt: string;
    FCustomCommand: boolean;
    FCustomCommandName: string;
    FCustomCommandPass: string;
    FCustomCommandState: Integer;
    FLastCommand: string;
    procedure SetBooting(const Value: boolean);
    procedure SetPrompt(const Value: string);
    procedure SetCustomCommand(const Value: boolean);
    procedure SetCustomCommandName(const Value: string);
    procedure SetCustomCommandPass(const Value: string);
    procedure SetCustomCommandState(const Value: Integer);
    procedure SetLastCommand(const Value: string);
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    // True, if console is currently booting
    property Booting: boolean read FBooting write SetBooting default false;
    // Temporary variables to store data for a basic interactive command.
    property CustomCommand: boolean read FCustomCommand write SetCustomCommand;
    property CustomCommandName: string read FCustomCommandName write SetCustomCommandName;
    property CustomCommandPass: string read FCustomCommandPass write SetCustomCommandPass;
    property CustomCommandState: Integer read FCustomCommandState write SetCustomCommandState;
    // Stores the current prompt
    property Prompt: string read FPrompt write SetPrompt;
    // Stores the last command (basic replacement of a command history)
    property LastCommand: string read FLastCommand write SetLastCommand;
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

{ TfMain }

// This is called when the boot thread has completed it's work
procedure TfMain.BootFinishedHandler(Sender: TObject);
begin
  // Print some text
  Console.Writeln;
  Console.Writeln('Booting finished. Type "help" for a list of available commands.');
  Console.Writeln;

  // Close Output Buffer (and open a prompt)
  Console.EndExternalOutput;

  // Update ST´tatus Property
  Booting := False;
end;

// This is called everytime to boot thread as completed a bit of its work. Of
// course, in this demo this is only a simulation, in fact the thread does
// nothing senseful.
procedure TfMain.BootTickHandler(Sender: TObject);
begin
  Console.Write('.');
  // Force repaint
  Console.Repaint;
end;

// Called when the console object gets activated
procedure TfMain.ConsoleBoot(Sender: TCustomConsole;
  var ABootFinished: Boolean);
var BootThread: TWaitThread;
begin
  // Print Booting Messages
  Sender.Writeln('TConsole Demo Application by Michael Elsdfer');
  Sender.Writeln('Get TConsole Component at [http://www.elsdoerfer.net?pid=console]');
  Sender.Writeln;
  Sender.Write('Booting');
  ABootFinished := False;

  // Create A Boot Thread (In Reality, this thread should do some real work)
  BootThread := TWaitThread.Create(True);
  BootThread.OnTick := BootTickHandler;
  BootThread.OnFinished := BootFinishedHandler;
  BootThread.Resume;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  // Reset Variables
  FCustomCommand := False;
  FPrompt := '(enter your command) ';

  // Boot the console
  Console.Boot;
  FBooting := True;
end;

// This is called when a key is pressed while TConsole is focused AND in command
// mode (there is no prompt).
procedure TfMain.ConsoleCommandKeyPress(Sender: TCustomConsole;
  var AKey: Char; var ATerminateCommand: boolean);
begin
  // No Input Is Accepted While Booting
  if (FBooting) then AKey := #0
  else

  // Handling of the Custom Interactive Command
  if (CustomCommand) then Begin
  
    // State = 0 means we are currently asking for users's name
    if CustomCommandState = 0 then Begin
      // Enter Key Pressed
      if AKey = #13 then Begin
       CustomCommandName := Copy(Sender.CurrLine.Text, Sender.MinLeftCaret, MaxInt);
       CustomCommandState := 1;
       Sender.Writeln;
       Sender.Write('What is your favorite color: ', True);
      // Escape Key Pressed
      end else if AKey = Chr(VK_ESCAPE) then Begin
        Sender.Writeln;
        Sender.Writeln('Command aborted by user.');
        FCustomCommand := False;
        AKey := #0;        
        ATerminateCommand := True;
      end;
      
    // State = 1 means we are currently asking for user's favorite colour
    end else Begin
      // Enter Key Pressed
      if AKey = #13 then Begin
        CustomCommandPass := Copy(Sender.CurrLine.Text, Sender.MinLeftCaret, MaxInt);      
        Sender.Writeln;
        Sender.Writeln('Hello ' + CustomCommandName + ', your favorite color is ' + CustomCommandPass);
        Sender.Writeln();
        FCustomCommand := False;
        ATerminateCommand := True;
      // Escape Key Pressed
      end else if AKey = Chr(VK_ESCAPE) then Begin
        Sender.Writeln;
        Sender.Writeln('Command aborted by user.');
        FCustomCommand := False;
        AKey := #0;
        ATerminateCommand := True;
      end;
    end;
    
  end;
end;

procedure TfMain.SetBooting(const Value: boolean);
begin
  FBooting := Value;
end;

// Called by TConsole when the user pressed Enter or Return while in Prompt Mode
procedure TfMain.ConsoleCommandExecute(Sender: TCustomConsole;
  ACommand: String; var ACommandFinished: Boolean);
var i: integer;
begin
  // We are using TCommandParser to parse the command string, which comes with
  // TConsole. Simple create it and read the command and the parameters from
  // it's properties.
  with TCommandParser.Create(ACommand) do Begin

    // HELP Command
    if (Command = 'help') then Begin
      Sender.Writeln('The following commands are available: ');
      Sender.Writeln('  help - Show this list of commands');
      Sender.Writeln('  echo [string] - Prints a string on the screen');
      Sender.Writeln('  setborder [int] - Changes the border size of the console');
      Sender.Writeln('  setprompt [string] - Changes the prompt');
      Sender.Writeln('  setcolor [int] - Changes the background color of the console');
      Sender.Writeln('  askme - Example for an interactive command');
      Sender.Writeln('  exit - Terminates the program');
      Sender.Writeln;

    // ECHO Command
    end else if (Command = 'echo') then
      for i := 1 to ParamCount do Sender.Writeln(Parameters[i])
    else if (Command = 'setborder') then Begin
      if (ParamCount > 0) then
        try
          Sender.BorderSize := StrToInt(Parameters[1]);
        except
          Sender.Writeln('Invalid Border Value.');
        end
      else Sender.Writeln('Current value is: ' + IntToStr(Sender.BorderSize));

    // SETCOLOR Command
    end else if (Command = 'setcolor') then Begin
      if (ParamCount > 0) then
        try
          TConsole(Sender).Color := StrToInt(Parameters[1]);
        except
          Sender.Writeln('Invalid Color Value.');
        end
      else Sender.Writeln('Current value is: ' + IntToStr(Integer(TConsole(Sender).Color)));

    // ASKME Command
    end else if (Command = 'askme') then Begin
      Sender.Write('What is your name (esc to cancel command): ', True);
      FCustomCommand := True;
      FCustomCommandState := 0;
      FCustomCommandName := '';
      FCustomCommandPass := '';
      // Command has not finished yet. We use a custom command handler
      ACommandFinished := False;

    // SETPROMPT Command
    end else if (Command = 'setprompt') then Begin
      if (ParamCount > 0) then FPrompt := Parameters[1]
      else Sender.Writeln('Current value is: ' + FPrompt);

    // EXIT Command
    end else if (Command = 'exit') then  Sender.Shutdown

    // Invalid Command
    else Begin
      Sender.Writeln('"' + Command + '" is not recognized.');
      Sender.Writeln;
    end;

    // Free Command Parser
    Free;
  end;

  // Update Last Command
  LastCommand := ACommand;
end;

procedure TfMain.SetPrompt(const Value: string);
begin
  FPrompt := Value;
end;

procedure TfMain.ConsoleGetPrompt(Sender: TCustomConsole; var APrompt,
  ADefaultText: string; var ADefaultCaretPos: Integer);
begin
  APrompt := FPrompt;
end;

procedure TfMain.SetCustomCommand(const Value: boolean);
begin
  FCustomCommand := Value;
end;

procedure TfMain.SetCustomCommandName(const Value: string);
begin
  FCustomCommandName := Value;
end;

procedure TfMain.SetCustomCommandPass(const Value: string);
begin
  FCustomCommandPass := Value;
end;

procedure TfMain.SetCustomCommandState(const Value: Integer);
begin
  FCustomCommandState := Value;
end;

procedure TfMain.SetLastCommand(const Value: string);
begin
  FLastCommand := Value;
end;

// This is executed while a key is pressed in prompt mode
// We use it to implement a little command history (in fact, it's
// a "show last command" feature ;-)
procedure TfMain.ConsolePromptKeyPress(Sender: TCustomConsole;
  var AKey: Char);
begin
  if (AKey = Chr(vk_up)) then Begin
    Sender.CurrLine.Text := FLastCommand;
    Sender.CaretX := Length(FLastCommand) + 1;
    Sender.Invalidate;
  end;
end;

{ TWaitThread }

procedure TWaitThread.Execute;
var i: Integer;
begin
  Self.FreeOnTerminate := True;

  // Just do nothing
  for i := 0 to 10 do Begin
    sleep(300);
    if Assigned(fOnTick) then fOnTick(Self);
  end;

  if Assigned(fOnFinished) then fOnFinished(Self);
end;

procedure TWaitThread.SetOnFinished(const Value: TNotifyEvent);
begin
  FOnFinished := Value;
end;

procedure TWaitThread.SetOnTick(const Value: TNotifyEvent);
begin
  FOnTick := Value;
end;

end.
