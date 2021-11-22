unit Mu.MSSQL.Exec;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys.MSSQL, FireDAC.Moni.RemoteClient,
  FireDAC.Phys, FireDAC.Stan.Intf,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet,
  Data.DBXDataSets, FireDAC.Phys.ODBCWrapper, FireDAC.Phys.ODBCCli,
  qjson, Mu.DBHelp, qlog, qstring,
  Mu.Pool.qjson;

type
  TOnEnd     = procedure(Sender: TObject; aDoCount: Int64) of object;
  TOnProcess = procedure(Sender: TObject; aTotalCount, aDoCount: Int64; var continue: boolean) of object;

type
  TODBCStatementBase_ = class helper for TODBCStatementBase
    function MoreResults: boolean;
  end;

type
  TMuMSSQLExec = class(TObject)
    private
      FRetryTimes     : integer;
      FIsAbort        : boolean;
      FProcessPerCount: integer;

      FOnEnd    : TOnEnd;
      FOnProcess: TOnProcess;

      function GetOneSQLDBHelp(Sv: TQJson): TSQLDBHelp;
    protected

    public
      constructor Create();
      destructor Destroy; override;

      /// 保存数据到数据库，下面是Config参数,默认数据库参数都是对的
      /// Server:{Server:"127.0.0.1,1433",Username:"sa",Password:"sa",Database:"master",},
      /// SQL:"DomainDropped.dbo.P_DomainDropped_add",
      /// Type:"proc",
      /// Parames:[
      /// {Name:"@Domain",Type:"varchar",Length: 100,Value:""},
      /// {Name:"@DDate",Type:"date",Length:0,Value:""}
      /// {Name:"@Result",Type:"varchar",Length:1000,Direction:"output" }
      /// ]
      /// 下面是值的
      ///
      ///
      ///
      ///
      ///
      function InitProc(aConfig: TQJson; Proc: TFDStoredProc; aProcName: String; AParameDemo: TQJson;
        var aErrStr: String): boolean;

      function ExecProc_Dateset(aConfig: TQJson; ParamsFilds: TQJson; aDs: TDataset; var aErrStr: String): string;
      function Exec(aConfig: TQJson; aValue: TQJson; var aErrStr: String): string; overload;
      function Exec(aConfig: TQJson; aValue: String; var aErrStr: String): string; overload;
      function Exec(aConfig: String; aValue: String; var aErrStr: String): string; overload;
      function ExecProc(aConfig: TQJson; aValue: TQJson; var aErrStr: String): String;
      function ExecSQL(aConfig: TQJson; aValue: TQJson; var aErrStr: String): String;

      function JSONResult_proc(aConfig: TQJson; aValue: TQJson; var aErrStr: String): String;
      function JSONResult_SQL(aConfig: TQJson; aValue: TQJson; var aErrStr: String): String;
      function JSONResult(aConfig: TQJson; aValue: TQJson; var aErrStr: String): String;
      procedure stop();
      property OnEnd: TOnEnd read FOnEnd write FOnEnd;
      property OnProcess: TOnProcess read FOnProcess write FOnProcess;
      property ProcessPerCount: integer read FProcessPerCount write FProcessPerCount;
  end;

implementation

{ TMuMSSQLExec }

constructor TMuMSSQLExec.Create;
begin
  FIsAbort         := false;
  FProcessPerCount := 10;
  FRetryTimes      := 0;
end;

destructor TMuMSSQLExec.Destroy;
var
  i: integer;
begin
  FIsAbort := true;
  inherited;
end;

function TMuMSSQLExec.Exec(aConfig, aValue: TQJson; var aErrStr: String): string;
var
  tp: String;
  js: TQJson;
begin
  aErrStr          := '';
  tp               := aConfig.ValueByName('Type', 'SQL');
  FProcessPerCount := aConfig.IntByName('ProcessPerCount', FProcessPerCount);
  if tp.ToLower.IndexOf('json') <> -1 then
  begin
    result := JSONResult(aConfig, aValue, aErrStr);
  end else if (tp.ToLower() = 'proc') or (tp.ToLower() = 'procedure') then
  begin
    FRetryTimes := 0;
    logs.Post(lldebug, 'ExecProc');
    try
      result := ExecProc(aConfig, aValue, aErrStr);
    except
      on e: exception do
      begin
        aErrStr := format('ExecProc exception:%s', [e.message]);
        logs.Post(llerror, aErrStr);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.ExecProc(aConfig, aValue, aErrStr);
            exit;
          end;
        end;
      end;
    end;
  end else begin
    try
      result := self.ExecSQL(aConfig, aValue, aErrStr);
    except
      on e: exception do
      begin
        aErrStr := format('ExecSQL exception:%s', [e.message]);
        logs.Post(llerror, aErrStr);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.ExecSQL(aConfig, aValue, aErrStr);
            exit;
          end;
        end;
      end;
    end;
  end;
end;

function TMuMSSQLExec.Exec(aConfig: TQJson; aValue: String; var aErrStr: String): string;
var
  vjs: TQJson;
begin
  vjs := qjsonPool.get;
  try
    vjs.Parse(aValue);
    result := Exec(aConfig, vjs, aErrStr);
  finally
    qjsonPool.return(vjs);
  end;
end;

function TMuMSSQLExec.Exec(aConfig, aValue: String; var aErrStr: String): string;
var
  vjs, cjs: TQJson;
begin
  vjs := qjsonPool.get;
  cjs := qjsonPool.get;
  try
    vjs.Parse(aValue);
    cjs.Parse(aConfig);
    result := Exec(cjs, vjs, aErrStr);
  finally
    qjsonPool.return(vjs);
    qjsonPool.return(cjs);
  end;
end;

function TMuMSSQLExec.ExecSQL(aConfig, aValue: TQJson; var aErrStr: String): String;
var
  FQ        : TFDQuery;
  pjs       : TQJson;
  i, c, l   : integer;
  rjs       : TQJson;
  es        : String;
  aSql      : String;
  aSQLDBHelp: TSQLDBHelp;
  aContinue : boolean;
  function doOne(aValue: TQJson; R: TQJson): TQJson;
  var
    i    : integer;
    pname: String;
  begin
    if (FQ.SQL.Text <> aSql) then
    begin
      FQ.SQL.Text := aSql;
      FQ.Prepare;
    end else if FQ.Params.Count <> aValue.Count then
    begin
      FQ.Prepare;
    end;
    if FQ.Params.Count <> pjs.Count then
    begin
      aErrStr := 'SQL的参数和配置文件的参数数目不一样.';
      exit;
    end;
    for i := 0 to aValue.Count - 1 do
    begin
      pname := aValue[i].Name;
      with FQ.Params.ParamByName(pname) do
        case DataType of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            begin
              l  := Size;
              es := aValue[i].AsString;
              if l < es.Length then
              begin
                logs.Post(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
                es := copy(es, 1, l);
              end;
              AsString := es;
            end;
          // AsString := aValue[i].AsString;
          // ftWideString:
          // AsWideString := aValue[i].AsString;

          ftInteger:
            asInteger := aValue[i].asInteger;
          ftSmallint:
            AsSmallInt := aValue[i].asInteger;
          ftShortint:
            AsShortInt := aValue[i].asInteger;
          ftWord:
            AsWord := aValue[i].asInteger;
          ftLargeint:
            AsLargeInt := aValue[i].AsInt64;
          ftLongWord:
            AsLongword := aValue[i].AsInt64;

          ftDate:
            asDate := aValue[i].asDatetime;
          ftTime:
            astime := aValue[i].asDatetime;
          ftDateTime:
            asDatetime := aValue[i].asDatetime;
          // ftTimeStamp:
          // AsSQLTimeStamp := aValue[i].asDatetime;

          ftBoolean:
            asBoolean := aValue[i].asBoolean;

          ftFloat:
            asFloat := aValue[i].asFloat;
          ftCurrency:
            asCurrency := aValue[i].asFloat;
          ftExtended:
            asExtended := aValue[i].asFloat;
          ftSingle:
            asSingle := aValue[i].asFloat;

        else
          Value := aValue[i].AsVariant;
        end;

      // FQ.Params.ParamByName(pname).Value := aValue[i].AsVariant;
    end;
    try
      FQ.ExecSQL;
      with (R.Add()) do
      begin
        for i := 0 to FQ.Params.Count - 1 do
        begin
          AddVariant(FQ.Params[i].Name, FQ.Params[i].Value);
        end;
      end;

    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr  := aValue.encode(false) + ' ExecSQL ' + e.message;
        FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  try
    try

      aSql       := aConfig.ItemByName('SQL').AsString;
      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      FQ         := aSQLDBHelp.getCusQuery(aSql);

    except
      on e: exception do
      begin
        aErrStr := e.message;
      end;
    end;
    // 此时获取到的，默认是服务器没有更改参数。如果更改了，就自动获取。

    // 数据格式，默认都是对的  bin image text暂时不支持，可以到parames字段的类型读取
    FIsAbort     := false;
    rjs.DataType := jdtArray;

    if aValue.DataType = jdtArray then
    begin
      c     := aValue.Count;
      for i := 0 to c - 1 do
      begin
        if FIsAbort then
          break;
        doOne(aValue[i], rjs);
        if (i mod FProcessPerCount = 0) or (i = c - 1) then
          if assigned(FOnProcess) then
          begin
            FOnProcess(self, c, i + 1, aContinue);
            if not aContinue then
              break;
          end;
      end;
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
          exit;
      end;
    end else begin
      c := 1;
      doOne(aValue, rjs);

      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, i + 1, aContinue);
        if not aContinue then
          exit;
      end;
    end;

    if assigned(FOnEnd) then
      FOnEnd(self, c);
  finally

    result := rjs.ToString();
    rjs.Clear;
    aSQLDBHelp.returnCusQuery(aSql, FQ);

    qjsonPool.return(rjs);
  end;

end;

function TMuMSSQLExec.ExecProc(aConfig, aValue: TQJson; var aErrStr: String): String;
var
  Proc            : TFDStoredProc;
  pjs             : TQJson;
  i, j, c, succ, l: integer;
  rjs             : TQJson;
  tmpjs           : TQJson;
  es              : String;
  server, aSql    : String;
  pname           : string;
  aSQLDBHelp      : TSQLDBHelp;
  aContinue       : boolean;
  needSeconds     : boolean;
  needPrepare     : boolean;

  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i   : integer;
    tmps: String;
  begin
    result := false;

    for i := 0 to Proc.Params.Count - 1 do
    begin
      if (Proc.Params[i].ParamType in [ptInput]) // ptInputOutput
      then
      begin
        pname := Proc.Params[i].Name;

        if not(aValue.Exists(pname) or (aValue.Exists(pname.Replace('@', '')))) then
        begin

          aErrStr := format('%s 参数 (%d)"%s"没有值！%s', [Proc.Name, i, pname, aValue.ToString]);

          exit;
        end;
      end else if Proc.Params[i].ParamType in [ptOutput, ptInputOutput] then
        case Proc.Params[i].DataType of
          ftWideMemo, ftFmtMemo, ftMemo:
            begin // 必须设置为null，不然会造成参数冲突。
              Proc.Params[i].Value := null;
            end;
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            Proc.Params[i].Value := '';
        end;
    end;
    try
      // messagebox(0, pchar(aValue.ToString), pchar(''), 0);
      for i := 0 to aValue.Count - 1 do
      begin
        pname := aValue[i].Name;

        if copy(pname, 1, 1) <> '@' then
          pname := '@' + pname;
        { ftUnknown, ftString, ftSmallint, ftInteger, ftWord, // 0..4
          ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, // 5..11
          ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
          ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
          ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
          ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
          ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
          ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
          ftTimeStampOffset, ftObject, ftSingle }

        with Proc.Params.ParamByName(pname) do
          case DataType of
            // ftString, ftWideString:
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := aValue[i].AsString;
                if l < es.Length then
                begin
                  logs.Post(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;

            // ftWideString:
            // AsWideString := aValue[i].AsString;
            ftWideMemo:
              begin
                // logs.Post(lldebug, pname + ':' + aValue[i].AsString);
                // aValue[i].AsBytes loadfromstream();
                asWideMemo := aValue[i].AsString;
              end;
            ftFmtMemo, ftMemo:
              asMemo := aValue[i].AsString;
            ftInteger:
              asInteger := aValue[i].asInteger;
            ftSmallint:
              AsSmallInt := aValue[i].asInteger;
            ftShortint:
              AsShortInt := aValue[i].asInteger;
            ftWord:
              AsWord := aValue[i].asInteger;
            ftLargeint:
              AsLargeInt := aValue[i].AsInt64;
            ftLongWord:
              AsLongword := aValue[i].AsInt64;

            ftDate:
              asDate := aValue[i].asDatetime;
            ftTime:
              astime := aValue[i].asDatetime;
            ftDateTime:
              asDatetime := aValue[i].asDatetime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;

            ftBoolean:
              asBoolean := aValue[i].asBoolean;

            ftFloat:
              asFloat := aValue[i].asFloat;
            ftCurrency:
              begin
                asCurrency := aValue[i].asFloat;
              end;
            ftExtended:
              asExtended := aValue[i].asFloat;
            ftSingle:
              asSingle := aValue[i].asFloat;
          else
            Value := aValue[i].AsVariant;
          end;


        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;

      end;
    except
      on e: exception do
      begin
        aErrStr := format('Proc Params set value ,%s %s', [aValue.encode(false), e.message]);
        logs.Post(llerror, '%s', [aErrStr]);
      end;
    end;
    try
      // logs.Post(lldebug, 'Proc.ExecProc %s', [aValue.encode(false)]);
      // if needRepared then
      // Proc.Prepare;

      Proc.ExecProc;

      // logs.Post(lldebug, 'Proc.ExecProc End');
      result := true;
      with (R.Add()) do
      begin
        for i := 0 to Proc.Params.Count - 1 do
        begin
          if Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput] then
          begin

            case Proc.Params[i].DataType of
              ftString, ftFixedChar, ftWideString, ftFixedWideChar:
                begin
                  // tmps := Proc.Params[i].Name;
                  tmps := (Proc.Params[i].AsString);
                  // logs.Post(llmessage, '%s:%s', [Proc.Params[i].Name, tmps]);
                  AddVariant(Proc.Params[i].Name, tmps);
                end;
              ftWideMemo:
                begin
                  tmps := Proc.Params[i].asWideMemo;
                  // logs.Post(llmessage, 'ftWideMemo:%s', [tmps]);
                  AddVariant(Proc.Params[i].Name, tmps);
                end;
              ftMemo:
                begin
                  tmps := Proc.Params[i].asMemo;
                  // logs.Post(llmessage, 'asMemo:%s', [tmps]);
                  AddVariant(Proc.Params[i].Name, tmps);
                end
            else
              AddVariant(Proc.Params[i].Name, (Proc.Params[i].Value));
            end;
          end;
        end;
      end;
      // logs.Post(lldebug, 'Proc.ExecProc End 2');
    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        // messagebox(0,pchar( e.message),'',0);
        aErrStr := aValue.encode(false) + ' ExecProc ' + e.message;
        logs.Post(llerror, '%s', [aErrStr]);
        // self.FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := '{}';
  rjs     := qjsonPool.get;
  rjs.Clear;
  succ        := 0;
  needSeconds := false;
  needPrepare := true;

  // logs.Post(lldebug, 'execproc save value %s ', [aValue.ToString]);

  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // logs.Post(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      logs.Post(lldebug, 'get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID]);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        logs.Post(llWarning, aErrStr);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'GetOneSQLDBHelp %s', [aErrStr]);
        exit;
      end;
    end;

    try
      Proc := aSQLDBHelp.getCusProc(aSql);
    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'getCusProc %s', [aErrStr]);
        exit;
      end;

    end;

    try
      tmpjs := aValue;
      if aValue.DataType = jdtArray then
        if aValue.Count > 0 then
          tmpjs := aValue[0];

      if not self.InitProc(aConfig, Proc, aSql, tmpjs, aErrStr) then
      begin
        logs.Post(llerror, 'InitProc Error 1 %s', [aErrStr]);
        exit;
      end;
    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'InitProc %s', [aErrStr]);
      end;
    end;
    rjs.DataType := jdtArray;
    rjs.Clear;
    if aValue.DataType = jdtArray then
    begin
      c := aValue.Count;
      logs.Post(lldebug, 'aValue.Count:=%d', [c]);
      aContinue := true;
      for i     := 0 to c - 1 do
      begin
        if FIsAbort then
          break;
        if (aErrStr = '') then
        begin
          if doOne(aValue[i], rjs) then
          begin
            inc(succ);
            if Proc.Tag = 2001 then
            begin
              Proc.Tag := 2002;
              rjs.Clear;
              doOne(aValue[i], rjs);
            end;
          end;
          if ((i + 1) mod FProcessPerCount = 0) or (i = c - 1) then
            if assigned(FOnProcess) then
            begin
              FOnProcess(self, c, i + 1, aContinue);
              // logs.Post(lldebug, 'FOnProcess End');
              if not aContinue then
              begin
                logs.Post(lldebug, 'not aContinue exit');
                exit;
              end;
              if aErrStr <> '' then
                logs.Post(lldebug, 'aErrStr:%s', [aErrStr]);
            end;
        end;
      end;
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
      end;

    end else begin
      c := 1;

      if doOne(aValue, rjs) then
      begin
        inc(succ);
        if Proc.Tag = 2001 then
        begin
          Proc.Tag := 2002;
          rjs.Clear;
          doOne(aValue, rjs);
        end;
      end;
    end;
    if assigned(FOnEnd) then
      FOnEnd(self, c);
    logs.Post(llmessage, '执行成功：%d', [succ]);

  finally
    result := rjs.ToString();
    rjs.Clear;
    try
      aSQLDBHelp.returnCusProc(aSql, Proc);
      qjsonPool.return(rjs);
    except
      on e: exception do
      begin
        logs.Post(llerror, 'aSQLDBHelp.returnCusProc(aSql, Proc):%s', [e.message]);
      end;
    end;
  end;
end;

function TMuMSSQLExec.InitProc(aConfig: TQJson; Proc: TFDStoredProc; aProcName: String; AParameDemo: TQJson;
  var aErrStr: String): boolean;
var
  i: integer;
  function checkparams(): boolean;
  var
    i: integer;
  begin
    result := true;

    if Proc.Params.Count < AParameDemo.Count then
    begin
      // exit(false);
    end;
    for i := 0 to Proc.Params.Count - 1 do
    begin
      if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
      begin
        if (not AParameDemo.Exists(Proc.Params[i].Name)) and
          (not AParameDemo.Exists(Proc.Params[i].Name.Replace('@', ''))) then
        begin
          logs.Post(lldebug, 'check params ,Param not exists:%s', [Proc.Params[i].Name]);
          result := false;
          exit(false);
        end;
      end;
    end;
  end;

begin
  result := false;
  try
    if not Proc.Connection.Connected then
    begin
      logs.Post(llmessage, '开始打开链接');
      // logs.Post(llmessage, Proc.Connection.ConnectionString);
      Proc.Connection.Connected := true;
    end;
  except
    on e: exception do
    begin
      aErrStr := format('proc.StoredProcName Connection.Connected 1 %s ', [e.message]);
      exit;
    end;
  end;

  if Proc.Tag > 2000 then
  begin
    exit(true);
  end;

  i := 0;

  Proc.Prepared := false;
  while (i < 5) and (not Proc.Prepared) do
  begin
    try
      logs.Post(lldebug, 'proc.Prepare repeat:%d', [i + 1]);

      Proc.StoredProcName := aProcName;
      Proc.Prepare;

      if (checkparams) then
        break;
      inc(i);
      sleep(100);
    except
      on e: exception do
      begin
        aErrStr := format('proc.StoredProcName Prepare repeat 2 %s ', [e.message]);
        exit;
      end;
    end;
  end;
  logs.Post(lldebug, 'ProcName:%s,StoredProcName:%s,Params:%d', [Proc.Name, Proc.StoredProcName, Proc.Params.Count]);

  if not Proc.Prepared then
  begin
    logs.Post(llWarning, 'Procedure %s is not prepared', [Proc.Name]);

  end;

  for i := 0 to Proc.Params.Count - 1 do
  begin
    if Proc.Params[i].ParamType in [ptOutput, ptInputOutput] then
      if Proc.Params[i].DataType in [ftWideMemo, ftFmtMemo, ftMemo] then
      begin
        Proc.Tag := 2001;
        break;
      end;
  end;

  logs.Post(lldebug, 'InitProc end');
  result := true;
end;

function TMuMSSQLExec.ExecProc_Dateset(aConfig: TQJson; ParamsFilds: TQJson; aDs: TDataset;
  var aErrStr: String): string;
var
  Proc                : TFDStoredProc;
  pjs                 : TQJson;
  i, j, c, succ, l    : integer;
  rjs                 : TQJson;
  es                  : String;
  server, aSql, fdName: String;
  pname               : string;
  aSQLDBHelp          : TSQLDBHelp;
  aContinue           : boolean;
  aFDParam            : TFDParam;
  afd                 : TField;
begin

  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  rjs.Clear;

  succ := 0;

  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // logs.Post(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      logs.Post(llmessage, 'get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID]);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        logs.Post(llWarning, aErrStr);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'GetOneSQLDBHelp %s', [aErrStr]);
        exit;
      end;
    end;

    try
      Proc := aSQLDBHelp.getCusProc(aSql);
    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'getCusProc %s', [aErrStr]);
        exit;
      end;
    end;

    if not InitProc(aConfig, Proc, aSql, ParamsFilds, aErrStr) then
    begin
      logs.Post(llerror, 'InitProc Error 2 %s', [aSql]);
      exit;
    end;
    c := aDs.RecordCount;

    logs.Post(llmessage, 'Start saving recordcount %d', [c]);
    j    := 0;
    succ := 0;
    aDs.First;
    rjs.DataType := jdtArray;
    aContinue    := true;
    while (not aDs.Eof) and (not self.FIsAbort) do
    begin
      inc(j);
      try
        for i := 0 to ParamsFilds.Count - 1 do
        begin
          fdName := ParamsFilds[i].AsString;
          if aDs.FindField(fdName) = nil then
            continue;
          afd   := aDs.FieldByName(fdName);
          pname := ParamsFilds[i].Name;
          if copy(pname, 1, 1) <> '@' then
            pname  := '@' + pname;
          aFDParam := Proc.Params.ParamByName(pname);
          with aFDParam do
            case DataType of
              ftString, ftFixedChar, ftWideString, ftFixedWideChar:
                begin
                  l  := Size;
                  es := afd.AsString;
                  if l < es.Length then
                  begin
                    logs.Post(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
                    es := copy(es, 1, l);
                  end;
                  AsString := es;
                end;
              // ftWideString:
              // AsWideString := afd.AsString;
              ftInteger:
                asInteger := afd.asInteger;
              ftSmallint:
                AsSmallInt := afd.asInteger;
              ftShortint:
                AsShortInt := afd.asInteger;
              ftWord:
                AsWord := afd.asInteger;
              ftLargeint:
                AsLargeInt := afd.AsLargeInt;
              ftLongWord:
                AsLongword := afd.AsLongword;
              ftDate:
                asDate := afd.asDatetime;
              ftTime:
                astime := afd.asDatetime;
              ftDateTime:
                asDatetime := afd.asDatetime;
              // ftTimeStamp:
              // AsSQLTimeStamp := aValue[i].asDatetime;
              ftBoolean:
                asBoolean := afd.asBoolean;
              ftFloat:
                asFloat := afd.asFloat;
              ftCurrency:
                asCurrency := afd.asFloat;
              ftExtended:
                asExtended := afd.asFloat;
              ftSingle:
                asSingle := afd.asFloat;

            else
              Value := afd.AsVariant;
            end;
          // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;
        end;
        {
          Proc.Params.ParamByName(pname).Value :=
          aDs.FieldByName(ParamsFilds[i].AsString).AsVariant;
        }

      except
        on e: exception do
        begin
          aErrStr := e.message;
          logs.Post(llerror, aErrStr);
        end;
      end;
      try
        Proc.ExecProc;
        inc(succ);
        // logs.Post(llmessage, '  saving  end %d', [j]);
        with (rjs.Add()) do
        begin
          for i := 0 to Proc.Params.Count - 1 do
          begin
            if Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput] then
            begin
              AddVariant(Proc.Params[i].Name, Proc.Params[i].Value);

              // logs.Post(llmessage, '%s', [Proc.Params[i].Value]);
            end;
          end;
        end;
        if ((j) mod FProcessPerCount = 0) or (j = c - 1) then
          if assigned(FOnProcess) then
          begin
            FOnProcess(self, c, j, aContinue);
            if not aContinue then
              exit;
          end;
      except
        on e: exception do
        begin
          // if aErrStr <> '' then
          // aErrStr := aErrStr + #13#10;
          aErrStr := e.message;
          logs.Post(llerror, aErrStr);
          // self.FIsAbort := true;
        end;
      end;
      aDs.Next();
    end;

    logs.Post(llmessage, '执行成功：%d', [succ]);
    try
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
          exit;
      end;

      if assigned(FOnEnd) then
        FOnEnd(self, c);
    except
      on e: exception do
      begin
        logs.Post(llerror, 'ExecProc_Dateset :%s', [e.message]);
      end;
    end;
  finally
    result := rjs.ToString();
    rjs.Clear;
    if (assigned(Proc)) then
      aSQLDBHelp.returnCusProc(aSql, Proc);
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec.JSONResult(aConfig, aValue: TQJson; var aErrStr: String): String;
var
  tp: String;
  js: TQJson;
begin
  aErrStr := '';
  tp      := aConfig.ValueByName('Type', 'SQL');
  // logs.Post(llhint, '需要执行的类型是：%s', [tp]);
  if (tp.ToLower() = 'jsonproc') or (tp.ToLower() = 'procjson') or (tp.ToLower() = 'jsonprocedure') then
  begin

    FRetryTimes := 0;
    logs.Post(lldebug, 'ExecProc for json');
    try
      result := JSONResult_proc(aConfig, aValue, aErrStr);
    except
      on e: exception do
      begin
        aErrStr := format('ExecProc exception:%s', [e.message]);
        logs.Post(llerror, aErrStr);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.JSONResult_proc(aConfig, aValue, aErrStr);
            exit;
          end;
        end;
      end;
    end;
  end else begin
    try
      result := self.JSONResult_SQL(aConfig, aValue, aErrStr);
    except
      on e: exception do
      begin
        aErrStr := format('ExecSQL exception:%s', [e.message]);
        logs.Post(llerror, aErrStr);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.JSONResult_SQL(aConfig, aValue, aErrStr);
            exit;
          end;
        end;
      end;
    end;
  end;

end;

function TMuMSSQLExec.JSONResult_proc(aConfig, aValue: TQJson; var aErrStr: String): String;
var
  Proc            : TFDStoredProc;
  pjs             : TQJson;
  i, j, c, succ, l: integer;
  rjs             : TQJson;
  es              : String;
  server, aSql    : String;
  pname           : string;
  aSQLDBHelp      : TSQLDBHelp;
  aContinue       : boolean;
var
  tmpjs: TQJson;
  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i: integer;
  begin
    result := false;
    for i  := 0 to Proc.Params.Count - 1 do
    begin
      if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
      begin
        pname := Proc.Params[i].Name;
        if (aValue.ItemByName(pname) = nil) and (aValue.ItemByName(pname.Replace('@', '')) = nil) then
        begin
          aErrStr := format('%s参数 (%d)"%s"没有值！%s', [Proc.Name, i, Proc.Params[i].Name, aValue.ToString]);
          exit;
        end;
      end;
    end;

    try
      for i := 0 to aValue.Count - 1 do
      begin
        pname := aValue[i].Name;
        if copy(pname, 1, 1) <> '@' then
          pname := '@' + pname;
        with Proc.Params.ParamByName(pname) do
          case DataType of
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := aValue[i].AsString;
                if l < es.Length then
                begin
                  logs.Post(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;
            // AsString := aValue[i].AsString;
            // ftWideString:
            // AsWideString := aValue[i].AsString;
            ftWideMemo:
              begin
                // logs.Post(lldebug, pname + ':' + aValue[i].AsString);
                // aValue[i].AsBytes loadfromstream();
                asWideMemo := aValue[i].AsString;
              end;
            ftFmtMemo, ftMemo:
              asMemo := aValue[i].AsString;
            ftInteger:
              asInteger := aValue[i].asInteger;
            ftSmallint:
              AsSmallInt := aValue[i].asInteger;
            ftShortint:
              AsShortInt := aValue[i].asInteger;
            ftWord:
              AsWord := aValue[i].asInteger;
            ftLargeint:
              AsLargeInt := aValue[i].AsInt64;
            ftLongWord:
              AsLongword := aValue[i].AsInt64;

            ftDate:
              asDate := aValue[i].asDatetime;
            ftTime:
              astime := aValue[i].asDatetime;
            ftDateTime:
              asDatetime := aValue[i].asDatetime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;

            ftBoolean:
              asBoolean := aValue[i].asBoolean;

            ftFloat:
              asFloat := aValue[i].asFloat;
            ftCurrency:
              asCurrency := aValue[i].asFloat;
            ftExtended:
              asExtended := aValue[i].asFloat;
            ftSingle:
              asSingle := aValue[i].asFloat;

          else
            Value := aValue[i].AsVariant;
          end;
        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;

      end;
    except
      on e: exception do
      begin
        aErrStr := format('Proc Params set value ,%s %s', [aValue.encode(false), e.message]);
        logs.Post(llerror, '%s', [aErrStr]);
      end;
    end;
    try
      logs.Post(lldebug, 'Proc.ExecProc %s', [aValue.encode(false)]);
      Proc.Active := true;
      // logs.Post(lldebug, 'Proc.ExecProc end %s', [aValue.encode(false)]);

      logs.Post(lldebug, 'Proc.ExecProc FieldCount:%d,RecordCount:%d ', [Proc.FieldCount, Proc.RecordCount]);
      if Proc.RecordCount = 0 then
      begin

        exit;
      end;
      if Proc.FieldCount = 0 then
      begin

        exit;
      end;
      if Proc.RecordCount = 1 then
      begin
        rjs.DataType := jdtObject;
        Proc.First;
        while not Proc.Eof do
        begin
          // logs.Post(llmessage, Proc.Fields[0].AsString);
          rjs.Parse(Proc.Fields[0].AsString);
          Proc.Next;
        end;
      end else begin
        Proc.First;
        while not Eof do
        begin
          // logs.Post(llmessage,Proc.Fields[0].AsString);
          rjs.Add.Parse(Proc.Fields[0].AsString);
          Proc.Next;
        end;
        rjs.DataType := jdtArray;

      end;
      // logs.Post(lldebug, 'Proc.ExecProc End');
      result := true;

      // logs.Post(lldebug, 'Proc.ExecProc End 2');
    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr := aValue.encode(false) + ' JSONResult_proc' + e.message;
        logs.Post(llerror, '%s', [aErrStr]);
        // self.FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := '{}';
  rjs     := qjsonPool.get;
  rjs.Clear;
  succ := 0;
  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // logs.Post(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      logs.Post(lldebug, 'get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID]);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        logs.Post(llWarning, aErrStr);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        logs.Post(llerror, 'GetOneSQLDBHelp %s', [aErrStr]);
        exit;
      end;
    end;
    try
      try
        Proc := aSQLDBHelp.getCusProc(aSql);

        // logs.Post(llerror, 'getCusProc %s', [proc.]);
      except
        on e: exception do
        begin
          aErrStr := e.message;
          logs.Post(llerror, 'getCusProc %s', [aErrStr]);
          exit;
        end;

      end;
      try
        tmpjs := aValue;
        if aValue.DataType = jdtArray then
          if aValue.Count > 0 then
            tmpjs := aValue[0];

        if not self.InitProc(aConfig, Proc, aSql, tmpjs, aErrStr) then
        begin
          logs.Post(llerror, 'InitProc Error 3 %s', [aErrStr]);
          exit;
        end;
      except
        on e: exception do
        begin
          aErrStr := e.message;
          logs.Post(llerror, 'InitProc %s', [aErrStr]);
        end;
      end;
      try
        logs.Post(lldebug, 'start doon jsonproc  %s', [aValue.ToString]);
        if doOne(aValue, rjs) then
        begin
          inc(succ);
        end;
      finally
        Proc.Active := false;
      end;
      if assigned(FOnEnd) then
        FOnEnd(self, c);
      logs.Post(llmessage, '执行成功：%d', [succ]);
    finally
      aSQLDBHelp.returnCusProc(aSql, Proc);
    end;
  finally
    result := rjs.ToString();
    rjs.Clear;
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec.JSONResult_SQL(aConfig, aValue: TQJson; var aErrStr: String): String;
var
  FQ        : TFDQuery;
  pjs       : TQJson;
  i, c, l   : integer;
  rjs, tmpjs: TQJson;
  es        : String;
  aSql      : String;
  aSQLDBHelp: TSQLDBHelp;
  aContinue : boolean;
  function doOne(aValue: TQJson; R: TQJson): TQJson;
  var
    i    : integer;
    pname: String;
  begin
    if (FQ.SQL.Text <> aSql) then
    begin
      FQ.SQL.Text := aSql;
      // FQ.Prepare;
    end else if FQ.Params.Count <> aValue.Count then
    begin
      FQ.Prepare;
    end;
    if FQ.Params.Count <> aValue.Count then
    begin
      aErrStr := format('SQL的参数%d和配置文件的参数%d数目不一样.', [FQ.Params.Count, aValue.Count]);
      exit;
    end;

    for i := 0 to aValue.Count - 1 do
    begin
      pname := aValue[i].Name;
      // sql 里面一般不是显示声明的类型
      with FQ.Params.ParamByName(pname) do
      begin
        case DataType of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            begin
              l  := Size;
              es := aValue[i].AsString;
              // if l < es.Length then
              // begin
              // logs.Post(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
              // es := copy(es, 1, l);
              // end;
              AsString := es;

            end;
          // AsString := aValue[i].AsString;
          // ftWideString:
          // AsWideString := aValue[i].AsString;

          ftInteger:
            asInteger := aValue[i].asInteger;
          ftSmallint:
            AsSmallInt := aValue[i].asInteger;
          ftShortint:
            AsShortInt := aValue[i].asInteger;
          ftWord:
            AsWord := aValue[i].asInteger;
          ftLargeint:
            AsLargeInt := aValue[i].AsInt64;
          ftLongWord:
            AsLongword := aValue[i].AsInt64;

          ftDate:
            asDate := aValue[i].asDatetime;
          ftTime:
            astime := aValue[i].asDatetime;
          ftDateTime:
            asDatetime := aValue[i].asDatetime;
          // ftTimeStamp:
          // AsSQLTimeStamp := aValue[i].asDatetime;

          ftBoolean:
            asBoolean := aValue[i].asBoolean;

          ftFloat:
            asFloat := aValue[i].asFloat;
          ftCurrency:
            asCurrency := aValue[i].asFloat;
          ftExtended:
            asExtended := aValue[i].asFloat;
          ftSingle:
            asSingle := aValue[i].asFloat;

        else
          Value := aValue[i].AsVariant;
        end;
      end;
      // FQ.Params.ParamByName(pname).Value := aValue[i].AsVariant;
    end;
    try
      FQ.Active := true;

      if FQ.RecordCount = 0 then
      begin
        exit;
      end;
      if FQ.FieldCount = 0 then
      begin
        exit;
      end;
      if FQ.RecordCount = 1 then
      begin

        rjs.DataType := jdtObject;
        FQ.First;
        while not FQ.Eof do
        begin
          rjs.Parse(FQ.Fields[0].AsString);
          FQ.Next;
        end;
      end else begin
        FQ.First;
        while not Eof do
        begin
          rjs.Add.Parse(FQ.Fields[0].AsString);
          FQ.Next;
        end;
        rjs.DataType := jdtArray;

      end;

    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr  := aValue.encode(false) + ' JSONResult_SQL' + e.message;
        FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  try
    try
      aSql       := aConfig.ItemByName('SQL').AsString;
      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      FQ         := aSQLDBHelp.getCusQuery(aSql);

    except
      on e: exception do
      begin
        aErrStr := e.message;
      end;
    end;
    // 此时获取到的，默认是服务器没有更改参数。如果更改了，就自动获取。

    // 数据格式，默认都是对的  bin image text暂时不支持，可以到parames字段的类型读取
    FIsAbort     := false;
    rjs.DataType := jdtArray;

    c := 1;
    try

      doOne(aValue, rjs);
    finally
      FQ.Active := false;
    end;
    if assigned(FOnProcess) then
    begin
      FOnProcess(self, c, i + 1, aContinue);
      if not aContinue then
        exit;
    end;

    if assigned(FOnEnd) then
      FOnEnd(self, c);
  finally

    result := rjs.ToString();
    rjs.Clear;
    aSQLDBHelp.returnCusQuery(aSql, FQ);

    qjsonPool.return(rjs);
  end;

end;

function TMuMSSQLExec.GetOneSQLDBHelp(Sv: TQJson): TSQLDBHelp;
begin
  result := SQLDBHelps.get(Sv);
end;

procedure TMuMSSQLExec.stop;
begin
  self.FIsAbort := true;
end;

{ TODBCStatementBase_ }

function TODBCStatementBase_.MoreResults: boolean;
var
  iRes: SQLReturn;
begin
  result := false;
  if NoMoreResults then
    exit;
  iRes := Lib.SQLMoreResults(Handle);
  case iRes of

    SQL_PARAM_DATA_AVAILABLE:
      begin
        result := true;
      end
  else
    inherited;
  end;
end;

initialization

// SDBHelp := TSDBHelp.Create(getexepath + 'db\ac.sdb');

finalization

// SDBHelp.Free;

end.
