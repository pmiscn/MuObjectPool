unit Mu.CmdLink;

interface

uses
  sysutils, windows, classes, // qdb, qvalue, qjson, qrbtree,
  typinfo, Rtti, Generics.Collections;

Type

  TRttiCmd = record
    Name: String;
    // Path: String;
    Instance: TValue;
    Method: TRttiMethod;
    // Params: TArray<TRttiParameter>;
    MethodString: String;
    handle: Pointer;
  end;

  TRttiCmds = TArray<TRttiCmd>;
  // TRttiCmds = TDictionary<string, TRttiCmd>;
 

  TMuCmdLink = class
  private
    FCmds: TRttiCmds;

    FInstance: TObject;
    procedure GetObjectMethod(AInstance: TValue);
  protected

  public
    constructor create;
    destructor Destroy; override;

    function AObject(AInstance: TValue): Integer;
    function AddRecord(AInstance: TValue): Integer;
    function exec(AMethodName: String; Args: array of TValue): TValue;

    function Invoke(AInstance: TValue): TValue;
  end;

implementation

{ TMuCmdLink }
resourcestring
  SParamMissed = '参数 %s 同名的结点未找到。';
  SMethodMissed = '指定的函数 %s 不存在。';
  SParamCountError = '函数要求的参数数量是%d，而给予的参数数量是%d。';

procedure TMuCmdLink.GetObjectMethod(AInstance: TValue);
begin
end;

function TMuCmdLink.AObject(AInstance: TValue): Integer;
var
  AMethods: TArray<TRttiMethod>;
  AParams: TArray<TRttiParameter>;
  // AType: TRttiType;
  // AType: PTypeInfo;
  ARttiType: TRttiType;
  AContext: TRttiContext;
  I, c, j: Integer;

  ARttiCmd: TRttiCmd;
  AKeyName: String;
begin
  AContext := TRttiContext.create;
  {
    if AInstance.IsObject then
    ARttiType := AContext.GetType(AInstance.AsObject.ClassInfo)
    else if AInstance.IsClass then
    ARttiType := AContext.GetType(AInstance.AsClass)
    else if AInstance.Kind = tkRecord then
    ARttiType := AContext.GetType(AInstance.TypeInfo)
    else
    ARttiType := AContext.GetType(AInstance.TypeInfo);
  }
  ARttiType := AContext.GetType(AInstance.AsObject.ClassInfo);
  // AType := AInstance.TypeInfo;

  AMethods := ARttiType.GetMethods;
  c := length(AMethods);
  setlength(FCmds, c);
  for I := Low(AMethods) to High(AMethods) do
  begin
    AKeyName := AMethods[I].Name;
    // if AMethods[j].MethodKind in [mkProcedure, mkFunction] then
    // if AKeyName = 'Create' then
    // break;
    AParams := AMethods[I].GetParameters;
    FCmds[I].Name := AKeyName;
    // FCmds[I].Params := AParams;
    FCmds[I].MethodString := AMethods[I].ToString;
    FCmds[I].Method := AMethods[I];
    FCmds[I].handle := AMethods[I].handle;
    FCmds[I].Instance := AInstance;
    { 
      ARttiCmd.Instance := AInstance;
      ARttiCmd.Name := AKeyName;
      ARttiCmd.Params := AParams;
      ARttiCmd.MethodString := AMethods[i].ToString;
      ARttiCmd.Method := AMethods[i];
      ARttiCmd.handle := AMethods[i].handle;
      // FCmds.Add(AKeyName, ARttiCmd);
      FCmds.Add(ARttiCmd);
    }
  end;

end;

function TMuCmdLink.AddRecord(AInstance: TValue): Integer;
begin

end;

constructor TMuCmdLink.create();
begin
  // FCmds := TRttiCmds.create;
end;

destructor TMuCmdLink.Destroy;
begin
  // FCmds.Free;
  inherited;
end;

function TMuCmdLink.exec(AMethodName: String; Args: array of TValue): TValue;
var
  AMethod: TRttiMethod;
  AParams: TArray<TRttiParameter>;
  ACmd: TRttiCmd;

  AMethods: TArray<TRttiMethod>;
  AContext: TRttiContext;
  AInstance: TValue;
  AType: TRttiType;

  I: Integer;

begin
  // if FCmds.ContainsKey(AMethodName) then
  AContext := TRttiContext.create;
  for I := 0 to length(FCmds) - 1 do
  begin
    if FCmds[I].Name = AMethodName then
    begin
      AInstance := FCmds[I].Instance;

      AType := AContext.GetType(AInstance.AsObject.ClassInfo);

      ACmd := FCmds[I];
      // AMethod := ACmd.Method;
      AMethods := AType.GetMethods(AMethodName);
      for AMethod in AMethods do
      begin
        AParams := AMethod.GetParameters;
  //      messagebox(0, pchar(AMethod.ToString), pchar(ACmd.MethodString), 0);
        if length(Args) = length(AParams) then
        begin
          AMethod.Invoke(ACmd.Instance, Args);
          exit;
        end
        else
          raise Exception.CreateFmt(SParamCountError,
            [length(AParams), length(Args)]);
      end;
    end;
  end;

  raise Exception.CreateFmt(SMethodMissed, [AMethodName]);

end;

function TMuCmdLink.Invoke(AInstance: TValue): TValue;
var
  AMethods: TArray<TRttiMethod>;
  AParams: TArray<TRttiParameter>;
  AMethod: TRttiMethod;
  AType: TRttiType;
  AContext: TRttiContext;
  AParamValues: array of TValue;
  I, c: Integer;
begin
  AContext := TRttiContext.create;
  Result := TValue.Empty;
  if AInstance.IsObject then
    AType := AContext.GetType(AInstance.AsObject.ClassInfo)
  else if AInstance.IsClass then
    AType := AContext.GetType(AInstance.AsClass)
  else if AInstance.Kind = tkRecord then
    AType := AContext.GetType(AInstance.TypeInfo)
  else
    AType := AContext.GetType(AInstance.TypeInfo);
  {
    AMethods := AType.GetMethods(Name);
    c := Count;
    for AMethod in AMethods do
    begin
    AParams := AMethod.GetParameters;
    if Length(AParams) = c then
    begin
    SetLength(AParamValues, c);
    for I := 0 to c - 1 do
    begin
    AParamItem := ItemByName(AParams[I].Name);
    if AParamItem <> nil then
    AParamValues[I] := AParamItem.ToRttiValue
    else
    raise Exception.CreateFmt(SParamMissed, [AParams[I].Name]);
    end;
    Result := AMethod.Invoke(AInstance, AParamValues);
    Exit;
    end;
    end;
    raise Exception.CreateFmt(SMethodMissed, [Name]);
  }
end;

end.
