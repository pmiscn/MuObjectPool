unit Mu.Task1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.SyncObjs,
  qworker, Mu.qworkerHelper, // tring,
  // qtimetypes, qsimplepool,
  Mu.LookPool, // Mu.LookCount,
  Mu.Task, // son, Mu.Pool.qjson,
  Generics.Collections;

var
  _isExit: boolean = false;

type
  // TOnDoJobEvent1<Tt> = procedure(Sender: TObject; at: Tt) of object;

  TOnDoJobNotify1<Tt> = reference to function(Sender: TObject; at: Tt): string;

  TOnBeforeJobNotify1<Tt> = reference to procedure(Sender: TObject; at: Tt;
    aIndex: integer);

  TOnJobEndNotify1<Tt> = reference to procedure(Sender: TObject; at: Tt;
    aIndex: integer);
  TOnRuningListAdd<Tt> = reference to procedure(Sender: TObject;
    Ajob: PQJob; at: Tt);
  TDoRuningListRemove<Tt> = reference to procedure(Sender: TObject;
    Ajob: PQJob; at: Tt);

  TMuTask1<TTaskRecord> = class(TObject)
  type
    PTaskRecord = ^TTaskRecord;
    PTaskAndRecord = ^TTaskAndRecord;

    TTaskAndRecord = record
      JobIndex: integer;
      Task: TMuTask1<TTaskRecord>;
      Rcrd: TTaskRecord;
      JobHandle: intPtr;
    end;
  private

  protected

    FJobintervalDelay: integer;

    FLastError: String;

    FTimerHandle, FTimeOutHandle: intPtr;
    FGroupIsRuning: boolean;
    FGroupTimeOut: Cardinal;
    FRunningCount: integer;
    FCompletedCount: int64;
    FIgnoreCount: int64;

    FWaitRunningDone: boolean;
    FEmpetySleepTime: intPtr;
    FEmptySleepEnd: boolean;
    FIntervalSleepTime: intPtr;
    FJobErrorReturnList: boolean;
    FThreadCount: integer;
    FIsStop: boolean;
    FIsPause: boolean;
    FSaveToResultList: boolean;
    // FJobHandle: array of IntPtr;
    FTaskJobHandles: TARRAY<THandle>;
    FTaskList: TMuLockList<TTaskRecord>;
    FRunningTaskList: TMuLockList<TTaskRecord>;

    FJobTimeOutSeconds, FJobTimeDone: Uint;

    FOnBeforeJob: TOnBeforeJobNotify1<TTaskRecord>;
    FOnDoJob: TOnDoJobNotify1<TTaskRecord>;
    FOnJobEnd: TOnJobEndNotify1<TTaskRecord>;

    FOnGroupJobEnd: TOnGroupJobEndNotify;
    FOnListJobEnd: TOnListJobEndNotify;

    FOnBeforeGroupJob: TOnBeforeGroupJobNotify;
    FOnBeforeListJob: TOnBeforeListJobNotify;

    FOnRuningListAdd: TOnRuningListAdd<TTaskRecord>;
    FDoRuningListRemove: TDoRuningListRemove<TTaskRecord>;

    procedure TimerJob(Ajob: PQJob); virtual;
    function doJob(at: TTaskRecord): string; virtual;

    procedure TaskJob(Ajob: PQJob); virtual;
    Procedure setStop(aValue: boolean); virtual;

    function GetTaskSignal: string; virtual;
    procedure SetTaskList(aTaskList: TMuLockList<TTaskRecord>);
    procedure TaskAddEvent(Sender: TObject; aData: TTaskRecord);

    function GetRuningCount: int64;
    function GetRunsCount: int64;
  public
    constructor Create(aTaskList: TMuLockList<TTaskRecord>;
      aThreadCount: integer = 4; aStartImmediately: boolean = true); virtual;
    destructor Destroy; override;
    procedure Stop(); virtual;
    procedure ForceStop(); virtual;
    procedure Start(); virtual;
    procedure Pause(); virtual;
    procedure resume(); virtual;

    property TaskList: TMuLockList<TTaskRecord> read FTaskList write FTaskList;
    property RunningTaskList: TMuLockList<TTaskRecord> read FRunningTaskList
      write FRunningTaskList;

    property isStop: boolean read FIsStop write setStop;
    property ThreadCount: integer read FThreadCount;

    property OnBeforeJob: TOnBeforeJobNotify1<TTaskRecord> read FOnBeforeJob
      write FOnBeforeJob;
    property OnDoJob: TOnDoJobNotify1<TTaskRecord> read FOnDoJob write FOnDoJob;
    property OnJobEnd: TOnJobEndNotify1<TTaskRecord> read FOnJobEnd
      write FOnJobEnd;

    property EmpetySleepTime: intPtr read FEmpetySleepTime
      write FEmpetySleepTime;
    property IntervalSleepTime: intPtr read FIntervalSleepTime
      write FIntervalSleepTime;
    property WaitRunningDone: boolean read FWaitRunningDone
      write FWaitRunningDone;

    property OnGroupJobEnd: TOnGroupJobEndNotify read FOnGroupJobEnd
      write FOnGroupJobEnd;
    property OnListJobEnd: TOnListJobEndNotify read FOnListJobEnd
      write FOnListJobEnd;
    property OnBeforeGroupJob: TOnBeforeGroupJobNotify read FOnBeforeGroupJob
      write FOnBeforeGroupJob;
    property OnBeforeListJob: TOnBeforeListJobNotify read FOnBeforeListJob
      write FOnBeforeListJob;

    property GroupTimeOut: Cardinal read FGroupTimeOut write FGroupTimeOut;
    property LastError: String read FLastError;

    property CompletedCount: int64 read FCompletedCount;
    property IgnoreCount: int64 read FIgnoreCount;

    property JobErrorReturnList: boolean read FJobErrorReturnList
      write FJobErrorReturnList;

    property OnRuningListAdd: TOnRuningListAdd<TTaskRecord>
      read FOnRuningListAdd write FOnRuningListAdd;
    property DoRuningListRemove: TDoRuningListRemove<TTaskRecord>
      read FDoRuningListRemove write FDoRuningListRemove;

    property GroupIsRuning: boolean read FGroupIsRuning write FGroupIsRuning;
    property RunningCount: int64 read GetRuningCount;
    property RunsCount: int64 read GetRunsCount;

    property JobintervalDelay: integer read FJobintervalDelay
      write FJobintervalDelay;
    property JobTimeOutSeconds: Uint read FJobTimeOutSeconds
      write FJobTimeOutSeconds;
    property JobTimeDone: Uint read FJobTimeDone write FJobTimeDone;
  end;

function MySleep(aCount: integer): boolean;

implementation

uses qlog; // Mu.Logs;

function MySleep(aCount: integer): boolean;
var
  Msg: TMsg;
begin
  result := _isExit;

  if _isExit then
  begin
    exit;
  end;
  if aCount < 10 then
  begin
    sleep(aCount);
    exit;
  end;
  while (aCount > 0) and (not _isExit) do
  begin
    sleep(10);
    dec(aCount, 10);
  end;
  { while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
    end;
  }
end;

{ TMuTask1<TRecord> }
function TMuTask1<TTaskRecord>.GetTaskSignal: string;
var
  LTep: TGUID;
begin
  CreateGUID(LTep);
  result := GUIDToString(LTep);
end;

function TMuTask1<TTaskRecord>.GetRuningCount: int64;
begin
  result := self.FRunningCount;
end;

function TMuTask1<TTaskRecord>.GetRunsCount: int64;
begin
  result := 0;
end;

constructor TMuTask1<TTaskRecord>.Create(aTaskList: TMuLockList<TTaskRecord>;
  aThreadCount: integer; aStartImmediately: boolean);
var
  i: integer;
  p: Pint;
begin

  FRunningTaskList := TMuLockList<TTaskRecord>.Create;
  FJobTimeOutSeconds := 0;
  SetTaskList(aTaskList);

  FIsStop := false;
  FIsPause := true;
  FEmptySleepEnd := false;
  FEmpetySleepTime := 3000;
  FIntervalSleepTime := 10;
  FThreadCount := aThreadCount;
  FSaveToResultList := true;
  FJobErrorReturnList := true;

  FWaitRunningDone := false;

  // FTimerHandle := workers.at(self.TimerJob, 100, 1000, nil, false);
  FGroupIsRuning := false;
  FGroupTimeOut := INFINITE;

  FJobintervalDelay := 1000;
  FRunningCount := 0;
  FCompletedCount := 0;
  FIgnoreCount := 0;
  setlength(FTaskJobHandles, FThreadCount);

  for i := 0 to FThreadCount - 1 do
  begin
    new(p);
    p^ := i;
    FTaskJobHandles[i] := Workers.Delay(TaskJob, FIntervalSleepTime * 10, p,
      false, jdfFreeAsSimpleRecord, true);
  end;
  if aStartImmediately then
    Start();

end;

destructor TMuTask1<TTaskRecord>.Destroy;
var
  i: integer;
  job: PQJob;
begin

  Stop();
  try
    for i := 0 to FThreadCount - 1 do
    begin
      Workers.ClearSingleJob(FTaskJobHandles[i], true);
    end;

    if assigned(FRunningTaskList) then
      FRunningTaskList.Free;

  except
    on e: exception do
    begin
      logs.post(llerror, 'Task Free Exception Error: ' + #9 + e.Message);
    end;
  end;
  inherited;
end;

function TMuTask1<TTaskRecord>.doJob(at: TTaskRecord): string;
begin
  result := '';
  if assigned(FOnDoJob) then
    result := FOnDoJob(self, at);
end;

procedure TMuTask1<TTaskRecord>.ForceStop;
var
  i: integer;
  Ajob: PQJob;
begin

end;

procedure TMuTask1<TTaskRecord>.Pause;
begin
  FIsPause := true;
end;

procedure TMuTask1<TTaskRecord>.resume;
begin
  FIsPause := false;
end;

procedure TMuTask1<TTaskRecord>.TaskJob(Ajob: PQJob);
var
  at: TTaskRecord;
  errstr: string;
  c, idx: integer;
begin
  if _isExit then
  begin
    Ajob.Worker.ForceQuit;
    exit;
  end;

  c := 0;
  FEmptySleepEnd := false;

  Ajob.Worker.ComNeeded();
  try
    try
      AtomicIncrement(FRunningCount);

      idx := Pint(Ajob.Data)^;
      if Ajob.IsTerminated then
      begin
        exit;
      end;

      if assigned(FOnBeforeListJob) then
        FOnBeforeListJob(self, integer(Ajob.Data));

      if FIsStop then
      begin
        exit;
      end;
      if FIsPause then
      begin
        exit;
      end;

      if not assigned(FTaskList) then
      begin
        exit;
      end;
      if not assigned(FTaskList) then
        exit;
      if FTaskList.GetOne(at) then
      begin
        FRunningTaskList.add(at);
        if assigned(FOnRuningListAdd) then
        begin
          FOnRuningListAdd(self, Ajob, at);
        end;
        FEmptySleepEnd := false;
        try
          if assigned(FOnBeforeJob) then
            FOnBeforeJob(self, at, idx);

          errstr := doJob(at);

          if Ajob = nil then
            exit;

          inc(c);
        except
          on e: exception do
          begin
            logs.post(llerror, 'Task1 Job do job Exception Error: ' + #9 +
              inttostr(idx) + #9 + inttostr(Ajob.Handle) + #9 + e.Message);
            if FJobErrorReturnList then
            begin
              self.FTaskList.add(at);
            end;
          end;
        end;
        {
          if errstr = 'IgnoreResultAdd' then
          begin
          errstr := '';
          continue;
          // break;
          end;
        }
        if errstr <> '' then
        begin
          AtomicIncrement(self.FIgnoreCount);
          logs.post(llerror, 'Task1 Job do job Error: ' + #9 + inttostr(idx) +
            #9 + inttostr(Ajob.Handle) + #9 + errstr + #9);
        end;
        try
          AtomicIncrement(self.FCompletedCount);
          if assigned(FOnJobEnd) then
            FOnJobEnd(self, at, integer(Ajob.Data));
          if assigned(FDoRuningListRemove) then
          begin
            FDoRuningListRemove(self, Ajob, at);
            FRunningTaskList.delete(at)
          end
          else
            FRunningTaskList.delete(at);
          // logs.post(lldebug, 'Task1 Job %d delete from running list ', [idx]);

        except
          on e: exception do
          begin
            logs.post(llerror, 'Task1 Job FOnJobEnd Error: ' + inttostr(idx) +
              #9 + inttostr(Ajob.Handle) + #9 + e.Message);
            if FJobErrorReturnList then
              self.FTaskList.add(at);
          end;
        end;
      end
      else
      begin
        // logs.post(lldebug, 'Task1 Job %d tasklist empty', [idx]);

        if assigned(FOnListJobEnd) then
          FOnListJobEnd(self, c, integer(Ajob.Data));
        // Mu.Logs.public_addLogs('Task1 Job , Break ');
        // 如果没有任务数据了，就退出循环，结束Job
        sleep(FEmpetySleepTime);

        if not FEmptySleepEnd then
        begin
          FEmptySleepEnd := true;
        end
        else
        begin
          exit;
        end;
      end;
    except
      on e: exception do
        logs.post(llerror, 'Task1 Job Error: ' + inttostr(idx) + #9 +
          inttostr(Ajob.Handle) + #9 + e.Message);
    end;

  finally
    // logs.post(lldebug, 'Task1 Job %d, End ', [idx]);
    AtomicDecrement(FRunningCount);
  end;
end;

procedure TMuTask1<TTaskRecord>.TaskAddEvent(Sender: TObject;
  aData: TTaskRecord);
begin

end;

procedure TMuTask1<TTaskRecord>.TimerJob(Ajob: PQJob);
begin
  exit;
  if self.FIsStop then
    exit;
  if self.FIsPause then
    exit;
  if self.FTaskList.count > 0 then
  begin
    if not FGroupIsRuning then
    begin
      // logs.post(lldebug, 'TimerJob Task1 Startint group ');
      Workers.Delay(
        procedure(Ajob: PQJob)
        var
          _Self: TMuTask1<TTaskRecord>;
        begin
          _Self := TMuTask1<TTaskRecord>(Ajob.Data);
          _Self.GroupIsRuning := true;

        end, 50, self, false);
    end
    else
    begin
      // logs.post(lldebug, 'TimerJob FGroupIsRuning=true');
    end;
  end;
end;

procedure TMuTask1<TTaskRecord>.Start;
var
  i: integer;
begin
  FIsStop := false;
  FIsPause := false;
  logs.post(lldebug, 'TMuTask1 Start count %d', [FThreadCount]);

end;

procedure TMuTask1<TTaskRecord>.SetTaskList
  (aTaskList: TMuLockList<TTaskRecord>);
begin
  FTaskList := aTaskList;
  FTaskList.OnAddDataEvent := TaskAddEvent;
end;

procedure TMuTask1<TTaskRecord>.setStop(aValue: boolean);
begin
  if aValue then
  begin
    Stop()
  end
  else
    Start();
end;

procedure TMuTask1<TTaskRecord>.Stop;
var
  i: integer;
begin
  _isExit := true;
  FIsStop := true;
  FIsPause := true;
end;

end.
