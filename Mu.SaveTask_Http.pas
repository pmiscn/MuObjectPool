unit Mu.SaveTask_Http;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,

  PerlRegEx, curl, curl_d, Mu.Pool.curl,
  qstring, qworker, qtimetypes, qdb, qlog, qjson, qsimplepool,
  Mu.DbHelp, Mu.Pool.qjson, Mu.Pool.st, Mu.Pool.Reg, Mu.LookPool,
  Mu.SaveTask,
  Generics.Collections;

type
  TOnSaveByCurlNotify<T> = reference to procedure(Sender: TObject;
    aHttp: TCurlHttpRequest; aData: T);

  TSaveTaskByCURL<TRecord> = class(TSaveTask<TRecord>)
  private
    FHttps: array of TCurlHttpRequest;
    FOnSave: TOnSaveByCurlNotify<TRecord>;
  protected
    procedure Stop(); override;
    procedure Start(); override;
    function doJob(at: TRecord): string; override;
    // procedure SaveToDbJob(AJob: PQJob); override;
  public
    property OnSaveByCUrl: TOnSaveByCurlNotify<TRecord> read FOnSave
      write FOnSave;
  end;

implementation

uses Mu.Logs;
{ TSaveTaskByCURL<TRecord> }

// procedure TSaveTaskByCURL<TRecord>.SaveToDbJob(AJob: PQJob);

function TSaveTaskByCURL<TRecord>.doJob(at: TRecord): string;
var
  idx: Integer;
begin

  if assigned(FOnSave) then
  begin
    if not assigned(FHttps[idx]) then
    begin
      FHttps[idx] := CurlHttpPool.get;
      // FHttps[idx].Tag := idx;
      Mu.Logs.public_addLogs('get http');
    end;

    try // FHttps[idx]
      FOnSave(self, FHttps[idx], at);
    except
      CurlHttpPool.return(FHttps[idx]);
      FHttps[idx] := nil;
    end;
  end;

end;

procedure TSaveTaskByCURL<TRecord>.Start;
var
  i: Integer;
begin
  setlength(FHttps, FThreadCount);
  for i := Low(FHttps) to High(FHttps) do
    FHttps[i] := nil;
  inherited;

end;

procedure TSaveTaskByCURL<TRecord>.Stop;
begin
  inherited;
  setlength(FHttps, 0);
end;

end.
