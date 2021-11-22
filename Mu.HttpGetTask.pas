unit Mu.HttpGetTask;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Mu.Task,
  PerlRegEx, // curl, curl_d, Curl_help,
  qstring, qworker, qdb, qlog, qsimplepool,

  // Mu.pool.qjson, Mu.pool.Reg, Mu.DbHelp,qjson, qtimetypes,
  Mu.pool.st, Mu.LookPool,
  Generics.Collections;

type

  TOnHtmlParseNotify<T> = reference to procedure(Sender: TObject; aHtml: String;
    aData: tlist<T>);
  TOnHtmlGetNotify<TUrl> = reference to procedure(Sender: TObject; aUrl: TUrl;
    var aHtml: String; var ErrStr: string);

  TOnHtmlGetAndParseNotify<TUrl, T> = reference to procedure(Sender: TObject;
    aUrl: TUrl; aData: tlist<T>; var aHtml: String; var ErrStr: string);

  TMuHttpGetTask<TTaskRecord, TResultRecord> = class
    (TMuTask<TTaskRecord, TResultRecord>)
  private
    FResultListPool: TListPool<TResultRecord>;
    FOnHtmlGet: TOnHtmlGetNotify<TTaskRecord>;
    FOnHtmlParse: TOnHtmlParseNotify<TResultRecord>;
    FOnHtmlGetAndParseNotify
      : TOnHtmlGetAndParseNotify<TTaskRecord, TResultRecord>;
  protected
    function doJob(at: TTaskRecord; ar: TResultRecord): string; override;
  public
    constructor Create(aTaskList: TMuLockList<TTaskRecord>;
      aResultList: TMuLockList<TResultRecord>; aThreadCount: integer = 4;
      aStartImmediately: Boolean = true); override;
    destructor Destroy; override;

    property OnHtmlGet: TOnHtmlGetNotify<TTaskRecord> read FOnHtmlGet
      write FOnHtmlGet;
    property OnHtmlParse: TOnHtmlParseNotify<TResultRecord> read FOnHtmlParse
      write FOnHtmlParse;
    property OnHtmlGetAndParse
      : TOnHtmlGetAndParseNotify<TTaskRecord, TResultRecord>
      read FOnHtmlGetAndParseNotify write FOnHtmlGetAndParseNotify;
  end;

implementation

uses Mu.Logs;
{ TMuHttpGetTask<TTaskRecord, TResultRecord> }

constructor TMuHttpGetTask<TTaskRecord, TResultRecord>.Create
  (aTaskList: TMuLockList<TTaskRecord>; aResultList: TMuLockList<TResultRecord>;
  aThreadCount: integer; aStartImmediately: Boolean);
begin
  FResultListPool := TListPool<TResultRecord>.Create;
  inherited;
end;

destructor TMuHttpGetTask<TTaskRecord, TResultRecord>.Destroy;
begin
  FResultListPool.Free;
  inherited;
end;

function TMuHttpGetTask<TTaskRecord, TResultRecord>.doJob(at: TTaskRecord;
  ar: TResultRecord): string;
var
  html, ErrStr: String;
  aList: tlist<TResultRecord>;
  i: integer;
begin
  inherited;
  result := '';
  ErrStr := '';
  try
    aList := tlist<TResultRecord>(FResultListPool.get);

  except
    on e: exception do
      ErrStr := ('resultlist get ' + e.Message);
  end;
  try

    if assigned(FOnHtmlGetAndParseNotify) then
    begin
      try
        FOnHtmlGetAndParseNotify(self, at, aList, html, ErrStr);
      except
        on e: exception do
          ErrStr := ('FOnHtmlGetAndParseNotify ' + e.Message);
      end;

    end
    else if assigned(FOnHtmlGet) then
    begin
      FOnHtmlGet(self, at, html, ErrStr);
      if ErrStr = '' then
      begin
        if assigned(FOnHtmlParse) then
        begin
          FOnHtmlParse(self, html, aList);
        end;
      end;
    end;

    try
      // ErrStr := 'IgnoreResultAdd';
      self.FSaveToResultList := false;
      if assigned(FResultList) then
        for i := 0 to aList.Count - 1 do
        begin
          FResultList.add(aList[i])
        end;
    except
      on e: exception do
        ErrStr := ('resultlist add ' + e.Message);
    end;
  finally
    try
      FResultListPool.return(aList);
    except
      on e: exception do
        ErrStr := ('resultlist return ' + e.Message);
    end;
  end;

end;

end.
