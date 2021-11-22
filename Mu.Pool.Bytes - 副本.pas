unit Mu.Pool.Bytes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  QSimplePool, Generics.Collections,
  SyncObjs, qstring,
  System.Classes;

type
  PBytes = ^TBytes;

  TBytesPool = class(TObject)
  private
    FOutObj: Tlist;
    FPool: TQSimplePool;
    FByteLength: integer;
    FBytess: array of TBytes;
    FLock: TCriticalSection;
    procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
    function GetLength: integer;
  protected

  public
    constructor Create(aByteLength: integer; Poolsize: integer = 100);
    destructor Destroy; override;
    function get(): TBytes;
    procedure return(aSt: TBytes);
    property count: integer read GetLength;
  end;

implementation

{ TstPool }

constructor TBytesPool.Create(aByteLength: integer; Poolsize: integer);
begin
  FLock := TCriticalSection.Create;
  FByteLength := aByteLength;
  FPool := TQSimplePool.Create(Poolsize, FOnObjectCreate, FOnObjectFree,
    FOnObjectReset);
end;

destructor TBytesPool.Destroy;
begin
  FLock.Free;
  FPool.Free;
  inherited;
end;

procedure TBytesPool.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
var
  l: integer;
begin
  FLock.Enter;
  try
    l := length(FBytess);
    setlength(FBytess, l + 1);

    setlength(FBytess[l], self.FByteLength);
    AData := @FBytess[l][0];
  finally
    FLock.Leave;
  end;
end;

procedure TBytesPool.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  //
end;

procedure TBytesPool.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin
  ZeroMemory(AData, self.FByteLength);

  // tstringlist(AData).Clear;
end;

function TBytesPool.get: TBytes;
begin
  result := TBytes(FPool.pop);
end;

function TBytesPool.GetLength: integer;
begin
  result := length(self.FBytess);
end;

procedure TBytesPool.return(aSt: TBytes);
begin
  FPool.Push(aSt);
end;

initialization


finalization

end.
