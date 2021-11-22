unit uFileStream;

interface

uses
  Classes, Windows, SysUtils;

const
  DW_ONEM = 1024 * 1024; // 1 M

type
  /// <summary>
  /// YXD 带缓存的文件流
  /// </summary>
  TYXDFileStream = class(TFileStream)
  private
    FCache: TMemoryStream;
    FIsRead: Boolean;
    FGetSizeing: Boolean;
    FCacheSize: Integer;
    FReadSize: Cardinal;
    FFilePosition: Int64;
    FFileSize: Int64;
    procedure InitCache;
    procedure WriteCacheToFile;
    procedure ReadToCacheFromFile();
    function GetPosition: Int64;
    procedure SetPosition(const Value: Int64);
    procedure SetCacheSize(const Value: Integer);
  protected
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(const AFileName: string; Mode: Word); overload;
    constructor Create(const AFileName: string; Mode: Word; Rights: Cardinal); overload;
    destructor Destroy; override;
    procedure RealWriteFile;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    // 缓存大小
    property CacheSize: Integer read FCacheSize write SetCacheSize;
    property Position: Int64 read GetPosition write SetPosition;
  end;

implementation

{ TYXDFileStream }

constructor TYXDFileStream.Create(const AFileName: string; Mode: Word);
begin
  inherited Create(AFileName, Mode);
  InitCache;
end;

constructor TYXDFileStream.Create(const AFileName: string; Mode: Word;
  Rights: Cardinal);
begin
  inherited Create(AFileName, Mode, Rights);
  InitCache;
end;

destructor TYXDFileStream.Destroy;
begin
  if Assigned(FCache) then begin
    WriteCacheToFile();
    FreeAndNil(FCache);
  end;
  inherited;
end;

function TYXDFileStream.GetPosition: Int64;
begin
  if FFilePosition < 0 then
    FFilePosition := inherited Position;
  Result := FFilePosition - FReadSize + FCache.Position
end;

function TYXDFileStream.GetSize: Int64;
begin
  if FFileSize > -1 then
    Result := FFileSize
  else begin
    FGetSizeing := True;
    Result := inherited GetSize;
    if not FIsRead then
      Result := Result + FCache.Position;
    FGetSizeing := False;
    FFileSize := Result;
  end;
end;

procedure TYXDFileStream.InitCache;
begin
  FCache := TMemoryStream.Create;
  FCache.Position := 0;
  FIsRead := False;
  FCacheSize := 8 * 1024 * 1024; // 默认8M缓存
  FReadSize := 0;
  FGetSizeing := False;
  FFilePosition := -1;
  FFileSize := -1;
end;

function TYXDFileStream.Read(var Buffer; Count: Longint): Longint;
var
  i: Integer;
  p: PAnsiChar;
begin
  if (not FIsRead) then begin
    WriteCacheToFile();
    FIsRead := True;
  end;
  if (FReadSize > 0) then begin
    // 已经使用过读缓存
    if (FCache.Position + Count <= FReadSize) then begin
      // 要读取的内容已经在缓存中
      Result := FCache.Read(Buffer, Count);
    end else begin
      // 要读的内容超出了缓存区域
      i := FReadSize - FCache.Position;
      if i > 0 then begin
        Result := FCache.Read(Buffer, i);
        p := @Buffer;
        Inc(p, i);
      end else begin
        Result := 0;
        p := @Buffer;
      end;
      if (Count - i) < FCacheSize then begin
        ReadToCacheFromFile();
        Result := Result + FCache.Read(p^, Count - i);
      end else begin
        Result := Result + inherited Read(p^, Count - i);
        FReadSize := 0;
        FCache.Position := 0;
      end;
    end;
  end else begin
    // 还没有使用过读缓存
    if Count < FCacheSize then begin
      // 要读取的数据大小小于缓存大小时
      // 从文件中读取最大缓存的内容
      ReadToCacheFromFile();
      // 从缓存中读取数据返回
      Result := FCache.Read(Buffer, Count);
    end else
      // 要读取的数据大小大于等于缓存大小时，不使用缓存
      Result := inherited Read(Buffer, Count);
  end;
end;

procedure TYXDFileStream.ReadToCacheFromFile();
var
  i: Int64;
begin
  if FFileSize < 0 then
    FFileSize := inherited GetSize;
  i := FFileSize - Position;
  if i > 0 then begin
    if i > FCacheSize then i := FCacheSize;
    if (FCache.Size < i) then FCache.SetSize(i);
    FReadSize := inherited Read(FCache.Memory^, i);
    if Cardinal(i) <> FReadSize then
      FCache.SetSize(FReadSize);
  end else begin
    FReadSize := 0;
    FCache.SetSize(0);
  end;
  FFilePosition := inherited Position;
  FCache.Position := 0;
end;

procedure TYXDFileStream.RealWriteFile;
begin
  WriteCacheToFile;
end;

function TYXDFileStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  if (not FGetSizeing) and ((Origin <> soCurrent) or (Offset <> 0)) then
    WriteCacheToFile();
  Result := inherited Seek(Offset, Origin);
end;

procedure TYXDFileStream.SetSize(NewSize: Integer);
begin
  WriteCacheToFile();
  inherited SetSize(NewSize);
end;

procedure TYXDFileStream.SetCacheSize(const Value: Integer);
begin
  FCacheSize := Value;
end;

procedure TYXDFileStream.SetPosition(const Value: Int64);
begin
  FFilePosition := Seek(Value, soBeginning);
end;

procedure TYXDFileStream.SetSize(const NewSize: Int64);
begin
  WriteCacheToFile();
  inherited;
end;

function TYXDFileStream.Write(const Buffer; Count: Integer): Longint;
var
  i: Integer;
begin
  if (FIsRead) then begin
    i := FReadSize - FCache.Position;
    if (i > 0) then
      Self.Position := Self.Position - i;
    FReadSize := 0;
    FCache.Position := 0; // 如果上一个操作为读，则认为没有缓存任务待写数据
    FIsRead := False;
  end;
  if FCache.Position + Count > CacheSize then begin
    WriteCacheToFile();
    if Count > CacheSize then begin
      Result := inherited Write(Buffer, Count);
      FFileSize := -1;
      Exit;
    end;
  end;
  Result := FCache.Write(Buffer, Count);
  if FFileSize > -1 then Inc(FFileSize, Result);
end;

procedure TYXDFileStream.WriteCacheToFile;
begin
  if (not FIsRead) and (FCache.Size > 0) and (FCache.Position > 0) then begin
    inherited Write(FCache.Memory^, FCache.Position);
    FFileSize := -1;
  end else
    FReadSize := 0;
  if (FCache.Position <> 0) then FCache.Position := 0;
  FFilePosition := -1;
end;

end.
