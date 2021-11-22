unit Mu.Pool.QJson;

interface

uses
  System.SysUtils, System.Variants,
  QSimplePool, QJson,
  System.Classes;

type
  TQJsonPool = class(TObject)
  private
    FPool: TQSimplePool;
    procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
  protected

  public
    constructor Create(Poolsize: integer = 20);
    destructor Destroy; override;
    function get(): TQJson;
    function borrowObject(): TQJson;
    procedure return(ajs: TQJson);
    procedure release(ajs: TQJson);
    procedure releaseObject(ajs: TQJson);

  end;

var
  qjsonPool: TQJsonPool;

implementation

{ TQJsonPool }

constructor TQJsonPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnObjectCreate, FOnObjectFree,
    FOnObjectReset);
end;

destructor TQJsonPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TQJsonPool.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  TQJson(AData) := TQJson.Create;
end;

procedure TQJsonPool.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  TQJson(AData).Free;
end;

procedure TQJsonPool.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin
  with TQJson(AData) do
  begin
    reset(false);
    // DataType := jdtUnknown;
    // Clear;
  end;
end;

function TQJsonPool.get: TQJson;
begin
  result := TQJson(FPool.pop);
end;

function TQJsonPool.borrowObject: TQJson;
begin
  result := TQJson(FPool.pop);
end;

procedure TQJsonPool.release(ajs: TQJson);
begin
  ajs.Clear;
  FPool.push(ajs);
end;

procedure TQJsonPool.releaseObject(ajs: TQJson);
begin
  ajs.Clear;
  FPool.push(ajs);
end;

procedure TQJsonPool.return(ajs: TQJson);
begin
  FPool.push(ajs);
end;

initialization

qjsonPool := TQJsonPool.Create(10);

finalization

qjsonPool.Free;

end.

