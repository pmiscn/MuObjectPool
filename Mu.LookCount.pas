unit Mu.LookCount;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.classes,
  SyncObjs, Generics.Collections;

type

  TMuLockCount = class(TObject)
  private
    FLock: TCriticalSection;
    FCount: int64;
    function getCount(): int64;
    procedure SetCount(const Value: int64);
    procedure lock();
    procedure unlock();
  public
    constructor create(aDefault: int64 = 0);
    destructor destroy; override;
    function inc(aC: int64 = 1): int64;
    function dec(aC: int64 = 1): int64;
    property count: int64 read getCount write SetCount;
  end;

implementation

// --------- TMuLockList<TRecord> ----------------------------------------------------

constructor TMuLockCount.create(aDefault: int64 = 0);
begin
  FLock := TCriticalSection.create;
  FCount := aDefault;
end;

function TMuLockCount.dec(aC: int64): int64;
begin
  FLock.Enter;
  try
    FCount := FCount - aC;
  finally
    FLock.Leave;
  end;
end;

destructor TMuLockCount.destroy;
begin
  FLock.Free;
  inherited destroy;
end;

procedure TMuLockCount.lock;
begin
  FLock.Enter;
end;

procedure TMuLockCount.SetCount(const Value: int64);
begin
  FLock.Enter;
  try
    FCount := Value;
  finally
    FLock.Leave;
  end;
end;

function TMuLockCount.getCount(): int64;
begin
  FLock.Enter;
  try
    result := FCount;
  finally
    FLock.Leave;
  end;
end;

function TMuLockCount.inc(aC: int64): int64;
begin
  FLock.Enter;
  try
    FCount := FCount + aC;
  finally
    FLock.Leave;
  end;
end;

procedure TMuLockCount.unlock;
begin
  FLock.Leave;
end;

end.
