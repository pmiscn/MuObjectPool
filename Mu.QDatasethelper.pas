unit Mu.QDatasethelper;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.TypInfo, System.Rtti, System.SyncObjs,

  qvalue, QDB, // qconverter_stds, qconverter_fdac,  qconverter_csv,
  qstring,
  qaes, Mu.CharsHelper, Mu.Varchar, {Mu.BytesHelper,}
  qsp_aes, zlib, qsp_zlib,
  DateUtils, Generics.Collections,
  Data.DB, QJSON;

resourcestring
  SMissRttiTypeDefine =
    '无法找到 %s 的RTTI类型信息，尝试将对应的类型单独定义(如array[0..1] of Byte改为TByteArr=array[0..1]，然后用TByteArr声明)。';

var
  RttiEnumAsInt: boolean = false;

  // TQDBDataset = class(TQDataset)
type

  PBytes = ^TBytes;

type
  TQUpdateExp = class;
{$IFDEF UNICODE}
  TQUpdateExps = TList<TQUpdateExp>;
{$ELSE}
  TQUpdateExps = TList;
{$ENDIF}
  PQUpdateExp = ^TQUpdateExp;
  TQUpdateOperator = (uoUnknown, uoEQ, uoIsNull, uoPlus, uoDec, uoMultiply,
    uoDivide, uoNot, uoAnd, uoOr); // , uoIsNotNull
  { }
  TQUpdateGroupOperator = (ugoUnkown, ugoAnd, ugoDone);

  { 更新条件表达式 }
  TQUpdateExp = class
  protected
    FField: TQFieldDef; // 字段索引
    FValue: TQValue; // 设置的目标值
    FValue2: TQValue; // 第二个表达式
    FIsSub: boolean;
    FDisplayFormat: QStringW; // 字段的显示格式
    FCompareOpr: TQUpdateOperator; // 只有= 这个抄的，先留着参考
    FOnCompare: TQValueCompare;
    FNextOpr: TQUpdateGroupOperator; // 下一逻辑表达式，最后一个表达式为fgoDone
    FParent: TQUpdateExp; // 父表达式
    FItems: TQUpdateExps; // 子表达式列表
    // FRegex: TPerlRegEx;
    FDataSet: TQDataSet;
    FLocker: TCriticalSection;
    FValueInQuoter: boolean;
    FValueIsFieldName: boolean;
    FValue2IsFieldName: boolean;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQUpdateExp;
  public
    constructor Create(ADataSet: TQDataSet); overload;
    destructor Destroy; override;
    function Add(AExp: TQUpdateExp): Integer; overload; // 添加一个子表达式
    function Add: TQUpdateExp; overload; // 添加一个子表达式
    procedure Clear; // 清除子表达式
    procedure Parse(const S: QStringW);
    property Count: Integer read GetCount; // 子表达式数据

    property Items[AIndex: Integer]: TQUpdateExp read GetItems; default;
    // 子表达式列表
    property Value: TQValue read FValue; // 比较的目标值
    property Value2: TQValue read FValue2;
    // function Accept(ARecord: TQRecord): Boolean;
    property CompareOpr: TQUpdateOperator read FCompareOpr;
    // 比较操作符
    property NextOpr: TQUpdateGroupOperator read FNextOpr write FNextOpr;
    // 下一逻辑操作符
    property Parent: TQUpdateExp read FParent; // 父表达式
    property Field: TQFieldDef read FField write FField; // 关联字段
    property IsSub: boolean read FIsSub; // 是否子表达式
    property ValueInQuoter: boolean read FValueInQuoter;
    property ValueIsFieldName: boolean read FValueIsFieldName;
    property Value2IsFieldName: boolean read FValue2IsFieldName;

  end;

  TQDatasetHelper = class helper for TQDataSet

  private

  public
    procedure FieldsFromRecordType<T>();
    procedure FieldsFromRecord<T>(aRecord: T);
    function AppendRecord<T>(aRecord: T): boolean;
    function AppendFromQJson(rjs: TQjson): boolean;
    function LoadFromQJson(datajs: TQjson): boolean;
    function ToRecord<T>(var aRecord: T): boolean;
    function ToJson(rjs: TQjson): boolean;

    function FromRecord<T>(aRecord: T): boolean;

    function FieldDefByName(aFieldName: String): TFieldDef;

    function Where(aWhere: String; aIsClone: boolean = false)
      : TQDataSet; overload;
    function Where(aDesc: TQDataSet; aWhere: String): TQDataSet; overload;
    function Update(aException: String): TQDataSet; overload;
    function Update(aException: String; aWhere: String): TQDataSet; overload;
    property FieldDef[aFieldName: String]: TFieldDef read FieldDefByName;

  end;

implementation

resourcestring
  SUpdateLogisticError = '更新表达式中存在无法识别的逻辑操作符 [%s]。';
  SFieldCantUpdate = '要更新的字段 [%s] 不存在或不支持革命性。';
  SUnknownUpdateOperator = '更新表达式中存在无法识别的操作符 [%s]。';
  SUpdateExpUnknown = '无效的更新表达式[%s]。';
  SUnsupportNullCompare = '不支持当前操作符与 null 进行运算。';

  { TQUpdateExp }
  {
    function TQUpdateExp.Accept(ARecord: TQRecord): Boolean;
    begin

    end;
  }

function IsNumeric(S: String): boolean;
var
  f: Extended;
begin
  result := TryStrToFloat(S, f);
end;

function IsDateTime(S: String): boolean;
var
  d: TDateTime;
begin
  result := ParseDateTime(PChar(S), d);
end;

function IsBoolean(S: String): boolean;
var
  b: boolean;
begin
  result := TryStrToBool(S, b);
end;

function TQUpdateExp.Add: TQUpdateExp;
begin
  result := TQUpdateExp.Create(FDataSet);
  Add(result);
end;

function TQUpdateExp.Add(AExp: TQUpdateExp): Integer;
begin
  AExp.FParent := Self;
  result := FItems.Add(AExp);
end;

procedure TQUpdateExp.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(FItems[I]);
  FItems.Clear;
end;

constructor TQUpdateExp.Create(ADataSet: TQDataSet);
begin
  inherited Create;
  FItems := TQUpdateExps.Create;
  FNextOpr := ugoDone;
  FDataSet := ADataSet;
  FValueInQuoter := false;
  FValueIsFieldName := false;
  FValue2IsFieldName := false;
  FIsSub := false;
end;

destructor TQUpdateExp.Destroy;
begin
  Clear;
  FreeObject(FItems);
  if Assigned(FLocker) then
    FreeObject(FLocker);
  inherited;
end;

function TQUpdateExp.GetCount: Integer;
begin
  result := FItems.Count;
end;

function TQUpdateExp.GetItems(AIndex: Integer): TQUpdateExp;
begin
  result := FItems[AIndex];
end;

procedure TQUpdateExp.Parse(const S: QStringW);
var
  p: PQCharW;
  AExp: TQUpdateExp;
  AToken, AValue: QStringW;

  procedure ParseExp(AParent: TQUpdateExp);
  const
    TokenDelimiters: PWideChar = ' '#9#13#10;
    NameValueDelimiters: PWideChar = ' =+-*/×÷!≠'#9#13#10;
    ValueDelimiters: PWideChar = '"'''' ),'#9#10#13;
    ValueListDelimiters: PWideChar = ';,'#9#10#13;
  var
    S: PQCharW;
    I, ACount: Cardinal;
    AQuoter: QCharW;
  begin
    while p^ <> #0 do
    begin
      case p^ of
        '(': // 嵌套解析开始
          begin
            Inc(p);
            SkipSpaceW(p);
            ParseExp(AExp);
          end;
        ')': // 嵌套解析结束
          begin
            Inc(p);
            SkipSpaceW(p);
            Exit;
          end
      else
        begin
          // messagebox(0, PChar(AParent.FField.Name), '', 0);
          AExp := AParent.Add;
          if (AParent <> Self) then
            FIsSub := true;
          AExp.FValueIsFieldName := false;

          S := p;
          if (p^ = '''') or (p^ = '"') then
          begin
            AToken := DecodeTokenW(p, NameValueDelimiters, p^, true);
            AExp.FValue2.AsString := AToken;
            AExp.FValue2IsFieldName := false;
          end
          else
          begin
            AToken := DecodeTokenW(p, NameValueDelimiters, QCharW(#0), true);

            AExp.FValue2IsFieldName := true;
            // 如果主表达式，必须是字段

            AExp.FField := FDataSet.FieldDefs.Find(AToken) as TQFieldDef;
            if not Assigned(AExp.FField) then
              DatabaseError(Format(SFieldCantUpdate, [AToken]));
          end;
          // messagebox(0, PChar(AToken), '', 0);
          // AExp.FOnCompare := AExp.FField.FOnCompare;
          while p > S do
          begin
            Dec(p);
            if not IsSpaceW(p) then
            begin
              while (p > S) and CharInW(p, NameValueDelimiters) do
                Dec(p);
              Inc(p);
              Break;
            end;
          end;
          SkipSpaceW(p);
          if p^ = '=' then
          begin
            AExp.FCompareOpr := uoEQ;
            Inc(p);
          end
          else if (p^ = '!') or (p^ = '≠') then
          begin
            AExp.FCompareOpr := uoNot;
            Inc(p);
          end
          else if p^ = '+' then
          begin
            AExp.FCompareOpr := uoPlus;
            Inc(p);
          end
          else if p^ = '-' then
          begin
            AExp.FCompareOpr := uoDec;
            Inc(p);
          end
          else if (p^ = '*') or (p^ = '×') then
          begin
            AExp.FCompareOpr := uoMultiply;
            Inc(p);
          end
          else if (p^ = '/') or (p^ = '÷') then
          begin
            AExp.FCompareOpr := uoDivide;
            Inc(p);
          end
          else if (p^ = '&') then
          begin
            AExp.FCompareOpr := uoAnd;
            Inc(p);
          end
          else if (p^ = '|') then
          begin
            AExp.FCompareOpr := uoOr;
            Inc(p);
          end
          else
            DatabaseError(Format(SUnknownUpdateOperator,
              [DecodeTokenW(p, ValueDelimiters, QCharW(#0), true)]));
          // 解析值
          SkipSpaceW(p);
          case p^ of
            '(': // 嵌套解析开始
              begin
                Inc(p);
                SkipSpaceW(p);
                ParseExp(AExp);
              end;
            ')': // 嵌套解析结束
              begin
                Inc(p);
                SkipSpaceW(p);
                Exit;
              end
          else
            begin
              // if (AExp.FCompareOpr in [uoEQ]) then
              begin
                if (p^ = '''') or (p^ = '"') then
                begin
                  AQuoter := p^;
                  AToken := DequotedStrW(DecodeTokenW(p, ValueDelimiters, p^,
                    true, false), AQuoter);
                  FValueInQuoter := true;
                end
                else
                begin
                  AQuoter := #0;
                  AToken := DecodeTokenW(p, ValueDelimiters, QCharW(#0),
                    true, false);
                  if AExp.FCompareOpr in [uoEQ] then
                  begin
                    if StrCmpW(PQCharW(AToken), 'null', true) = 0 then
                    begin
                      if AExp.FCompareOpr = uoEQ then
                        AExp.FCompareOpr := uoIsNull
                        // else
                        // AExp.FCompareOpr := uoIsNotNull;
                    end;
                  end;
                end;

                if (AQuoter = #0) and
                  (StrCmpW(PQCharW(AToken), 'null', true) = 0) then // =null?
                begin
                  // if AExp.FCompareOpr = uoEQ then
                  // AExp.FCompareOpr := uoIsNull
                  // else if AExp.FCompareOpr = foNotEQ then
                  // AExp.FCompareOpr := uoIsNotNull
                  // else
                  // DatabaseError(SUnsupportNullCompare);
                end
                else
                begin
                  if FValueInQuoter then
                  begin
                    AExp.FValue.TypeNeeded(AExp.Field.ValueType);
                    AExp.FValue.AsString := AToken
                  end
                  else
                  begin
                    if IsNumeric(AToken) then
                    begin
                      AExp.FValue.TypeNeeded(AExp.Field.ValueType);
                      AExp.FValue.AsString := AToken
                    end
                    else if IsBoolean(AToken) then
                    begin
                      AExp.FValue.TypeNeeded(vdtBoolean);
                      AExp.FValue.AsBoolean := strtobool(AToken);
                    end
                    else
                    begin
                      if FDataSet.FieldDefs.Find(AToken) <> nil then
                      begin
                        AExp.FValueIsFieldName := true;
                        AExp.FValue.TypeNeeded(vdtString);
                        // AExp.FValue.ValueType := vdtString;
                        AExp.FValue.AsString := AToken;
                      end
                      else
                        DatabaseError(Format(SFieldCantUpdate, [AToken]));
                    end;
                  end;
                end;
              end
              { else if (AExp.FCompareOpr in [ugoPlus, ugoDec, ugoMultiply,
                ugoDivide, ugoNot]) then
                begin
                if (p^ = '''') or (p^ = '"') then
                begin
                AQuoter := p^;
                AToken := DequotedStrW(DecodeTokenW(p, ValueDelimiters, p^,
                True, false), AQuoter);
                FValueInQuoter := True;
                end
                else
                begin
                AQuoter := #0;
                AToken := DecodeTokenW(p, ValueDelimiters, QCharW(#0),
                True, false);
                end;

                if FValueInQuoter then
                begin
                AExp.FValue.TypeNeeded(AExp.Field.ValueType);
                AExp.FValue.AsString := AToken
                end
                else
                begin
                if IsNumeric(AToken) then
                begin
                AExp.FValue.TypeNeeded(AExp.Field.ValueType);
                AExp.FValue.AsString := AToken
                end
                else if IsBoolean(AToken) then
                begin
                AExp.FValue.TypeNeeded(vdtBoolean);
                AExp.FValue.AsBoolean := strtobool(AToken);
                end
                else
                begin
                if FDataSet.FieldDefs.Find(AToken) <> nil then
                begin
                AExp.FValueIsFieldName := True;
                AExp.FValue.TypeNeeded(vdtString);
                // AExp.FValue.ValueType := vdtString;
                AExp.FValue.AsString := AToken;
                end
                else
                DatabaseError(Format(SFieldCantUpdate, [AToken]));
                end;
                end;

                end; }
            end;

          end;
        end;
        SkipSpaceW(p);
        if (p^ <> #0) { and (p^ <> ')') } then
        begin
          // 找下一个表达式
          // AToken := DecodeTokenW(p, TokenDelimiters, QCharW(#0), True);
          S := p;
          if Length(S) > 0 then
          begin
            // S := PQCharW(AToken);
            // if StrNCmpW(S, ',', True, 1) = 0 then
            if S^ = ',' then
            begin
              AExp.NextOpr := ugoAnd;
              Inc(p);
            end
            else if S^ = ')' then
            begin
              AExp.NextOpr := ugoDone;
              Exit;
            end
            else
              DatabaseError(Format(SUpdateLogisticError, [AToken]));
          end
          else
          begin
            AExp.NextOpr := ugoDone;
            Exit;
          end;
        end;
      end;
    end;
  end;

begin
  p := PQCharW(S);
  ParseExp(Self);
end;

{ TQDatasetHelper }

function TQDatasetHelper.FieldDefByName(aFieldName: String): TFieldDef;
begin
  result := Self.FieldDefs.Find(aFieldName);
end;

procedure TQDatasetHelper.FieldsFromRecord<T>(aRecord: T);
var
  AType: PTypeInfo;
  AValue: TValue;
var
  AContext: TRttiContext;
  AFields: TArray<TRttiField>;
  ARttiType: TRttiType;
  I, J: Integer;
  AObj: TObject;
  ASource: Pointer;

  aTime: TTime;
  stm: TMemoryStream;
  aNVarChar: TNVarChar;
  aVarChar: TVarChar;
  AFieldTypeName: string;
begin
  AType := (TypeInfo(T));
  ASource := @aRecord;
  AContext := TRttiContext.Create;
  ARttiType := AContext.GetType(AType);
  AFields := ARttiType.GetFields;

  for J := Low(AFields) to High(AFields) do
  begin
    if AFields[J].FieldType <> nil then
    begin
      AFieldTypeName := AFields[J].FieldType.ToString;
      AValue := AFields[J].GetValue(ASource);
      // 如果是从结构体，则记录其成员，如果是对象，则只记录其公开的属性，特殊处理TStrings和TCollection
      if (AFieldTypeName = 'TShortString') or (AFieldTypeName = 'ShortString')
      then
      begin
        Self.FieldDefs.Add(AFields[J].Name, ftString, Length(AValue.AsString));
      end
      else if AFieldTypeName = 'TNVarChar' then
      begin
        Self.FieldDefs.Add(AFields[J].Name, ftWideString,
          AValue.AsType<TNVarChar>().Size);
      end
      else if (AFieldTypeName = 'TVarChar') or
        (AFieldTypeName = 'TArray<System.Char>') then
      begin
        aVarChar := AValue.AsType<TVarChar>();
        Self.FieldDefs.Add(AFields[J].Name, ftString, Length(aVarChar));
      end
      else if AFieldTypeName = 'TVarcharMax' then
      begin
        Self.FieldDefs.Add(AFields[J].Name, ftString, 8000);
      end
      else if AFieldTypeName = 'TNVarcharMax' then
      begin
        Self.FieldDefs.Add(AFields[J].Name, ftWideString, 4000);
      end
      else if (AFieldTypeName = 'TArray<System.Byte>') or
        (AFieldTypeName = 'TBytes') then
      begin
        Self.FieldDefs.Add(AFields[J].Name, ftBlob);
      end
      else
      begin

        case AFields[J].FieldType.TypeKind of
          { tkArray:
            begin
            Self.FieldDefs.Add(AFields[J].Name, ftArray, sizeof(AFields[J].FieldType.TypeKind));
            end;
          }
          // tkString, tkWString:
{$IFNDEF NEXTGEN}tkString, tkLString, tkWString,
{$ENDIF !NEXTGEN}tkUString:
            begin
              Self.FieldDefs.Add(AFields[J].Name, ftString,
                Length(AValue.AsString));
            end;
          { tkDynArray:
            begin

            end; }
          tkInteger:
            begin
              Self.FieldDefs.Add(AFields[J].Name, ftInteger);
            end;
          tkEnumeration:
            begin
              if GetTypeData(AFields[J].FieldType.Handle)
                .BaseType^ = TypeInfo(boolean) then
                Self.FieldDefs.Add(AFields[J].Name, ftBoolean)
              else
              begin
                if RttiEnumAsInt then
                  Self.FieldDefs.Add(AFields[J].Name, ftInteger)
                else
                  Self.FieldDefs.Add(AFields[J].Name, ftString);
              end;
            end;
          tkSet:
            begin
              if RttiEnumAsInt then
                Self.FieldDefs.Add(AFields[J].Name, ftInteger)
              else
                Self.FieldDefs.Add(AFields[J].Name, ftString);
            end;
          tkChar, tkWChar:
            begin
              Self.FieldDefs.Add(AFields[J].Name, ftString, sizeof(AFields[J]));
            end;
          tkFloat:
            begin
              if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) then
                Self.FieldDefs.Add(AFields[J].Name, ftDateTime)
              else if (AFields[J].FieldType.Handle = TypeInfo(TTime)) then
                Self.FieldDefs.Add(AFields[J].Name, ftTime)
              else if (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
                Self.FieldDefs.Add(AFields[J].Name, ftDate)
              else
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftFloat);
              end;

            end;
          tkInt64:
            begin
              Self.FieldDefs.Add(AFields[J].Name, ftLargeint);
            end;
          tkVariant:
            begin
              Self.FieldDefs.Add(AFields[J].Name, ftVariant);
            end;
        end;
      end;
    end
    else
      raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
  end;
end;

procedure TQDatasetHelper.FieldsFromRecordType<T>();
var
  AType: PTypeInfo;
  AValue: TValue;
var
  AContext: TRttiContext;
  AFields: TArray<TRttiField>;
  ARttiType: TRttiType;
  I, J: Integer;
  AObj: TObject;
  AFieldTypeName: String;
begin
  Self.DisableControls;
  try
    AType := (TypeInfo(T));

    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(AType);
    AFields := ARttiType.GetFields;

    for J := Low(AFields) to High(AFields) do
    begin
      if AFields[J].FieldType <> nil then
      begin
        AFieldTypeName := AFields[J].FieldType.ToString;

        // 如果是从结构体，则记录其成员，如果是对象，则只记录其公开的属性，特殊处理TStrings和TCollection
        if (AFieldTypeName = 'TShortString') or (AFieldTypeName = 'ShortString')
        then
        begin
          Self.FieldDefs.Add(AFields[J].Name, ftString, 255);
        end
        else if AFieldTypeName = 'TNVarChar' then
        begin
          Self.FieldDefs.Add(AFields[J].Name, ftWideString, 255);
        end
        else if (AFieldTypeName = 'TVarChar') or
          (AFieldTypeName = 'TArray<System.Char>') then
        begin
          // AFields[J].FieldType.TypeSize;
          Self.FieldDefs.Add(AFields[J].Name, ftString, 255);
        end
        else if AFieldTypeName = 'TVarcharMax' then
        begin
          Self.FieldDefs.Add(AFields[J].Name, ftString, 8000);
        end
        else if AFieldTypeName = 'TNVarcharMax' then
        begin
          Self.FieldDefs.Add(AFields[J].Name, ftWideString, 4000);
        end
        else if (AFieldTypeName = 'TArray<System.Byte>') or
          (AFieldTypeName = 'TBytes') then
        begin
          Self.FieldDefs.Add(AFields[J].Name, ftBlob);
        end
        else
        begin

          case AFields[J].FieldType.TypeKind of
            { tkArray:
              begin
              Self.FieldDefs.Add(AFields[J].Name, ftArray, sizeof(AFields[J].FieldType.TypeKind));
              end;
            }
            // tkString, tkWString:
{$IFNDEF NEXTGEN}tkString, tkLString, tkWString,
{$ENDIF !NEXTGEN}tkUString:
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftString, 255);
              end;
            { tkDynArray:
              begin

              end; }
            tkInteger:
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftInteger);
              end;
            tkEnumeration:
              begin
                if GetTypeData(AFields[J].FieldType.Handle)
                  .BaseType^ = TypeInfo(boolean) then
                  Self.FieldDefs.Add(AFields[J].Name, ftBoolean)
                else
                begin
                  if RttiEnumAsInt then
                    Self.FieldDefs.Add(AFields[J].Name, ftInteger)
                  else
                    Self.FieldDefs.Add(AFields[J].Name, ftString);
                end;
              end;
            tkSet:
              begin
                if RttiEnumAsInt then
                  Self.FieldDefs.Add(AFields[J].Name, ftInteger)
                else
                  Self.FieldDefs.Add(AFields[J].Name, ftString);
              end;
            tkChar, tkWChar:
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftString,
                  sizeof(AFields[J]));
              end;
            { Add(AFields[J].Name).AsString :=
              AFields[J].GetValue(ASource).ToString; }
            { (ftUnknown, ftString, ftSmallint, ftInteger, ftWord, // 0..4
              ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, // 5..11
              ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
              ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
              ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
              ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
              ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
              ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
              ftTimeStampOffset, ftObject, ftSingle); }
            tkFloat:
              begin
                if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) then
                  Self.FieldDefs.Add(AFields[J].Name, ftDateTime)
                else if (AFields[J].FieldType.Handle = TypeInfo(TTime)) then
                  Self.FieldDefs.Add(AFields[J].Name, ftTime)
                else if (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
                  Self.FieldDefs.Add(AFields[J].Name, ftDate)
                else
                begin
                  Self.FieldDefs.Add(AFields[J].Name, ftFloat);
                end;

              end;
            tkInt64:
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftLargeint);
              end;
            tkVariant:
              begin
                Self.FieldDefs.Add(AFields[J].Name, ftVariant);
              end;
          end;
        end;
      end
      else
        raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
    end;
  finally
    Self.EnableControls;
  end;
end;

function TQDatasetHelper.FromRecord<T>(aRecord: T): boolean;
var
  AType: PTypeInfo;
  AValue: TValue;
var
  AContext: TRttiContext;
  AFields: TArray<TRttiField>;
  ARttiType: TRttiType;
  I, J: Integer;
  AObj: TObject;
  ASource: Pointer;

  aTime: TTime;
  stm: TMemoryStream;
  aNVarChar: TNVarChar;
  aVarChar: TVarChar;
  AFieldTypeName: string;
begin
  AType := (TypeInfo(T));
  ASource := @aRecord;
  AContext := TRttiContext.Create;
  ARttiType := AContext.GetType(AType);
  AFields := ARttiType.GetFields;

  if Self.RecordsetCount = 0 then
    Self.CreateDataSet;

  Self.Edit;
  for J := Low(AFields) to High(AFields) do
  begin
    if AFields[J].FieldType <> nil then
    begin
      AFieldTypeName := AFields[J].FieldType.ToString;
      if Self.Fields.FindField(AFields[J].Name) <> nil then
        with Self.FieldByName(AFields[J].Name) do
        begin

          AValue := AFields[J].GetValue(ASource);

          if AFieldTypeName = 'string' then
          begin
            AsString := AValue.AsString;
          end
          else if (AFieldTypeName = 'TShortString') or
            (AFieldTypeName = 'ShortString') then
          begin
            AsString := AValue.AsString;
          end
          else if (AFieldTypeName = 'TNVarChar') then
          begin
            aNVarChar := AValue.AsType<TNVarChar>();
            AsWideString := aNVarChar.AsString;
          end
          else if (AFieldTypeName = 'TVarChar') or
            (AFieldTypeName = 'TArray<System.Char>') then
          begin
            aVarChar := AValue.AsType<TVarChar>();
            AsString := aVarChar.AsString;
          end
          else if AFieldTypeName = 'TVarcharMax' then
          begin
            AsString := ArrayValueToStr(AValue);
          end
          else if AFieldTypeName = 'TNVarcharMax' then
          begin
            AsWideString := ArrayValueToWideStr(AValue);
          end
          else if (AFieldTypeName = 'TArray<System.Byte>') or
            (AFieldTypeName = 'TBytes') then
          begin
            stm := TMemoryStream.Create;
            try
              ByteArrayValueToStream(AValue, stm);
              stm.Position := 0;
              TBlobField(Self.FieldByName(AFields[J].Name)).LoadFromStream(stm);
            finally
              stm.Free;
            end;
            // Value := AValue.asVariant;
          end
          else
          begin
            Value := AValue.AsVariant;
          end;
        end;
    end
    else
    begin
      Self.Cancel;
      raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
    end;
  end;
  Self.Post;

end;

function TQDatasetHelper.LoadFromQJson(datajs: TQjson): boolean;
var
  rjs, js: TQjson;
  fd: TField;
  I: Integer;
  AFieldType: TFieldType;
begin
  Self.DisableControls;
  try

    Self.Empty;
    Self.FieldDefs.Clear;
    result := false;
    // 根据第一行，加入字段名
    if datajs.DataType = jdtarray then
    begin
      if datajs.Count > 0 then
        rjs := datajs[0]
      else
        Exit;
    end
    else
      rjs := datajs;


    for js in rjs do
    begin
      case js.DataType of
        jdtUnknown:
          Self.FieldDefs.Add(js.Name, ftWideString, 2000);
        jdtNull:
          Self.FieldDefs.Add(js.Name, ftWideString);
        jdtString:
          Self.FieldDefs.Add(js.Name, ftWideString, 2000);
        jdtinteger:
          begin
            Self.FieldDefs.Add(js.Name, ftFloat); // ftInteger
          end;
        jdtfloat:
          Self.FieldDefs.Add(js.Name, ftFloat);
        jdtBoolean:
          Self.FieldDefs.Add(js.Name, ftBoolean);
        jdtDateTime:
          Self.FieldDefs.Add(js.Name, ftDateTime);
        jdtarray:
          Self.FieldDefs.Add(js.Name, ftWideString, 2000);
        jdtObject:
          Self.FieldDefs.Add(js.Name, ftWideString, 2000);
      end;
    end;

    if not Self.Active then
      Open;
    for rjs in datajs do
    begin
      Self.Append;
      try
        for js in rjs do
        begin
          fd := Self.FieldByName(js.Name);
          if fd <> nil then
          begin
            case js.DataType of
              jdtUnknown:
                fd.Value := js.Value;
              jdtNull:
                fd.Value := '';
              jdtString:
                fd.AsString := js.Value;
              jdtinteger:
                fd.AsLargeInt := js.AsInt64;
              jdtfloat:
                fd.AsFloat := js.AsFloat;
              jdtBoolean:
                fd.AsBoolean := js.AsBoolean;
              jdtDateTime:
                fd.AsDateTime := js.AsDateTime;
              jdtarray:
                fd.AsString := js.AsString;
              jdtObject:
                fd.AsString := js.AsString;
            end;
          end;
        end;
        Self.Post;
      except
        Self.Cancel;
      end;
    end;

    result := true;
  finally
    Self.EnableControls;
  end;

end;

function TQDatasetHelper.AppendFromQJson(rjs: TQjson): boolean;
var
  fd: TField;
  I: Integer;
  AFieldType: TFieldType;
begin

  try
    Self.Append;
    for I := 0 to rjs.Count - 1 do
    begin
      fd := Self.FieldByName(rjs[I].Name);
      if fd <> nil then
      begin
        AFieldType := fd.DataType;
        { (ftUnknown,  , // 0..4
          , , ftBCD, ,  , , // 5..11
          , , , , , , // 12..18
          ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, , , // 19..24
          , ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
          , ftInterface, ftIDispatch,, ftFMTBcd, // 32..37
          , ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
          ,ftConnection, ftParams, ftStream, //42..48
          ftTimeStampOffset, ftObject); }

        case AFieldType of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            fd.AsString := rjs[I].AsString;
          ftSmallint, ftInteger, ftWord, ftAutoInc, ftShortint:
            fd.AsInteger := rjs[I].AsInteger;
          ftLargeint:
            fd.AsLargeInt := rjs[I].AsInt64;
          ftLongWord:
            fd.AsLongWord := rjs[I].AsInt64;
          ftBoolean:
            fd.AsBoolean := rjs[I].AsBoolean;
          ftFloat, ftExtended:
            fd.AsFloat := rjs[I].AsFloat;
          ftSingle:
            fd.AsSingle := rjs[I].AsFloat;
          ftCurrency:
            fd.AsCurrency := rjs[I].AsFloat;
          ftDate, ftTime, ftDateTime, ftTimeStamp:
            fd.AsDateTime := rjs[I].AsDateTime;
          ftGuid:
            fd.AsString := rjs[I].AsString;
          ftBytes, ftVarBytes:
            fd.AsBytes := rjs[I].AsBytes;
          ftByte:
            fd.AsInteger := rjs[I].AsInteger;
          ftVariant:
            fd.AsVariant := rjs[I].AsVariant;
          ftBlob, ftGraphic, ftTypedBinary, ftMemo, ftFmtMemo, ftWideMemo:
            begin
              TBlobField(fd).Value := rjs[I].AsBytes;
            end
        else
          fd.Value := rjs[I].AsVariant;
        end;
      end;
    end;
    Self.Post;
  except
    Self.Cancel;
  end;
end;

function TQDatasetHelper.AppendRecord<T>(aRecord: T): boolean;
var
  AType: PTypeInfo;
  AValue: TValue;
var
  AContext: TRttiContext;
  AFields: TArray<TRttiField>;
  ARttiType: TRttiType;
  I, J: Integer;
  AObj: TObject;
  ASource: Pointer;

  aTime: TTime;
  stm: TMemoryStream;
  aNVarChar: TNVarChar;
  aVarChar: TVarChar;
  AFieldTypeName: string;
begin
  AType := (TypeInfo(T));
  ASource := @aRecord;
  AContext := TRttiContext.Create;
  ARttiType := AContext.GetType(AType);
  AFields := ARttiType.GetFields;

  if Self.RecordsetCount = 0 then
    Self.CreateDataSet;

  Self.Append;
  for J := Low(AFields) to High(AFields) do
  begin
    if AFields[J].FieldType <> nil then
    begin
      AFieldTypeName := AFields[J].FieldType.ToString;
      if Self.Fields.FindField(AFields[J].Name) <> nil then
      begin
        with Self.FieldByName(AFields[J].Name) do
        begin
          AValue := AFields[J].GetValue(ASource);

          if AFieldTypeName = 'string' then
          begin
            AsString := AValue.AsString;
          end
          else if (AFieldTypeName = 'TShortString') or
            (AFieldTypeName = 'ShortString') then
          begin
            AsString := AValue.AsString;
          end
          else if (AFieldTypeName = 'TNVarChar') then
          begin
            aNVarChar := AValue.AsType<TNVarChar>();
            AsWideString := aNVarChar.AsString;
          end
          else if (AFieldTypeName = 'TVarChar') or
            (AFieldTypeName = 'TArray<System.Char>') then
          begin
            aVarChar := AValue.AsType<TVarChar>();
            AsString := aVarChar.AsString;
          end
          else if AFieldTypeName = 'TVarcharMax' then
          begin
            AsString := ArrayValueToStr(AValue);
          end
          else if AFieldTypeName = 'TNVarcharMax' then
          begin
            AsWideString := ArrayValueToWideStr(AValue);
          end
          else if (AFieldTypeName = 'TArray<System.Byte>') or
            (AFieldTypeName = 'TBytes') then
          begin
            stm := TMemoryStream.Create;
            try
              ByteArrayValueToStream(AValue, stm);
              stm.Position := 0;
              TBlobField(Self.FieldByName(AFields[J].Name)).LoadFromStream(stm);
            finally
              stm.Free;
            end;
            // Value := AValue.asVariant;
          end
          else if AFieldTypeName = 'Int64' then
          begin
            AsLargeInt := AValue.AsInt64;
          end
          else if AFieldTypeName = 'Integer' then
          begin
            AsInteger := AValue.AsInteger;
          end
          else if AFieldTypeName = 'TDateTime' then
          begin
            AsDateTime := AValue.AsExtended;
          end
          else if AFieldTypeName = 'Double' then
          begin
            AsFloat := AValue.AsExtended;
          end
          else
          begin
            Value := AValue.AsVariant;
          end;
        end;
      end;
    end
    else
    begin
      Self.Cancel;
      raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
    end;
  end;
  Self.Post;
end;

function TQDatasetHelper.ToJson(rjs: TQjson): boolean;
var
  js: TQjson;
  I: Integer;
begin
  rjs.Clear;
  rjs.DataType := jdtObject;
  for I := 0 to Self.FieldCount - 1 do
  begin

    js := rjs.Add(Fields[I].FieldName);
    case Fields[I].DataType of
      ftString, ftFixedChar, ftWideString, ftFixedWideChar:
        js.AsString := Fields[I].AsString;
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftShortint:
        js.AsInteger := Fields[I].AsInteger;
      ftLargeint:
        js.AsInt64 := Fields[I].AsLargeInt;
      ftLongWord:
        js.AsInt64 := Fields[I].AsLongWord;
      ftBoolean:
        js.AsBoolean := Fields[I].AsBoolean;
      ftFloat, ftExtended, ftSingle:
        js.AsFloat := Fields[I].AsFloat;
      ftCurrency:
        js.AsFloat := Fields[I].AsCurrency;
      ftDate, ftTime, ftDateTime, ftTimeStamp:
        js.AsDateTime := Fields[I].AsDateTime;
      ftGuid:
        js.AsString := Fields[I].AsString;
      ftBytes, ftVarBytes:
        js.AsBytes := Fields[I].AsBytes;
      ftByte:
        js.AsInteger := Fields[I].AsInteger;
      ftVariant:
        js.AsVariant := Fields[I].AsVariant;
      ftBlob, ftGraphic, ftTypedBinary, ftMemo, ftFmtMemo, ftWideMemo:
        begin
          rjs[I].AsBytes := TBlobField(Fields[I]).Value;
        end;
    end;
  end;

end;

function TQDatasetHelper.ToRecord<T>(var aRecord: T): boolean;
var
  AType: PTypeInfo;
  AValue: TValue;
var
  AContext: TRttiContext;
  AFields: TArray<TRttiField>;
  ARttiType: TRttiType;
  I, J: Integer;
  AObj: TObject;
  ABaseAddr: Pointer;
  aFieldName: String;
  AFieldTypeName: String;
  aDsField: TField;
  aTime: TTime;
  stm: TMemoryStream;

  aMaxVarchar: TVarcharMax;
  aNVarcharMax: TNVarcharMax;
  aArrayByte: TArray<byte>;
  aNVarChar: TNVarChar;
  aWs: WideString;
begin
  AType := (TypeInfo(T));

  AContext := TRttiContext.Create;
  ARttiType := AContext.GetType(AType);
  ABaseAddr := @aRecord;
  AFields := ARttiType.GetFields;
  for J := Low(AFields) to High(AFields) do
  begin
    if AFields[J].FieldType <> nil then
    begin
      aFieldName := AFields[J].Name;
      AFieldTypeName := AFields[J].FieldType.ToString;
      if Self.FindField(aFieldName) <> nil then
      begin
        aDsField := Self.FieldByName(aFieldName);
        case aDsField.DataType of
          ftInteger:
            begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsInteger);
            end;
          ftString:
            begin
              if (AFieldTypeName = 'TShortString') or
                (AFieldTypeName = 'ShortString') then
              begin
                PShortString(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                  ShortString(aDsField.AsString);
              end
              else if (AFieldTypeName = 'TVarChar') or
                (AFieldTypeName = 'TArray<System.Char>') then
              begin
                PVarChar(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                  aDsField.AsString.ToCharArray();
              end
              else if AFieldTypeName = 'TVarcharMax' then
              begin
                StrCopy(@aMaxVarchar, Pansichar(aDsField.AsAnsiString));
                PVarcharMax(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                  aMaxVarchar;
              end
              else
                case AFields[J].FieldType.TypeKind of
                  tkChar:
                    begin
                      Pansichar(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                        ansichar(aDsField.AsAnsiString[1]);
                    end;
                  tkWChar:
                    begin
                      PWideChar(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                        WideChar(aDsField.AsWideString[1]);
                    end;
{$IFNDEF NEXTGEN}
                  tkString:
                    PShortString(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                      ShortString(aDsField.AsString);
{$ENDIF !NEXTGEN}
                  tkUString{$IFNDEF NEXTGEN}, tkLString,
                    tkWString{$ENDIF !NEXTGEN}:
                    AFields[J].SetValue(ABaseAddr, aDsField.AsString);
                end;
            end;
          ftWideString:
            begin
              if (AFieldTypeName = 'TNVarChar') then
              begin
                aWs := aDsField.AsWideString;
                PNVarChar(IntPtr(ABaseAddr) + AFields[J].Offset)
                  ^.AsString := aWs;
              end
              else
                StrCopy(@aNVarcharMax, PWideChar(aDsField.AsWideString));
            end;
          ftBlob:
            begin
              if (AFieldTypeName = 'TArray<System.Byte>') or
                (AFieldTypeName = 'TBytes') then
              begin
                stm := TMemoryStream.Create;
                try
                  TBlobField(aDsField).SaveToStream(stm);
                  stm.Position := 0;
                  setlength(aArrayByte, stm.Size);
                  stm.ReadData(aArrayByte, stm.Size);
                  PBytes(IntPtr(ABaseAddr) + AFields[J].Offset)^ := aArrayByte;
                finally
                  stm.Free;
                end;
              end;
            end;
          ftBoolean:
            begin
              if GetTypeData(AFields[J].FieldType.Handle)
                ^.BaseType^ = TypeInfo(boolean) then
                AFields[J].SetValue(ABaseAddr, aDsField.AsBoolean)
            end;
          ftLargeint:
            begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsLargeInt);
            end;
          ftVariant:
            begin
              // AFields[J].SetValue(ABaseAddr, aDsField.AsVariant);
              PVariant(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                aDsField.AsVariant;
            end;
          ftDateTime:
            Begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsDateTime);
            End;
          ftDate:
            Begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsDateTime);
            End;
          ftTime:
            Begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsDateTime);
            End;
          ftFloat:
            Begin
              AFields[J].SetValue(ABaseAddr, aDsField.AsFloat);
            End;
        end;
      end;
    end;
  end;
end;

function TQDatasetHelper.Update(aException, aWhere: String): TQDataSet;
begin
  result := Self.Where(aWhere).Update(aException);
end;

function TQDatasetHelper.Update(aException: String): TQDataSet;
var
  IdxRecord, IdxColValue, IdxUpdate, IdxSub: Integer;
  QUpdateExp, AExp: TQUpdateExp;
  FieldStatusIdx: Integer;
  aQCVs: TQColumnValues;

  function setValueByItem(AParent: TQUpdateExp): TQValue;
  begin
    { uoPlus, uoDec, uoMultiply,
      uoDivide, uoNot }

  end;
  function OperaterValue(rtype: TQValueDataType; v1, v2: TQValue;
    op: TQUpdateOperator): TQValue;
  begin

    if IsNumeric(v1.AsString) and IsNumeric(v2.AsString) then
    begin
      result.TypeNeeded(rtype);

      if result.ValueType in [vdtSingle, vdtFloat, vdtInteger, vdtInt64,
        vdtCurrency] then
      begin

        case op of
          uoPlus:
            result.AsFloat := v1.AsFloat + v2.AsFloat;
          uoDec:
            result.AsFloat := v2.AsFloat - v1.AsFloat;
          uoMultiply:
            result.AsFloat := v1.AsFloat + v2.AsFloat;
          uoDivide:
            result.AsFloat := v1.AsFloat / v2.AsFloat;
        end;
      end
      else if result.ValueType = vdtString then
      begin
        case op of
          uoPlus:
            result.AsString := ((v1.AsString) + (v2.AsString));
        end;
      end
      else if result.ValueType = vdtBoolean then
      begin
        case op of
          uoNot:
            result.AsBoolean := not v1.AsBoolean;
          uoAnd:
            result.AsBoolean := v1.AsBoolean and v2.AsBoolean;
          uoOr:
            result.AsBoolean := v1.AsBoolean or v2.AsBoolean;
        end;
      end
      else if result.ValueType = vdtDateTime then
      begin
        case op of
          uoPlus:
            result.AsDateTime := v1.AsDateTime + v2.AsDateTime;
          uoDec:
            result.AsDateTime := v2.AsDateTime - v1.AsDateTime;
        end;
      end;

      { vdtUnset, vdtNull, vdtBoolean, vdtSingle, vdtFloat,
        vdtInteger, vdtInt64, vdtCurrency, vdtBcd, vdtGuid, vdtDateTime,
        vdtInterval, vdtString, vdtStream, vdtArray
      }
    end;
  end;
  function getValueFromSub(AParent: TQUpdateExp): TQValue;
  var
    v1, v2: TQValue;
  begin
    IdxSub := 0;
    with AParent[IdxSub] do
    begin
      { ugoPlus, ugoDec, ugoMultiply,
        ugoDivide, ugoNot
      }
      if ValueIsFieldName then
      begin
        v1 := aQCVs[Self.FieldDef[Value.AsString].Index].OldValue;
      end
      else
        v1 := Value;
      if Value2IsFieldName then
      begin
        v2 := aQCVs[Field.Index].OldValue;
      end
      else
        v2 := Value2;
    end;
    result := OperaterValue(aQCVs[AParent.Field.Index].OldValue.ValueType, v1,
      v2, AParent[IdxSub].CompareOpr);
  end;

begin
  QUpdateExp := TQUpdateExp.Create(Self);
  Self.ApplyChanges;
  try
    QUpdateExp.Parse(aException);

    for IdxRecord := 0 to Self.RecordCount - 1 do
    begin
      aQCVs := RealRecord(Records[IdxRecord]).Values;

      // for j := 0 to high(aQCVs) do
      for IdxUpdate := 0 to QUpdateExp.Count - 1 do // 子表达式暂时不实现
      begin
        AExp := QUpdateExp[IdxUpdate];
        if AExp.CompareOpr = uoEQ then
        begin
          if QUpdateExp[IdxUpdate].Count > 0 then
          begin
            aQCVs[AExp.Field.FieldNo - 1].OldValue.Copy
              (getValueFromSub(QUpdateExp[IdxUpdate]), true);

            // setValueByItem(QUpdateExp[IdxUpdate]);
            // 只支持一层   子 是 运算

          end
          else
          begin
            if AExp.ValueIsFieldName then
            begin
              if aQCVs[AExp.Field.FieldNo - 1].OldValue.ValueType = aQCVs
                [FieldDef[AExp.Value.AsString].FieldNo - 1].OldValue.ValueType
              then
                aQCVs[AExp.Field.FieldNo - 1].OldValue :=
                  aQCVs[FieldDef[AExp.Value.AsString].Index].OldValue
              else
              begin
                aQCVs[AExp.Field.FieldNo - 1].OldValue.AsVariant :=
                  aQCVs[Self.FieldDef[AExp.Value.AsString].FieldNo - 1]
                  .OldValue.AsVariant
              end;
            end
            else
            begin
              if AExp.Value.IsNull then
                aQCVs[AExp.Field.FieldNo - 1].OldValue.Reset
              else
              begin
                aQCVs[AExp.Field.FieldNo - 1].OldValue.TypeNeeded
                  (AExp.Field.ValueType);
                aQCVs[AExp.Field.FieldNo - 1].OldValue.Copy(AExp.Value, true);
              end;
            end;
          end;
        end
        else if AExp.CompareOpr = uoIsNull then
        begin
          aQCVs[AExp.Field.FieldNo - 1].OldValue.TypeNeeded(vdtNull);
        end;
      end;
    end;
    DataEvent(deDataSetChange, 0);
  finally
    result := Self;
    QUpdateExp.Free;
  end;
end;

function TQDatasetHelper.Where(aDesc: TQDataSet; aWhere: String): TQDataSet;
begin
  result := aDesc;
  with aDesc do
  begin
    Filtered := false;
    OnFilterRecord := nil;
    Filter := aWhere;
    Filtered := true;
  end;
end;

function TQDatasetHelper.Where(aWhere: String; aIsClone: boolean = false)
  : TQDataSet;
begin
  if aIsClone then
  begin
    result := TQDataSet.Create(Owner);
    result.Clone(Self);
  end
  else
    result := Self;

  with result do
  begin
    Filtered := false;
    OnFilterRecord := nil;
    Filter := aWhere;
    Filtered := true;
  end;
end;

end.
