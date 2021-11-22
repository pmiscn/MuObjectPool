unit Mu.Task1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.SyncObjs,
  // PerlRegEx, // curl, curl_d, Curl_help,
  qstring, qworker,
  // qtimetypes, qsimplepool,  Mu.pool.qjson, Mu.pool.st, Mu.pool.Reg, qdb, qlog, qjson,
  Mu.LookPool,
  Mu.Task,
  Generics.Collections;

type
  // TOnDoJobEvent1<Tt> = procedure(Sender: TObject; at: Tt) of object;

  TOnDoJobNotify1<Tt> = reference to function(Sender: TObject; at: Tt): string;

  TOnBeforeJobNotify1<Tt> = reference to procedure(Sender: TObject; at: Tt;
    aIndex: integer);

  TOnJobEndNotify1<Tt> = reference to procedure(Sender: TObject; at: Tt;
    aIndex: integer);

  TMuTask1<TTaskRecord> = class(TObject)
  type
    PTaskRecord = ^TTaskRecord;
  private

  protected
    FLastError: String;
    FGroup: TQJobGroup;
    FTimerHandle: intPtr;
    FGroupIsRuning: Boolean;
    FGroupTimeOut: Cardinal;

    FWaitRunningDone: Boolean;
    FEmpetySleepTime: intPtr;
    FIntervalSleepTime: intPtr;
    FThreadCount: integer;
    FIsStop: Boolean;
    FIsPause: Boolean;
    FSaveToResultList: Boolean;
    // FJobHandle: array of IntPtr;

    FTaskList: TMuLockList<TTaskRecord>;
    FOnBeforeJob: TOnBeforeJobNotify1<TTaskRecord>;
    FOnDoJob: TOnDoJobNotify1<TTaskRecord>;
    FOnJobEnd: TOnJobEndNotify1<TTaskRecord>;

    FOnGroupJobEnd: TOnGroupJobEndNotify;
    FOnListJobEnd: TOnListJobEndNotify;

    FOnBeforeGroupJob: TOnBeforeGroupJobNotify;
    FOnBeforeListJob: TOnBeforeListJobNotify;

    procedure TimerJob(AJob: PQJob); virtual;
    procedure StartGroup(); virtual;

    function doJob(at: TTaskRecord): string; virtual;

    procedure TaskJob(AJob: PQJob); virtual;
    Procedure setStop(aValue: Boolean); virtual;
  public
    constructor Create(aTaskList: TMuLockList<TTaskRecord>;
      aThreadCount: integer = 4; aStartImmediately: Boolean = true); virtual;
    destructor Destroy; override;
    procedure Stop(); virtual;
    procedure Start(); virtual;
    procedure Pause(); virtual;
    procedure resume(); virtual;
    property TaskList: TMuLockList<TTaskRecord> read FTaskList write FTaskList;

    property isStop: Boolean read FIsStop write setStop;
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
    property WaitRunningDone: Boolean read FWaitRunningDone
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
  end;

implementation

uses Mu.Logs;
{ TMuTask1<TRecord> }

constructor TMuTask1<TTaskRecord>.Create(aTaskList: TMuLockList<TTaskRecord>;
  aThreadCount: integer; aStartImmediately: Boolean);
begin
  FTaskList := aTaskList;
  FIsStop := false;
  FIsPause := true;
  FEmpetySleepTime := 1000;
  FIntervalSleepTime := 1;
  FThreadCount := aThreadCount;
  FSaveToResultList := true;

  FWaitRunningDone := false;

  FGroup := TQJobGroup.Create(false);
  FTimerHandle := workers.at(self.TimerJob, 100, 1000, nil, false);
  FGroupIsRuning := false;
  FGroupTimeOut := INFINITE;

  if aStartImmediately then
    Start();

end;

destructor TMuTask1<TTaskRecord>.Destroy;
var
  i: integer;
begin
  { for i := low(FJobHandle) to high(FJobHandle) do
    begin
    Workers.ClearSingleJob(FJobHandle[i], false)
    end;
  }
  workers.ClearSingleJob(FTimerHandle, false);
  FGroup.Cancel(FWaitRunningDone);
  FGroup.Free;
  inherited;
end;

function TMuTask1<TTaskRecord>.doJob(at: TTaskRecord): string;
begin
  result := '';
  if assigned(FOnDoJob) then
    result := FOnDoJob(self, at);
end;

procedure TMuTask1<TTaskRecord>.Pause;
begin
  FIsPause := true;
end;

procedure TMuTask1<TTaskRecord>.resume;
begin
  FIsPause := false;
end;

procedure TMuTask1<TTaskRecord>.TaskJob(AJob: PQJob);
var
  at: TTaskRecord;
  errstr: string;
  c: integer;
begin
  c := 0;
  if assigned(FOnBeforeListJob) then
    FOnBeforeListJob(self, integer(AJob.Data));
  while not FIsStop do //
  begin
    if AJob.IsTerminated then
    begin
      break;
    end;
    // Mu.Logs.public_addLogs('TaskJob ');
    if FIsPause then
    begin
      sleep(100);
      continue;
    end;
    try
      try
        // Mu.Logs.public_addLogs('Start get one ');
        if FTaskList.GetOne(at) then
        begin
          { Mu.Logs.public_addLogs('Task1 get one from Tasklist ' +
            inttostr(sizeof(at)));
          }
          try
            if assigned(FOnBeforeJob) then
              FOnBeforeJob(self, at, integer(AJob.Data));
            errstr := doJob(at);
            inc(c);
          except
            on e: Exception do
              Mu.Logs.public_addLogs('Task1 Job do job Exception Error: ' + #9 +
                inttostr(AJob.Handle) + #9 + e.Message);
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
            Mu.Logs.public_addLogs('Task1 Job do job Error: ' + #9 +
              inttostr(AJob.Handle) + #9 + errstr + #9);
          end;
          try
            if assigned(FOnJobEnd) then
              FOnJobEnd(self, at, integer(AJob.Data));
          except
            on e: Exception do
              Mu.Logs.public_addLogs('Task1 Job FOnJobEnd Error: ' +
                inttostr(AJob.Handle) + #9 + e.Message);
          end;
        end
        else
        begin
          if assigned(FOnListJobEnd) then
            FOnListJobEnd(self, c, integer(AJob.Data));
          // Mu.Logs.public_addLogs('Task1 Job , Break ');
          // 如果没有任务数据了，就退出循环，结束Job
          break;
          // sleep(FEmpetySleepTime);
        end;
      except
        on e: Exception do
          Mu.Logs.public_addLogs('Task1 Job Error: ' + inttostr(AJob.Handle) +
            #9 + e.Message);
      end;
    finally
      sleep(FIntervalSleepTime);
    end;
  end;
  Mu.Logs.public_addLogs('Task1 Job , End ');
end;

procedure TMuTask1<TTaskRecord>.TimerJob(AJob: PQJob);
begin
  if self.FIsStop then
    exit;
  if self.FIsPause then
    exit;
  if self.FTaskList.count > 0 then
  begin
    if not FGroupIsRuning then
    begin
      Mu.Logs.public_addLogs('Task1 Startint group ');
      StartGroup();
    end;
  end;
end;

procedure TMuTask1<TTaskRecord>.setStop(aValue: Boolean);
begin
  if aValue then
  begin
    Stop()
  end
  else
    Start();
end;

procedure TMuTask1<TTaskRecord>.Start;
var
  i: integer;
begin
  FIsStop := false;
  FIsPause := false;
  Mu.Logs.public_addLogs('TMuTask1 Start count ' + inttostr(FThreadCount));

end;

procedure TMuTask1<TTaskRecord>.StartGroup;
var
  i: integer;
  r: TWaitResult;
begin
  if assigned(FOnBeforeGroupJob) then
    FOnBeforeGroupJob(self);
  // Mu.Logs.public_addLogs(' FGroupIsRuning := true');
  FLastError := '';
  FGroupIsRuning := true;
  FGroup.Prepare;
  for i := 0 to FThreadCount - 1 do
  begin
    FGroup.add(TaskJob, pointer(i), false);
  end;
  FGroup.Run();
  r := FGroup.MsgWaitFor(FGroupTimeOut);

  if assigned(FOnGroupJobEnd) then
    FOnGroupJobEnd(self, r);

  if r <> wrSignaled then
  begin
    if r = wrTimeout then
      FLastError := format('MuTask1 TaskJob TimeOut %ds', [self.FGroupTimeOut])
    else
      FLastError := format('MuTask1 TaskJob Error %d', [integer(r)]);
    Mu.Logs.public_addLogs('Job Do error ' + FLastError);
  end;
  FGroupIsRuning := false;
  // Mu.Logs.public_addLogs(' FGroupIsRuning := false');
end;

procedure TMuTask1<TTaskRecord>.Stop;
var
  i: integer;
begin
  FGroup.Cancel(FWaitRunningDone);
  FIsStop := true;
  FIsPause := true;
end;

end.
