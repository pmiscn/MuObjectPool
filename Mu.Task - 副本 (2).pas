unit Mu.Task;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.SyncObjs,
  // PerlRegEx, // curl, curl_d, Curl_help,
  qstring, qworker,
  // qtimetypes, qsimplepool,  Mu.pool.qjson, Mu.pool.st, Mu.pool.Reg,   qdb, qlog, qjson,
  Mu.LookPool, Mu.LookCount, qlog,
  Generics.Collections;

type
  TOnGroupJobEndNotify = reference to procedure(Sender: TObject;
    aWaitResult: TWaitResult);
  TOnListJobEndNotify = reference to procedure(Sender: TObject; aIndex: integer;
    aCount: integer);

  TOnBeforeGroupJobNotify = reference to procedure(Sender: TObject);
  TOnBeforeListJobNotify = reference to procedure(Sender: TObject;
    aIndex: integer);

  TOnDoJobEvent<Tt, Tr> = procedure(Sender: TObject; at: Tt; out ar: Tr)
    of object;
  TOnDoJobNotify<Tt, Tr> = reference to function(Sender: TObject; at: Tt;
    out ar: Tr): string;
  TOnBeforeJobNotify<Tt> = reference to procedure(Sender: TObject; at: Tt;
    aIndex: integer);
  TOnJobEndNotify<Tt, Tr> = reference to procedure(Sender: TObject; at: Tt;
    ar: Tr; aIndex: integer);

  TMuTask<TTaskRecord, TResultRecord> = class(TObject)
  type
    PTaskRecord = ^TTaskRecord;
    PResultRecord = ^TResultRecord;
  private

  protected
    FMuLockCount: TMuLockCount;

    FTaskAddSignal: String;
    FSignalId: integer;
    FSignalWaitHandle: NativeInt;

    FLastError: String;
    FGroup: TQJobGroup;
    FTimerHandle: intPtr;
    FGroupIsRuning: Boolean;
    FGroupTimeOut: Cardinal;

    FWaitRunningDone: Boolean;
    FEmpetySleepTime: intPtr;
    FEmptySleepEnd: Boolean;
    FIntervalSleepTime: intPtr;
    FJobErrorReturnList: Boolean;

    FThreadCount: integer;
    FIsStop: Boolean;
    FIsPause: Boolean;
    FSaveToResultList: Boolean;
    // FJobHandle: array of IntPtr;

    FTaskList: TMuLockList<TTaskRecord>;
    FResultList: TMuLockList<TResultRecord>;
    FOnBeforeJob: TOnBeforeJobNotify<TTaskRecord>;
    FOnDoJob: TOnDoJobNotify<TTaskRecord, TResultRecord>;
    FOnJobEnd: TOnJobEndNotify<TTaskRecord, TResultRecord>;

    FOnGroupJobEnd: TOnGroupJobEndNotify;
    FOnListJobEnd: TOnListJobEndNotify;

    FOnBeforeGroupJob: TOnBeforeGroupJobNotify;
    FOnBeforeListJob: TOnBeforeListJobNotify;

  protected
    procedure TimerJob(AJob: PQJob); virtual;
    procedure StartGroup(); virtual;
    function doJob(at: TTaskRecord; ar: TResultRecord): string; virtual;

    procedure TaskJob(AJob: PQJob); virtual;

    Procedure setStop(aValue: Boolean); virtual;

    function GetTaskSignal: string; virtual;
    procedure SetTaskList(aTaskList: TMuLockList<TTaskRecord>); virtual;
    procedure TaskAddEvent(Sender: TObject; aData: TTaskRecord); virtual;
    function GetRuningCount(): Int64; virtual;
  public
    constructor Create(aTaskList: TMuLockList<TTaskRecord>;
      aResultList: TMuLockList<TResultRecord>; aThreadCount: integer = 4;
      aStartImmediately: Boolean = true); virtual;
    destructor Destroy; override;
    procedure Stop(); virtual;
    procedure Start(); virtual;
    procedure Pause(); virtual;
    procedure resume(); virtual;
    property TaskList: TMuLockList<TTaskRecord> read FTaskList
      write SetTaskList;
    property ResultList: TMuLockList<TResultRecord> read FResultList
      write FResultList;
    property isStop: Boolean read FIsStop write setStop;
    property ThreadCount: integer read FThreadCount;

    property OnBeforeJob: TOnBeforeJobNotify<TTaskRecord> read FOnBeforeJob
      write FOnBeforeJob;
    property OnDoJob: TOnDoJobNotify<TTaskRecord, TResultRecord> read FOnDoJob
      write FOnDoJob;
    property OnJobEnd: TOnJobEndNotify<TTaskRecord, TResultRecord>
      read FOnJobEnd write FOnJobEnd;

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
    property TaskAddSignal: String read FTaskAddSignal;
    property JobErrorReturnList: Boolean read FJobErrorReturnList
      write FJobErrorReturnList;

    property RunningCount: Int64 read GetRuningCount;
  end;

implementation

// uses Mu.Logs;

{ TMuTask<TRecord> }

function TMuTask<TTaskRecord, TResultRecord>.GetTaskSignal: string;
var
  LTep: TGUID;
begin
  CreateGUID(LTep);
  result := GUIDToString(LTep);
end;

function TMuTask<TTaskRecord, TResultRecord>.GetRuningCount: Int64;
begin
  result := self.FMuLockCount.count;
end;

constructor TMuTask<TTaskRecord, TResultRecord>.Create
  (aTaskList: TMuLockList<TTaskRecord>; aResultList: TMuLockList<TResultRecord>;
  aThreadCount: integer; aStartImmediately: Boolean);
begin
  FMuLockCount := TMuLockCount.Create;

  FTaskAddSignal := GetTaskSignal();
  FSignalId := Workers.RegisterSignal(FTaskAddSignal);

  // FTaskList := aTaskList;
  SetTaskList(aTaskList);

  FResultList := aResultList;
  FIsStop := false;
  FIsPause := true;
  FEmpetySleepTime := 3000;
  FEmptySleepEnd := false;
  FIntervalSleepTime := 1;
  FThreadCount := aThreadCount;
  FSaveToResultList := true;

  FWaitRunningDone := false;

  FGroup := TQJobGroup.Create(false);
  FSignalWaitHandle := Workers.Wait(TimerJob, FSignalId);
  // FTimerHandle := workers.at(self.TimerJob, 100, 1000, nil, false);
  FGroupIsRuning := false;
  FGroupTimeOut := INFINITE;

  if aStartImmediately then
    Start();

end;

destructor TMuTask<TTaskRecord, TResultRecord>.Destroy;
var
  i: integer;
begin
  self.Stop;
  try
    Workers.Clear(FTaskAddSignal);
    // Workers.ClearSingleJob(FSignalWaitHandle, false);
    // FGroup.Cancel(FWaitRunningDone);
    FGroup.Free;
    FMuLockCount.Free;
  except
    on e: exception do
    begin
      Logs.Post(llError,'Task Free Exception Error: ' + #9 + e.Message);
    end;
  end;
  inherited;
end;

function TMuTask<TTaskRecord, TResultRecord>.doJob(at: TTaskRecord;
  ar: TResultRecord): string;
begin
  result := '';
  if assigned(FOnDoJob) then
    result := FOnDoJob(self, at, ar);
end;

procedure TMuTask<TTaskRecord, TResultRecord>.Pause;
begin
  FIsPause := true;
end;

procedure TMuTask<TTaskRecord, TResultRecord>.resume;
begin
  FIsPause := false;
end;

procedure TMuTask<TTaskRecord, TResultRecord>.TaskJob(AJob: PQJob);
var
  at: TTaskRecord;
  ar: TResultRecord;
  errstr: string;
  c: integer;
  idx: integer;
begin
  FMuLockCount.inc();
  c := 0;
  idx := intPtr(AJob.Data);
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
          { Mu.Logs.public_addLogs('get one from Tasklist ' +
            inttostr(sizeof(at)));
          }
          FEmptySleepEnd := false;
          try
            if assigned(FOnBeforeJob) then
              FOnBeforeJob(self, at, integer(AJob.Data));

            errstr := doJob(at, ar);
            inc(c);
          except
            on e: exception do
            begin
              Logs.Post(llError,'Task Job do job Exception Error: ' + #9 +
                inttostr(idx) + #9 + inttostr(AJob.Handle) + #9 + e.Message);
              // if FJobErrorReturnList then
              // self.FTaskList.add(at);
            end;
          end;

          if errstr = 'IgnoreResultAdd' then
          begin
            errstr := '';
            continue;
            // break;
          end;

          if errstr <> '' then
          begin
            Logs.Post(llError,'Task Job do job Error: ' + #9 +
              inttostr(idx) + #9 + inttostr(AJob.Handle) + #9 + errstr + #9);
            // if FJobErrorReturnList then
            // FTaskList.add(at);
          end;
          try
            { if self.FSaveToResultList then
              if assigned(FResultList) then
              FResultList.add(ar); }
            // if assigned(FOnJobEnd) then
            // FOnJobEnd(self, at, ar, integer(AJob.Data));
          except
            on e: exception do
              Logs.Post(llError,'Task Job OnJobEnd Error: ' + inttostr(idx)
                + #9 + inttostr(AJob.Handle) + #9 + e.Message);
          end;
        end
        else
        begin
          if assigned(FOnListJobEnd) then
            FOnListJobEnd(self, c, integer(AJob.Data));
          Logs.Post(llMessage,'Task Job , Break ');
          // 如果没有任务数据了，就退出循环，结束Job
          if not FEmptySleepEnd then
          begin
            sleep(FEmpetySleepTime);
            FEmptySleepEnd := true;
          end
          else
            break;
          //
        end;
      except
        on e: exception do
          Logs.Post(LLError,'Task Job Error: ' + inttostr(idx) + #9 +
            inttostr(AJob.Handle) + #9 + e.Message);
      end;
    finally
      sleep(FIntervalSleepTime);
    end;
  end;
  Logs.Post(LLMessage,'Task Job , End ');
  FMuLockCount.dec();
end;

procedure TMuTask<TTaskRecord, TResultRecord>.TimerJob(AJob: PQJob);
begin
  if self.FIsStop then
    exit;
  if self.FIsPause then
    exit;
  if self.FTaskList.count > 0 then
  begin
    if not FGroupIsRuning then
    begin
      Logs.Post(LLMessage,' Startint group ');
      StartGroup();
    end;
  end;
end;

procedure TMuTask<TTaskRecord, TResultRecord>.TaskAddEvent(Sender: TObject;
  aData: TTaskRecord);
begin
  // if FTaskList.count = 1 then
  if self.isStop then
    exit;
  if not FGroupIsRuning then
  begin
    // 等添加完成后，再执行任务信号
    sleep(10);
    Workers.Signal(FTaskAddSignal);
  end;
end;

procedure TMuTask<TTaskRecord, TResultRecord>.SetTaskList
  (aTaskList: TMuLockList<TTaskRecord>);
begin
  FTaskList := aTaskList;
  FTaskList.OnAddDataEvent := TaskAddEvent;
end;

procedure TMuTask<TTaskRecord, TResultRecord>.setStop(aValue: Boolean);
begin
  if aValue then
  begin
    Stop()
  end
  else
    Start();
end;

procedure TMuTask<TTaskRecord, TResultRecord>.Start;
var
  i: integer;
begin
  FIsStop := false;
  FIsPause := false;

  if self.FTaskList.count > 0 then
  begin
    Workers.Signal(FTaskAddSignal);
  end;

  Logs.Post(LLMEssage,'TMuTask Start count ' + inttostr(FThreadCount));

end;

procedure TMuTask<TTaskRecord, TResultRecord>.StartGroup;
var
  i: integer;
  r: TWaitResult;
begin
  // Mu.Logs.public_addLogs(' FGroupIsRuning := true');
  if assigned(FOnBeforeGroupJob) then
    FOnBeforeGroupJob(self);
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
      FLastError := format('Mu.Task TaskJob TimeOut %ds', [self.FGroupTimeOut])
    else
      FLastError := format('Mu.Task TaskJob Error %d', [integer(r)]);
    Logs.Post(LLMessage,'Job Do error ' + FLastError);
  end;
  FGroupIsRuning := false;
  // Mu.Logs.public_addLogs(' FGroupIsRuning := false');
end;

procedure TMuTask<TTaskRecord, TResultRecord>.Stop;
var
  i: integer;
begin
  FGroup.Cancel(FWaitRunningDone);
  FIsStop := true;
  FIsPause := true;
end;

end.
