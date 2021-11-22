unit Mu.Aes;

interface

uses System.SysUtils, System.Classes, windows,
  qaes, qstring, //Mu.Byteshelper, // Mu.Charshelper,

  System.ZLib;

var
  MuAesDefaultPwd: String = 'Hello' + chr(32) + 'Amu'#13#10;

type
  TMuAesOptions = record
    Key: String;
    CBCOrECB: Boolean; // True:AsCBC false:AsECB
    InitVector: String; // TQAESBuffer;
    KeyType: TQAESKeyType; // kt128  kt192 kt256
  end;

type
  TMuAes = Record

    FQAES: TQAES;
    AesOptions: TMuAesOptions;
    // FMuAesOptions: TMuAesOptions;

  public
    procedure Init();

    procedure Encrypt(ASource, ADest: TStream); overload;
    procedure Encrypt(const p: Pointer; len: Integer;
      var AResult: TBytes); overload;
    procedure Encrypt(const AData: TBytes; var AResult: TBytes); overload;
    procedure Encrypt(const AData: QStringW; var AResult: TBytes); overload;
    function Encrypt(const AData: QStringW): QStringW; overload;
    procedure Encrypt(const ASourceFile, ADestFile: QStringW); overload;

    procedure Decrypt(ASource, ADest: TStream); overload;
    procedure Decrypt(const AData: TBytes; var AResult: TBytes); overload;
    function Decrypt(const AData: TBytes): String; overload;
    function Decrypt(const S: String): String; overload;
    procedure Decrypt(const ASourceFile, ADestFile: QStringW); overload;

    procedure LoadFromFile(afn: String; aStm: TStream); overload;
    procedure LoadFromFile(afn: String; aSt: TStrings); overload;
    function LoadFromFile(afn: String): String; overload;

    procedure SaveToFile(afn: String; aStm: TStream); overload;
    procedure SaveToFile(afn: String; aSt: TStrings); overload;
    procedure SaveToFile(afn: String; S: String); overload;

    // property AesOptions: TMuAesOptions read FAesOptions write FAesOptions;
  end;

var
  MuAesOptions: TMuAesOptions;
  PubMuAES: TMuAes;
  MuAES: TMuAes;
  PubQAES: TQAES;

procedure InitEncrypt(var Aes: TQAES);

implementation

uses System.NetEncoding;

resourcestring
  SBadStream = '无效的加密数据流';

type
  { AES异常类 }
  EAESError = class(Exception);

  { TMuAes }
procedure InitEncrypt(var Aes: TQAES);
var
  QAESBuffer: TQAESBuffer;
begin
  with MuAesOptions do
  begin
    fillchar(QAESBuffer, length(QAESBuffer), #0);
    Move(InitVector[1], QAESBuffer[0], length(InitVector));
    // QAESBuffer := bytesof(InitVector);
    if not CBCOrECB then
      Aes.AsECB(Key, KeyType)
    else
      Aes.AsCBC(QAESBuffer, Key, KeyType);
  end;
end;

procedure TMuAes.Decrypt(ASource, ADest: TStream);
begin
  // InitEncrypt(FQAES);
  FQAES.Decrypt(ASource, ADest);
end;

procedure TMuAes.Decrypt(const ASourceFile, ADestFile: QStringW);
begin
  // InitEncrypt(FQAES);
  FQAES.Decrypt(ASourceFile, ADestFile);
end;

procedure TMuAes.Decrypt(const AData: TBytes; var AResult: TBytes);
begin
  // InitEncrypt(FQAES);
  FQAES.Decrypt(AData, AResult);
end;

function TMuAes.Decrypt(const S: String): String;
begin
  // InitEncrypt(FQAES);
  result := FQAES.Decrypt(S);
end;

function TMuAes.Decrypt(const AData: TBytes): String;
begin
  // InitEncrypt(FQAES);
  result := FQAES.Decrypt(AData);
end;

procedure TMuAes.Encrypt(const AData: TBytes; var AResult: TBytes);
begin
  // InitEncrypt(FQAES);
  FQAES.Encrypt(AData, AResult);
end;

procedure TMuAes.Encrypt(const p: Pointer; len: Integer; var AResult: TBytes);
begin
  // InitEncrypt(FQAES);
  FQAES.Encrypt(p, len, AResult);
end;

procedure TMuAes.Encrypt(ASource, ADest: TStream);
begin
  // InitEncrypt(FQAES);
  FQAES.Encrypt(ASource, ADest);
end;

procedure TMuAes.Encrypt(const ASourceFile, ADestFile: QStringW);
begin
  // InitEncrypt(FQAES);
  FQAES.Encrypt(ASourceFile, ADestFile);
end;

function TMuAes.Encrypt(const AData: QStringW): QStringW;
begin
  // InitEncrypt(FQAES);
  result := FQAES.Encrypt(AData);
end;

procedure TMuAes.Encrypt(const AData: QStringW; var AResult: TBytes);
begin
  // InitEncrypt(FQAES);
  FQAES.Encrypt(AData, AResult);
end;

procedure TMuAes.Init();
var
  QAESBuffer: TQAESBuffer;
begin
  with AesOptions do
  begin
    fillchar(QAESBuffer, length(QAESBuffer), #0);
    Move(InitVector[1], QAESBuffer[0], length(InitVector));
    // QAESBuffer := bytesof(InitVector);
    if not CBCOrECB then
      FQAES.AsECB(Key, KeyType)
    else
      FQAES.AsCBC(QAESBuffer, Key, KeyType);
  end;
end;

function TMuAes.LoadFromFile(afn: String): String;
var
  aStm: TStringStream;
begin
  try
    aStm := TStringStream.Create;
    LoadFromFile(afn, aStm);
    aStm.Position := 0;
    result := aStm.DataString;
  finally
    aStm.Free;
  end;
end;

procedure TMuAes.LoadFromFile(afn: String; aSt: TStrings);
var
  aStm: TMemoryStream;
begin
  try
    aStm := TMemoryStream.Create;
    LoadFromFile(afn, aStm);
    aStm.Position := 0;
    aSt.LoadFromStream(aStm);
  finally
    aStm.Free;
  end;
end;

procedure TMuAes.LoadFromFile(afn: String; aStm: TStream);
var
  sourceStm: TMemoryStream;
begin
  sourceStm := TMemoryStream.Create;
  try
    if not assigned(aStm) then
      aStm := TMemoryStream.Create;
    sourceStm.LoadFromFile(afn);
    if sourceStm.Size = 0 then
      exit;
    sourceStm.Position := 0;
    try
      FQAES.Decrypt(sourceStm, aStm);
    except
      on e: Exception do
        if e.Message = SBadStream then
        begin
          sourceStm.Position := 0;
          TMemoryStream(aStm).LoadFromStream(sourceStm);
        end
        else
          raise EAESError.Create(SBadStream);
    end;
    if (aStm.Size = 0) then
    begin
      raise EAESError.Create(SBadStream);
    end;
    aStm.Position := 0;
  finally
    sourceStm.Free;
  end;
end;

procedure TMuAes.SaveToFile(afn, S: String);
var
  aStm: TStringStream;
begin
  try
    aStm := TStringStream.Create;
    aStm.WriteString(S);

    aStm.Position := 0;

    SaveToFile(afn, aStm);
  finally
    aStm.Free;
  end;
end;

procedure TMuAes.SaveToFile(afn: String; aSt: TStrings);
var
  DestStm, aStm: TMemoryStream;
begin
  DestStm := TMemoryStream.Create;
  aStm := TMemoryStream.Create;
  try
    aSt.SaveToStream(aStm);
    self.FQAES.Encrypt(aStm, DestStm);

    DestStm.SaveToFile(afn);
  finally
    DestStm.Free;
    aStm.Free;
  end;
end;

procedure TMuAes.SaveToFile(afn: String; aStm: TStream);
var
  DestStm: TMemoryStream;
begin
  DestStm := TMemoryStream.Create;
  try

    aStm.Position := 0;

    self.FQAES.Encrypt(aStm, DestStm);

    DestStm.Position := 0;
    DestStm.SaveToFile(afn);
  finally
    DestStm.Free;
  end;
end;

initialization

MuAesOptions.InitVector := '青岛庞城';
// MuAesOptions.InitVector := 'pangcheng.comamu';

MuAesOptions.Key := MuAesDefaultPwd;
MuAesOptions.CBCOrECB := true;
MuAesOptions.KeyType := kt256;

MuAesOptions.Key := MuAesOptions.InitVector;
MuAesOptions.Key := MuAesOptions.Key + ' AMU' + #9 + '' + #13#10#32;
MuAesOptions.Key := MuAesOptions.Key + 'QDB' + chr(32) + 'By pangcheng.com';

with PubMuAES.AesOptions do
begin
  Key := MuAesOptions.Key;
  CBCOrECB := MuAesOptions.CBCOrECB;
  InitVector := MuAesOptions.InitVector;
  KeyType := MuAesOptions.KeyType;
end;
PubMuAES.Init();

MuAES := PubMuAES;

InitEncrypt(PubQAES);

end.

