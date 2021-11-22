program ConsoleDemo;

uses
  Forms,
  uMain in 'uMain.pas' {fMain},
  Console in '..\Console.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
