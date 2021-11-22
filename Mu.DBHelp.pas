unit Mu.DbHelp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Moni.RemoteClient,
  FireDAC.Phys.MSSQL, qjson, qMacros,
  // Mu.ObjectPool,
  QSimplePool, qrbtree, uqdbjson,
  Mu.Pool.qMacro,
  Generics.Collections, SyncObjs,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI;

var
  SQLDBHelpStopALL: boolean = false;
  PbConnCount: integer = 0;
  PbQueryCount: integer = 0;
  PbProcCount: integer = 0;

type
  TSDBHelp = class(TObject)
  private
    FDConnection1: TFDConnection;
    FDCommand1: TFDCommand;
    FDQuerys: array of TFDQuery;

  protected

  public
    constructor Create(dbpath: string; username: string = '';
      password: string = ''; Params: string = '');
    destructor Destroy; override;
    function execsql(sql: String): LongInt; overload;
    function execsql(const ASQL: String; const AParams: array of Variant)
      : LongInt; overload;
    property Conn: TFDConnection read FDConnection1;
    // property Query: TFDQuery read getQuery;

    function getQuery(): TFDQuery;
    procedure returnQuery;

  end;

  TSQLDBHelp = class(TObject)
  private
    FID: integer;
    FProcCount: integer;

    FConnectionDefName: string;
    FServer, FUsername, FPassword, FDatabase: string;

    oDef: IFDStanConnectionDef;
    // FDConnection1: TFDConnection;

    // FDCommand1: TFDCommand;
    FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink;
    FDMoniRemoteClientLink1: TFDMoniRemoteClientLink;

    FDFConnPool: TQSimplePool;

    FDQueryPool: TQSimplePool;

    FCusProcs: TObjectDictionary<string, TQSimplePool>;
    FCusQuerys: TObjectDictionary<string, TQSimplePool>;

    FDProcPool: TQSimplePool;
    FDProcPool2: TQSimplePool;
    FDProcPool3: TQSimplePool;

    // FDStoredProc: TFDStoredProc;

    procedure FOnQueryCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnQueryFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnQueryReset(Sender: TQSimplePool; AData: Pointer);

    procedure FOnQueryCreate_c(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnQueryFree_c(Sender: TQSimplePool; AData: Pointer);
    procedure FOnQueryReset_c(Sender: TQSimplePool; AData: Pointer);

    procedure FOnProcCreate(ASender: TQSimplePool; var AData: Pointer);
    procedure FOnProcFree(ASender: TQSimplePool; AData: Pointer);
    procedure FOnProcReset(ASender: TQSimplePool; AData: Pointer);
    procedure FOnProcCreate_c(ASender: TQSimplePool; var AData: Pointer);
    procedure FOnProcFree_c(ASender: TQSimplePool; AData: Pointer);
    procedure FOnProcReset_c(ASender: TQSimplePool; AData: Pointer);
    procedure FOnConnCreate(ASender: TQSimplePool; var AData: Pointer);
    procedure FOnConnFree(ASender: TQSimplePool; AData: Pointer);
    procedure FOnConnReset(ASender: TQSimplePool; AData: Pointer);

    procedure setServer(Value: string);
    procedure setUsername(Value: string);
    procedure setPassword(Value: string);
    procedure setDatabase(Value: string);

    Procedure ConnOnLost(ASender: TObject);
  protected

  public
    constructor Create(aServer: string; ausername: string = '';
      apassword: string = ''; aDatabase: string = '');
    procedure setConnectionParams();
    destructor Destroy; override;
    function execsql(sql: String): LongInt; overload;
    function execsql(const ASQL: String; const AParams: array of Variant)
      : LongInt; overload;
    // property Conn: TFDConnection read FDConnection1;

    // property Query: TFDQuery read getQuery;
    function getQuery(): TFDQuery;
    procedure returnQuery(fdq: TFDQuery);
    function getProc(): TFDStoredProc;
    function getProc2(): TFDStoredProc;
    function getProc3(): TFDStoredProc;
    function getConn(): TFDConnection;
    procedure returnConn(fdq: TFDConnection);
    procedure returnProc(fdq: TFDStoredProc);
    procedure returnProc2(fdq: TFDStoredProc);
    procedure returnProc3(fdq: TFDStoredProc);

    procedure AddCusProc(aProcName: String);
    function getCusProc(aProcName: String): TFDStoredProc;
    procedure returnCusProc(aProcName: String; proc: TFDStoredProc);

    procedure AddCusQuery(aQueryName: String);
    function getCusQuery(aQueryName: String): TFDQuery;
    procedure returnCusQuery(aQueryName: String; fdq: TFDQuery);
    //
    procedure getProcedureParames(procName: string; Params: TFDParams);
    procedure getQueryParames(sql: string; Params: TFDParams);
    //
    function SqlToJson(ASQL: String; aJson: TQJson): String; overload;
    function SqlToJson(ASQL: String): String; overload;
    property Server: String read FServer; // write setServer;
    property username: String read FUsername write setUsername;
    property password: String read FPassword write setPassword;
    property Database: String read FDatabase write setDatabase;
    property DQueryPool: TQSimplePool read FDQueryPool;
    property DProcPool: TQSimplePool read FDProcPool;
    property DProcPool2: TQSimplePool read FDProcPool2;
    property DProcPool3: TQSimplePool read FDProcPool3;
    property ConnectionDefName: string read FConnectionDefName;
    property ID: integer read FID;
  published

  end;

  TSQLDBHelps = class
    FLock: TCriticalSection;
    FaTs: Tlist<TSQLDBHelp>;
  public
    constructor Create();
    destructor Destroy; override;
    function get(sv: TQJson): TSQLDBHelp; overload;
    function get(aServer, aUser, aPwd, aDbName: String): TSQLDBHelp; overload;
  end;

function datasettojson(ds: tdataset; jso: TQJson): bool;
function datasettojson_nofields(ds: tdataset; jso: TQJson): bool;
function datasettojson2(ds: tdataset; jso: TQJson): bool;
function datasettoList(ds: tdataset; jsResultList, jso: TQJson): bool;

function getMacroList(input: String; QMacroManager: TQMacroManager;
  st: Tstrings): bool;

var
  SDBHelp: TSDBHelp;
  SQLDBHelp: TSQLDBHelp;
  SQLDBHelps: TSQLDBHelps;

implementation

uses qstring, typinfo, math, qlog;

function datasettojson(ds: tdataset; jso: TQJson): bool;
var
  i: integer;
  pt: PTypeInfo;
begin
  result := false;

  pt := TypeInfo(TFieldType);
  with jso.AddArray('Cols') do
  begin
    for i := 0 to ds.FieldCount - 1 do
    begin
      with add() do
      begin
        add('Index').AsInteger := ds.Fields[i].Index;
        add('Name').AsString := ds.Fields[i].FieldName;
        add('Size').AsInteger := ds.Fields[i].Size;
        add('DataType').AsString :=
          GetEnumName(pt, integer(ds.Fields[i].DataType));
      end;
    end;
  end;
  with jso.AddArray('Values') do
  begin
    ds.First;
    while not ds.Eof do
    begin
      with add() do
      begin
        for i := 0 to ds.FieldCount - 1 do
        begin
          add(ds.Fields[i].FieldName).AsString := ds.Fields[i].AsString;
        end;
      end;
      ds.Next;
    end;
  end;
end;

function datasettojson_nofields(ds: tdataset; jso: TQJson): bool;
var
  i, j: integer;
  js: TQJson;
begin
  jso.DataType := jdtArray;
  with ds do
    while not Eof do
    begin
      js := jso.add();
      for i := 0 to ds.FieldCount - 1 do
      begin
        js.add(ds.Fields[i].FieldName).AsString := ds.Fields[i].AsString;
      end;
      Next;
    end;
end;

function getMacroList(input: String; QMacroManager: TQMacroManager;
  st: Tstrings): bool;
var
  AComplied: TQMacroComplied;

  i, sp: integer;
begin
  result := false;
  AComplied := QMacroManager.Complie(input, '%', '%', MRF_DELAY_BINDING);
  if AComplied <> nil then
  begin
    result := (AComplied.EnumUsedMacros(st)) > 0;
    FreeObject(AComplied);
  end;
end;

// jsResultList 的要求格式，jso是返回的结果
function datasettoList(ds: tdataset; jsResultList, jso: TQJson): bool;
var
  jsf, jsfs: TQJson;
  i: integer;
  fmstr, sfs: String;
  stMacro: Tstringlist;
  QMacroManager: TQMacroManager;

begin
  result := false;
  jso.DataType := jdtArray;

  stMacro := Tstringlist.Create;

  QMacroManager := QMacroHelp.getMacro;
  try
    sfs := '';
    fmstr := jsResultList.AsString;
    if (fmstr = '') or (fmstr = 'null') then
    begin
      fmstr := '';
      for i := 0 to ds.Fields.Count - 1 do
      begin
        if fmstr <> '' then
          fmstr := fmstr + ',';
        fmstr := fmstr + '%' + ds.Fields[i].FieldName + '%';
      end;
    end;

    ds.First;
    getMacroList(fmstr, QMacroManager, stMacro);

    while not ds.Eof do
    begin
      if jsResultList.HasChild('Fields', jsfs) then
      begin
        for jsf in jsfs do
        begin
          QMacroManager.Push(jsf.AsString, ds.FieldByName(jsf.AsString)
            .AsString);
        end;
      end
      else
      begin
        if stMacro.Count > 0 then
        begin
          for i := 0 to stMacro.Count - 1 do
            QMacroManager.Push(stMacro[i], ds.FieldByName(stMacro[i]).AsString);
        end
        else
        begin
          for i := 0 to ds.FieldCount - 1 do
          begin
            QMacroManager.Push(ds.Fields[i].AsString, ds.Fields[i].AsString);
          end;
        end;
      end;
      jso.add('').AsString := QMacroManager.Replace(fmstr, '%', '%');
      ds.Next;
    end;
  finally
    stMacro.Free;
    QMacroHelp.returnMacro(QMacroManager);
  end;

end;

function datasettojson2(ds: tdataset; jso: TQJson): bool;
var
  i: integer;
  // pt: PTypeInfo;
begin
  result := false;
  jso.Clear;
  TQDBJson.DataSet2Json(ds, true, true, true, true, 0, 0, [], true, jso);
  result := jso.Count > 0;
  exit;

  // pt := TypeInfo(TFieldType);
  with jso.AddArray('Fields') do
  begin

    begin
      for i := 0 to ds.FieldCount - 1 do
      begin
        add('', ds.Fields[i].FieldName, jdtstring);
      end;
    end;
  end;
  with jso.AddArray('Values') do
  begin
    ds.First;
    while not ds.Eof do
    begin
      with AddArray('') do
      begin
        for i := 0 to ds.FieldCount - 1 do
        begin
          add('', ds.Fields[i].AsString, jdtstring);
        end;
      end;
      ds.Next;
    end;
    result := true;
  end;
end;

{ TSDBHelp }
constructor TSDBHelp.Create(dbpath: string; username: string = '';
  password: string = ''; Params: string = '');
var
  i: integer;

begin
  FDConnection1 := TFDConnection.Create(nil);

  FDCommand1 := TFDCommand.Create(nil);

  for i := 0 to high(FDQuerys) do
  begin
    FDQuerys[i] := TFDQuery.Create(nil);
    FDQuerys[i].Connection := FDConnection1;
  end;
  FDCommand1.Connection := FDConnection1;
  FDConnection1.LoginPrompt := false;

  FDConnection1.Params.add('DriverID=SQLite');
  FDConnection1.Params.add('Database=' + dbpath);
  FDConnection1.Params.add('Password=' + password);
  FDConnection1.Params.add('UserName=' + username);
  // ournal Mode=WAL;
  FDConnection1.Params.add('ournal Mode=WAL');
  FDConnection1.Params.Pooled := true;
  FDConnection1.Open();

end;

destructor TSDBHelp.Destroy;
var
  i: integer;
begin

  for i := 0 to high(FDQuerys) do
  begin
    FDQuerys[i].Free;
  end;

  FDCommand1.Free;
  FDConnection1.Close;
  FDConnection1.Free;
  inherited;
end;

function TSDBHelp.execsql(sql: String): LongInt;
begin
  result := FDConnection1.execsql(sql);
end;

function TSDBHelp.execsql(const ASQL: String;
  const AParams: array of Variant): LongInt;
begin
  result := FDConnection1.execsql(ASQL, AParams);
end;

function TSDBHelp.getQuery: TFDQuery;
var
  i: integer;
begin
  result := nil;
  for i := 0 to high(FDQuerys) do
  begin
    if not FDQuerys[i].Active then
    begin
      result := FDQuerys[i];
      break;
    end;
  end;
  if result = nil then
  begin
    i := Length(FDQuerys);
    SetLength(FDQuerys, i + 1);

    FDQuerys[i] := TFDQuery.Create(nil);
    FDQuerys[i].Connection := FDConnection1;
    result := FDQuerys[i];
  end;

end;

procedure TSDBHelp.returnQuery;
begin

end;

{ TSQLDBHelp }

procedure TSQLDBHelp.setConnectionParams;
var
  i: integer;
begin
  FDManager.CloseConnectionDef(FConnectionDefName);
  FDManager.ConnectionDefFileAutoLoad := false;
  // FDManager.ConnectionDefFileName := getexepath + 'config\def.ini';
  oDef := FDManager.ConnectionDefs.FindConnectionDef(FConnectionDefName);

  if oDef = nil then
  begin
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
  end;

  oDef.Name := FConnectionDefName;
  oDef.Params.DriverID := 'MSSQL';
  oDef.Params.Values['Server'] := FServer;
  oDef.Params.Database := FDatabase;
  oDef.Params.username := FUsername;
  oDef.Params.password := FPassword;
  oDef.Params.Values['User_Name'] := FUsername;
  oDef.Params.Values['MetaDefSchema'] := 'dbo';
  oDef.Params.add('SharedCache=False');
  oDef.Params.add('LockingMode=Normal');
  oDef.Params.add('Synchronous=Full');
  oDef.Params.add('LockingMode=Normal');
  oDef.Params.add('CacheSize=60000');
  oDef.Params.add('BusyTimeOut=30000');
  oDef.Params.add('POOL_MaximumItems=1000');
  // oDef.Params.Values['MetaDefCatalog'] := FDatabase;
  // oDef.Params.Values['MonitorBy'] := 'Remote';
  // resourceoptions.autoreconnect

  oDef.Params.Pooled := true;
  // oDef.MarkPersistent;
  // FDManager.ConnectionDefs.Save;
  oDef.Apply;
end;

procedure TSQLDBHelp.AddCusProc(aProcName: String);
var
  aProcPool: TQSimplePool;
begin
  if not assigned(FCusProcs) then
    FCusProcs := TObjectDictionary<string, TQSimplePool>.Create();

  if FCusProcs.ContainsKey(aProcName) then
    exit;
  aProcPool := TQSimplePool.Create(2, FOnProcCreate, FOnProcFree, FOnProcReset);
  FCusProcs.add(aProcName, aProcPool);

end;

function TSQLDBHelp.getCusProc(aProcName: String): TFDStoredProc;
var
  proc: TFDStoredProc;
  con: TFDConnection;
begin
  inc(FProcCount);
  { con := FDFConnPool.Pop;

    // con.ResourceOptions.autoreconnect := true;
    // con.OnLost := self.ConnOnLost;
    // con.LoginPrompt := false;
    // con.ConnectionDefName := FDConnection1.ConnectionDefName;

    proc := TFDStoredProc.Create(nil);
    proc.Name := format('Proc%d_%d', [FProcCount, random(10000)]);
    proc.Connection := con;
    proc.FetchOptions.AutoClose := false; // 支持多数据集
    result := proc; }
  result := nil;
  if not assigned(FCusProcs) then
    FCusProcs := TObjectDictionary<string, TQSimplePool>.Create();

  if not FCusProcs.ContainsKey(aProcName) then
    self.AddCusProc(aProcName);
  begin
    result := TFDStoredProc(FCusProcs[aProcName].Pop);
    con := FDFConnPool.Pop;
    result.Connection := con;
  end;
end;

procedure TSQLDBHelp.returnCusProc(aProcName: String; proc: TFDStoredProc);

begin
  // logs.Post(lldebug, 'TFDStoredProc %s free', [proc.Name]);
  {
    if proc.Active then
    proc.Active := false;
    if proc.Connection <> nil then
    begin
    proc.Connection.Close;
    proc.Connection.Free;
    end;
    freeandnil(proc); }
  if not assigned(FCusProcs) then
    exit;
  if FCusProcs.ContainsKey(aProcName) then
  begin
    // logs.Post(lldebug, 'TFDStoredProc %s returned', [proc.Name]);
    FDFConnPool.Push(proc.Connection);
    FCusProcs[aProcName].Push(proc);
  end;
end;

procedure TSQLDBHelp.AddCusQuery(aQueryName: String);
var
  aProcPool: TQSimplePool;
begin
  if not assigned(FCusQuerys) then
    FCusQuerys := TObjectDictionary<string, TQSimplePool>.Create();

  if FCusQuerys.ContainsKey(aQueryName) then
    exit;
  aProcPool := TQSimplePool.Create(100, FOnQueryCreate_c, FOnQueryFree_c,
    FOnQueryReset_c);
  FCusQuerys.add(aQueryName, aProcPool);
end;

function TSQLDBHelp.getCusQuery(aQueryName: String): TFDQuery;
var
  qr: TFDQuery;
  con: TFDConnection;
begin
  result := nil;
  { con := FDFConnPool.Pop; // TFDConnection.Create(nil);

    //  con.ResourceOptions.autoreconnect := true;
    //  con.OnLost := ConnOnLost;
    //  con.LoginPrompt := false;
    //  con.ConnectionDefName := FDConnection1.ConnectionDefName;

    qr := TFDQuery.Create(nil);
    qr.Connection := con;
    qr.FetchOptions.AutoClose := false; // 支持多数据集
    result := qr;
  }
  result := nil;
  if not assigned(FCusQuerys) then
    self.AddCusQuery(aQueryName)
  else if not FCusQuerys.ContainsKey(aQueryName) then
    self.AddCusQuery(aQueryName);
  begin
    con := FDFConnPool.Pop;
    result := TFDQuery(FCusQuerys[aQueryName].Pop);
    result.Connection := con;
  end;
end;

procedure TSQLDBHelp.returnCusQuery(aQueryName: String; fdq: TFDQuery);
var
  qr: TFDQuery;
begin
  qr := TFDQuery(fdq);
  { if qr.Active then
    qr.Active := false;
    if qr.Connection <> nil then
    begin
    FDFConnPool.Push(qr.Connection);
    // qr.Connection.Close;
    // qr.Connection.Free;
    end;
    freeandnil(qr);
  }
  if not assigned(FCusQuerys) then
    exit;
  if FCusQuerys.ContainsKey(aQueryName) then
  begin
    FDFConnPool.Push(fdq.Connection);
    FCusQuerys[aQueryName].Push(fdq);
  end;

end;

procedure TSQLDBHelp.ConnOnLost(ASender: TObject);
var
  Conn: TFDConnection;
begin
  Conn := TFDConnection(ASender);
  Conn.Close;
  // try
  setConnectionParams();
  // except
  // on e: exception do
  // logs.Post(llerror, 'ConnOnLost setConnectionParams ' + e.Message);
  // end;
end;

constructor TSQLDBHelp.Create(aServer, ausername, apassword, aDatabase: string);
var
  i: integer;
begin
  FID := random(10000000);
  FProcCount := 0;

  FConnectionDefName := 'MSSQL_Connection';
  // FDConnection1 := TFDConnection.Create(nil);
  // FDConnection1.LoginPrompt := false;
  if aDatabase = '' then
    aDatabase := 'master';
  FServer := aServer;
  FUsername := ausername;
  FPassword := apassword;
  FDatabase := aDatabase;
  if (FServer <> '') then
    setConnectionParams;

  // if FDConnection1.Connected then
  // FDConnection1.Close;
  // FDConnection1.OnLost := self.ConnOnLost;
  // FDConnection1.ResourceOptions.AutoConnect := true;

  // FDConnection1.ConnectionDefName := FConnectionDefName;
  {
    FDConnection1.Params.Clear;
    FDConnection1.Params.add('DriverID=MSSQL');
    FDConnection1.Params.add('Address=' + FServer);
    FDConnection1.Params.add('Database=' + FDatabase);
    FDConnection1.Params.add('Password=' + FPassword);
    FDConnection1.Params.add('User_Name=' + FUsername);
  }
  try
    // FDConnection1.Open();
    //
  except

  end;

  // FDCommand1 := TFDCommand.Create(nil);

  FDFConnPool := TQSimplePool.Create(50, FOnConnCreate, FOnConnFree,
    FOnConnReset);

  FDQueryPool := TQSimplePool.Create(10, FOnQueryCreate, FOnQueryFree, FOnQueryReset);

  FDProcPool := TQSimplePool.Create(10, FOnProcCreate, FOnProcFree, FOnProcReset);
  FDProcPool2 := TQSimplePool.Create(10, FOnProcCreate, FOnProcFree, FOnProcReset);
  FDProcPool3 := TQSimplePool.Create(10, FOnProcCreate, FOnProcFree, FOnProcReset);

  // FDCommand1.Connection := FDConnection1;

  FDPhysMSSQLDriverLink1 := TFDPhysMSSQLDriverLink.Create(nil);

  FDMoniRemoteClientLink1 := TFDMoniRemoteClientLink.Create(nil);

  // FDStoredProc := TFDStoredProc.Create(nil);
  // FDStoredProc.Connection := FDConnection1;
  // FDStoredProc.FetchOptions.AutoClose := false; // 支持多数据集
  // FDConnection1.Open();
end;

destructor TSQLDBHelp.Destroy;
var
  i: integer;
  key: String;
begin

  FDQueryPool.Free;

  FDProcPool.Free;
  FDProcPool2.Free;
  FDProcPool3.Free;

  // FDStoredProc.Free;

  // FDCommand1.Free;
  // FDConnection1.Close;
  // FDConnection1.Free;

  FDFConnPool.Free;

  if FCusProcs <> nil then
  begin
    for key in FCusProcs.Keys do
      TQSimplePool(FCusProcs[key]).Free;

    FCusProcs.Free;
  end;

  if FCusQuerys <> nil then
  begin
    for key in FCusQuerys.Keys do
      TQSimplePool(FCusProcs[key]).Free;
    FCusQuerys.Free;
  end;

  FDManager.CloseConnectionDef(FConnectionDefName);

  FDPhysMSSQLDriverLink1.Free;

  if not IsLibrary then
    FDMoniRemoteClientLink1.Free; // dll里面 加上这句，cpu无法退出

  inherited;
end;

function TSQLDBHelp.execsql(sql: String): LongInt;
var
  con: TFDConnection;
begin
  con := FDFConnPool.Pop;
  try
    result := con.execsql(sql);
  finally
    FDFConnPool.Push(con);
  end;
end;

function TSQLDBHelp.execsql(const ASQL: String;
  const AParams: array of Variant): LongInt;
var
  con: TFDConnection;
begin
  con := self.FDFConnPool.Pop;
  try
    result := con.execsql(ASQL, AParams);
  finally
    FDFConnPool.Push(con);
  end;
end;

procedure TSQLDBHelp.FOnQueryCreate(Sender: TQSimplePool; var AData: Pointer);
var
  qr: TFDQuery;
  con: TFDConnection;
begin
  inc(PbQueryCount);
  con := self.FDFConnPool.Pop; // TFDConnection.Create(nil);

  // con.ResourceOptions.autoreconnect := true;
  // con.OnLost := self.ConnOnLost;
  // con.LoginPrompt := false;
  // con.ConnectionDefName := FDConnection1.ConnectionDefName;

  qr := TFDQuery.Create(nil);
  qr.Connection := con;
  qr.FetchOptions.AutoClose := false; // 支持多数据集
  AData := qr;
end;

procedure TSQLDBHelp.FOnQueryFree(Sender: TQSimplePool; AData: Pointer);
var
  qr: TFDQuery;
begin
  qr := TFDQuery(AData);
  if qr.Active then
    qr.Active := false;
  if qr.Connection <> nil then
  begin
    // qr.Connection.Close;
    // qr.Connection.Free;
    // qr.Connection := nil;
  end;
  freeandnil(qr);
  dec(PbQueryCount);
end;

procedure TSQLDBHelp.FOnQueryCreate_c(Sender: TQSimplePool; var AData: Pointer);
var
  qr: TFDQuery;
  con: TFDConnection;
begin
  // con := FDFConnPool.Pop;

  // con.ResourceOptions.autoreconnect := true;
  // con.OnLost := self.ConnOnLost;
  // con.LoginPrompt := false;
  // con.ConnectionDefName := FDConnection1.ConnectionDefName;
  inc(PbQueryCount);
  qr := TFDQuery.Create(nil);
  // qr.Connection := con;
  qr.FetchOptions.AutoClose := false; // 支持多数据集
  AData := qr;
end;

procedure TSQLDBHelp.FOnQueryFree_c(Sender: TQSimplePool; AData: Pointer);
var
  qr: TFDQuery;
begin
  qr := TFDQuery(AData);
  if qr.Active then
    qr.Active := false;
  if qr.Connection <> nil then
  begin

  end;
  dec(PbQueryCount);
  freeandnil(qr);
end;

procedure TSQLDBHelp.FOnQueryReset_c(Sender: TQSimplePool; AData: Pointer);
begin

end;

procedure TSQLDBHelp.FOnQueryReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

procedure TSQLDBHelp.FOnConnCreate(ASender: TQSimplePool; var AData: Pointer);
var
  con: TFDConnection;
begin
  inc(PbConnCount);
  con := TFDConnection.Create(nil);
  con.LoginPrompt := false;
  con.OnLost := self.ConnOnLost;
  con.ConnectionDefName := FConnectionDefName;

  con.ResourceOptions.autoreconnect := true;
  // con.Open();
  AData := con;
  // logs.Post(lldebug, con.ConnectionString);
end;

procedure TSQLDBHelp.FOnConnFree(ASender: TQSimplePool; AData: Pointer);
var
  con: TFDConnection;
begin
  con := TFDConnection(AData);
  if con.Connected then
    con.Close;

  freeandnil(AData);
  dec(PbConnCount);
end;

procedure TSQLDBHelp.FOnConnReset(ASender: TQSimplePool; AData: Pointer);
begin

end;

procedure TSQLDBHelp.FOnProcCreate(ASender: TQSimplePool; var AData: Pointer);
var
  proc: TFDStoredProc;
  con: TFDConnection;
begin
  inc(FProcCount);
  inc(PbProcCount);
  // con := TFDConnection.Create(nil);

  // con.ResourceOptions.autoreconnect := true;
  // con.OnLost := self.ConnOnLost;
  // con.LoginPrompt := false;
  // con.ConnectionDefName := FDConnection1.ConnectionDefName;

  proc := TFDStoredProc.Create(nil);
  proc.Name := format('Proc%d_%d', [FProcCount, random(100000)]);
  // proc.Connection := con;
  proc.FetchOptions.AutoClose := false; // 支持多数据集
  AData := proc;

  // logs.Post(lldebug, 'TFDStoredProc %s created', [proc.Name]);
end;

procedure TSQLDBHelp.FOnProcFree(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  proc := TFDStoredProc(AData);

  // logs.Post(lldebug, 'TFDStoredProc %s free', [proc.Name]);

  if proc.Active then
    proc.Active := false;
  if proc.Connection <> nil then
  begin
    // proc.Connection.Close;
    // proc.Connection.Free;
  end;
  freeandnil(AData);
  dec(PbProcCount);
end;

procedure TSQLDBHelp.FOnProcReset(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  proc := TFDStoredProc(AData);
  // logs.Post(llhint, 'TFDStoredProc %s reset', [proc.Name]);

end;

procedure TSQLDBHelp.FOnProcCreate_c(ASender: TQSimplePool; var AData: Pointer);
var
  proc: TFDStoredProc;
  con: TFDConnection;
begin
  inc(FProcCount);


  // con.ResourceOptions.autoreconnect := true;
  // con.OnLost := self.ConnOnLost;
  // con.LoginPrompt := false;
  // con.ConnectionDefName := FDConnection1.ConnectionDefName;

  proc := TFDStoredProc.Create(nil);
  proc.Name := format('Proc%d_%d', [FProcCount, random(10000)]);
  // proc.Connection := con;
  proc.FetchOptions.AutoClose := false; // 支持多数据集
  AData := proc;

  // logs.Post(lldebug, 'TFDStoredProc %s created', [proc.Name]);
end;

procedure TSQLDBHelp.FOnProcFree_c(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  proc := TFDStoredProc(AData);

  // logs.Post(lldebug, 'TFDStoredProc %s free', [proc.Name]);

  if proc.Active then
    proc.Active := false;
  if proc.Connection <> nil then
  begin
    // proc.Connection.Close;
    // proc.Connection.Free;
  end;
  freeandnil(AData);
  dec(PbProcCount);
end;

procedure TSQLDBHelp.FOnProcReset_c(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  proc := TFDStoredProc(AData);
  // logs.Post(llhint, 'TFDStoredProc %s reset', [proc.Name]);

end;

function TSQLDBHelp.getConn: TFDConnection;
begin
  result := TFDConnection(FDFConnPool.Pop);
end;

function TSQLDBHelp.getProc: TFDStoredProc;
var
  con: TFDConnection;
begin
  con := FDFConnPool.Pop;
  result := TFDStoredProc(FDProcPool.Pop);
  result.Connection := con;
end;

function TSQLDBHelp.getProc2: TFDStoredProc;
var
  con: TFDConnection;
begin
  con := FDFConnPool.Pop;
  result := TFDStoredProc(FDProcPool2.Pop);
  result.Connection := con;
end;

function TSQLDBHelp.getProc3: TFDStoredProc;
var
  con: TFDConnection;
begin
  con := FDFConnPool.Pop;
  result := TFDStoredProc(FDProcPool3.Pop);
  result.Connection := con;
end;

procedure TSQLDBHelp.getProcedureParames(procName: string; Params: TFDParams);
var
  proc: TFDStoredProc;
  Param: TFDParam;
  i: integer;
begin
  proc := self.getProc;
  try
    Params.Clear;
    proc.StoredProcName := procName;
    proc.Prepare;
    for i := 0 to proc.Params.Count - 1 do
    // for Param in proc.Params do
    begin
      Param := proc.Params[i];
      Params.add(Param.Name, Param.Value, Param.ParamType);
      Params[i].Size := Param.Size;
      Params[i].DataType := Param.DataType;

    end;
  finally
    self.returnProc(proc);
  end;
end;

procedure TSQLDBHelp.returnConn(fdq: TFDConnection);
begin
  FDFConnPool.Push(fdq);
end;

procedure TSQLDBHelp.returnProc(fdq: TFDStoredProc);
begin
  fdq.Connection.Close;
  FDFConnPool.Push(fdq.Connection);
  FDProcPool.Push(fdq);
end;

procedure TSQLDBHelp.returnProc2(fdq: TFDStoredProc);
begin
  fdq.Connection.Close;
  FDFConnPool.Push(fdq.Connection);
  FDProcPool2.Push(fdq);
end;

procedure TSQLDBHelp.returnProc3(fdq: TFDStoredProc);
begin
  fdq.Connection.Close;
  FDFConnPool.Push(fdq.Connection);
  FDProcPool3.Push(fdq);
end;

function TSQLDBHelp.getQuery: TFDQuery;
var
  con: TFDConnection;
begin
  result := TFDQuery(FDQueryPool.Pop);
  con := FDFConnPool.Pop; // TFDConnection.Create(nil);
  result.Connection := con;
end;

procedure TSQLDBHelp.getQueryParames(sql: string; Params: TFDParams);
var
  fqd: TFDQuery;
  Param: TFDParam;
  i: integer;
begin
  fqd := self.getQuery;
  try
    Params.Clear;
    fqd.sql.Text := sql;

    for i := 0 to fqd.Params.Count - 1 do
    // for Param in proc.Params do
    begin
      Param := fqd.Params[i];
      Params.add(Param.Name, Param.Value, Param.ParamType);
      Params[i].Size := Param.Size;
      Params[i].DataType := Param.DataType;

    end;
  finally
    self.returnQuery(fqd);
  end;

end;

procedure TSQLDBHelp.returnQuery(fdq: TFDQuery);
begin
  FDFConnPool.Push(fdq.Connection);
  FDQueryPool.Push(fdq);
end;

procedure TSQLDBHelp.setDatabase(Value: string);
begin
  self.FDatabase := Value;
end;

procedure TSQLDBHelp.setPassword(Value: string);
begin
  self.FPassword := Value;
end;

procedure TSQLDBHelp.setServer(Value: string);
begin
  self.FServer := Value;
end;

procedure TSQLDBHelp.setUsername(Value: string);
begin
  self.FUsername := Value;
end;

function TSQLDBHelp.SqlToJson(ASQL: String; aJson: TQJson): String;
var
  fdq: TFDQuery;
begin
  result := '[]';
  try
    fdq := self.getCusQuery(ASQL);
    fdq.sql.Text := ASQL;
    fdq.Active := true;
    datasettojson_nofields(fdq, aJson);
  finally
    fdq.Active := false;
    SQLDBHelp.returnCusQuery(ASQL, fdq);
  end;
  result := aJson.ToString();
end;

function TSQLDBHelp.SqlToJson(ASQL: String): String;
var
  aJson: TQJson;
begin
  aJson := TQJson.Create;
  try
    SqlToJson(ASQL, aJson);
  finally
    aJson.Free;
  end;
end;

{ TSQLDBHelps }

constructor TSQLDBHelps.Create;
begin
  FLock := TCriticalSection.Create;
  FaTs := Tlist<TSQLDBHelp>.Create;
end;

destructor TSQLDBHelps.Destroy;
var
  i: integer;
begin
  FLock.Leave;
  FLock.Free;
  for i := (FaTs.Count) - 1 downto 0 do
  begin
    FaTs[i].Free;
  end;
  FaTs.Free;
  inherited;
end;

function TSQLDBHelps.get(aServer, aUser, aPwd, aDbName: String): TSQLDBHelp;
var
  i: integer;
begin
  FLock.Enter;
  try
    result := nil;
    // logs.Post(lldebug, 'start find TSQLDBHelp');
    for i := 0 to FaTs.Count - 1 do
    begin
      if FaTs[i].Server = aServer then
      begin
        result := FaTs[i];
        exit;
      end;
    end;
    logs.Post(lldebug, 'Need create TSQLDBHelp');

    result := TSQLDBHelp.Create(aServer, aUser, aPwd, aDbName);

    FaTs.add(result);

  finally
    FLock.Leave;
  end;

end;

function TSQLDBHelps.get(sv: TQJson): TSQLDBHelp;
var
  i: integer;
begin
  result := get(sv.ItemByName('Server').AsString, sv.ItemByName('Username')
    .AsString, sv.ItemByName('Password').AsString, sv.ItemByName('Database')
    .AsString);

end;

initialization

SQLDBHelps := TSQLDBHelps.Create;

finalization

SQLDBHelps.Free;

end.
