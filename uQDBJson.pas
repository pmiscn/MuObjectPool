{ ******************************************************* }
{ }
{ QJSON�����ݼ���ת }
{ }
{ ��Ȩ���� (C) 2014 ��ˮ�������� }
{ ���ߣ��ֺ� QQ11241450 }
{ QJSON��Ȩ���� QDAC��QQȺΪ:250530692 }
{ }
{ V1.0.1 - 2014.07.01 }
{ ******************************************************* }

unit uQDBJson;

interface

uses System.SysUtils, classes, System.Variants,windows, Data.DB, Qjson;

type

  TQDBJson = class
  private
    class function ISOStr2DateTime(DateStr: string): TDateTime;
    class function Variant2Bytes(V: Variant): TBytes;
    class function Bytes2Variant(Bytes: TBytes): Variant;
  public
    class constructor Create;
    // �ڴ���ת�����ַ���
    class function MemStream2Str(MemStream: TMemoryStream): string; static;
    // �ַ���ת������
    class procedure Str2MemStream(StrValue: string;
      MemStream: TMemoryStream); static;

    // json blob ת�� ��
    class function JSONToStream(const Data: TQJson): TStream; static;
    // json blob ת�� bytes����
    class function JSONToBytes(const Data: TQJson): TBytes; static;
    // ��ת��json
    class function StreamToJSON(Stream: TStream; const Offset: Integer;
      const ByteCount: Integer): TQJson; static;
    // bytes ����ת����json
    class function BytesToJSON(const Bytes: TBytes; const Offset: Integer;
      const ByteCount: Integer): TQJson; static;
    // ���ݼ�ת����json
    class function DataSet2Json(DataSet: TDataSet;
      const ShowMeata, ShowData, RowArray, StreamEncoded: Boolean;
      const PageIndex, PageSize: Integer; const ArgsFields: Array of string;
      const Included: Boolean; resultjs: TQJson): Boolean; static;
    // ������ת��json
    class function DataSetRow2Json(DataSet: TDataSet;
      const StreamEncoded: Boolean; JsonStream: TStringStream;
      BlobStream: TMemoryStream; const ArgsFields: Array of string;
      const Included: Boolean; resultjs: TQJson): Boolean; static;
    // ����¼ ��ת����json����
    class function DataSetRow2JsonArray(DataSet: TDataSet;
      const StreamEncoded: Boolean; JsonStream: TStringStream;
      BlobStream: TMemoryStream; const ArgsFields: Array of string;
      const Included: Boolean; resultjs: TQJson): Boolean; static; // array
    // json ת�����ݼ�
    class function Json2DataSet(DataSet: TDataSet; const jsonStr: string;
      DoDataSet: TProc): Integer; static;

    // У�������ʽ
    class function CheckJsonValue(const jsonValue, jsonFmt: string;
      out Info: string): Boolean; static;
    // Params ����ת����json
    class function Params2Json(Params: TParams;
      const OnlyOutput, RowArray, StreamEncoded: Boolean): TQJson; static;
  end;

implementation

uses System.StrUtils, Soap.EncdDecd, System.Math, System.DateUtils, System.Rtti;

type
  TJsonDBOpts = record
    ShowMeata, ShowData, RowArray, StreamEncoded: Boolean;
  end;

function IncrAfter(var Arg: Integer): Integer;
begin
  Result := Arg;
  Inc(Arg);
end;

class function TQDBJson.Bytes2Variant(Bytes: TBytes): Variant;
var
  p: pointer;
begin
  Result := VarArrayCreate([0, High(Bytes) - Low(Bytes)], varByte);
  p := VarArrayLock(Result);
  try
    if Length(Bytes) > 0 then
      Move(Bytes[0], p^, Length(Bytes));
  finally
    VarArrayUnlock(Result);
  end;
end;

class function TQDBJson.BytesToJSON(const Bytes: TBytes;
  const Offset, ByteCount: Integer): TQJson;
var
  i, NewByteCount: Integer;
  Value: TValue;
begin
  Result := TQJson.Create;
  if Length(Bytes) = 0 then
    Exit();

  Value := TValue.From<TBytes>(Bytes);
  Result.FromRtti(Value);
end;

class function TQDBJson.CheckJsonValue(const jsonValue, jsonFmt: string;
  out Info: string): Boolean;
var
  jsonUrlData, jsonFmtParam: TQJson;
  jsonCheckItem: TQJson;
begin
  Result := True;
  Info := '';

  if not jsonValue.IsEmpty and not jsonFmt.IsEmpty then
  begin
    // URL������ݸ�ʽ
    jsonUrlData := TQJson.Create();
    jsonFmtParam := TQJson.Create();
    try
      jsonUrlData.Parse(jsonValue);
      //

      jsonFmtParam.Parse(jsonFmt);

      for jsonCheckItem in jsonFmtParam do
      begin
        if jsonUrlData.ItemByName(jsonCheckItem.Name) = nil then
        begin
          Info := Format('ָ���� json ����������(%s)�Ҳ�����', [jsonCheckItem.Name]);
          Exit(False);
        end
        else
        begin
          // jsonUrlData.O[jsonCheckItem.Name].Self.DataType
          case jsonUrlData.ItemByName(jsonCheckItem.Name).DataType of
            // case jsonUrlData.Ancestor[jsonCheckItem.Name].DataType of
            jdtNull: // ��ֵУ��
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('NULL');
                if not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ��ֵ(NULL)��',
                    [jsonCheckItem.Name]);
              end;
            jdtBoolean: // У�� ��������
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('BOOLEAN');
                if not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ��������(Boolean)��',
                    [jsonCheckItem.Name]);
              end;
            jdtInteger: // У�� ������
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('INT');
                if not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ����(Integer)��',
                    [jsonCheckItem.Name]);
              end;
            jdtFloat: // У�� ��������
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('DOUBLE') or
                  jsonCheckItem.AsString.ToUpper.Equals('FLOAT');
                If not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ������(Double)��',
                    [jsonCheckItem.Name]);
              end;
            jdtArray:
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('ARRAY');
                If not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ��������(Array)��',
                    [jsonCheckItem.Name]);
              end;
            jdtDateTime:
              begin
                Result := jsonCheckItem.AsString.ToUpper.Equals('DATETIME');
                If not Result then
                  Info := Format('ָ���� json ����������(%s)����Ϊ����ʱ������(DATETIME)��',
                    [jsonCheckItem.Name]);
              end;
            jdtString: // У�� �ַ���
              begin
                // �ַ��������п�����������
                // if CheckDate(jsonUrlData.S[jsonCheckItem.Name]) then
                // begin
                // Result := jsonCheckItem.AsString.ToUpper.Equals('DATETIME');
                // If not Result then
                // Info := Format('ָ���� json ����������(%s)����Ϊ����ʱ������(DateTime)��',
                // [jsonCheckItem.Name]);
                // end
                // else
                if jsonUrlData.ItemByName(jsonCheckItem.Name)
                  .AsString.StartsWith('[blob]<') and
                  jsonUrlData.ItemByName(jsonCheckItem.Name)
                  .AsString.EndsWith('>') then
                begin
                  Result := jsonCheckItem.AsString.ToUpper.Equals('BLOB');
                  If not Result then
                    Info := Format('ָ���� json ����������(%s)����Ϊ BLOB ����(BLOB)��',
                      [jsonCheckItem.Name]);
                end
                else
                begin
                  Result := jsonCheckItem.AsString.ToUpper.Equals('STRING');
                  If not Result then
                    Info := Format('ָ���� json ����������(%s)����Ϊ �ַ��� ����(STRING)��',
                      [jsonCheckItem.Name]);
                end;
              end;
          end;
        end;
        if not Result then
          Break;
      end; // end of for...
    finally
      jsonUrlData.Free;
      jsonFmtParam.Free;
    end;

  end;
end;

class constructor TQDBJson.Create;
begin
  JsonCaseSensitive := False; // ��Сд������
end;

class function TQDBJson.DataSet2Json(DataSet: TDataSet;
  const ShowMeata, ShowData, RowArray, StreamEncoded: Boolean;
  const PageIndex, PageSize: Integer; const ArgsFields: Array of string;
  const Included: Boolean; resultjs: TQJson): Boolean;
// ����Ԫ���ݰ�
  function JsonValue4Field(Field: TField): TQJson;
  begin
    Result := TQJson.Create;
    Result.DataType := jdtArray;

    Result.Add.AsString := Field.FieldName;
    Result.Add.AsInteger := Ord(Field.DataType);
    Result.Add.AsInteger := Field.Size;
    Result.Add.AsBoolean := Field.Required;
    Result.Add.AsString := Field.DisplayLabel;
    Result.Add.AsString := Field.ClassName;

  end;

var
  Meta: TQJson;
  Field: TField;
  // BM: TBookmark;
  JsonStream: TStringStream;
  BlobStream: TMemoryStream;
  MoveIndex, StepIndex: Integer;
  Opts: TJsonDBOpts;
begin
  // Result := TQJson.Create;

  if not Assigned(DataSet) or not DataSet.Active then
    Exit;

  // ���Ԫ����
  if ShowMeata then
  begin
    resultjs.Add('Meta').DataType := jdtArray;
    resultjs.Add('Fields').DataType := jdtArray;

    for Field in DataSet.Fields do
    begin
      resultjs.ItemByName('Meta').Add(JsonValue4Field(Field));
      resultjs.ItemByName('Fields').Add.AsString := Field.FieldName;
    end;
  end;
{  resultjs.Add('opts').DataType := jdtObject; // ѡ��
  Opts.ShowMeata := ShowMeata;
  Opts.ShowData := ShowData;
  Opts.RowArray := RowArray;
  Opts.StreamEncoded := StreamEncoded;
  resultjs.ItemByName('opts').FromRecord<TJsonDBOpts>(Opts);
 }
  // raise Exception.Create(Result.AsJson);

  JsonStream := TStringStream.Create();
  BlobStream := TMemoryStream.Create;
  // ��ӻ�������
  DataSet.DisableControls;
  try
    // BM := DataSet.GetBookmark;
    if ShowData then
    begin
      MoveIndex := 0;
      resultjs.Add('Data').DataType := jdtArray;
      DataSet.First;
      // ��ҳ�ƶ���¼
      if (PageIndex > 0) and (PageSize > 0) then
      begin
        MoveIndex := (PageIndex - 1) * PageSize;
        DataSet.MoveBy(MoveIndex);
      end;
      StepIndex := 0;
      while not DataSet.Eof do
      begin
        // ��ǰ��
        if RowArray then
          DataSetRow2JsonArray(DataSet, StreamEncoded, JsonStream, BlobStream,
            ArgsFields, Included,resultjs.ItemByName('Data').Add())
          // resultjs.A['data'].Add(DataSetRow2JsonArray(DataSet, StreamEncoded,
          // JsonStream, BlobStream, ArgsFields, Included))
        else
          DataSetRow2Json(DataSet, StreamEncoded, JsonStream, BlobStream,
            ArgsFields, Included, resultjs.ItemByName('Data').Add());
        //
        // resultjs.A['data'].Add(DataSetRow2Json(DataSet, StreamEncoded,
        // JsonStream, BlobStream, ArgsFields, Included));

        if (PageSize > 0) then
        begin
          Inc(StepIndex);
          if StepIndex >= PageSize then
            Break
          else
          begin
            DataSet.Next;
            Continue;
          end;
        end
        else
          DataSet.Next;
      end;
    end;
    // DataSet.GotoBookmark(BM);
  finally
    JsonStream.Free;
    BlobStream.Free;
    // DataSet.FreeBookmark(BM);
    DataSet.EnableControls;
  end;
end;

class function TQDBJson.DataSetRow2Json(DataSet: TDataSet;
  const StreamEncoded: Boolean; JsonStream: TStringStream;
  BlobStream: TMemoryStream; const ArgsFields: Array of string;
  const Included: Boolean; resultjs: TQJson): Boolean;

// �ж����鷶Χ��
  function CheckArrayExists(const Args: array of string;
    const CheckName: string; const Included: Boolean): Boolean;
  var
    argsSize: Integer;
  begin
    Result := False;
    argsSize := Length(Args);
    // ������������
    Result := (Included and ((argsSize = 0) or (IndexText(CheckName,
      Args) <> -1))) or
    // ����������
      (not Included and ((argsSize = 0) or (IndexText(CheckName, Args) = -1)));
  end;

var
  Field: TField;
  ja: TQJson;
  JsonStreamCreated, BlobStreamCreated: Boolean;
begin
  // �б�Ϊ��ģʽ
  // resultjs := TQJson.Create;
  // ����Ƶ��������
  JsonStreamCreated := False;
  BlobStreamCreated := False;
  if not Assigned(JsonStream) then
  begin
    JsonStream := TStringStream.Create();
    JsonStreamCreated := True;
  end;

  if not Assigned(BlobStream) then
  begin
    BlobStream := TMemoryStream.Create;
    BlobStreamCreated := True;
  end;

  try

    for Field in DataSet.Fields do
    begin
      // �ж��ֶ��Ƿ���Ҫ����
      if not CheckArrayExists(ArgsFields, Field.FieldName, Included) then
        Continue;

      if Field.IsNull then
        resultjs.Add(Field.FieldName, null, jdtNull)
      else
      begin
        case Field.DataType of
          ftBoolean:
            resultjs.Add(Field.FieldName).AsBoolean := Field.AsBoolean;
          ftDate, ftTime, ftDateTime, ftTimeStamp:
            resultjs.Add(Field.FieldName).AsDateTime := Field.AsDateTime;
          ftInteger, ftAutoInc, ftWord, ftSmallint, ftShortint:
            resultjs.Add(Field.FieldName).AsInteger := Field.AsInteger;
          ftLargeint:
            resultjs.Add(Field.FieldName).AsInt64 := Field.AsLargeInt;
          ftFloat, ftSingle, ftBCD, ftCurrency:
            resultjs.Add(Field.FieldName).AsFloat := Field.AsFloat;
          ftString, ftWideString, ftGuid:
            resultjs.Add(Field.FieldName).AsString := Field.AsString;
          ftBlob, ftGraphic, ftMemo, ftTypedBinary:
            begin
              if not StreamEncoded then
              begin
                resultjs.ItemByName(Field.FieldName)
                  .Add(BytesToJSON(TBlobField(Field).Value, 0, 0));
              end
              else // BASE64 ������Խ�ʡ�ֽڴ�С
              begin
                JsonStream.Clear;
                BlobStream.Clear;
                TBlobField(Field).SaveToStream(BlobStream);
                // JsonStream.Position :=0;
                BlobStream.Position := 0;
                EncodeStream(BlobStream, JsonStream);
                resultjs.ItemByName(Field.FieldName).AsString := '[blob]<' +
                  JsonStream.DataString + '>';
                JsonStream.Clear;
                BlobStream.Clear;
              end;
            end;

        else
          resultjs.Add(Field.FieldName).AsString := Field.AsString;
        end;
      end;
    end;
  finally
    if Assigned(JsonStream) and JsonStreamCreated then
      JsonStream.Free;

    if Assigned(BlobStream) and BlobStreamCreated then
      BlobStream.Free;
  end;
end;

class function TQDBJson.DataSetRow2JsonArray(DataSet: TDataSet;
  const StreamEncoded: Boolean; JsonStream: TStringStream;
  BlobStream: TMemoryStream; const ArgsFields: array of string;
  const Included: Boolean; resultjs: TQJson): boolean;
// �ж����鷶Χ��
  function CheckArrayExists(const Args: array of string;
    const CheckName: string; const Included: Boolean): Boolean;
  var
    argsSize: Integer;
  begin
    Result := False;
    argsSize := Length(Args);
    // ������������
    Result := (Included and ((argsSize = 0) or (IndexText(CheckName,
      Args) <> -1))) or
    // ����������
      (not Included and ((argsSize = 0) or (IndexText(CheckName, Args) = -1)));
  end;

var
  Field: TField;
  JsonStreamCreated, BlobStreamCreated: Boolean;
begin
  // �б�Ϊ������ģʽ
  // Result := TQJson.Create;
  resultjs.DataType := jdtArray;
  // ����Ƶ��������
  JsonStreamCreated := False;
  BlobStreamCreated := False;
  if not Assigned(JsonStream) then
  begin
    JsonStream := TStringStream.Create();
    JsonStreamCreated := True;
  end;

  if not Assigned(BlobStream) then
  begin
    BlobStream := TMemoryStream.Create;
    BlobStreamCreated := True;
  end;

  try
    for Field in DataSet.Fields do
    begin
      // �ж��ֶ��Ƿ���Ҫ����
      if not CheckArrayExists(ArgsFields, Field.FieldName, Included) then
        Continue;

      if Field.IsNull then
        resultjs.Add('' ).AsString:=''
      else
      begin
        case Field.DataType of
          ftBoolean:
            resultjs.Add.AsBoolean := Field.AsBoolean;
         ftDate, ftTime, ftDateTime, ftTimeStamp, ftTimeStampOffset:
            resultjs.Add.AsDateTime := Field.AsDateTime ;
          ftInteger, ftAutoInc, ftWord, ftSmallint, ftShortint:
            resultjs.Add.AsInteger :=  Field.AsInteger;
          ftLargeint:
            resultjs.Add.AsInt64 := Field.AsLargeInt;
          ftFloat, ftSingle, ftBCD:
            resultjs.Add.AsFloat := Field.AsFloat;
          ftCurrency:
            resultjs.Add.AsFloat := Field.AsCurrency;
          ftString, ftWideString, ftGuid:
            resultjs.Add.AsString := Field.AsString;
          ftBlob, ftGraphic, ftMemo, ftTypedBinary:
            begin
              if not StreamEncoded then
              begin
                resultjs.Add(BytesToJSON(TBlobField(Field).Value, 0, 0));
              end
              else // BASE64 ������Խ�ʡ�ֽڴ�С
              begin
                JsonStream.Clear;
                BlobStream.Clear;
                TBlobField(Field).SaveToStream(BlobStream);
                // JsonStream.Position :=0;
                BlobStream.Position := 0;
                EncodeStream(BlobStream, JsonStream);
                resultjs.Add.AsString := '[blob]<' +
                  JsonStream.DataString + '>';
                JsonStream.Clear;
                BlobStream.Clear;
              end;
            end;

        else
          resultjs.Add(Field.AsString);
        end;

      end;
    end;
  finally
    if Assigned(JsonStream) and JsonStreamCreated then
      JsonStream.Free;

    if Assigned(BlobStream) and BlobStreamCreated then
      BlobStream.Free;
  end;
end;

class function TQDBJson.ISOStr2DateTime(DateStr: string): TDateTime;
var
  y, m, D, hh, mm, ss, ms: Word;
  s2: string;
  A: Integer;
  function GetNum(const sep: string): Word;
  begin
    if DateStr = '' then
      Result := 0
    else if sep = '' then
    begin
      Result := StrToInt(DateStr);
      DateStr := '';
    end
    else
    begin
      A := Pos(sep, DateStr);
      if A <= 0 then
        A := Length(DateStr) + 1;
      try
        Result := StrToInt(Copy(DateStr, 1, A - 1));
      except
        raise EConvertError.Create('Invalid DateTime format.');
      end;
      Delete(DateStr, 1, A);
      DateStr := Trim(DateStr);
    end;
  end;

begin
  try
    Result := 0;
    A := Pos('T', DateStr);
    if (A > 0) or (Pos(':', DateStr) < Low(DateStr)) then
    // date included or time not included
    begin
      if Pos('-', DateStr) > 0 then
      begin
        y := GetNum('-');
        m := GetNum('-');
        D := GetNum('T');
      end
      else
      begin
        if A > 0 then
        begin
          s2 := Copy(DateStr, 1, A - 1);
          Delete(DateStr, 1, A);
        end
        else
        begin
          s2 := DateStr;
          DateStr := '';
        end;
        if Length(s2) >= 4 then
        begin
          y := StrToInt(Copy(s2, 1, 4));
          Delete(s2, 1, 4);
        end
        else
          y := 0;
        if Length(s2) >= 2 then
        begin
          m := StrToInt(Copy(s2, 1, 2));
          Delete(s2, 1, 2);
        end
        else
          m := 0;
        if Length(s2) >= 2 then
        begin
          D := StrToInt(Copy(s2, 1, 2));
          Delete(s2, 1, 2);
        end
        else
          D := 0;
      end;

      if (y > 0) or (m > 0) or (D > 0) then
        Result := EncodeDate(y, m, D);

      if Length(s2) > 0 then
        raise EConvertError.Create('Date Part too long.');
    end;

    if Length(DateStr) > 0 then // time included
    begin
      hh := GetNum(':');
      mm := GetNum(':');
      ss := GetNum('.');
      ms := GetNum('+');
      if (hh > 0) or (mm > 0) or (ss > 0) or (ms > 0) then
        if Result >= 0 then
          Result := Result + EncodeTime(hh, mm, ss, ms)
        else
          Result := Result - EncodeTime(hh, mm, ss, ms);
    end;
  except
    on E: Exception do
      raise EConvertError.Create(E.Message + #13#10'Invalid DateTime format.');
  end;
end;

class function TQDBJson.Json2DataSet(DataSet: TDataSet; const jsonStr: string;
  DoDataSet: TProc): Integer;

  function JsonValue2Var(json: TQJson;
    JsonStream, BlobStream: TMemoryStream): Variant;
  var
    dt: TDateTime;
    JsonStreamCreated, BlobStreamCreated: Boolean;
    jsonBlobStr: string;
    Args: TBytes;
  begin
    Result := null;
    case json.DataType of
      jdtNull:
        Result := null;
      jdtBoolean:
        Result := json.AsBoolean;
      jdtInteger:
        Result := json.AsInteger;
      jdtFloat:
        Result := json.AsFloat;
      jdtDateTime:
        Result := json.AsDateTime;
      jdtString:
        begin
          if json.AsString.StartsWith('[blob]<') And json.AsString.EndsWith('>')
          then
          begin
            // ����Ƶ��������
            try
              JsonStreamCreated := False;
              BlobStreamCreated := False;
              if not Assigned(JsonStream) then // �п����� base64 ����
              begin
                JsonStream := TStringStream.Create();
                JsonStreamCreated := True;
              end;

              if not Assigned(BlobStream) then
              begin
                BlobStream := TMemoryStream.Create;
                BlobStreamCreated := True;
              end;
              JsonStream.Clear;
              BlobStream.Clear;
              // ȥ�����ͷβ
              jsonBlobStr := json.AsString.Substring(7,
                json.AsString.Length - 8);
              JsonStream.Write(jsonBlobStr[Low(jsonBlobStr)],
                Length(jsonBlobStr) * SizeOf(Char));
              JsonStream.Position := 0;

              DecodeStream(JsonStream, BlobStream);
              BlobStream.Position := 0;

              SetLength(Args, BlobStream.Size);
              BlobStream.ReadBuffer(Args, 0, BlobStream.Size);
              Result := Args;
            finally
              if Assigned(JsonStream) and JsonStreamCreated then
                JsonStream.Free;

              if Assigned(BlobStream) and BlobStreamCreated then
                BlobStream.Free;
            end;
          end
          else
            Result := json.AsString;
        end;
      jdtArray:
        begin
          // Result := TJsonHelper.JSONToBytes(json.AsArray)
          Result := TQDBJson.JSONToBytes(json)
        end;
    end;
  end;

var
  i: Integer;
  json, FieldData: TQJson;
  Meta, Data: TQJson; // ����
  Item, json2: TQJson;
  Field: TField;
  JsonStream, BlobStream: TMemoryStream;
  FldName: string;
  Opts: TJsonDBOpts;
begin
  Result := -1;
  if jsonStr.Trim.IsEmpty then
    Exit;

  JsonStream := TMemoryStream.Create;
  BlobStream := TMemoryStream.Create;
  try
    DataSet.DisableControls;
    DataSet.Close;
    DataSet.FieldDefs.Clear;

    json := TQJson.Create;
    json.Parse(jsonStr.Trim);
    // or (json.N['meta'].DataType = stNull)
    if (json.ItemByName('meta') = nil) or
      (json.ItemByName('meta').DataType <> jdtArray) then
      Exit;

    try
      Meta := json.ItemByName('meta');
      if not Assigned(Meta) or (Meta.DataType <> jdtArray) then
        raise Exception.Create('�ֶ�Ԫ��ϢΪ�ջ��Json�������ͣ�');

      for json2 in Meta do
      begin
        // json2.Items[0].AsString
        DataSet.FieldDefs.Add(json2.Items[0].AsString,
          TFieldType(json2.Items[1].AsInteger), json2.Items[2].AsInteger,
          json2.Items[3].AsBoolean);
      end;
      // DataSet.FieldDefs.Update;

      if Assigned(DoDataSet) then
        DoDataSet;

      if not DataSet.Active then
        DataSet.Open;

      Meta := json.ItemByName('field');

      Data := json.ItemByName('data');
      if json.ItemByName('opts') <> nil then
        json.ItemByName('opts').ToRtti(@Opts, TypeInfo(TJsonDBOpts));

      if not Assigned(Data) or (Data.DataType <> jdtArray) then
        Exit;

      // Data ѭ�������ݣ�����һ������
      for json2 in Data do
      begin
        FldName := '';
        // ����ģʽ
        if json2.DataType = jdtArray then
        begin
          DataSet.Append;
          i := 0;
          for Item in json2 do
          begin
            FldName := DataSet.Fields[i].FieldName;
            DataSet.Fields[i].Value := JsonValue2Var(Item, JsonStream,
              BlobStream);
            Inc(i);
          end;
          DataSet.Post;
        end // ����ģʽ
        else if json2.DataType = jdtObject then
        begin
          for Item in json2 do
          begin
            if DataSet.FindField(Item.Name) = nil then
              Continue;
            FldName := Item.Name;
            DataSet.FieldByName(Item.Name).Value :=
              JsonValue2Var(Item, JsonStream, BlobStream);
          end;
        end;
      end;
    except
      raise Exception.CreateFmt('json���ֶ�(%s)��ֵ�����ݼ������쳣��', [FldName]);
    end;

  finally
    JsonStream.Free;
    BlobStream.Free;
    if DataSet.Active then
      DataSet.First;

    json.Free;
    DataSet.EnableControls;
  end;
end;

class function TQDBJson.JSONToBytes(const Data: TQJson): TBytes;
var
  i: Integer;
  ByteVal: Integer;
  Member: TQJson;
  // Value:TValue;
begin
  SetLength(Result, 0);
  if not Assigned(Data) or (Data.DataType <> jdtArray) then
    Exit;
  SetLength(Result, Data.Count);
  // Value := Data.ToRttiValue;
  // if not Value.IsEmpty then
  // Result := Value.AsType<TBytes>;
  i := 0;
  for Member in Data do
  begin
    if (Member.DataType = jdtInteger) and (Member.AsInteger >= 0) and
      (Member.AsInteger <= 255) then
    begin
      ByteVal := Member.AsInteger;
      Result[i] := Byte(ByteVal);
    end
    else
      Result[i] := 0;

    Inc(i);
    // raise Exception.Create('Cannot convert JSON input into a stream');
  end;
end;

class function TQDBJson.JSONToStream(const Data: TQJson): TStream;
var
  Bytes: TArray<Byte>;
begin
  Result := nil;
  if Assigned(Data) and (Data.DataType = jdtArray) then
  begin
    // TSuperArray.Create(jo.Self as TJSONArray);
    Bytes := JSONToBytes(Data);
    Result := TBytesStream.Create(Bytes);
  end;
end;

class function TQDBJson.MemStream2Str(MemStream: TMemoryStream): string;
var
  StrSteam: TStringStream;
begin
  StrSteam := TStringStream.Create('', TEncoding.UTF8);
  try
    MemStream.SaveToStream(StrSteam);
    Result := StrSteam.DataString;
    // result := EncodeString(StrSteam.DataString);
  finally
    StrSteam.Free;
  end;
end;

class function TQDBJson.Params2Json(Params: TParams;
  const OnlyOutput, RowArray, StreamEncoded: Boolean): TQJson;

  procedure Var2Json(json: TQJson; const KeyName: string; const Value: Variant);
  var
    Dynarray: TArray<Variant>;
    Vaue: TValue;
  begin
    if not Assigned(json) then
      Exit;

    if json.DataType = jdtArray then
    begin
      case VarType(Value) of
        varEmpty, varNull:
          json.Add(null);
        varBoolean:
          json.Add.AsBoolean := Boolean(Value);
        varDate:
          json.Add.AsDateTime := VarToDateTime(Value);
        varSmallInt, varInteger, varShortInt, varByte, varWord, varLongWord,
          varInt64, varUInt64:
          json.Add.AsInt64 := Value;
        varSingle, varDouble, varCurrency:
          json.Add.AsFloat := Value;
        varOleStr, varString, varUString:
          json.Add.AsString := Value;
        (varByte or varArray): begin Vaue :=
          TValue.From<TBytes>(Variant2Bytes(Value));
        json.Add.FromRtti(Vaue);
        end;
        end;
        end else if json.DataType = jdtObject then begin case VarType(Value)
          of varEmpty, varNull:
          json.Add(KeyName).AsVariant := null;
        varBoolean:
          json.Add(KeyName).AsBoolean := Boolean(Value);
        varDate:
          json.Add(KeyName).AsDateTime := Value;
        // FormatDateTime('yyyy-MM-dd', VarToDateTime(Value));
        varSmallInt, varInteger, varShortInt, varByte, varWord, varLongWord,
          varInt64, varUInt64:
          json.Add(KeyName).AsInt64 := Value;
        varSingle, varDouble, varCurrency:
          json.Add(KeyName).AsFloat := Value;
        varOleStr, varString, varUString:
          json.Add(KeyName).AsString := Value;
        (varByte or varArray): begin Vaue :=
          TValue.From<TBytes>(Variant2Bytes(Value));
        json.Add(KeyName).FromRtti(Vaue);
        end;
        end;
        end;
        end;

        var i:
          Integer;
        begin
          Result := TQJson.Create();
          for i := 0 to Params.Count - 1 do
          begin
            if RowArray then
            begin
              if OnlyOutput then
              begin
                if (Params[i].ParamType in [ptOutput, ptInputOutput]) then
                  Var2Json(Result, Params[i].Name, Params[i].Value)
              end
              else
                Var2Json(Result, Params[i].Name, Params[i].Value)
            end
            else
            begin
              if OnlyOutput then
              begin
                if (Params[i].ParamType in [ptOutput, ptInputOutput]) then
                  Var2Json(Result, Params[i].Name, Params[i].Value)
              end
              else
                Var2Json(Result, Params[i].Name, Params[i].Value)
            end;
          end;
        end;

        class procedure TQDBJson.Str2MemStream(StrValue: string;
          MemStream: TMemoryStream);
        var
          StrSteam: TStringStream;
        begin
          StrSteam := TStringStream.Create(StrValue, TEncoding.UTF8);
          try
            // StrValue := DecodeString(StrValue);
            // StrSteam.Read(StrValue, length(StrValue));
            MemStream.LoadFromStream(StrSteam);
            MemStream.Position := 0;
          finally
            StrSteam.Free;
          end;
        end;

        class function TQDBJson.StreamToJSON(Stream: TStream;
          const Offset, ByteCount: Integer): TQJson;
        var
          ja: TQJson;
          Bytes: TBytes;
        begin
          Result := nil;

          if Stream = nil then
            Exit(ja);
          Stream.Position := 0;
          SetLength(Bytes, Stream.Size);
          Stream.ReadBuffer(Bytes, Stream.Size);
          Result := BytesToJSON(Bytes, Offset, ByteCount)
        end;

        class function TQDBJson.Variant2Bytes(V: Variant): TBytes;
        var
          p: pointer;
          Size: Int64;
        begin
          Size := VarArrayHighBound(V, 1) - VarArrayLowBound(V, 1) + 1;
          SetLength(Result, Size);
          p := VarArrayLock(V);
          try
            Move(p^, Result[0], Size);
          finally
            VarArrayUnlock(V);
          end;
        end;

end.
