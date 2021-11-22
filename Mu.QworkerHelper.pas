unit Mu.QworkerHelper;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  qworker, System.SyncObjs;

type

  TQJobGroup_ = class helper for TQJobGroup
  protected
    function getitem(AIndex: Integer): PQJob;

    function getItems: TQJobItemList;
    function getLocker: TQSimpleLock;
    function getPosted: Integer;
    procedure setPosted(AValue: Integer);
  public
    property Item[AIndex: Integer]: PQJob read getitem; default;
    property Items: TQJobItemList read getItems;
    property Locker: TQSimpleLock read getLocker;
    property Posted: Integer read getPosted write setPosted;
    procedure forceCancle();
  end;

  TQWorkers_ = class helper for TQWorkers
  protected
    function getBusyCount: Integer;
    procedure setBusyCount(AValue: Integer);

  public
    procedure KillTimeoutWorkers(FTimeOut: Integer);
    procedure resetWorker(aWorker: TQWorker);
    property BusyCount: Integer read getBusyCount write setBusyCount;

  end;

  TQWorker_ = class helper for TQWorker
  protected
    function getActiveJob(): PQJob;
    function getPending(): Boolean;
    function getEvent(): TEvent;
    procedure setPending(AValue: Boolean);
    function getOwner(): TQWorkers;
  public
    procedure SetFlags(AIndex: Integer; AValue: Boolean);
    property ActiveJob: PQJob read getActiveJob;
    property Pending: Boolean read getPending write setPending;
    property Event: TEvent read getEvent;
    property Owner: TQWorkers read getOwner;
  end;

implementation

{ TQJobGroup_ }

procedure TQJobGroup_.forceCancle;
var
  i: Integer;
  AJob: PQJob;
  aOwner: TQWorkers;
begin
  // workers.Clear();

//  FLocker.Enter;
  try
    // if FGroup.count > 0 then
    // FGroup.Cancel(false);
    for i := 0 to count - 1 do
    begin
      AJob := FItems[i];
      if AJob = nil then
        continue;
      if AJob.Worker = nil then
        continue;
      if AJob.Worker.IsBusy then
      begin
        // SimpleJobs
        aOwner := AJob.Worker.Owner;
        aOwner.resetWorker(AJob.Worker);
      end;
    end;
    // FItems.Clear;
  finally
  //  FLocker.Leave;
  end;
end;

function TQJobGroup_.getitem(AIndex: Integer): PQJob;
begin
  Result := FItems[AIndex];
end;

function TQJobGroup_.getItems: TQJobItemList;
begin
  Result := FItems;
end;

function TQJobGroup_.getLocker: TQSimpleLock;
begin
  Result := FLocker;
end;

function TQJobGroup_.getPosted: Integer;
begin
  Result := FPosted;
end;

procedure TQJobGroup_.setPosted(AValue: Integer);
begin
  FPosted := AValue;
end;

{ TQWorkers_ }

function TQWorkers_.getBusyCount: Integer;
begin
  Result := FBusyCount;
end;

procedure TQWorkers_.KillTimeoutWorkers(FTimeOut: Integer);
var
  i: Integer;
  ATime: Int64;
begin
  try
    for i := 0 to Workers - 1 do
    begin
      if FWorkers[i] = nil then
        continue;

      if FWorkers[i].IsBusy then
      begin
        if Assigned(FWorkers[i].ActiveJob) then
        begin
          // if (FWorkers[i].ActiveJob.Handle and $03) <> 0 then // SingleJob
          // continue;
          ATime := GetTimeStamp;
          if (ATime - FWorkers[i].ActiveJob.PopTime) / 10000 > FTimeOut then
          // 如果线程执行任务超过规定时间
          begin
            resetWorker(FWorkers[i]);
          end;
        end;
      end;

      sleep(0);
    end;
  except

  end;

end;

procedure TQWorkers_.resetWorker(aWorker: TQWorker);
var
  i: Integer;
begin
  for i := low(FWorkers) to high(FWorkers) do
  begin
    if (FWorkers[i] = aWorker) then
    begin
      ClearSingleJob(FWorkers[i].ActiveJob.Handle, false); // 清理任务
      FWorkers[i].SetFlags(WORKER_FIRING, true);
      FWorkers[i].Terminate;
      TerminateThread(FWorkers[i].Handle, 0);
      // 强制立即结束线程, 不等待执行完毕,会有内存泄漏
      FWorkers[i] := nil;
      AtomicDecrement(FBusyCount);

      FWorkers[i] := TQWorker.Create(self); // 重启线程
      FWorkers[i].Pending := true;
      FWorkers[i].Event.SetEvent;
      FWorkers[i].Suspended := false;
      break;
    end;
  end;
end;

procedure TQWorkers_.setBusyCount(AValue: Integer);
begin
  FBusyCount := AValue;
end;

{ TQWorker_ }

function TQWorker_.getActiveJob: PQJob;
begin
  Result := FActiveJob;
end;

function TQWorker_.getEvent: TEvent;
begin
  Result := FEvent;
end;

function TQWorker_.getOwner: TQWorkers;
begin
  Result := FOwner;
end;

function TQWorker_.getPending: Boolean;
begin
  Result := FPending;
end;

procedure TQWorker_.SetFlags(AIndex: Integer; AValue: Boolean);
begin
  if AValue then
    FFlags := FFlags or AIndex
  else
    FFlags := FFlags and (not AIndex);
end;

procedure TQWorker_.setPending(AValue: Boolean);
begin
  FPending := AValue;
end;

end.
