unit Mu.SaveTask;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.SyncObjs,

  PerlRegEx, // curl, curl_d, Curl_help,
  qstring, qworker, qtimetypes, qdb, qlog, qjson, qsimplepool,
  Mu.DbHelp, Mu.pool.qjson, Mu.pool.st, Mu.pool.Reg, Mu.LookPool, Mu.Task1,
  Generics.Collections,

  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Vcl.Grids, Vcl.DBGrids, Data.DB, Vcl.StdCtrls,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TOnSaveEvent<T> = procedure(Sender: TObject; aData: T) of object;
  TOnSaveNotify<T> = reference to procedure(Sender: TObject; aData: T);
  TOnSaveByFDacNotify<T> = reference to procedure(Sender: TObject;
    aFDataset: TFDStoredProc; aData: T);

  TSaveTask<TTaskRecord> = class(TMuTask1<TTaskRecord>)
  protected
  public
 //   property OnSave: TOnDoJobNotify1<TTaskRecord> read FOnDoJob write FOnDoJob;
  end;

  TSaveTaskByFDac<TRecord> = class(TMuTask1<TRecord>)
  private
    // FProcs: array of TFDStoredProc;
    FProc: TFDStoredProc;
  protected
    FOnSave: TOnSaveByFDacNotify<TRecord>;
    // procedure doJob(AJob: PQJob); override;
    destructor Destroy; override;
    function doJob(at: TRecord): string; override;
    procedure Stop(); override;
    procedure Start(); override;
  public
    property OnSaveByFDac: TOnSaveByFDacNotify<TRecord> read FOnSave
      write FOnSave;
  end;

implementation

uses Mu.Logs;

procedure TSaveTaskByFDac<TRecord>.Start;
var
  i: Integer;
begin
  // setlength(FProcs, FThreadCount);
  // for i := Low(FProcs) to High(FProcs) do
  // FProcs[i] := nil;
  FProc := nil;
  inherited;
end;

procedure TSaveTaskByFDac<TRecord>.Stop;
var
  i: Integer;
begin
  inherited;
  { for i := Low(FProcs) to High(FProcs) do
    SQLDBHelp.returnProc(FProcs[i]);
    setlength(FProcs, 0);

    SQLDBHelp.returnProc(FProc); }
end;

destructor TSaveTaskByFDac<TRecord>.Destroy;
begin
  Stop;
  inherited;
end;

function TSaveTaskByFDac<TRecord>.doJob(at: TRecord): string;

begin
  inherited;
  if assigned(FOnSave) then
  begin
    { if not assigned(FProcs[idx]) then
      begin
      FProcs[idx] := SQLDBHelp.getProc;
      FProcs[idx].Tag := idx;
      Mu.Logs.public_addLogs('get proc');
      end; }
    // proc.ResourceOptions.CmdExecMode := amBlocking; // amAsync;
    try
      try
        FProc := SQLDBHelp.getProc;
        FOnSave(self, FProc, at);
      finally
        SQLDBHelp.returnProc(FProc);
      end;
    except
      on e: exception do
      begin
        Mu.Logs.public_addLogs(e.Message);
      end;
    end;
  end;

end;

end.
