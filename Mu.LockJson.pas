unit Mu.LockJson;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.classes, qjson,
  SyncObjs;

type

  TOnAddDataEvent<T> = reference to procedure(Sender: TObject; aData: T);
  TInnerProcedure<T> = reference to procedure(aData: T; index: integer);

  TOnAddData = reference to procedure(Sender: TObject; aData: TQjson);
  TInnerProc = reference to procedure(aData: TQjson; index: integer);

  TLockJson = class(TObject)
    private
      FFileName: String;
      FData    : TQjson;
      FLock    : TCriticalSection;

      FOnAddDataEvent: TOnAddData;

      function getCount(): integer;
      function getCountLocked(): integer;
      function getItem(aIndex: integer): TQjson;
    public
      constructor Create(aFileName: String = '');
      destructor Destroy; override;

      procedure LoadFromFile(aFileName: String);
      procedure SaveToFile(aFileName: String);

      procedure lock();
      procedure unlock();
      function Pop(adt: TQjson): boolean;
      function PopAll(adt: TQjson): boolean;
      procedure Add(adt: TQjson); overload;
      procedure Add(aJsonStr: String); overload;
      procedure AddArray(adt: TQjson);

      procedure Push(adt: TQjson);
      function delete(aT: TQjson): integer;

      property Count: integer read getCount;
      property CountLocked: integer read getCountLocked;
      property data: TQjson read FData;
      property Items[aIndex: integer]: TQjson read getItem; default;

      procedure each(iproc: TInnerProc);
      property OnAddDataEvent: TOnAddData read FOnAddDataEvent write FOnAddDataEvent;
  end;

  TLockJsonT<TRecord: record > = class(TObject)
    private
      FFileName: String;
      FData    : TQjson;
      FLock    : TCriticalSection;

      FOnAddDataEvent: TOnAddDataEvent<TRecord>;

      function getCount(): integer;
      function getCountLocked(): integer;
      function getItem(aIndex: integer): TRecord;
    public
      constructor Create(aFileName: String = '');
      destructor Destroy; override;
      procedure lock();
      procedure unlock();
      function Pop(var adt: TRecord): boolean;
      procedure Add(adt: TRecord);
      procedure Push(adt: TRecord);
      function delete(aT: TRecord): integer;

      property Count: integer read getCount;
      property CountLocked: integer read getCountLocked;
      property data: TQjson read FData;
      property Items[aIndex: integer]: TRecord read getItem; default;

      procedure each(iproc: TInnerProcedure<TRecord>);
      property OnAddDataEvent: TOnAddDataEvent<TRecord> read FOnAddDataEvent write FOnAddDataEvent;
  end;

implementation

{ TLockJsonT<TRecord> }

constructor TLockJsonT<TRecord>.Create(aFileName: String);
begin
  FFileName := aFileName;
  FLock     := TCriticalSection.Create;
  FLock.Enter;
  try
    FData := TQjson.Create;
    if fileexists(FFileName) then
    begin
      FData.LoadFromFile(FFileName);
    end;
  finally
    FLock.Leave;
  end;
end;

destructor TLockJsonT<TRecord>.Destroy;
begin
  FLock.Enter;
  try
    if FData.Count > 0 then
      if FFileName <> '' then
        FData.SaveToFile(FFileName);
    FData.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  inherited;
end;

procedure TLockJsonT<TRecord>.each(iproc: TInnerProcedure<TRecord>);
var
  i: integer;
  T: TRecord;
begin
  FLock.Enter;
  try
    for i := 0 to FData.Count - 1 do
    begin
      FData[i].ToRecord<TRecord>(T);
      iproc(T, i);
    end;
  finally
    FLock.Leave;
  end;
end;

function TLockJsonT<TRecord>.getCount: integer;
begin
  result := FData.Count;
end;

function TLockJsonT<TRecord>.getCountLocked: integer;
begin
  FLock.Enter;
  try
    result := FData.Count;
  finally
    FLock.Leave;
  end;
end;

function TLockJsonT<TRecord>.getItem(aIndex: integer): TRecord;
begin
  FLock.Enter;
  try
    if FData.Count < aIndex then
    begin
      FData[aIndex].ToRecord<TRecord>(result);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLockJsonT<TRecord>.lock;
begin
  FLock.Enter;
end;

procedure TLockJsonT<TRecord>.Add(adt: TRecord);
begin
  FLock.Enter;
  try
    FData.Add.FromRecord<TRecord>(adt);
    if assigned(FOnAddDataEvent) then
      FOnAddDataEvent(self, adt);
  finally
    FLock.Leave;
  end;
end;

function TLockJsonT<TRecord>.delete(aT: TRecord): integer;
var
  ajs: TQjson;
  i  : integer;
begin
  FLock.Enter;
  try
    if FData.Count = 0 then
      exit(-1);

    ajs := TQjson.Create;
    try
      ajs.FromRecord<TRecord>(aT);
      for i := FData.Count - 1 downto 0 do
      begin
        if FData[i].Equals(ajs) then
        begin
          result := i;
          FData.delete(i);
        end;
      end;
    finally
      ajs.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

function TLockJsonT<TRecord>.Pop(var adt: TRecord): boolean;
begin
  FLock.Enter;
  try
    result := FData.Count > 0;
    if result then
    begin
      FData[0].ToRecord<TRecord>(adt);
      FData.delete(0);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLockJsonT<TRecord>.Push(adt: TRecord);
var
  ajs: TQjson;
begin
  FLock.Enter;
  try
    if FData.Count = 0 then
    begin
      FData.Add.FromRecord<TRecord>(adt);
    end else begin
      ajs := TQjson.Create;
      ajs.FromRecord<TRecord>(adt);
      ajs.MoveTo(FData, 0);
    end;
    if assigned(FOnAddDataEvent) then
      FOnAddDataEvent(self, adt);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJsonT<TRecord>.unlock;
begin
  FLock.Leave;
end;

{ TLockJson }

constructor TLockJson.Create(aFileName: String);
begin
  FFileName := aFileName;
  FLock     := TCriticalSection.Create;
  FLock.Enter;
  try
    FData          := TQjson.Create;
    FData.DataType := jdtarray;
    if fileexists(FFileName) then
    begin
      FData.LoadFromFile(FFileName);
      if (FData.Count = 0) then
        FData.DataType := jdtarray;
    end;
  finally
    FLock.Leave;
  end;
end;

destructor TLockJson.Destroy;
begin
  FLock.Enter;
  try
    // if FData.Count > 0 then
    if FFileName <> '' then
      FData.SaveToFile(FFileName);
    FData.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  inherited;
end;

procedure TLockJson.each(iproc: TInnerProc);
var
  i: integer;
begin
  FLock.Enter;
  try
    for i := 0 to FData.Count - 1 do
    begin
      iproc(FData[i], i);
    end;
  finally
    FLock.Leave;
  end;

end;

function TLockJson.getCount: integer;
begin
  result := FData.Count;
end;

function TLockJson.getCountLocked: integer;
begin
  FLock.Enter;
  try
    result := FData.Count;
  finally
    FLock.Leave;
  end;
end;

function TLockJson.getItem(aIndex: integer): TQjson;
begin
  // 不安全的，解锁后，可能被删除了。
  FLock.Enter;
  try
    if FData.Count < aIndex then
      result := FData[aIndex];
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.LoadFromFile(aFileName: String);
begin
  FLock.Enter;
  try
    self.FData.LoadFromFile(aFileName);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.lock;
begin
  FLock.Enter;
end;

procedure TLockJson.Add(adt: TQjson);
begin
  FLock.Enter;
  try
    FData.Add.Assign(adt);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.Add(aJsonStr: String);
begin
  FLock.Enter;
  try
    FData.Add.Parse(aJsonStr);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.AddArray(adt: TQjson);
var
  js: TQjson;
begin
  FLock.Enter;
  try
    if adt.DataType = jdtarray then
    begin
      for js in adt do
        FData.Add.Assign(js);
    end;
  finally
    FLock.Leave;
  end;
end;

function TLockJson.delete(aT: TQjson): integer;
var
  i: integer;
begin
  FLock.Enter;
  try
    if FData.Count = 0 then
      exit(-1);

    for i := FData.Count - 1 downto 0 do
    begin
      if FData[i].Equals(aT) then
      begin
        result := i;
        FData.delete(i);
      end;
    end;

  finally
    FLock.Leave;
  end;

end;

function TLockJson.Pop(adt: TQjson): boolean;
begin
  FLock.Enter;
  try
    result := FData.Count > 0;
    if result then
    begin
      adt.Assign(FData[0]);
      FData.delete(0);
    end;
  finally
    FLock.Leave;
  end;
end;

function TLockJson.PopAll(adt: TQjson): boolean;
begin
  FLock.Enter;
  try
    result := FData.Count > 0;
    if result then
    begin
      adt.Assign(FData);
      FData.Clear;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.Push(adt: TQjson);
var
  ajs: TQjson;
begin
  FLock.Enter;
  try
    if FData.Count = 0 then
    begin
      FData.Add.Assign(adt);
    end else begin
      ajs := TQjson.Create;
      ajs.Assign(adt);
      ajs.MoveTo(FData, 0);
    end;
    if assigned(FOnAddDataEvent) then
      FOnAddDataEvent(self, adt);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.SaveToFile(aFileName: String);
begin
  FLock.Enter;
  try
    self.FData.SaveToFile(aFileName);
  finally
    FLock.Leave;
  end;
end;

procedure TLockJson.unlock;
begin
  FLock.Leave;
end;

end.
