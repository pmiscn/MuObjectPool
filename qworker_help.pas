unit qworker_help;

interface

uses System.SysUtils, System.Variants, System.Classes, System.Types, qworker;

type
  TQWorkers_ = class helper for TQWorkers
  public
    /// <summary>等待指定的作业结束</summary>
    /// <param name="AHandle">要等待的作业对象句柄</param>
    /// <param name="ATimeout">超时时间，单位为毫秒</param>
    /// <param name="AMsgWait">等待时是否响应消息</param>
    /// <returns>如果作业不是普通作业，则返回wrError，如果作业不存在或已经结束，返回 wrSignal，否则，返回 wrTimeout</returns>
    // function WaitJob(AHandle: IntPtr; ATimeout: Cardinal; AMsgWait: Boolean): TWaitResult;

    function PostWait(AProc: TQJobProc; AData: Pointer; ATimeout: Cardinal;
      AMsgWait: Boolean = true; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    function PostWait(AProc: TQJobProcG; AData: Pointer; ATimeout: Cardinal;
      AMsgWait: Boolean = true; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$IFDEF UNICODE}
    function PostWait(AProc: TQJobProcA; AData: Pointer; ATimeout: Cardinal;
      AMsgWait: Boolean = true; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$ENDIF}
  end;

implementation

{ TQWorkers_ }

function TQWorkers_.PostWait(AProc: TQJobProc; AData: Pointer;
  ATimeout: Cardinal; AMsgWait, ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): Boolean;
var
  h: IntPtr;
begin
  h := self.Post(AProc, AData, ARunInMainThread, AFreeType);
  result := self.WaitJob(h, ATimeout, AMsgWait) = wrSignaled;
end;

function TQWorkers_.PostWait(AProc: TQJobProcG; AData: Pointer;
  ATimeout: Cardinal; AMsgWait, ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): Boolean;
var
  h: IntPtr;
begin
  h := self.Post(AProc, AData, ARunInMainThread, AFreeType);
  result := self.WaitJob(h, ATimeout, AMsgWait) = wrSignaled;

end;

function TQWorkers_.PostWait(AProc: TQJobProcA; AData: Pointer;
  ATimeout: Cardinal; AMsgWait, ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): Boolean;
var
  h: IntPtr;
begin
  h := self.Post(AProc, AData, ARunInMainThread, AFreeType);
  result := self.WaitJob(h, ATimeout, AMsgWait) = wrSignaled;
end;

end.
