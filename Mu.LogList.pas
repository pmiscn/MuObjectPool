unit Mu.LogList;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, SyncObjs,
  System.Types,
  qlog, qstring, Generics.Collections;

type
  TOnQLogAddedEvent = procedure(AItem: PQLogItem) of object;

  TQLogListWriter = class(TQLogWriter)
  private
    FList: TList<PQLogItem>;
    FCount: Integer;
    FMaxSize: Integer;
    // FList: TQLogList;
    FLock: TCriticalSection;
    FEvent: TEvent;
    FOnQLogAddedEvent: TOnQLogAddedEvent;
    FOnQLogAddedMessage: TNotifyEvent;
    function getCount(): Integer;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function WriteItem(AItem: PQLogItem): Boolean; override;
    procedure HandleNeeded; override;
    procedure lock();
    procedure unlock();
    property List: TList<PQLogItem> read FList;
    property count: Integer read getCount;
    property MaxSize: Integer read FMaxSize write FMaxSize;
    property Event: TEvent read FEvent;
    property OnQLogAddedEvent: TOnQLogAddedEvent read FOnQLogAddedEvent
      write FOnQLogAddedEvent;
    property OnQLogAddedMessage: TNotifyEvent read FOnQLogAddedMessage
      write FOnQLogAddedMessage;

  end;

implementation

{ TQLogListWriter }

procedure FreeItem(AItem: PQLogItem);
begin
  FreeMem(AItem);
end;

constructor TQLogListWriter.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FList := TList<PQLogItem>.Create;
  FMaxSize := 100;
  FCount := 0;
  FEvent := TEvent.Create(nil, true, False, '');
end;

destructor TQLogListWriter.Destroy;
var
  i: Integer;
begin
  FLock.Enter;
  try
    for i := FList.count - 1 downto 0 do
    begin
      // dispose(PQLogItem(FList[i]));
      FreeMem(PQLogItem(FList[i]));
    end;
    FList.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  freeandnil(FEvent);
  inherited;
end;

function TQLogListWriter.getCount: Integer;
begin
  lock;
  try
    result := self.FList.count;
  finally
    unlock;
  end;
end;

procedure TQLogListWriter.lock;
begin
  FLock.Enter;
end;

procedure TQLogListWriter.unlock;
begin
  FLock.Leave;
end;

function TQLogListWriter.WriteItem(AItem: PQLogItem): Boolean;
var
  Item, Item2: PQLogItem;
  sz: Integer;
begin
  inc(FCount);
  sz := SizeOf(TQLogItem) + AItem.MsgLen;
  GetMem(Item, sz);

  Move(PQLogItem(AItem)^, Item^, sz);
  Item.Next := PQLogItem(FCount);
  // Item.Next := nil;

  lock;
  try

    FList.Add(Item);
    if FList.count > FMaxSize then
    begin
      Item2 := FList[0];
      FList.Delete(0);
      // dispose(Item2);
      FreeMem(Item2);
    end;
    Event.SetEvent;
  finally
    unlock
  end;
  if assigned(FOnQLogAddedEvent) then
    FOnQLogAddedEvent(AItem);

  if assigned(FOnQLogAddedMessage) then
    FOnQLogAddedMessage(self);
end;

procedure TQLogListWriter.HandleNeeded;
begin
  // Nothing Needed
end;

initialization

finalization

end.
