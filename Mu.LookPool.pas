unit Mu.LookPool;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.classes,
  SyncObjs, Generics.Collections;

type

  TOnAddDataEvent<T> = reference to procedure(Sender: TObject; aData: T);
  TInnerProcedure<T> = reference to procedure(aData: T; index: integer);

  TMuLockList<TRecord> = class(TObject)
  private
    FLock: TCriticalSection;
    FaTs: Tlist<TRecord>;
    FOnAddDataEvent: TOnAddDataEvent<TRecord>;
    function getCount(): integer;
    function getCountLocked(): integer;
    function getItem(aIndex: integer): TRecord;

  public
    constructor create();
    destructor destroy; override;
    procedure lock();
    procedure unlock();
    procedure Clear;
    function GetOne(var aT: TRecord): boolean;
    function add(aT: TRecord): boolean;
    function put(aT: TRecord): boolean; overload;
    function delete(aT: TRecord): integer;
    procedure each(iproc: TInnerProcedure<TRecord>);
    procedure DoAddDataEvent();
    property Count: integer read getCount;
    property CountLocked: integer read getCountLocked;
    property DataList: Tlist<TRecord> read FaTs write FaTs;
    property Items[aIndex: integer]: TRecord read getItem; default;
    property OnAddDataEvent: TOnAddDataEvent<TRecord> read FOnAddDataEvent
      write FOnAddDataEvent;
  end;

implementation

// --------- TMuLockList<TRecord> ----------------------------------------------------

procedure TMuLockList<TRecord>.Clear;
begin
  FLock.Enter;
  try
    FaTs.Clear;
  finally
    FLock.Leave;
  end;
end;

constructor TMuLockList<TRecord>.create;
begin
  FLock := TCriticalSection.create;
  FaTs := Tlist<TRecord>.create;
end;

function TMuLockList<TRecord>.delete(aT: TRecord): integer;
var
  i: integer;
begin
  if not assigned(FLock) then
    exit;
  FLock.Enter;
  try
    i := FaTs.IndexOf(aT);
    if i >= 0 then
      FaTs.delete(i);
  finally
    FLock.Leave;
  end;
end;

destructor TMuLockList<TRecord>.destroy;
var
  i: integer;
begin
  if not assigned(FLock) then
    exit;
  FLock.Enter;
  try
    // FaTs.Clear;
    FaTs.Free;
  finally
    FLock.Leave;
    FLock.Free;
  end;
  inherited destroy;
end;

procedure TMuLockList<TRecord>.DoAddDataEvent;
begin
  if assigned(FOnAddDataEvent) then
    FOnAddDataEvent(self, FaTs[0]);
end;

procedure TMuLockList<TRecord>.each(iproc: TInnerProcedure<TRecord>);
var
  i: integer;
begin
  FLock.Enter;
  try
    for i := 0 to FaTs.Count - 1 do
    begin
      iproc(FaTs[i], i);
    end;
  finally
    FLock.Leave;
  end;
end;

function TMuLockList<TRecord>.GetOne(var aT: TRecord): boolean;
begin
  // if not assigned(FLock) then
  // exit;
  FLock.Enter;
  try
    if FaTs.Count > 0 then
    begin
      aT := FaTs[0];
      FaTs.delete(0);
      result := true;
    end
    else
      result := false;
  finally
    FLock.Leave;
  end;
end;

procedure TMuLockList<TRecord>.lock;
begin
  FLock.Enter;
end;

function TMuLockList<TRecord>.getCountLocked(): integer;
begin
  FLock.Enter;
  try
    result := FaTs.Count;
  finally
    FLock.Leave;
  end;
end;

function TMuLockList<TRecord>.getCount(): integer;
begin

  result := FaTs.Count;

end;

function TMuLockList<TRecord>.getItem(aIndex: integer): TRecord;
begin
  FLock.Enter;
  try
    result := FaTs[aIndex];
  finally
    FLock.Leave;
  end;
end;

function TMuLockList<TRecord>.add(aT: TRecord): boolean;
begin
  if not assigned(FLock) then
    exit;
  FLock.Enter;
  try
    FaTs.add(aT);
    if assigned(FOnAddDataEvent) then
      FOnAddDataEvent(self, aT);
  finally
    FLock.Leave;
  end;
  if assigned(FOnAddDataEvent) then
    FOnAddDataEvent(self, aT);
end;

function TMuLockList<TRecord>.put(aT: TRecord): boolean;
var
  psw: TRecord;
begin
  if not assigned(FLock) then
    exit;
  FLock.Enter;
  try
    FaTs.Insert(0, aT);
  finally
    FLock.Leave;
  end;
  if assigned(FOnAddDataEvent) then
    FOnAddDataEvent(self, aT);
end;

procedure TMuLockList<TRecord>.unlock;
begin
  FLock.Leave;
end;

end.
