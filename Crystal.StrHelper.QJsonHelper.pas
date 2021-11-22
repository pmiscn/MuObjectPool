unit Crystal.StrHelper.QJsonHelper;
// unit Maxwell.QJsonHelper;

{ ******************************************************* }
{ }
{ QJSON的增强功能，类似Superobject的写法 }
{ 引入了日期类型，Bytes,blobs类型 }
{ 版权所有 (C) 2014 碧水航工作室 }
{ 作者：恢弘 QQ ：41450 }
{ QJSON版权属于 QDAC作者， }
{ 版权归 swish(QQ:109867294) 官方QQ群为:250530692 }
{ }
{ V1.0.1 - 2014.07.15 }
{
  mod by:黑夜杀手 2015.8.20
  1、去除恢弘版的几个警告提示。。。
  2、重写并加入音儿小白的两个函数parseObjectByName和parseStringByName
  (本来想打补丁的，但改了两次发现改的不对，自己水平太菜了。。。只能按自己的思路重写)
  ，增加可控项：KeyOrdIndex:即第几次找到为准默认为1。
  5、代码只在XE8中小测
}
{ ******************************************************* }
interface

uses System.SysUtils, System.Variants, System.Math, System.NetEncoding, qjson,
  qstring;

type
  // 扩展的数据类型
  // sdtBytes 在QJSON存储成2位的十六进制编码
  // sdtBlobs 压缩成base64的编码，体积减少更明显
  TSuperDataType = (sdtUnknown, sdtNull, sdtString, sdtInteger, sdtFloat,
    sdtBoolean, sdtDateTime,
    sdtArray, sdtObject, sdtBytes, sdtBlobs);

  TQJsonHelper = class helper for TQJson
  private
    function GetAsArray(KeyName: string): TQJson;
    function GetAsBlobs(KeyName: string): TBytes;
    function GetAsBoolean(KeyName: string): Boolean;
    function GetAsBytes(KeyName: string): TBytes;
    function GetAsDateTime(KeyName: string): TDateTime;
    function GetAsFloat(KeyName: string): Double;
    function GetAsInt(KeyName: string): Int64;
    function GetAsObject(KeyName: string): TQJson;
    function GetAsString(KeyName: string): string;
    function GetAsSuperDataType(KeyName: string): TSuperDataType;
    procedure SetAsArray(KeyName: string; const Value: TQJson);
    procedure SetAsBlobs(KeyName: string; const Value: TBytes);
    procedure SetAsBoolean(KeyName: string; const Value: Boolean);
    procedure SetAsBytes(KeyName: string; const Value: TBytes);
    procedure SetAsDateTime(KeyName: string; const Value: TDateTime);
    procedure SetAsFloat(KeyName: string; const Value: Double);
    procedure SetAsInt(KeyName: string; const Value: Int64);
    procedure SetAsObject(KeyName: string; const Value: TQJson);
    procedure SetAsString(KeyName: string; const Value: string);

  public
    constructor Create(const JsonStr: string); overload;
    property S[KeyName: string]: string read GetAsString write SetAsString;
    property I[KeyName: string]: Int64 read GetAsInt write SetAsInt;
    property F[KeyName: string]: Double read GetAsFloat write SetAsFloat;
    property B[KeyName: string]: Boolean read GetAsBoolean write SetAsBoolean;
    property O[KeyName: string]: TQJson read GetAsObject write SetAsObject;
    property A[KeyName: string]: TQJson read GetAsArray write SetAsArray;
    property D[KeyName: string]: TDateTime read GetAsDateTime
      write SetAsDateTime;
    // 普通的bytes数组模式，十六进制存储
    property Bytes[KeyName: string]: TBytes read GetAsBytes write SetAsBytes;
    // 存储Base64压缩，存储成字符串格式
    property Blobs[KeyName: string]: TBytes read GetAsBlobs write SetAsBlobs;
    // 压缩和加密
    // write SetAsSuperDataType
    property SuperDataType[KeyName: string]: TSuperDataType
      read GetAsSuperDataType;
    // 获取节点类型

    // property N[KeyName:string]:v  read GetAsNull write SetAsNull;
    // 节点如果存在，，则不创建，不存在则创建
    function AddItem(const AName: string;
      const ADataType: TQJsonDataType): TQJson;

    // RTTI类型转换
    // 从记录类型转换成json或json字符串
    class function JsonFromRecord<T: record >(ARec: T): TQJson;
    class function JsonStrFromRecord<T: record >(ARec: T;
      const Formated, Encoded: Boolean): string;
    // 从对象类型转换成json或json字符串
    class function JsonFromObject<T: class>(AObj: T): TQJson;
    class function JsonStrFromObject<T: class>(AObj: T;
      const Formated, Encoded: Boolean): string;

    // 将json转换成记录
    function JsonToRecord<T: record >: T; overload;
    // 将json字符串转换成记录
    class function JsonToRecord<T: record >(const JsonStr: string): T; overload;
    class procedure JsonToRtti<T>(ADest: Pointer; const JsonStr: string);
    // 将json字符串转换成对象类型
    class procedure JsonToObject<T: class>(AObj: T; const JsonStr: string);
    /// <summary>
    /// 获取 name-value的数组模式
    /// </summary>
    /// <param name="JsonStr"></param>
    /// <returns></returns>
    class function GetNameValues(const JsonStr: string)
      : TArray<Variant>; overload;

    class function GetNameValues(Json: TQJson): TArray<Variant>; overload;
    // 是否存在节点
    function Contains(KeyName: string): Boolean;

    // 将变体数组转换成json对象字符串
    class function VarArray2JsonStr(const Values: array of Variant;
      const Encoded: Boolean): string;

    // 将变体数组转换成json对象字符串
    class function VarArray2Json(const Values: array of Variant): TQJson;

    class function VarArrayT2JsonStr<T>(const Values: TArray<T>;
      const Encoded: Boolean): string;

    // 将 namevalue 数组模式转换成json字符串
    class function NameValues2JsonStr(const NameValues: array of Variant;
      const Encoded: Boolean): string;

    // 将 namevalue 数组模式转换成json对象
    class function NameValues2Json(const NameValues: array of Variant): TQJson;
    // 将数组转换成变体数组
    class function JsonArray2VarArray(JsonArray: TQJson;
      const OnlySimpleData: Boolean): TArray<Variant>; overload;
    class function JsonArray2VarArray(JsonArrayStr: string;
      const OnlySimpleData: Boolean): TArray<Variant>; overload;

    class function JsonArray2StrArray(JsonArray: TQJson;
      const OnlySimpleData: Boolean): TArray<string>; overload;
    class function JsonArray2StrArray(JsonArrayStr: string;
      const OnlySimpleData: Boolean): TArray<string>; overload;

    // 获取json值
    class function GetValue(const JsonStr, NodeName: string;
      const DataType: TQJsonDataType;
      const DeftValue: Variant): Variant;
    class function GetValues(const JsonStr: string;
      const NodeNames: array of string)
      : TArray<Variant>;
    // 将开放数组的字符串，赋值给泛型字符串数组
    class function GetTArray_String(const Sources: array of string)
      : TArray<string>;
    class function ParseValue(ABuilder: TQStringCatHelperW;
      var p: PQCharW): Variant;
    class function parseObjectByName(const JsonStr, KeyName: QStringW;
      Value: Variant; KeyOrdIndex: Integer = 1): TQJson;
    class function parseStringByName(const JsonStr, KeyName: QStringW;
      KeyOrdIndex: Integer = 1): QStringW;
  end;

implementation

uses Soap.EncdDecd, System.TypInfo, System.Rtti;

{ TQJsonHelper }

function TQJsonHelper.AddItem(const AName: string;
  const ADataType: TQJsonDataType): TQJson;
begin
  Result := ItemByName(AName);
  if Result = nil then
    Result := Add(AName, ADataType);
end;

function TQJsonHelper.Contains(KeyName: string): Boolean;
begin
  Result := ItemByName(KeyName) <> nil;
end;

constructor TQJsonHelper.Create(const JsonStr: string);
begin
  inherited Create();
  if JsonStr <> '' then
    Parse(JsonStr)
end;

function TQJsonHelper.GetAsArray(KeyName: string): TQJson;
begin
  Result := nil;
  if (ItemByName(KeyName) <> nil) and (ItemByName(KeyName).DataType = jdtArray)
  then
    Result := ItemByName(KeyName);
end;

function TQJsonHelper.GetAsBlobs(KeyName: string): TBytes;
var
  jsonBlobStr: string;
begin
  SetLength(Result, 0);
  if SuperDataType[KeyName] = sdtBlobs then
  begin
    if KeyName.IsEmpty then // 数组节点
      jsonBlobStr := AsString
    else
      jsonBlobStr := S[KeyName];
    // 去掉标记头尾
    jsonBlobStr := jsonBlobStr.Substring(8, jsonBlobStr.Length - 9);
    if jsonBlobStr <> '' then
    begin
      Result := DecodeBase64(AnsiString(jsonBlobStr));
    end;
  end;
end;

function TQJsonHelper.GetAsBoolean(KeyName: string): Boolean;
begin
  if KeyName.IsEmpty and (DataType = jdtBoolean) then
    Result := AsBoolean
  else
    if (ItemByName(KeyName) <> nil) and
      (ItemByName(KeyName).DataType = jdtBoolean) then
      Result := ItemByName(KeyName).AsBoolean
    else
      Result := False;
end;

function TQJsonHelper.GetAsBytes(KeyName: string): TBytes;
var
  sBytes: QStringW;
begin
  if SuperDataType[KeyName] = sdtBytes then
  begin
    if KeyName.IsEmpty then // 数组节点
      sBytes := AsString
    else
      sBytes := S[KeyName];
    Result := HexToBin(StrDupX(PQCharW(sBytes) + 8, Length(sBytes) - 9));
  end
  else
    SetLength(Result, 0);
end;

function TQJsonHelper.GetAsDateTime(KeyName: string): TDateTime;
begin
  Result := 0.00;
  if (ItemByName(KeyName) <> nil) then
  begin
    if (ItemByName(KeyName).DataType = jdtDateTime) or
      (ItemByName(KeyName).IsDateTime) then
      Result := ItemByName(KeyName).AsDateTime
  end
  else
    if KeyName.IsEmpty and IsDateTime then
      Result := AsDateTime
    else
      Result := 0.00;
end;

function TQJsonHelper.GetAsFloat(KeyName: string): Double;
begin
  if (ItemByName(KeyName) <> nil) then
    // and (ItemByName(KeyName).DataType = jdtFloat)
    Result := ItemByName(KeyName).AsFloat
  else
    if KeyName.IsEmpty then
      Result := AsFloat
    else
      Result := 0.00;
end;

function TQJsonHelper.GetAsInt(KeyName: string): Int64;
begin
  if (ItemByName(KeyName) <> nil) then
    // (ItemByName(KeyName).DataType = jdtInteger) then
    Result := ItemByName(KeyName).AsInt64
  else
    if KeyName.IsEmpty then
      Result := AsInt64
    else
      Result := 0;
end;

function TQJsonHelper.GetAsObject(KeyName: string): TQJson;
begin
  Result := nil;
  if (ItemByName(KeyName) <> nil) and (ItemByName(KeyName).DataType = jdtObject)
  then
    Result := ItemByName(KeyName)
  else
    if KeyName.IsEmpty then
      Result := Self
end;

function TQJsonHelper.GetAsString(KeyName: string): string;
begin
  if (ItemByName(KeyName) <> nil) then
    Result := ItemByName(KeyName).AsString
  else
    if KeyName.IsEmpty then
      Result := AsString
    else
      Result := '';
end;

function TQJsonHelper.GetAsSuperDataType(KeyName: string): TSuperDataType;
var
  Item: TQJson;
begin
  Item := nil;
  Result := sdtUnknown;
  if not KeyName.IsEmpty and Contains(KeyName) then
    Item := ItemByName(KeyName)
  else
    if KeyName.IsEmpty then
      Item := Self;

  if Assigned(Item) then
  begin
    case Item.DataType of
      jdtUnknown:
        Result := sdtUnknown;
      jdtObject:
        Result := sdtObject;
      jdtBoolean:
        Result := sdtBoolean;
      jdtInteger:
        Result := sdtInteger;
      jdtFloat:
        Result := sdtFloat;
      jdtNull:
        Result := sdtNull;
      jdtArray:
        Result := sdtArray;
      jdtString:
        begin
          if Item.IsDateTime then
            Result := sdtDateTime
          else
            if Item.AsString.StartsWith('[blobs]<') and
              Item.AsString.EndsWith('>') then
              Result := sdtBlobs
            else
              if Item.AsString.StartsWith('[bytes]<') and
                Item.AsString.EndsWith('>') then
                Result := sdtBytes
              else
                Result := sdtString;
        end;
    end;
  end;
end;

class function TQJsonHelper.GetNameValues(Json: TQJson): TArray<Variant>;
var
  json2: TQJson;
  I: Integer;
begin
  I := 0;
  SetLength(Result, 0);
  if Json.Count > 0 then
    SetLength(Result, Json.Count * 2);
  for json2 in Json do
  begin
    if json2.Name <> '' then
    begin
      Result[I] := json2.Name;
      Inc(I);
      Result[I] := json2.AsVariant;
      Inc(I);
    end
    else
    begin
      Result[I] := json2.AsVariant;
      Inc(I);
    end;
  end;
  SetLength(Result, I);
end;

class function TQJsonHelper.GetTArray_String(const Sources: array of string)
  : TArray<string>;
begin
  SetLength(Result, Length(Sources));
  if Length(Sources) > 0 then
    Move(Sources[0], Result[0], Length(Sources) * sizeOf(string));
end;

class function TQJsonHelper.GetValue(const JsonStr, NodeName: string;
  const DataType: TQJsonDataType; const DeftValue: Variant): Variant;
var
  Json: TQJson;
  idx: Integer;
begin
  Result := DeftValue;
  Json := TQJson.Create();
  try
    if Json.TryParse(JsonStr) then
    begin
      Json.Parse(JsonStr);
      idx := Json.IndexOf(NodeName);
      if (idx <> -1) and ((DataType = jdtUnknown) or
        (Json.Items[idx].DataType = DataType)) then
      begin
        VarClear(Result);
        if (DataType = jdtObject) or (DataType = jdtArray) then
          Result := Json.Items[idx].Encode(False, True)
        else
          Result := Json.Items[idx].Value;
      end;
    end;
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.GetValues(const JsonStr: string;
  const NodeNames: array of string)
  : TArray<Variant>;
var
  Json: TQJson;
  I, ArrayIdx, idx: Integer;
begin
  SetLength(Result, 0);
  Json := TQJson.Create();
  try
    if Json.TryParse(JsonStr) then
    begin
      Json.Parse(JsonStr);
      ArrayIdx := 0;
      SetLength(Result, Length(NodeNames));
      for I := Low(NodeNames) to High(NodeNames) do
      begin
        idx := Json.IndexOf(NodeNames[I]);
        if (idx <> -1) then
        begin
          Result[ArrayIdx] := Json.Items[idx].Value;
          Inc(ArrayIdx);
        end;
      end;
      SetLength(Result, ArrayIdx);
    end;
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.GetNameValues(const JsonStr: string)
  : TArray<Variant>;
var
  Json: TQJson;
  // I: Integer;
begin
  SetLength(Result, 0);
  Json := TQJson.Create();
  try
    if JsonStr.StartsWith('{') and JsonStr.EndsWith('}') then
      Json.Parse(JsonStr);

    Result := GetNameValues(Json);
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.JsonArray2VarArray(JsonArray: TQJson;
  const OnlySimpleData: Boolean): TArray<Variant>;
var
  Json: TQJson;
  I: Integer;
begin
  SetLength(Result, 0);
  if JsonArray.DataType <> jdtArray then
    Exit;

  Result := nil;
  I := 0;
  SetLength(Result, JsonArray.Count);
  for Json in JsonArray do
  begin
    case Json.SuperDataType[''] of
      sdtNull:
        begin
          Result[I] := null;
          Inc(I);
        end;
      sdtDateTime:
        begin
          Result[I] := Json.AsDateTime;
          Inc(I);
        end;
      sdtBoolean:
        begin
          Result[I] := Json.AsBoolean;
          Inc(I);
        end;
      sdtInteger:
        begin
          Result[I] := Json.AsInt64;
          Inc(I);
        end;
      sdtFloat:
        begin
          Result[I] := Json.AsFloat;
          Inc(I);
        end;
      sdtBytes:
        begin
          Result[I] := Json.Bytes[''];
          Inc(I);
        end;
      sdtBlobs:
        begin
          Result[I] := Json.Blobs[''];
          Inc(I);
        end;
      sdtString:
        begin
          Result[I] := Json.AsString;
          Inc(I);
        end;
      sdtObject:
        begin
          if not OnlySimpleData then
          begin
            Result[I] := Json.AsString;
            Inc(I);
          end;
        end;
      sdtArray:
        begin
          if not OnlySimpleData then
          begin
            Result[I] := Json.AsString;
            Inc(I);
          end;
        end;
    end;
  end;
  SetLength(Result, I);
end;

class function TQJsonHelper.JsonArray2StrArray(JsonArray: TQJson;
  const OnlySimpleData: Boolean): TArray<string>;
var
  Json: TQJson;
  I: Integer;
begin
  SetLength(Result, 0);
  if JsonArray.DataType <> jdtArray then
    Exit;

  Result := nil;
  I := 0;
  SetLength(Result, JsonArray.Count);
  for Json in JsonArray do
  begin
    case Json.SuperDataType[''] of
      sdtNull:
        begin
          Result[I] := '';
          Inc(I);
        end;
      sdtDateTime:
        begin
          Result[I] := Json.AsString;
          Inc(I);
        end;
      sdtBoolean:
        begin
          Result[I] := Json.AsBoolean.ToString;
          Inc(I);
        end;
      sdtInteger:
        begin
          Result[I] := Json.AsInt64.ToString;
          Inc(I);
        end;
      sdtFloat:
        begin
          Result[I] := Json.AsFloat.ToString;
          Inc(I);
        end;
      sdtBytes:
        begin // 起始标记   [bytes]<XXXXX>
          Result[I] := Json.AsString.Substring(7, Json.AsString.Length - 8);
          Inc(I);
        end;
      sdtBlobs:
        begin
          Result[I] := Json.AsString.Substring(7, Json.AsString.Length - 8);
          Inc(I);
        end;
      sdtString:
        begin
          Result[I] := Json.AsString;
          Inc(I);
        end;
      sdtObject:
        begin
          if not OnlySimpleData then
          begin
            Result[I] := Json.AsString;
            Inc(I);
          end;
        end;
      sdtArray:
        begin
          if not OnlySimpleData then
          begin
            Result[I] := Json.AsString;
            Inc(I);
          end;
        end;
    end;
  end;
  SetLength(Result, I);
end;

class function TQJsonHelper.JsonArray2StrArray(JsonArrayStr: string;
  const OnlySimpleData: Boolean): TArray<string>;
var
  Json: TQJson;
begin
  SetLength(Result, 0);
  if JsonArrayStr.StartsWith('[') and JsonArrayStr.EndsWith(']') then
  begin
    Json := TQJson.Create(JsonArrayStr);
    try
      JsonArray2StrArray(Json, OnlySimpleData);
    finally
      Json.Free;
    end;
  end;
end;

class function TQJsonHelper.JsonArray2VarArray(JsonArrayStr: string;
  const OnlySimpleData: Boolean): TArray<Variant>;
var
  Json: TQJson;
begin
  SetLength(Result, 0);
  if JsonArrayStr.StartsWith('[') and JsonArrayStr.EndsWith(']') then
  begin
    Json := TQJson.Create(JsonArrayStr);
    try
      JsonArray2VarArray(Json, OnlySimpleData);
    finally
      Json.Free;
    end;
  end;
end;

class function TQJsonHelper.JsonFromObject<T>(AObj: T): TQJson;
begin
  Result := TQJson.Create;
  Result.FromRtti(@Self, TypeInfo(T));
end;

class function TQJsonHelper.JsonFromRecord<T>(ARec: T): TQJson;
begin
  Result := TQJson.Create;
  Result.FromRecord<T>(ARec);
end;

class function TQJsonHelper.JsonStrFromObject<T>(AObj: T;
  const Formated, Encoded: Boolean): string;
begin
  with JsonFromObject<T>(AObj) do
    try
      if Encoded then
        Result := Encode(Formated, Encoded)
      else
        Result := AsJson;
    finally
      Free;
    end;
end;

class function TQJsonHelper.JsonStrFromRecord<T>(ARec: T;
  const Formated, Encoded: Boolean): string;
begin
  with JsonFromRecord<T>(ARec) do
    try
      if Encoded then
        Result := Encode(Formated, Encoded)
      else
        Result := AsJson;
    finally
      Free;
    end;
end;

class procedure TQJsonHelper.JsonToObject<T>(AObj: T; const JsonStr: string);
var
  Json: TQJson;
begin
  Json := TQJson.Create(JsonStr);
  try
    Json.ToRtti(@AObj, TypeInfo(T));
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.JsonToRecord<T>(const JsonStr: string): T;
var
  Json: TQJson;
begin
  Json := TQJson.Create(JsonStr);
  try
    Result := Json.JsonToRecord<T>;
  finally
    Json.Free;
  end;
end;

class procedure TQJsonHelper.JsonToRtti<T>(ADest: Pointer;
  const JsonStr: string);
var
  Json: TQJson;
begin
  Json := TQJson.Create(JsonStr);
  try
    Json.ToRtti(ADest, TypeInfo(T));
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.NameValues2Json(const NameValues
  : array of Variant): TQJson;
var
  I: Integer;
  PName: string;
begin
  Result := TQJson.Create;
  for I := 0 to (High(NameValues) + 1) div 2 - 1 do
  begin
    if VarIsStr(NameValues[I * 2]) then
      PName := NameValues[I * 2]
    else
      raise Exception.CreateFmt('第%d个参数的数据类型(参数名)必须为字符串类型！', [I * 2]);
    Result.Add(PName).AsVariant := NameValues[I * 2 + 1];
  end;
end;

class function TQJsonHelper.NameValues2JsonStr(const NameValues
  : array of Variant;
  const Encoded: Boolean): string;
var
  // I: Integer;
  // PName: string;
  Json: TQJson;
begin
  Result := '';
  Json := nil;
  try
    Json := NameValues2Json(NameValues);
    if Encoded then
      Result := Json.Encode(False, True)
    else
      Result := Json.AsJson;
  finally
    Json.Free;
  end;
end;

function TQJsonHelper.JsonToRecord<T>: T;
begin
  ToRtti(@Result, TypeInfo(T));
end;

procedure TQJsonHelper.SetAsArray(KeyName: string; const Value: TQJson);
begin
  if KeyName.IsEmpty then
    Add(Value)
  else
    AddItem(KeyName, jdtArray).Add(Value);
end;

procedure TQJsonHelper.SetAsBlobs(KeyName: string; const Value: TBytes);
begin
  if KeyName.IsEmpty then
    AsString := '[blobs]<' + string(EncodeBase64(Value, Length(Value))) + '>'
  else
    AddItem(KeyName, jdtString).AsString :=
      '[blobs]<' + string(EncodeBase64(Value, Length(Value))) + '>';
end;

procedure TQJsonHelper.SetAsBoolean(KeyName: string; const Value: Boolean);
begin
  if KeyName.IsEmpty then
    Add.AsBoolean := Value
  else
    AddItem(KeyName, jdtBoolean).AsBoolean := Value;
end;

procedure TQJsonHelper.SetAsBytes(KeyName: string; const Value: TBytes);
// var
// AChild: TQJson;
begin
  if KeyName.IsEmpty then
    AsString := '[bytes]<' + qstring.BinToHex(@Value[0], Length(Value)) + '>'
  else
    AddItem(KeyName, jdtString).AsString :=
      '[bytes]<' + qstring.BinToHex(@Value[0], Length(Value)) + '>';
end;

procedure TQJsonHelper.SetAsDateTime(KeyName: string; const Value: TDateTime);
begin
  if KeyName.IsEmpty then
    Add.AsDateTime := Value
  else
    AddItem(KeyName, jdtDateTime).AsDateTime := Value;
end;

procedure TQJsonHelper.SetAsFloat(KeyName: string; const Value: Double);
begin
  if KeyName.IsEmpty then
    Add.AsFloat := Value
  else
    AddItem(KeyName, jdtFloat).AsFloat := Value;
end;

procedure TQJsonHelper.SetAsInt(KeyName: string; const Value: Int64);
begin
  if KeyName.IsEmpty then
    Add.AsInt64 := Value
  else
    AddItem(KeyName, jdtInteger).AsInt64 := Value;
end;

procedure TQJsonHelper.SetAsObject(KeyName: string; const Value: TQJson);
begin
  if KeyName.IsEmpty then
    Add(Value)
  else
    AddItem(KeyName, jdtObject).Add(Value);
end;

procedure TQJsonHelper.SetAsString(KeyName: string; const Value: string);
begin
  if KeyName.IsEmpty then
    Add.AsString := Value
  else
    AddItem(KeyName, jdtString).AsString := Value;
end;

class function TQJsonHelper.VarArray2Json(const Values
  : array of Variant): TQJson;
var
  I: Integer;
begin
  Result := TQJson.Create();
  Result.DataType := jdtArray;
  for I := Low(Values) to High(Values) do
  begin
    Result.Add.AsVariant := Values[I];
  end;

end;

class function TQJsonHelper.VarArray2JsonStr(const Values: array of Variant;
  const Encoded: Boolean): string;
var
  Json: TQJson;
begin
  Result := '';
  Json := nil;
  try
    Json := VarArray2Json(Values);
    if Encoded then
      Result := Json.Encode(False, True)
    else
      Result := Json.AsJson;
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.VarArrayT2JsonStr<T>(const Values: TArray<T>;
  const Encoded: Boolean): string;
var
  Json: TQJson;
  I: Integer;
  Value: TValue;
begin
  Result := '';

  Json := TQJson.Create();
  try
    Json.DataType := jdtArray;
    for I := Low(Values) to High(Values) do
    begin
      Value := TValue.From<T>(Values[I]);
      Json.Add.FromRtti(Value);
    end;

    if Encoded then
      Result := Json.Encode(False, True)
    else
      Result := Json.AsJson;
  finally
    Json.Free;
  end;
end;

class function TQJsonHelper.ParseValue(ABuilder: TQStringCatHelperW;
  var p: PQCharW): Variant;
var
  ANum: Extended;
begin
  try
    if (p^ = '"') or (p^ = '''') then
    begin

      BuildJsonString(ABuilder, p);
      Result := ABuilder.Value;
    end
    else
      if ParseNumeric(p, ANum) then
      begin // 数字？
        if SameValue(ANum, Trunc(ANum)) then
          Result := Trunc(ANum)
        else
          Result := ANum;
      end
      else
        if StartWithW(p, 'False', True) then
        begin // False
          Inc(p, 5);
          Result := False;
        end
        else
          if StartWithW(p, 'True', True) then
          begin // True
            Inc(p, 4);
            Result := True;
          end
          else
            if StartWithW(p, 'NULL', True) then
            begin // Null
              Inc(p, 4);
              Result := varNull;
            end
            else
              Result := varEmpty;
  except
    on E: Exception do
  end;
end;

class function TQJsonHelper.parseObjectByName(const JsonStr, KeyName: QStringW;
  Value: Variant; KeyOrdIndex: Integer = 1): TQJson;
var
  ABuilder: TQStringCatHelperW;
  p, p1, p2, p3: PQCharW;
  c1, c2: QCharW;
  PrevKH, LastKH: PQCharW;
  nocmpValue: Boolean;
  TryTimes: Integer;
begin
  Result := nil;
  p2 := nil;
  if Length(KeyName) = 0 then
    Exit;
  p := PQCharW(JsonStr);
  nocmpValue := VarIsEmpty(Value) or VarIsNull(Value);
  ABuilder := TQStringCatHelperW.Create;
  try
    try
      p1 := p;
      TryTimes := 1;
      while p1^ <> #0 do // :"bbb"}
      begin
        p2 := StrPos(p1, PQCharW(KeyName)) - 1;
        if (p2 = nil) then
          Exit;
        p3 := p2 + Length(KeyName) + 1;
        c1 := p2^;
        c2 := p3^;
        if ((c1 = '"') or (c1 = '''')) and (c2 = c1) then
        begin
          if nocmpValue then
          begin
            if (TryTimes = KeyOrdIndex) then
              Break
            else
            begin
              Inc(TryTimes);
              p1 := p3;
              Continue;
            end;
          end
          else
          begin
            Inc(p3);
            SkipSpaceW(p3);
            if p3^ <> ':' then
              Exit;
            Inc(p3);
            SkipSpaceW(p3);
            if ParseValue(ABuilder, p3) = Value then
            begin
              if (TryTimes = KeyOrdIndex) then
                Break
              else
              begin
                Inc(TryTimes);
                p1 := p3;
                Continue;
              end;
            end
            else
            begin
              if (p3^ = '}') or (p3^ = #0) then
                Exit;
            end;
          end;
        end
        else
        begin
          p1 := p3;
        end;
      end;
      PrevKH := PQCharW(StringOfChar(#0, p2 - p));
      StrLCopy(PrevKH, PQCharW(JsonStr), p2 - p);
      PrevKH := StrRScan(PrevKH, '{');
      p3 := StrScan(p2, '}');
      LastKH := PQCharW(StringOfChar(#0, p3 - p2 + 1));
      StrLCopy(LastKH, p2, p3 - p2 + 1);
      Result := TQJson.Create(QStringW(PrevKH) + QStringW(LastKH));
    except
      FreeAndNil(Result);
    end;
  finally
    ABuilder.Free;
  end;
end;

class function TQJsonHelper.parseStringByName(const JsonStr,
  KeyName: QStringW; KeyOrdIndex: Integer = 1): QStringW;
var
  Json: TQJson;
begin
  Json := parseObjectByName(JsonStr, KeyName, null, KeyOrdIndex);
  if Assigned(Json) then
  begin  
    Result := Json.GetAsString(KeyName);  
    FreeAndNil(Json);  
  end
  else
    Result := '';
end;

end.
