unit Mu.Varchar;

interface

uses System.SysUtils, System.Classes, System.TypInfo, System.Rtti,
  Mu.CharsHelper;

type
  TShortString = string[255];
  TShortWideString = String[255];

  TVarcharMax = array [0 .. 7999] of ansichar;
  TNVarcharMax = array [0 .. 3999] of WideChar;
  PVarcharMax = ^TVarcharMax;
  PNVarcharMax = ^TNVarcharMax;

  {
    TVarchar10 = string[10];
    TVarchar20 = string[20];
    TVarchar30 = string[30];
    TVarchar40 = string[40];
    TVarchar50 = string[50];
    TVarchar100 = string[100];
    TVarchar200 = string[200];
  }

  PVarChar = ^TVarChar;
  TVarChar = TCharArray; // AnsiChar

  // TNVarChar = array of WideChar; // TArray<WideChar>;

  PNVarChar = ^TNVarChar;

  TNVarChar = Record
    Data: array of WideChar;
  public
    function ToString(): WideString;
    procedure FromString(AValue: WideString);
    function GetSize(): Integer;
    procedure SetSize(AValue: Integer);
    property AsString: WideString read ToString write FromString;
    property Size: Integer read GetSize write SetSize;
  end;

function ArrayValueToStr(aV: TValue): String;
function ArrayValueToWideStr(aV: TValue): WideString;
function ByteArrayValueToStream(aV: TValue; stm: TMemoryStream): Integer;

implementation

function ArrayValueToStr(aV: TValue): String;
var
  i, l: Integer;
  avc: TVarChar;
begin
  result := '';
  l := aV.GetArrayLength;
  result := '';
  for i := 0 to l - 1 do
  begin
    result := result + aV.GetArrayElement(i).AsString;
  end;
end;

function ArrayValueToWideStr(aV: TValue): WideString;
var
  i, l: Integer;
begin
  result := '';
  l := aV.GetArrayLength;
  for i := 0 to l - 1 do
  begin
    result := result + aV.GetArrayElement(i).AsString;
  end;
end;

function ByteArrayValueToStream(aV: TValue; stm: TMemoryStream): Integer;
var
  i, l: Integer;
var
  abyteArray: TArray<byte>;
  s: String;
begin
  // stm.Size := aV.DataSize;
  stm.Clear;

  l := aV.GetArrayLength;
  setlength(abyteArray, l);
  aV.ExtractRawData(@abyteArray);
  result := stm.WriteData(abyteArray, l);

  // s := StringOf(abyteArray);

end;

{ TNVarchar }

procedure TNVarChar.FromString(AValue: WideString);
begin
  setlength(Data, Length(AValue));
  move(AValue[1], Data[0], sizeof(WideChar) * Length(AValue));
end;

function TNVarChar.GetSize: Integer;
begin
  result := Length(Data);
end;

procedure TNVarChar.SetSize(AValue: Integer);
begin
  setlength(Data, AValue);
end;

function TNVarChar.ToString: WideString;
begin
  setlength(result, Length(Data));
  move(Data[0], result[1], sizeof(WideChar) * Length(Data));
end;

end.
