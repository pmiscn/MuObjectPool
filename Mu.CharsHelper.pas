unit Mu.CharsHelper;

interface

uses System.SysUtils, System.Classes, System.ZLib;

type
  TZipLevl = TZCompressionLevel;
  PCharArray = ^TCharArray;
  TChars = TCharArray;
  PChars = ^TChars;

  {
    TStringHelperEx = record helper for
    string

    public
    function SplitEx(const Separator: array of Char): TArray<string>;
    end;
  }
  TCharArrayHelper = record helper for TCharArray
  private

  public
    procedure Clear;

    function IsEmpty: boolean;
    class function Empty: TCharArray;

    function GetLength(): Int64;
    procedure SetLength(aValue: Int64);
    property Length: Int64 read GetLength write SetLength;
    property Size: Int64 read GetLength write SetLength;

    function ToString: string;
    procedure FromString(aValue: String);
    property AsString: string read ToString write FromString;

    function ToBytes: TBytes;
    procedure FromBytes(aValue: TBytes);
    property AsBytes: TBytes read ToBytes write FromBytes;

    function ToStream: TStream;
    procedure FromStream(AStream: TStream; Clear: boolean); overload;
    procedure FromStream(AStream: TStream); overload;
    property AsStream: TStream read ToStream write FromStream;

    // 压缩流/数组
    function ToZlib(const ZipLevel: TZipLevl = zcDefault): TBytes; overload;
    function ToZlib(out OutBuf: TBytes; const ZipLevel: TZipLevl = zcDefault)
      : boolean; overload;
    function FromZlib(AInput: TBytes): boolean; overload;

    // base64 转换 解密
    class function EncodeBase64(const Sources: TCharArray): TCharArray;
      overload;
    function EncodeBase64(): boolean; overload;
    class function DecodeBase64(const Sources: TCharArray): TCharArray;
      overload;
    function DecodeBase64(): boolean; overload;

    // 充文件装载
    function LoadFromFile(const FileName: string): boolean;
    function SaveToFile(const FileName: string): boolean;
    //
    function SameValue(Data: TCharArray): boolean;
    //
    procedure Append(AData: TCharArray; const Ended: boolean = true); overload;
    procedure Append(AData: String; const Ended: boolean = true); overload;
    procedure Append(AData: Char; const Ended: boolean = true); overload;

  end;

implementation

uses System.NetEncoding;

{ TCharArrayHelper }

procedure TCharArrayHelper.Clear;
begin
  system.SetLength(Self, 0);
end;

class function TCharArrayHelper.Empty: TCharArray;
begin
  Result := [];
end;

function TCharArrayHelper.IsEmpty: boolean;
begin
  Result := system.Length(Self) = 0;
end;

function TCharArrayHelper.ToString: string;
var
  l: integer;
begin
  l := system.Length(Self);
  system.SetLength(Result, l);
  Move(Self[0], PChar(Result)^, sizeof(Char) * l);
  { Result := PChar(Self); }
end;

procedure TCharArrayHelper.FromString(aValue: String);
var
  l: integer;
begin
  Self := aValue.ToCharArray();
end;

function TCharArrayHelper.ToBytes: TBytes;
var
  l: integer;
  s: String;
begin
  s := Self.ToString;
  Result := BytesOf(Self.ToString);
end;

procedure TCharArrayHelper.FromBytes(aValue: TBytes);
begin
  Self.AsString := StringOf(aValue);
end;

function TCharArrayHelper.ToStream: TStream;
begin
  Result := TMemoryStream.Create;
  Result.WriteData(Self.AsBytes, system.Length(Self));
end;

procedure TCharArrayHelper.FromStream(AStream: TStream; Clear: boolean);
var
  iPos: integer;
  aBytes: TBytes;
begin
  if Clear then
    system.SetLength(Self, 0);
  iPos := system.Length(Self);
  system.SetLength(aBytes, iPos + AStream.Size);
  AStream.Position := 0;
  AStream.ReadData(aBytes, iPos + AStream.Size);
  Self.AsBytes := aBytes;
end;

procedure TCharArrayHelper.FromStream(AStream: TStream);
begin
  Self.FromStream(AStream, true);
end;

function TCharArrayHelper.GetLength: Int64;
begin
  Result := system.Length(Self);
end;

procedure TCharArrayHelper.SetLength(aValue: Int64);
begin
  system.SetLength(Self, aValue);
end;

function TCharArrayHelper.ToZlib(out OutBuf: TBytes;
  const ZipLevel: TZipLevl = zcDefault): boolean;
var
  l: integer;
begin
  OutBuf := [];
  Result := False;
  if not Self.IsEmpty then
  begin
    ZCompress(Self.AsBytes, OutBuf, (ZipLevel));
    Result := true;
  end;
end;

function TCharArrayHelper.ToZlib(const ZipLevel: TZipLevl = zcDefault): TBytes;
begin
  Result := [];
  if not Self.IsEmpty then
  begin
    ZCompress(Self.AsBytes, Result, (ZipLevel));
  end;
end;

function TCharArrayHelper.FromZlib(AInput: TBytes): boolean;
var
  OutBuf: TBytes;
  l: integer;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    ZDecompress(AInput, OutBuf);
    Self.AsBytes := OutBuf;
    Result := true;
  end;
end;

function TCharArrayHelper.EncodeBase64(): boolean;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    Self.AsString := TNetEncoding.Base64.Encode(Self.AsString);
    Result := true;
  end;
end;

class function TCharArrayHelper.EncodeBase64(const Sources: TCharArray)
  : TCharArray;
begin
  Result.AsString := TNetEncoding.Base64.Encode(Sources.AsString);
end;

function TCharArrayHelper.DecodeBase64(): boolean;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    Self.AsString := TNetEncoding.Base64.Decode(Self.AsString);
    Result := true;
  end;
end;

class function TCharArrayHelper.DecodeBase64(const Sources: TCharArray)
  : TCharArray;
begin
  Result.AsString := TNetEncoding.Base64.Decode(Sources.AsString);
end;

function TCharArrayHelper.LoadFromFile(const FileName: string): boolean;
var
  MemStream: TMemoryStream;
  aBytes: TBytes;
begin
  Result := False;
  Self.Clear;
  if FileExists(FileName) then
  begin
    MemStream := TMemoryStream.Create;
    try
      MemStream.LoadFromFile(FileName);
      MemStream.Position := 0;
      system.SetLength(aBytes, MemStream.Size);
      MemStream.ReadData(aBytes, MemStream.Size);
      Self.AsBytes := aBytes;
      Result := true;
    finally
      MemStream.Free;
    end;
  end;
end;

function TCharArrayHelper.SaveToFile(const FileName: string): boolean;
var
  MemStream: TMemoryStream;
begin
  Result := False;
  // if not Self.IsEmpty then  //空的就不能保存了啊
  begin
    MemStream := TMemoryStream.Create;
    try
      MemStream.WriteData(Self.AsBytes, Self.Length);
      MemStream.Position := 0;
      MemStream.SaveToFile(FileName);
      Result := FileExists(FileName);
    finally
      MemStream.Free;
    end;
  end;
end;

function TCharArrayHelper.SameValue(Data: TCharArray): boolean;
begin
  Result := Self.Length = Data.Length;
  if not Result then
  begin
    Result := Self.ToString.Equals(Data.ToString);
  end;
end;

procedure TCharArrayHelper.Append(AData: TCharArray;
  const Ended: boolean = true);
begin
  if Ended then
    Self := Self + AData
  else
    Self := AData + Self;
end;

procedure TCharArrayHelper.Append(AData: String; const Ended: boolean = true);
begin
  if Ended then
    Self := Self + AData.ToCharArray()
  else
    Self := AData.ToCharArray() + Self;
end;

procedure TCharArrayHelper.Append(AData: Char; const Ended: boolean = true);
var
  ad: TCharArray;
begin
  system.SetLength(ad, 1);
  ad[0] := AData;
  Self.Append(ad, Ended);
end;

{ TStringHelperEx }
{
  function TStringHelperEx.SplitEx(const Separator: array of Char)
  : TArray<string>;
  var
  Str: string;
  Buf, Token: PChar;
  i, cnt: integer;
  sep: Char;
  begin
  cnt := 0;
  Str := Self;
  Buf := @Str[1];
  SetLength(Result, 0);

  if Assigned(Buf) then
  begin

  for sep in Separator do
  begin
  for i := 0 to Length(Self) do
  begin
  if Buf[i] = sep then
  begin
  Buf[i] := #0;
  inc(cnt);
  end;
  end;
  end;

  SetLength(Result, cnt + 1);

  Token := Buf;
  for i := 0 to cnt do
  begin
  Result[i] := StrPas(Token);
  Token := Token + Length(Token) + 1;
  end;

  end;
  end;
}
end.
