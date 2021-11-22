unit qworker_help;

interface

uses System.SysUtils, System.Variants, System.Classes, System.Types, qworker;

type
  TQWorkers_ = class helper for TQWorkers
  public
    /// <summary>�ȴ�ָ������ҵ����</summary>
    /// <param name="AHandle">Ҫ�ȴ�����ҵ������</param>
    /// <param name="ATimeout">��ʱʱ�䣬��λΪ����</param>
    /// <param name="AMsgWait">�ȴ�ʱ�Ƿ���Ӧ��Ϣ</param>
    /// <returns>�����ҵ������ͨ��ҵ���򷵻�wrError�������ҵ�����ڻ��Ѿ����������� wrSignal�����򣬷��� wrTimeout</returns>
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
