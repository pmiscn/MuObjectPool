unit Mu.QworkerJobStatus;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, dateutils,
  qworker, QMapSymbols, qtimetypes,

  qstring, Generics.Collections;

type
  TQworkerJobStatus = record
    index: IntPtr;
    Handle: IntPtr;
    Flags: Integer;
    JobFuncName: String[255];
    IsRunningStr: string[20];
    Style: String[20];
    Categray: String[20];
    IsRunning: Boolean;  // 是否在运行中，如果为False，则作业处于队列中
    Runs: Integer;       // 已经运行的次数
    EscapedTime: Int64;  // 已经执行时间
    PushTime: tdatetime; // 入队时间
    PopTime: tdatetime;  // 出队时间
    AvgTime: Int64;      // 平均时间
    TotalTime: Int64;    // 总执行时间
    MaxTime: Int64;      // 最大执行时间
    MinTime: Int64;      // 最小执行时间
    NextTime: tdatetime; // 重复作业的下次执行时间
    Plan: TQPlanMask;    // 计划任务设置
  end;

var
  QworkerJobStatuses: TList<TQworkerJobStatus>;
  _StartCounter:      IntPtr;
  _StartTime:         tdatetime;
  {

    Handle: IntPtr; // 作业对象句柄
    Proc: TQJobMethod; // 作业过程
    Flags: Integer; // 标志位
    IsRunning: Boolean; // 是否在运行中，如果为False，则作业处于队列中
    Runs: Integer; // 已经运行的次数
    EscapedTime: Int64; // 已经执行时间
    PushTime: Int64; // 入队时间
    PopTime: Int64; // 出队时间
    AvgTime: Int64; // 平均时间
    TotalTime: Int64; // 总执行时间
    MaxTime: Int64; // 最大执行时间
    MinTime: Int64; // 最小执行时间
    NextTime: Int64; // 重复作业的下次执行时间
    Plan: TQPlanMask; // 计划任务设置


    作业 #1 - 匿名函数 计划中:
    计划任务
    下次执行时间: 2015-08-12 18:00
    掩码:0 0 12,18 ? * 2-6
    已运行:0 次
    任务提交时间: 8秒 前
    平均每次用时:0ms
    总计用时:0ms
    最大用时:0ms
    最小用时:0ms
    标志位:主线程, }

function getQworkerJobStatuses(aWorkers: TQWorkers=nil): Integer;

implementation

function getQworkerJobStatuses(aWorkers: TQWorkers=nil): Integer;
var
  AStates: TQJobStateArray;
  i:       Integer;
  ALoc:    TQSymbolLocation;
  qwjs:    TQworkerJobStatus;
begin
  if aWorkers = nil then
    aWorkers := workers;
  AStates := aWorkers.EnumJobStates;
  QworkerJobStatuses.Clear;
  try
    result := length(AStates);

    for i := 0 to High(AStates) do
    begin
      try
        qwjs.index := i + 1;
        qwjs.Handle := AStates[i].Handle;
        qwjs.Flags := AStates[i].Flags;
        // qwjs.Proc := AStates[i].Proc;
        qwjs.IsRunning := AStates[i].IsRunning;
        qwjs.Runs := 0;
        qwjs.EscapedTime := 0;

        qwjs.PushTime := 0;
        qwjs.PopTime := 0;

        qwjs.AvgTime := 0;
        qwjs.TotalTime := 0;
        qwjs.MaxTime := 0;
        qwjs.MinTime := 0;
        qwjs.NextTime := 0;
        qwjs.JobFuncName := '';
        qwjs.IsRunningStr := '';
        qwjs.Style := '';
        qwjs.Categray := '';

        if (AStates[i].Flags and JOB_ANONPROC) = 0 then
        begin
          if LocateSymbol(AStates[i].proc.Code, ALoc) then
            qwjs.JobFuncName := (ALoc.FunctionName)
          else
            qwjs.JobFuncName := (TObject(AStates[i].proc.Data).MethodName(AStates[i].proc.Code));
        end
        else
          qwjs.JobFuncName := ('anonymous');

        if AStates[i].IsRunning then
          qwjs.IsRunningStr := ('running')
        else
          qwjs.IsRunningStr := ('planing');

        case AStates[i].Handle and $03 of
          0:
            begin
              qwjs.Style := ('simple-job');
              QworkerJobStatuses.Add(qwjs);
              continue;
            end;
          1:
            begin
              qwjs.Style := ('repeat-job');
              qwjs.NextTime := _StartTime + AStates[i].NextTime * OneMillisecond / 10;
            end;
          2:
            qwjs.Style := ('single-job');
          3:
            begin
              qwjs.Style := ('plan-job');
              qwjs.NextTime := AStates[i].Plan.NextTime;
              qwjs.Plan := AStates[i].Plan;
            end;
        end;
        qwjs.Runs := AStates[i].Runs;
        qwjs.PushTime := _StartTime + AStates[i].PushTime * OneMillisecond / 10;
        qwjs.PopTime := _StartTime + AStates[i].PopTime * OneMillisecond / 10;

        qwjs.EscapedTime := AStates[i].EscapedTime;
        qwjs.AvgTime := AStates[i].AvgTime;
        qwjs.TotalTime := AStates[i].TotalTime;
        qwjs.MaxTime := AStates[i].MaxTime;
        qwjs.MinTime := AStates[i].MinTime;
        qwjs.NextTime := _StartTime + AStates[i].NextTime * OneMillisecond / 10;

        { if AStates[i].PopTime <> 0 then
          begin
          end;
        }
        qwjs.Categray := ('');
        if (AStates[i].Flags and JOB_RUN_ONCE) <> 0 then
          qwjs.Categray := ('once');
        if (AStates[i].Flags and JOB_IN_MAINTHREAD) <> 0 then
          qwjs.Categray := ('main-theread');
        if (AStates[i].Flags and JOB_GROUPED) <> 0 then
          qwjs.Categray := ('grouped');

        QworkerJobStatuses.Add(qwjs);
      except
        // raise Exception.Create(' ' + i.ToString);
      end;
    end;

  finally
    try
      ClearJobStates(AStates);
    except
      // on e: exception do
      // raise Exception.Create('ClearJobStates(AStates) ' + e.message);
    end;
  end;
end;

initialization

QworkerJobStatuses := TList<TQworkerJobStatus>.Create;
_StartCounter := GetTickCount;
_StartTime := now();

finalization

QworkerJobStatuses.Clear;
QworkerJobStatuses.Free;

end.
