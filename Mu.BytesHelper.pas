unit Mu.BytesHelper;
{ ******************************************************* }
{ }
{ TBytes数组 Helper }
{ }
{ 抄的恢弘的ByteHelper }
{ }
{ ******************************************************* }

interface

uses System.SysUtils, System.Classes, System.ZLib;

type
  // zip rate
  TZipLevl = TZCompressionLevel;

  TBytesHelper = record helper for TBytes
  private

  public
    class function Empty: TBytes;
    function IsEmpty: Boolean;
    procedure Clear;

    function GetLength(): Int64;
    procedure SetLength(aValue: Int64);
    property Length: Int64 read GetLength write SetLength;
    property Size: Int64 read GetLength write SetLength;

    // 转换成字符串
    function ToString(): String;
    function TohexString: String;
    procedure FromString(aValue: String);
    property AsString: String read ToString write FromString;

    function ToChars: TCharArray;
    procedure FromChars(aValue: TCharArray);
    property AsChars: TCharArray read ToChars write FromChars;

    // 流
    function ToStream: TStream;
    procedure FromStream(Stream: TStream; const Clear: Boolean = true);

    // 压缩流/数组
    function ToZlib(const ZipLevel: TZipLevl = zcDefault): Boolean; overload;
    function ToZlib(out OutBuf: TBytes; const ZipLevel: TZipLevl = zcDefault)
      : Boolean; overload;
    // 自己压缩自己
    function UnZlib(): Boolean; overload;

    // 将字符串压缩赋值当前字节流
    function ZipFromStr(const Sources: string;
      const ZipLevel: TZipLevl = zcDefault): Boolean;
    function UnzipToStr(): string;

    function EncodeBase64(): Boolean; overload;
    // base64 转换 解密
    class function DecodeBase64(const Sources: TBytes): TBytes; overload;
    function DecodeBase64(): Boolean; overload;

    // 充文件装载
    function LoadFromFile(const FileName: string): Boolean;
    function SaveToFile(const FileName: string): Boolean;
    // 对比是否相同
    function SameValue(Data: TBytes): Boolean;
    // 追加数组  Ended 表示追加在尾部
    procedure AppendBytes(AData: TBytes; const Ended: Boolean = true);
    // 裁剪
    function SubStract(const StartIndex, Len: Int64): TBytes;
    function SubStract2(const StartIndex, EndIndex: Int64): TBytes;

    // *************以下是类方法*****************
    // Bytes数组压缩为Bytes
    class function ZipBytes(const Sources: TBytes;
      const ZipLevel: TZipLevl): TBytes;
    // 解压缩
    class function UnZipBytes(const Sources: TBytes): TBytes; overload;
    // 压缩字符串
    class function StrZipBytes(const Sources: string;
      const ZipLevel: TZipLevl = zcDefault): TBytes;
    // 讲Bytes数组解压缩位字符串
    class function Bytes2UnzipStr(const Sources: TBytes): string;
    // base64 转换 加密
    class function EncodeBase64(const Sources: TBytes): TBytes; overload;
  end;

implementation

uses System.NetEncoding;
{ TBytesHelper }

class function TBytesHelper.DecodeBase64(const Sources: TBytes): TBytes;
begin
  Result := TNetEncoding.Base64.Decode(Sources)
end;

procedure TBytesHelper.AppendBytes(AData: TBytes; const Ended: Boolean);
begin
  if Ended then
    Self := Self + AData
  else
    Self := AData + Self;
end;

procedure TBytesHelper.Clear;
begin
  System.SetLength(Self, 0);
end;

function TBytesHelper.GetLength: Int64;
begin
  Result := System.Length(Self);
end;

procedure TBytesHelper.SetLength(aValue: Int64);
begin
  System.SetLength(Self, aValue);
end;

function TBytesHelper.ToChars: TCharArray;
begin
  Result := StringOf(Self).ToCharArray;
end;

function TBytesHelper.TohexString: String;
var
  i: integer;
begin
  Result := '';
  for i := Low(Self) to High(Self) do
    Result := Result + inttohex(ord(Self[i]),1);
end;

procedure TBytesHelper.FromChars(aValue: TCharArray);
var
  l: integer;
  s: String;
begin
  l := System.Length(aValue);
  System.SetLength(aValue, l);
  Move(Self[0], PChar(s)^, sizeof(Char) * l);
  Self := bytesof(s);
end;

procedure TBytesHelper.FromString(aValue: String);
begin
  Self.Clear;
  if not aValue.IsEmpty then
  begin
    Self := bytesof(aValue);
  end;
end;

function TBytesHelper.ToString: String;
begin
  Result := '';
  if Self.Length > 0 then
  begin
    Result := StringOf(Self);
  end;
end;

function TBytesHelper.DecodeBase64: Boolean;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    Self := TNetEncoding.Base64.Decode(Self);
    Result := true;
  end;
end;

class function TBytesHelper.Empty: TBytes;
begin
  Result := [];
end;

function TBytesHelper.EncodeBase64: Boolean;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    Self := TNetEncoding.Base64.Encode(Self);
    Result := true;
  end;
end;

procedure TBytesHelper.FromStream(Stream: TStream; const Clear: Boolean);
var
  iPos: integer;
begin
  if Clear then
    System.SetLength(Self, 0);
  iPos := System.Length(Self);
  Stream.Position := 0;
  System.SetLength(Self, iPos + Stream.Size);
  Stream.ReadData(Self, iPos + Stream.Size);
end;

function TBytesHelper.UnZlib: Boolean;
var
  OutBuf: TBytes;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    ZDecompress(Self, OutBuf);
    Self := OutBuf;
    Result := true;
  end;
end;

class function TBytesHelper.Bytes2UnzipStr(const Sources: TBytes): string;
begin
  Result := '';
  if not Sources.IsEmpty then
    Result := ZDecompressStr(Sources);
end;

function TBytesHelper.ZipFromStr(const Sources: string;
  const ZipLevel: TZipLevl): Boolean;
begin
  Result := False;
  Self := [];
  if not Sources.IsEmpty then
  begin
    Self := ZCompressStr(Sources, (ZipLevel));
    Result := true;
  end;
end;

function TBytesHelper.UnzipToStr: string;
begin
  Result := '';
  if not Self.IsEmpty then
  begin
    Result := ZDecompressStr(Self);
  end;
end;

class function TBytesHelper.UnZipBytes(const Sources: TBytes): TBytes;
begin
  Result := [];
  if not Sources.IsEmpty then
  begin
    ZDecompress(Sources, Result);
  end;
end;

function TBytesHelper.IsEmpty: Boolean;
begin
  Result := System.Length(Self) = 0;
end;

function TBytesHelper.LoadFromFile(const FileName: string): Boolean;
var
  MemStream: TMemoryStream;
begin
  Result := False;
  Self.Clear;
  if FileExists(FileName) then
  begin
    MemStream := TMemoryStream.Create;
    try
      MemStream.LoadFromFile(FileName);
      MemStream.Position := 0;
      Self.SetLength(MemStream.Size);
      MemStream.ReadData(Self, Self.Length);
      Result := true;
    finally
      MemStream.Free;
    end;
  end;
end;

function TBytesHelper.SameValue(Data: TBytes): Boolean;
begin
  Result := Self.Length = Data.Length;
  if not Result then
  begin
    Result := Self.ToString.Equals(Data.ToString);
  end;
end;

function TBytesHelper.SaveToFile(const FileName: string): Boolean;
var
  MemStream: TMemoryStream;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    MemStream := TMemoryStream.Create;
    try
      MemStream.WriteData(Self, Self.Length);
      MemStream.Position := 0;
      MemStream.SaveToFile(FileName);
      Result := FileExists(FileName);
    finally
      MemStream.Free;
    end;
  end;
end;

function TBytesHelper.SubStract(const StartIndex, Len: Int64): TBytes;
begin
  Result := Copy(Self, StartIndex, Len);
end;

function TBytesHelper.SubStract2(const StartIndex, EndIndex: Int64): TBytes;
begin // 012345678       // StartIndex=2,EndIndex=7
  Result := Copy(Self, StartIndex, EndIndex - StartIndex + 1);
end;

function TBytesHelper.ToZlib(const ZipLevel: TZipLevl): Boolean;
var
  OutBuf: TBytes;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    ZCompress(Self, OutBuf, (ZipLevel));
    Self := OutBuf;
    Result := true;
  end;
end;

function TBytesHelper.ToZlib(out OutBuf: TBytes;
  const ZipLevel: TZipLevl = zcDefault): Boolean;
begin
  Result := False;
  if not Self.IsEmpty then
  begin
    ZCompress(Self, OutBuf, (ZipLevel));
    Result := true;
  end;
end;

class function TBytesHelper.ZipBytes(const Sources: TBytes;
  const ZipLevel: TZipLevl): TBytes;
begin
  Result := [];
  if not Sources.IsEmpty then
  begin
    ZCompress(Sources, Result, (ZipLevel));
  end;
end;

class function TBytesHelper.StrZipBytes(const Sources: string;
  const ZipLevel: TZipLevl): TBytes;
begin
  Result := [];
  if not Sources.IsEmpty then
  begin
    Result := ZCompressStr(Sources, (ZipLevel));
  end;
end;

class function TBytesHelper.EncodeBase64(const Sources: TBytes): TBytes;
begin
  Result := TNetEncoding.Base64.Encode(Sources)
end;

function TBytesHelper.ToStream: TStream;
begin
  Result := TMemoryStream.Create;
  Result.WriteData(Self, System.Length(Self));
end;

end.
