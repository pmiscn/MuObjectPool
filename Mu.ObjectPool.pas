unit Mu.ObjectPool;

interface

uses
  SyncObjs, Classes, Windows, SysUtils;

type
  TObjectCreateEvent = procedure(Sender: TObject; var aObject: TObject)
    of object;
  TObjectFreeEvent = procedure(Sender: TObject; var aObject: TObject) of object;

  TObjectBlock = record
  private
    FObject: TObject;
    FUsing: Boolean;
    FBorrowTime: Cardinal; // 借出时间
    FRelaseTime: Cardinal; // 归还时间
  end;

  PObjectBlock = ^TObjectBlock;

  TMuObjectPool = class(TObject)
  private
    FObjectClass: TClass;

    FLocker: TCriticalSection;

    // 全部归还信号
    FReleaseSingle: THandle;

    // 有可用的对象信号灯
    FUsableSingle: THandle;

    FMaxNum: Integer;

    /// <summary>
    /// 正在使用的对象列表
    /// </summary>
    FBusyList: TList;

    /// <summary>
    /// 可以使用的对象列表
    /// </summary>
    FUsableList: TList;

    FName: String;
    FTimeOut: Integer;

    FOnObjectCreate: TObjectCreateEvent;
    FOnObjectFree: TObjectFreeEvent;

    procedure makeSingle;
    function GetCount: Integer;
    procedure lock;
    procedure unLock;
  protected
    /// <summary>
    /// 清理空闲的对象
    /// </summary>
    procedure clear;

    /// <summary>
    /// 创建一个对象
    /// </summary>
    function createObject: TObject; virtual;
  public
    constructor Create(pvObjectClass: TClass = nil);
    destructor Destroy; override;

    /// <summary>
    /// 重置对象池
    /// </summary>
    procedure resetPool;

    /// <summary>
    /// 借用一个对象
    /// </summary>
    function borrowObject: TObject;

    /// <summary>
    /// 归还一个对象
    /// </summary>
    procedure releaseObject(pvObject: TObject);

    /// <summary>
    /// 获取正在使用的个数
    /// </summary>
    function getBusyCount: Integer;

    // 等待全部还回
    function waitForReleaseSingle: Boolean;

    /// <summary>
    /// 等待全部归还信号灯
    /// </summary>
    procedure checkWaitForUsableSingle;

    /// <summary>
    /// 当前总的个数
    /// </summary>
    property Count: Integer read GetCount;

    /// <summary>
    /// 最大对象个数
    /// </summary>
    property MaxNum: Integer read FMaxNum write FMaxNum;

    /// <summary>
    /// 对象池名称
    /// </summary>
    property Name: String read FName write FName;

    /// <summary>
    /// 等待超时信号灯
    /// 单位毫秒
    /// </summary>
    property TimeOut: Integer read FTimeOut write FTimeOut;
    property OnObjectCreate: TObjectCreateEvent read FOnObjectCreate
      write FOnObjectCreate;
    property OnObjectFree: TObjectFreeEvent read FOnObjectFree
      write FOnObjectFree;
  end;

implementation

procedure TMuObjectPool.clear;
var
  lvObj: PObjectBlock;
begin
  lock;
  try
    while FUsableList.Count > 0 do
    begin
      lvObj := PObjectBlock(FUsableList[FUsableList.Count - 1]);

      if assigned(FOnObjectFree) then
        FOnObjectFree(self, lvObj.FObject);

      if (lvObj.FObject) <> nil then
      begin
        freeandnil(lvObj.FObject);
      end;

      FreeMem(lvObj, SizeOf(TObjectBlock));
      FUsableList.Delete(FUsableList.Count - 1);
    end;
  finally
    unLock;
  end;
end;

constructor TMuObjectPool.Create(pvObjectClass: TClass = nil);
begin
  inherited Create;
  FObjectClass := pvObjectClass;

  FLocker := TCriticalSection.Create();
  FBusyList := TList.Create;
  FUsableList := TList.Create;

  // 默认可以使用5个
  FMaxNum := 5;

  // 等待超时信号灯 5 秒
  FTimeOut := 5 * 1000;

  //
  FUsableSingle := CreateEvent(nil, True, True, nil);

  // 创建信号灯,手动控制
  FReleaseSingle := CreateEvent(nil, True, True, nil);

  makeSingle;
end;

function TMuObjectPool.createObject: TObject;
begin
  Result := nil;
  if FObjectClass <> nil then
  begin
    if assigned(FOnObjectCreate) then
    begin
      FOnObjectCreate(self, Result);
    end;

    if Result = nil then
      Result := FObjectClass.Create;
  end;
end;

destructor TMuObjectPool.Destroy;
begin
  waitForReleaseSingle;
  clear;
  FLocker.Free;
  FBusyList.Free;
  FUsableList.Free;

  CloseHandle(FUsableSingle);
  CloseHandle(FReleaseSingle);
  inherited Destroy;
end;

function TMuObjectPool.getBusyCount: Integer;
begin
  Result := FBusyList.Count;
end;

{ TMuObjectPool }

procedure TMuObjectPool.releaseObject(pvObject: TObject);
var
  i: Integer;
  lvObj: PObjectBlock;
begin
  lock;
  try
    for i := 0 to FBusyList.Count - 1 do
    begin
      lvObj := PObjectBlock(FBusyList[i]);
      if lvObj.FObject = pvObject then
      begin
        FUsableList.Add(lvObj);
        lvObj.FRelaseTime := GetTickCount;
        FBusyList.Delete(i);
        Break;
      end;
    end;

    makeSingle;
  finally
    unLock;
  end;
end;

procedure TMuObjectPool.resetPool;
begin
  waitForReleaseSingle;

  clear;
end;

procedure TMuObjectPool.unLock;
begin
  FLocker.Leave;
end;

function TMuObjectPool.borrowObject: TObject;
var
  i: Integer;
  lvObj: PObjectBlock;
  lvObject: TObject;
begin
  Result := nil;

  while True do
  begin
    // 是否有可用的对象
    checkWaitForUsableSingle;
    /// /如果当前有1个可用，100线程同时借用时，都可以直接进入等待成功。

    lock;
    try
      lvObject := nil;
      if FUsableList.Count > 0 then
      begin
        lvObj := PObjectBlock(FUsableList[FUsableList.Count - 1]);
        FUsableList.Delete(FUsableList.Count - 1);
        FBusyList.Add(lvObj);
        lvObj.FBorrowTime := GetTickCount;
        lvObj.FRelaseTime := 0;
        lvObject := lvObj.FObject;
      end
      else
      begin
        if GetCount >= FMaxNum then
        begin
          // 如果当前有1个可用，100线程同时借用时，都可以直接(checkWaitForUsableSingle)成功。
          continue;
          // 退出(unLock)后再进行等待....
          // raise exception.CreateFmt('超出对象池[%s]允许的范围[%d]', [self.ClassName, FMaxNum]);
        end;
        lvObject := createObject;
        if lvObject = nil then
          raise exception.CreateFmt('不能得到对象,对象池[%s]未继承处理createObject函数',
            [self.ClassName]);

        GetMem(lvObj, SizeOf(TObjectBlock));
        try
          ZeroMemory(lvObj, SizeOf(TObjectBlock));

          lvObj.FObject := lvObject;
          lvObj.FBorrowTime := GetTickCount;
          lvObj.FRelaseTime := 0;
          FBusyList.Add(lvObj);
        except
          lvObject.Free;
          FreeMem(lvObj, SizeOf(TObjectBlock));
          raise;
        end;
      end;

      // 设置信号灯
      makeSingle;

      Result := lvObject;
      // 获取到
      Break;
    finally
      unLock;
    end;
  end;
end;

procedure TMuObjectPool.makeSingle;
begin
  if (GetCount < FMaxNum) // 还可以创建
    or (FUsableList.Count > 0) // 还有可使用的
  then
  begin
    // 设置有信号
    SetEvent(FUsableSingle);
  end
  else
  begin
    // 没有信号
    ResetEvent(FUsableSingle);
  end;

  if FBusyList.Count > 0 then
  begin
    // 没有信号
    ResetEvent(FReleaseSingle);
  end
  else
  begin
    // 全部归还有信号
    SetEvent(FReleaseSingle)
  end;
end;

function TMuObjectPool.GetCount: Integer;
begin
  Result := FUsableList.Count + FBusyList.Count;
end;

procedure TMuObjectPool.lock;
begin
  FLocker.Enter;
end;

function TMuObjectPool.waitForReleaseSingle: Boolean;
var
  lvRet: DWORD;
begin
  Result := false;
  lvRet := WaitForSingleObject(FReleaseSingle, INFINITE);
  if lvRet = WAIT_OBJECT_0 then
  begin
    Result := True;
  end;
end;

procedure TMuObjectPool.checkWaitForUsableSingle;
var
  lvRet: DWORD;
begin
  lvRet := WaitForSingleObject(FUsableSingle, FTimeOut);
  if lvRet <> WAIT_OBJECT_0 then
  begin
    raise exception.CreateFmt('对象池[%s]等待可使用对象超时(%d),使用状态[%d/%d]!',
      [FName, lvRet, getBusyCount, FMaxNum]);
  end;
end;

end.
