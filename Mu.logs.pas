unit Mu.logs;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, dateutils, SyncObjs;

type
  PMuLogSeq = ^TMuLogSeq;

  TMuLogSeq = packed record
    logs: string;
    LogLevel: integer;
  end;

type
  TLockedLogSeqs = class(TObject)
  private
    FLock: TCriticalSection;
    FLogSeqs: Tlist;
    function getCount(): integer;
  public
    constructor create;
    destructor destroy; override;
    function GetOne(var Logseq: PMuLogSeq): boolean;
    function add(Logseq: TMuLogSeq): boolean; overload;
    function add(s: string; level: integer = 9): boolean; overload;
    function put(s: string; level: integer = 9): boolean; overload;
    function put(Logseq: TMuLogSeq): boolean; overload;
    property count: integer read getCount;
  end;

type
  TLogWrite = class(TThread)
  private
    FLockedLogSeqs: TLockedLogSeqs;
    FLogLevel: integer;
    FLogPath: string;
    FShowDateTime: Bool;
    FFileExtName: String;
    FFileName: String;
    procedure SaveToFile(PLogSeq: PMuLogSeq);
  protected
    procedure Execute; override;
  public
    constructor create(aLockedLogSeqs: TLockedLogSeqs; aLogLevel: integer;
      aLogPath: string = '');
    property LogLevel: integer read FLogLevel write FLogLevel;
    property ShowDateTime: Bool read FShowDateTime write FShowDateTime;

    property FileExtName: String read FFileExtName write FFileExtName;
    property FileName: String read FFileName write FFileName;

    // destructor Destroy; override;
  end;

  //
var
  Public_LockedLogSeqs: TLockedLogSeqs;
  Public_LogWrite: TLogWrite;
procedure public_addLogs(s: string; level: integer = 0);
procedure addLogs(s: string; level: integer = 0);
function GetExePath: string;

implementation

function getNowDllFileName(): string;
var
  szModuleName: array [0 .. 255] of char;
begin
  begin
    GetModuleFileName(hInstance, szModuleName, sizeof(szModuleName));
  end;
  result := (szModuleName);
end;

function GetExePath: string;
begin
  // Result := Trim(ExtractFilePath(ParamStr(0)));
  result := ExtractFilePath(getNowDllFileName);
end;

{ TLockedStringlist }

constructor TLockedLogSeqs.create;
begin
  FLock := TCriticalSection.create;
  FLogSeqs := Tlist.create;
end;

destructor TLockedLogSeqs.destroy;
begin
  FLock.Enter;
  FLock.Free;
  FLogSeqs.Free;
  inherited destroy;
end;

function TLockedLogSeqs.GetOne(var Logseq: PMuLogSeq): boolean;
begin
  FLock.Enter;
  try
    if FLogSeqs.count > 0 then
    begin
      Logseq := PMuLogSeq(FLogSeqs[0]);
      FLogSeqs.Delete(0);
      result := true;
    end
    else
      result := false;
  finally
    FLock.Leave;
  end;
end;

function TLockedLogSeqs.getCount(): integer;
begin
  result := FLogSeqs.count;
end;

function TLockedLogSeqs.add(Logseq: TMuLogSeq): boolean;
var
  PLogSeq: PMuLogSeq;
begin
  FLock.Enter;
  try
    new(PLogSeq);
    PLogSeq^.logs := Logseq.logs;
    PLogSeq^.LogLevel := Logseq.LogLevel;
    FLogSeqs.add(PLogSeq);
  finally
    FLock.Leave;
  end;
end;

function TLockedLogSeqs.add(s: string; level: integer = 9): boolean;
var
  PLogSeq: PMuLogSeq;
begin
  FLock.Enter;
  try
    new(PLogSeq);
    PLogSeq^.logs := s;
    PLogSeq^.LogLevel := level;
    FLogSeqs.add(PLogSeq);
  finally
    FLock.Leave;
  end;
end;

function TLockedLogSeqs.put(s: string; level: integer = 9): boolean;
var
  PLogSeq: PMuLogSeq;
begin
  FLock.Enter;
  try
    new(PLogSeq);
    PLogSeq^.logs := s;
    PLogSeq^.LogLevel := level;
    FLogSeqs.Insert(0, PLogSeq);

  finally
    FLock.Leave;
  end;
end;

function TLockedLogSeqs.put(Logseq: TMuLogSeq): boolean;
var
  PLogSeq: PMuLogSeq;
begin
  FLock.Enter;
  try
    new(PLogSeq);
    PLogSeq^.logs := Logseq.logs;
    PLogSeq^.LogLevel := Logseq.LogLevel;
    FLogSeqs.Insert(0, PLogSeq);

  finally
    FLock.Leave;
  end;
end;

constructor TLogWrite.create(aLockedLogSeqs: TLockedLogSeqs; aLogLevel: integer;
  aLogPath: string = '');
var
  i: integer;
begin
  FFileExtName := '.log';
  FFileName := '';
  FreeOnTerminate := false; // true;
  FLockedLogSeqs := aLockedLogSeqs;
  FLogLevel := aLogLevel;
  FShowDateTime := true;
  if (FLogLevel > 9) then
    FLogLevel := 9;
  FLogPath := aLogPath;
  if FLogPath <> '' then
    if FLogPath[length(FLogPath)] <> '\' then
      FLogPath := FLogPath + '\';

  if not directoryExists(FLogPath) then
    ForceDirectories(FLogPath);
  inherited create(false);
end;
{
  destructor TLogWrite.Destroy;
  var i: integer;
  begin
  inherited Destroy;
  end;
}

procedure TLogWrite.SaveToFile(PLogSeq: PMuLogSeq);
var
  F: Textfile;
  fn: string;
begin
  if FLogPath = '' then
    FLogPath := GetExePath() + 'logs\';
  if FFileName = '' then
    fn := FLogPath + formatdatetime('yyyymmdd', now()) + FFileExtName
  else
  begin
    fn := FLogPath + FFileName + FFileExtName;
  end;
  try
    AssignFile(F, fn);
    try
      if not fileexists(fn) then
      begin
        rewrite(F);
      end
      else
        append(F);
      if FShowDateTime then
        Writeln(F, formatdatetime('yyyymmdd hh:mm:ss', now()) + #9 +
          PLogSeq^.logs)
      else
        Writeln(F, PLogSeq^.logs);
    finally
      closefile(F);
    end;
  except

  end;
end;

procedure TLogWrite.Execute;
var
  PLogSeq: PMuLogSeq;
begin
  while not terminated do
  begin

    if FLockedLogSeqs.GetOne(PLogSeq) then
    begin
      try
        if PLogSeq.LogLevel <= FLogLevel then
          SaveToFile(PLogSeq);
      finally
        Dispose(PMuLogSeq(PLogSeq)); // Dispose 不认识Record，必须给指定类
        PLogSeq := nil;
      end;
    end
    else
      sleep(200);

  end;
end;

/// ///////////////////////

procedure public_addLogs(s: string; level: integer = 0);
var
  F: Textfile;
  fn: string;
  Logseq: TMuLogSeq;
begin
  Logseq.logs := s; //
  Logseq.LogLevel := level;
  Public_LockedLogSeqs.add(Logseq);
end;

procedure addLogs(s: string; level: integer = 0);
var
  F: Textfile;
  fn: string;
  Logseq: TMuLogSeq;
begin
  Logseq.logs := s; //
  Logseq.LogLevel := level;
  Public_LockedLogSeqs.add(Logseq);
end;

initialization

Public_LockedLogSeqs := TLockedLogSeqs.create;
Public_LogWrite := TLogWrite.create(Public_LockedLogSeqs, 9,
  GetExePath() + 'logs\');

finalization

{ Public_LogWrite.Suspend;
}
Public_LogWrite.Terminate;
Public_LogWrite.Free;
Public_LockedLogSeqs.Free;

end.
