{*******************************************************}
{                                                       }
{       YxdInclude ���û�������                         }
{                                                       }
{       ��Ȩ���� (C) 2013      YangYxd                  }
{                                                       }
{*******************************************************}

unit YxdStr;

interface

// �Ƿ�ʹ��URL����
{$DEFINE USE_URLFUNC}
// �Ƿ�ʹ���ַ�������ת������
{$DEFINE USE_STRENCODEFUNC}

//Delphi XE
{$IF (RTLVersion>=26)}
{$DEFINE USE_UNICODE}
{$IFEND}

//�Ƿ�ʹ��Inline
{$DEFINE INLINE}

{$IF (RTLVersion>=26) and (not Defined(NEXTGEN))}
{$DEFINE ANSISTRINGS}
{$IFEND}

uses
  {$IFNDEF UNICODE}Windows, {$ELSE} {$IFDEF MSWINDOWS}Windows, {$ENDIF}{$ENDIF}
  {$IFDEF ANSISTRINGS}AnsiStrings, {$ENDIF}
  {$IFDEF POSIX}Posix.String_, {$ENDIF}
  {$IFDEF USE_URLFUNC}StrUtils, Math, {$ENDIF}
  SysUtils, SysConst, Classes, Variants;

type
  {$IFDEF NEXTGEN}
  AnsiChar = Byte;
  PAnsiChar = ^AnsiChar;
  WideString = UnicodeString;
  AnsiString = record
  private
    FValue:TBytes;
    function GetChars(AIndex: Integer): AnsiChar;
    procedure SetChars(AIndex: Integer; const Value: AnsiChar);
    function GetLength:Integer;
    procedure SetLength(const Value: Integer);
    function GetIsUtf8: Boolean;
  public
    class operator Implicit(const S:WideString):AnsiString;
    class operator Implicit(const S:AnsiString):PAnsiChar;
    class operator Implicit(const S:AnsiString):TBytes;
    class operator Implicit(const ABytes:TBytes):AnsiString;
    class operator Implicit(const S:AnsiString):WideString;
    //class operator Implicit(const S:PAnsiChar):AnsiString;
    //�ַ����Ƚ�
    procedure From(p:PAnsiChar;AOffset,ALen:Integer);
    property Chars[AIndex:Integer]:AnsiChar read GetChars write SetChars;default;
    property Length:Integer read GetLength write SetLength;
    property IsUtf8:Boolean read GetIsUtf8;
  end;
  {$ENDIF}
  
  {$if CompilerVersion < 23}
  NativeUInt = Cardinal;
  IntPtr = NativeInt;
  {$ifend}
  StringA = AnsiString;
  {$IFDEF UNICODE}
  StringW = UnicodeString;
  TIntArray = TArray<Integer>;
  {$ELSE}
  StringW = WideString;
  TIntArray = array of Integer;
  {$ENDIF}
  CharA = AnsiChar;
  CharW = WideChar;
  PCharA = PAnsiChar;
  PCharW = PWideChar;

type
  TTextEncoding = (teUnknown, {δ֪�ı���} teAuto,{�Զ����} teAnsi, { Ansi���� }
    teUnicode16LE, { Unicode LE ���� } teUnicode16BE, { Unicode BE ���� }
    teUTF8 { UTF8���� } );

type
  TStringCatHelper = class
  private
    FValue: array of char;
    FStart, FDest: PChar;
    FBlockSize: Integer;
    FSize: Integer;
    function GetValue: string;
    function GetPosition: Integer;
    function GetChars(AIndex:Integer): Char;
    procedure SetPosition(const Value: Integer);
    procedure NeedSize(ASize:Integer);
  public
    constructor Create; overload;
    constructor Create(ASize: Integer); overload;
    destructor Destroy; override;
    function Cat(p: PChar; len: Integer): TStringCatHelper; overload;
    function Cat(const s: string): TStringCatHelper; overload;
    function Cat(c: Char): TStringCatHelper; overload;
    function Cat(const V:Int64): TStringCatHelper;overload;
    function Cat(const V:Double): TStringCatHelper;overload;
    function Cat(const V:Boolean): TStringCatHelper;overload;
    function Cat(const V:Currency): TStringCatHelper;overload;
    function Cat(const V:TGuid): TStringCatHelper;overload;
    function Cat(const V:Variant): TStringCatHelper;overload;
    function Cat(const V:TStream): TStringCatHelper;overload;
    function Space(count: Integer): TStringCatHelper;
    function Back(ALen: Integer): TStringCatHelper;
    function BackIf(const s: PChar): TStringCatHelper;
    procedure Reset;
    property Value: string read GetValue;
    property Chars[Index: Integer]: Char read GetChars;
    property Start: PChar read FStart;
    property Current: PChar read FDest;
    property Position: Integer read GetPosition write SetPosition;
  end;

type
  TStringArrayItem = packed record
    P: PChar;
    Len: Integer;
  end;
  PStringArrayItem = ^TStringArrayItem;
  TStringArrayData = array of TStringArrayItem;

type
  TStringArray = class;
  TOnFilterEvent = function (Sender: TStringArray; const P: PChar; 
    const Len: Integer): Boolean;
  
  /// <summary>
  /// �ַ������飬���������ַ��ָ���
  /// </summary>
  TStringArray = class(TObject)
  private
    FData: string;
    FList: array of TStringArrayItem;
    FCount, FCapacity: Integer;
    FDelimiter: Char;
    FTag: Integer;
    FOnFilter: TOnFilterEvent;
    procedure Grow;
    procedure CheckIndex(const Index: Integer); 
    function GetItem(const Index: Integer): string; overload;
    procedure SetDelimitedText(const Value: string);
    procedure SetText(const Value: string); 
  protected
    procedure SetCapacity(NewCapacity: Integer); virtual;
  public
    procedure Clear;
    function Add(const P: PChar; const Len: Integer): Integer;
    procedure SetDelimitedData(const Value: Pointer; const Len: Integer);
    procedure GetString(const Index: Integer; var Data: string);
    function GetText(const ADelimiter: string = #13#10): string;
    function GetFloat(const Index: Integer): Double;
    function GetValue(const Index: Integer): PStringArrayItem;
    function GetItemValue(const Index: Integer): PStringArrayItem;
    property Delimiter: Char read FDelimiter write FDelimiter;
    property DelimitedText: string write SetDelimitedText;
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity;
    property Items[const Index: Integer]: string read GetItem; default;
    property Text: string read FData write SetText;
    property Tag: Integer read FTag write FTag;
    property OnFilter: TOnFilterEvent read FOnFilter write FOnFilter;
  end;

type
  /// <summary>
  /// �ַ������飬���������ַ��ָ���
  /// </summary>
  TStringArrayS = class(TObject)
  private
    FData: string;
    FList: array of string;
    FCount, FCapacity: Integer;
    FDelimiter: Char;
    procedure Grow;
    function GetItem(const Index: Integer): string;
    procedure SetItem(const Index: Integer; const Value: string);
    procedure SetDelimitedText(const Value: string);
  protected
    procedure SetCapacity(NewCapacity: Integer); virtual;
  public
    function Add(const S: string): Integer; overload; virtual;
    function Add(const P: PChar; const Len: Integer): Integer; overload; virtual;
    procedure Clear;
    property Delimiter: Char read FDelimiter write FDelimiter;
    property DelimitedText: string write SetDelimitedText;
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity;
    property Items[const Index: Integer]: string read GetItem write SetItem; default;
  end;

// --------------------------------------------------------------------------
//  �����ַ���������������ת��
// --------------------------------------------------------------------------

function StrDupX(const s: PChar; ACount:Integer): String;
function StrDupXA(const s: PCharA; ACount:Integer): StringA;
function StrDupXW(const s: PCharW; ACount:Integer): StringW;
function StrDup(const S: PChar; AOffset: Integer; const ACount: Integer): String;
procedure ExchangeByteOrder(p: PCharA; l: Integer); overload;
function ExchangeByteOrder(V: Smallint): Smallint; overload; inline;
function ExchangeByteOrder(V: Word): Word; overload; inline;
function ExchangeByteOrder(V: Integer): Integer; overload; inline;
function ExchangeByteOrder(V: Cardinal): Cardinal; overload; inline;
function ExchangeByteOrder(V: Int64): Int64; overload; inline;
function ExchangeByteOrder(V: Single): Single; overload; inline;
function ExchangeByteOrder(V: Double): Double; overload; inline;
// ת���ɴ�д�ַ�
function CharUpper(c: Char): Char; inline;
function CharUpperA(c: AnsiChar): AnsiChar;
function CharUpperW(c: WideChar): WideChar;
// �ڴ�ɨ��
function MemScan(S: Pointer; len_s: Integer; sub: Pointer; len_sub: Integer): Pointer;
// �ֽ�λ�Ƚ�
function BinaryCmp(const p1, p2: Pointer; len: Integer): Integer;
// �ַ������ң�������  ��UTF8ֱ��ʹ��Ansi�汾���ɣ�
function StrScanW(const Str: PCharW; Chr: CharW): PCharW;
function StrStr(src, sub: string): Integer; overload; inline;
function StrStr(src, sub: PChar): PChar; overload; inline;
function StrStrA(src, sub: PAnsiChar): PAnsiChar;
function StrStrW(src, sub: PWideChar): PWideChar;
function StrIStr(src, sub: string): Integer; overload;
function StrIStr(src, sub: PChar): PChar; overload;
function StrIStrA(src, sub: PAnsiChar): PAnsiChar;
function StrIStrW(src, sub: PWideChar): PWideChar; 
function PosStr(sub, src: AnsiString; Offset: Integer = 0): Integer; overload; inline;
function PosStr(sub: PAnsiChar; src: PAnsiChar; Offset: Integer = 0): Integer; overload; inline;
function PosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; Offset: Integer): Integer; overload; inline;
function PosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; srcLen: Integer; Offset: Integer): Integer; overload; 
// �����ַ��������ҵ���
function RPosStr(sub, src: AnsiString; Offset: Integer = 0): Integer; overload; inline;
function RPosStr(sub: PAnsiChar; src: PAnsiChar; Offset: Integer = 0): Integer; overload; inline;
function RPosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; srcLen: Integer; Offset: Integer): Integer; overload; 
// ����һ���� #0 Ϊ������־��Wide�ַ�������
function WideStrLen(S: PWideChar): Integer; inline;
// ����һ���� #0 Ϊ������־��Ansi�ַ�������
function AnsiStrLen(s: PAnsiChar): Integer; inline;
// ��һ���ַ���ȡ����ADelimΪ������־�����ӷ�����������ADeleteΪTrueʱ��ɾ��Դ�ַ��������ݣ�����Delim)
function Fetch(var AInput: string; const ADelim: string = ' ';
  const ADelete: Boolean = True): string; inline;
// ����һ������תΪ16�����ַ����ĳ���
function LengthAsDWordToHex(const Value: Cardinal): Integer;
{$IFDEF USE_URLFUNC}
// URL����
function UrlEncode(const AUrl: StringA): StringA; overload;
function UrlEncode(const AUrl: StringW): StringW; overload;
function UrlEncodeA(const AStr: PCharA; OutBuf: PCharA): Integer; overload;
function UrlEncodeW(const AStr: PCharW; OutBuf: PCharW): Integer; overload;
// URL����
function UrlDecode(const Src: PCharA; OutBuf: PCharA; RaiseError: Boolean = True): Integer; overload;
function UrlDecode(const AStr: StringA; RaiseError: Boolean = True): StringA; overload;
function UTFStrToUnicode(UTFStr: StringA): StringW;
{$ENDIF}
// �ַ�����ȡ
function LeftStr(const AText: AnsiString; const ACount: Integer): AnsiString; overload; inline;
function LeftStr(const AText: WideString; const ACount: Integer): WideString; overload; inline;
function RightStr(const AText: AnsiString; const ACount: Integer): AnsiString; overload; inline;
function RightStr(const AText: WideString; const ACount: Integer): WideString; overload; inline;
function MidStr(const AText: AnsiString; const AStart, ACount: Integer): AnsiString; overload; inline;
function MidStr(const AText: WideString; const AStart, ACount: Integer): WideString; overload; inline;
//����ת��
function IsHexChar(c: Char): Boolean; inline;
function HexValue(c: Char): Integer;
function HexChar(v: Byte): Char;
//����ַ��Ƿ���ָ�����б���
function CharIn(const c, list: PChar; ACharLen:PInteger = nil): Boolean; inline;
{$IFNDEF NEXTGEN}
function CharInA(c, list: PAnsiChar; ACharLen: PInteger = nil): Boolean;
function CharInU(c, list: PAnsiChar; ACharLen: PInteger = nil): Boolean;
{$ENDIF}
function CharInW(c, list: PWideChar; ACharLen: PInteger = nil): Boolean;
//�����ַ�����
function CharSizeA(c: PAnsiChar): Integer;
function CharSizeU(c: PAnsiChar): Integer;
function CharSizeW(c: PWideChar): Integer;
//��������ַ���������
function DetectTextEncoding(const p: Pointer; L: Integer; var b: Boolean): TTextEncoding;
{$IFDEF USE_STRENCODEFUNC}
function AnsiEncode(p:PWideChar; l:Integer): AnsiString; overload;
function AnsiEncode(const p: StringW): AnsiString; overload;
{$IFNDEF MSWINDOWS}
function AnsiDecode(const S: AnsiString): StringW; overload;
{$ENDIF}
function AnsiDecode(p: PAnsiChar; l:Integer): StringW; overload;
function Utf8Encode(const p: StringW): AnsiString; overload;
function Utf8Encode(p: PWideChar; l: Integer): AnsiString; overload;
{$IFNDEF MSWINDOWS}
function Utf8Decode(const S: AnsiString): StringW; overload;
{$ENDIF}
function Utf8Decode(p: PAnsiChar; l: Integer): StringW; overload;
// �����ַ���������
function LoadTextA(AStream: TStream; AEncoding: TTextEncoding=teUnknown): StringA; overload;
function LoadTextU(AStream: TStream; AEncoding: TTextEncoding=teUnknown): StringA; overload;
function LoadTextW(AStream: TStream; AEncoding: TTextEncoding=teUnknown): StringW; overload;
{$ENDIF}
function BinToHex(p: Pointer; l: Integer): string; overload;
function BinToHex(const ABytes:TBytes): string; overload;
procedure HexToBin(p: Pointer; l: Integer; var AResult: TBytes); overload;
function HexToBin(const S: String): TBytes; overload;
procedure HexToBin(const S: String; var AResult: TBytes); overload;

//�����ַ��������кţ������е���ʼ��ַ
function StrPosA(start, current: PAnsiChar; var ACol, ARow:Integer): PAnsiChar;
function StrPosU(start, current: PAnsiChar; var ACol, ARow:Integer): PAnsiChar;
function StrPosW(start, current: PWideChar; var ACol, ARow:Integer): PWideChar;
//��ȡһ��
function DecodeLineA(var p:PAnsiChar; ASkipEmpty:Boolean=True): StringA;
function DecodeLineW(var p:PWideChar; ASkipEmpty:Boolean=True): StringW;
//�����հ��ַ������� Ansi���룬��������#9#10#13#161#161������UCS���룬��������#9#10#13#$3000
function SkipSpaceA(var p: PAnsiChar): Integer;
function SkipSpaceU(var p: PAnsiChar): Integer;
function SkipSpaceW(var p: PWideChar): Integer;
//����һ��,��#10Ϊ�н�β
function SkipLineA(var p: PAnsiChar): Integer;
function SkipLineU(var p: PAnsiChar): Integer;
function SkipLineW(var p: PWideChar): Integer;
//����Ƿ��ǿհ��ַ�
function IsSpaceA(const c:PAnsiChar; ASpaceSize:PInteger=nil): Boolean;
function IsSpaceU(const c:PAnsiChar; ASpaceSize:PInteger=nil): Boolean;
function IsSpaceW(const c:PWideChar; ASpaceSize:PInteger=nil): Boolean;
//����ֱ������ָ�����ַ�
{$IFNDEF NEXTGEN}
function SkipUntilA(var p: PAnsiChar; AExpects: PAnsiChar; AQuoter: AnsiChar = {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF}): Integer;
function SkipUntilU(var p: PAnsiChar; AExpects: PAnsiChar; AQuoter: AnsiChar = {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF}): Integer;
{$ENDIF}
function SkipUntilW(var p: PWideChar; AExpects: PWideChar; AQuoter: WideChar = #0): Integer;
//�ж��Ƿ�����ָ�����ַ�����ʼ
function StartWith(s, startby: PChar; AIgnoreCase: Boolean): Boolean;
function StartWithIgnoreCase(s, startby: PChar): Boolean;
//�����ı�
procedure SaveTextA(AStream: TStream; const S: StringA);
procedure SaveTextU(AStream: TStream; const S: StringA; AWriteBom: Boolean = True);
procedure SaveTextW(AStream: TStream; const S: StringW; AWriteBom: Boolean = True);
procedure SaveTextWBE(AStream: TStream; const S: StringW; AWriteBom: Boolean = True);

var
  // ϵͳ ACP
  SysACP: Integer;
{$IFDEF USE_STRENCODEFUNC}
  // ����Java��ʽ���룬��#$0�ַ�����Ϊ#$C080
  JavaFormatUtf8: Boolean = True;
{$ENDIF}

implementation

resourcestring
  SOutOfIndex = '����Խ�磬ֵ %d ����[%d..%d]�ķ�Χ�ڡ�';
  SBadUnicodeChar = '��Ч��Unicode�ַ�:%d';
{$IFDEF USE_URLFUNC}
  sErrorDecodingURLText = 'Error decoding URL style (%%XX) encoded string at position %d';
  sInvalidURLEncodedChar = 'Invalid URL encoded character (%s) at position %d';
{$ENDIF}

{$IFDEF MSWINDOWS}
type
  TMSVCStrStr = function(s1, s2: PAnsiChar): PAnsiChar; cdecl;
  TMSVCStrStrW = function(s1, s2: PWideChar): PWideChar; cdecl;
  TMSVCMemCmp = function(s1, s2: Pointer; len: Integer): Integer; cdecl;
var
  hMsvcrtl: HMODULE;
  VCStrStr: TMSVCStrStr;
  VCStrStrW: TMSVCStrStrW;
  VCMemCmp: TMSVCMemCmp;
{$ENDIF}

function WideStrLen(S: PWideChar): Integer; inline;
begin
  Result := 0;
  if S <> nil then
    while S^ <> #0 do begin
      Inc(Result);
      Inc(S);
    end;
end;

function AnsiStrLen(s: PAnsiChar): Integer; inline;
begin
  Result := 0;
  if s <> nil then
    {$IFDEF POSIX}
    while S^ <> 0 do begin
    {$ELSE}
    while S^ <> #0 do begin
    {$ENDIF}
      Inc(Result);
      Inc(s);
    end;
end;

function Fetch(var AInput: string; const ADelim: string = ' ';
  const ADelete: Boolean = True): string;
var
  LPos: Integer;
begin
  if ADelim = #0 then
    LPos := Pos(ADelim, AInput)
  else
    LPos := Pos(ADelim, AInput);
  if LPos = 0 then begin
    Result := AInput;
    if ADelete then AInput := '';
  end else begin
    Result := Copy(AInput, 1, LPos - 1);
    if ADelete then
      AInput := Copy(AInput, LPos + Length(ADelim), MaxInt);
  end;
end;

procedure ExchangeByteOrder(p: PCharA; l: Integer);
var
  pe: PCharA;
  c: CharA;
begin
  pe := p;
  Inc(pe, l);
  while IntPtr(p) < IntPtr(pe) do begin
    c := p^;
    p^ := PCharA(IntPtr(p) + 1)^;
    PCharA(IntPtr(p) + 1)^ := c;
    Inc(p, 2);
  end;
end;

function ExchangeByteOrder(V: Smallint): Smallint;
var
  pv: array [0 .. 1] of Byte absolute V;
  pd: array [0 .. 1] of Byte absolute Result;
begin
  pd[0] := pv[1];
  pd[1] := pv[0];
end;

function ExchangeByteOrder(V: Word): Word;
var
  pv: array [0 .. 1] of Byte absolute V;
  pd: array [0 .. 1] of Byte absolute Result;
begin
  pd[0] := pv[1];
  pd[1] := pv[0];
end;

function ExchangeByteOrder(V: Integer): Integer;
var
  pv: array [0 .. 3] of Byte absolute V;
  pd: array [0 .. 3] of Byte absolute Result;
begin
  pd[0] := pv[3];
  pd[1] := pv[2];
  pd[2] := pv[1];
  pd[3] := pv[0];
end;

function ExchangeByteOrder(V: Cardinal): Cardinal;
var
  pv: array [0 .. 3] of Byte absolute V;
  pd: array [0 .. 3] of Byte absolute Result;
begin
  pd[0] := pv[3];
  pd[1] := pv[2];
  pd[2] := pv[1];
  pd[3] := pv[0];
end;

function ExchangeByteOrder(V: Int64): Int64;
var
  pv: array [0 .. 7] of Byte absolute V;
  pd: array [0 .. 7] of Byte absolute Result;
begin
  pd[0] := pv[7];
  pd[1] := pv[6];
  pd[2] := pv[5];
  pd[3] := pv[4];
  pd[4] := pv[3];
  pd[5] := pv[2];
  pd[6] := pv[1];
  pd[7] := pv[0];
end;

function ExchangeByteOrder(V: Single): Single;
var
  pv: array [0 .. 3] of Byte absolute V;
  pd: array [0 .. 3] of Byte absolute Result;
begin
  pd[0] := pv[3];
  pd[1] := pv[2];
  pd[2] := pv[1];
  pd[3] := pv[0];
end;

function ExchangeByteOrder(V: Double): Double;
var
  pv: array [0 .. 7] of Byte absolute V;
  pd: array [0 .. 7] of Byte absolute Result;
begin
  pd[0] := pv[7];
  pd[1] := pv[6];
  pd[2] := pv[5];
  pd[3] := pv[4];
  pd[4] := pv[3];
  pd[5] := pv[2];
  pd[6] := pv[1];
  pd[7] := pv[0];
end;

function StrDupX(const s: PChar; ACount:Integer): String;
begin
  SetLength(Result, ACount);
  Move(s^, PChar(Result)^, ACount{$IFDEF UNICODE} shl 1{$ENDIF});
end;

function StrDupXA(const s: PCharA; ACount:Integer): StringA;
begin
  {$IFDEF NEXTGEN}
  Result.From(s, 0, ACount);
  {$ELSE}
  SetLength(Result, ACount);
  Move(s^, PCharA(Result)^, ACount);
  {$ENDIF}
end;

function StrDupXW(const s: PCharW; ACount:Integer): StringW;
begin
  SetLength(Result, ACount);
  Move(s^, PCharW(Result)^, ACount shl 1);
end;

function StrDup(const S: PChar; AOffset: Integer; const ACount: Integer): String;
var
  C, ACharSize: Integer;
  p, pds, pd: PChar;
begin
  C := 0;
  p := S + AOffset;
  SetLength(Result, 4096);
  pd := PChar(Result);
  pds := pd;
  while (p^ <> #0) and (C < ACount) do begin
    ACharSize := {$IFDEF UNICODE} CharSizeW(p); {$ELSE} CharSizeA(p); {$ENDIF}
    AOffset := pd - pds;
    if AOffset + ACharSize = Length(Result) then begin
      SetLength(Result, Length(Result){$IFDEF UNICODE} shl 1{$ENDIF});
      pds := PChar(Result);
      pd := pds + AOffset;
    end;
    Inc(C);
    pd^ := p^;
    if ACharSize = 2 then
      pd[1] := p[1];
    Inc(pd, ACharSize);
    Inc(p, ACharSize);
  end;
  SetLength(Result, pd-pds);
end;

function CharUpper(c: Char): Char;
begin
  {$IFDEF UNICODE}
  Result := CharUpperW(c);
  {$ELSE}
  Result := CharUpperA(c);
  {$ENDIF};
end;

function CharUpperA(c: AnsiChar): AnsiChar;
begin
  {$IFNDEF NEXTGEN}
  if (c>=#$61) and (c<=#$7A) then
  {$ELSE}
  if (c>=$61) and (c<=$7A) then
  {$ENDIF}
    Result := AnsiChar(Ord(c)-$20)
  else
    Result := c;
end;

function CharUpperW(c: WideChar): WideChar;
begin
  if (c>=#$61) and (c<=#$7A) then
    Result := WideChar(PWord(@c)^-$20)
  else
    Result := c;
end;

function StrScanW(const Str: PCharW; Chr: CharW): PCharW; 
begin
  Result := Str;
  while Result^ <> Chr do begin
    if Result^ = #0 then begin
      Result := nil;
      Exit;
    end;
    Inc(Result);
  end;
end;

function MemScan(S: Pointer; len_s: Integer; sub: Pointer; len_sub: Integer): Pointer;
var
  pb_s, pb_sub, pc_sub, pc_s: PByte;
  remain: Integer;
begin
  if len_s > len_sub then begin
    pb_s := S;
    pb_sub := sub;
    Result := nil;
    while len_s >= len_sub do begin
      if pb_s^ = pb_sub^ then begin
        remain := len_sub - 1;
        pc_sub := pb_sub;
        pc_s := pb_s;
        Inc(pc_s);
        Inc(pc_sub);
        if BinaryCmp(pc_s, pc_sub, remain) = 0 then begin
          Result := pb_s;
          Break;
        end;
      end;
      Inc(pb_s);
    end;
  end else if len_s = len_sub then begin
    if CompareMem(S, sub, len_s) then
      Result := S
    else
      Result := nil;
  end else
    Result := nil;
end;

function BinaryCmp(const p1, p2: Pointer; len: Integer): Integer;
  function CompareByByte: Integer;
  var
    b1, b2: PByte;
  begin
    if (len <= 0) or (p1 = p2) then
      Result := 0
    else begin
      b1 := p1;
      b2 := p2;
      Result := 0;
      while len > 0 do begin
        if b1^ <> b2^ then begin
          Result := b1^ - b2^;
          Exit;
        end;
        Inc(b1);
        Inc(b2);
      end;
    end;
  end;
begin
  {$IFDEF MSWINDOWS}
  if Assigned(VCMemCmp) then
    Result := VCMemCmp(p1, p2, len)
  else
    Result := CompareByByte;
  {$ELSE}
  Result := memcmp(p1, p2, len);
  {$ENDIF}
end;

function StrStr(src, sub: string): Integer;
var
  p1, p2: PChar;
begin
  p1 := PChar(src);
  p2 := PChar(sub);
  {$IFDEF UNICODE}
  p2 := StrStrW(p1, p2);
  {$ELSE}
  p2 := StrStrA(p1, p2);
  {$ENDIF};
  if p2 <> nil then
    Result := p2 - p1
  else
    Result := -1;
end;

function StrIStr(src, sub: string): Integer;
var
  p1, p2: PChar;
begin
  p1 := PChar(src);
  p2 := PChar(sub);
  {$IFDEF UNICODE}
  p2 := StrIStrW(p1, p2);
  {$ELSE}
  p2 := StrIStrA(p1, p2);
  {$ENDIF};
  if p2 <> nil then
    Result := p2 - p1
  else
    Result := -1;
end;

function StrStr(src, sub: PChar): PChar;
begin
  {$IFDEF UNICODE}
  Result := StrStrW(src, sub);
  {$ELSE}
  Result := StrStrA(src, sub);
  {$ENDIF};
end;

function DoStrStrASearch(s1, ps2: PAnsiChar): PAnsiChar; inline;
var
  ps1: PAnsiChar;
begin
  ps1 := s1;
  Inc(ps1);
  Inc(ps2);
  while ps2^ <> {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if ps1^ = ps2^ then begin
      Inc(ps1);
      Inc(ps2);
    end else
      Break;
  end;
  if ps2^ = {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} then
    Result := s1
  else
    Result := nil;
end;

function StrStrA(src, sub: PAnsiChar): PAnsiChar;
begin
  {$IFDEF MSWINDOWS}
  if Assigned(VCStrStr) then begin
    Result := VCStrStr(src, sub);
    Exit;
  end;
  {$ENDIF}
  Result := nil;
  if (src <> nil) and (sub <> nil) then begin
    while src^ <> {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
      if src^ = sub^ then begin
        Result := DoStrStrASearch(src, sub);
        if Result <> nil then
          Exit;
      end;
      Inc(src);
    end;
  end;
end;

function StrStrW(src, sub: PWideChar): PWideChar;
var
  I: Integer;
begin
  {$IFDEF MSWINDOWS}
  if Assigned(VCStrStrW) then begin
    Result := VCStrStrW(src, sub);
    Exit;
  end;
  {$ENDIF}
  if (sub = nil) or (sub^ = #0) then
    Result := src
  else begin
    Result := nil;
    while src^ <> #0 do begin
      if src^ = sub^ then begin
        I := 1;
        while sub[I] <> #0 do begin
          if src[I] = sub[I] then
            Inc(I)
          else
            Break;
        end;
        if sub[I] = #0 then begin
          Result := src;
          Break;
        end;
      end;
      Inc(src);
    end;
  end;
end;

function StrIStr(src, sub: PChar): PChar;
begin
  {$IFDEF UNICODE}
  Result := StrIStrW(src, sub);
  {$ELSE}
  Result := StrIStrA(src, sub);
  {$ENDIF};
end;

function DoStrStrAISearch(s1, ps2: PAnsiChar): PAnsiChar; inline;
var
  ps1: PAnsiChar;
begin
  ps1 := s1;
  Inc(ps1);
  Inc(ps2);
  while ps2^ <> {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if CharUpperA(ps1^) = CharUpperA(ps2^) then begin
      Inc(ps1);
      Inc(ps2);
    end else
      Break;
  end;
  if ps2^ = {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} then
    Result := s1
  else
    Result := nil;
end;

function StrIStrA(src, sub: PAnsiChar): PAnsiChar;
begin
  Result := nil;
  if (src <> nil) and (sub <> nil) then begin
    while src^ <> {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
      if CharUpperA(src^) = CharUpperA(sub^) then begin
        Result := DoStrStrAISearch(src, sub);
        if Result <> nil then
          Exit;
      end;
      Inc(src);
    end;
  end;
end;

function StrIStrW(src, sub: PWideChar): PWideChar;
var
  I: Integer;
  ws2: StringW;
begin
  Result := nil;
  if (src = nil) or (sub = nil) then
    Exit;
  ws2 := UpperCase(sub);
  sub := PWideChar(ws2);
  while src^ <> #0 do begin
    if CharUpperW(src^) = sub^ then begin
      I := 1;
      while sub[I] <> #0 do begin
        if CharUpperW(src[I]) = sub[I] then
          Inc(I)
        else
          Break;
      end;
      if sub[I] = #0 then begin
        Result := src;
        Break;
      end;
    end;
    Inc(src);
  end;
end;

function PosStr(sub, src: AnsiString; Offset: Integer = 0): Integer;
begin
  Result := PosStr(PAnsiChar(sub), Length(sub), PAnsiChar(src), Length(src), Offset);
  if Result <> -1 then
    Inc(Result);
end;

function PosStr(sub: PAnsiChar; src: PAnsiChar; Offset: Integer): Integer;
begin
  Result := PosStr(sub, AnsiStrLen(sub), src, AnsiStrLen(src), Offset);
end;

function PosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; Offset: Integer): Integer;
begin
  Result := PosStr(sub, subLen, src, AnsiStrLen(src), Offset);
end;

function PosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; srcLen: Integer; Offset: Integer): Integer;
var
  p: PAnsiChar;
  j: Integer;
begin
  Result := -1;
  if (sub = nil) or (src = nil) then
    Exit;
  if (Offset > 0) then Dec(srcLen, Offset);
  if (subLen <= srcLen) and (subLen > 0) then begin
    p := src;
    Inc(p, Offset);
    Dec(subLen);
    Dec(srcLen, subLen);
    while srcLen > 0 do begin
      if PByte(p)^ = PByte(sub)^ then begin
        if subLen > 0 then begin
          for j := 1 to subLen do
            {$IFDEF NEXTGEN}
            if PAnsiChar(IntPtr(p)+j) <> PAnsiChar(IntPtr(sub)+j) then Break;
            {$ELSE}
            if p[j] <> sub[j] then Break;
            {$ENDIF}
        end else
          j := 1;
        if j > subLen then begin
          {$IFDEF NEXTGEN}
          Result := IntPtr(p) - IntPtr(src);
          {$ELSE}
          Result := p - src;
          {$ENDIF}
          Exit;
        end;
      end;
      Inc(p);
      Dec(srcLen);
    end;
  end;
end;

function RPosStr(sub, src: AnsiString; Offset: Integer = 0): Integer;
begin
  Result := RPosStr(PAnsiChar(sub), Length(sub), PAnsiChar(src), Length(src), Offset);
  if Result <> -1 then
    Inc(Result);
end;

function RPosStr(sub: PAnsiChar; src: PAnsiChar; Offset: Integer = 0): Integer;
begin
  Result := RPosStr(sub, AnsiStrLen(sub), src, AnsiStrLen(src), Offset);
end;

function RPosStr(sub: PAnsiChar; subLen: Integer; src: PAnsiChar; srcLen: Integer; Offset: Integer): Integer;
var
  p: PAnsiChar;
  j: Integer;
begin
  Result := -1;
  if (sub = nil) or (src = nil) then
    Exit;
  p := src;
  Inc(p, srcLen);
  if (Offset > 0) then begin
    Dec(p, Offset + 1);
    Dec(srcLen, Offset);
  end else
    Dec(p);
  if (subLen <= srcLen) and (subLen > 0) then begin  
    while srcLen > 0 do begin
      if PByte(p)^ = PByte(sub)^ then begin
        if (subLen > 1) then begin
          for j := 1 to subLen do
            {$IFDEF NEXTGEN}
            if PAnsiChar(IntPtr(p)+j) <> PAnsiChar(IntPtr(sub)+j) then Break;
            {$ELSE}
            if p[j] <> sub[j] then Break;
            {$ENDIF}
        end else
          j := 1;
        if j = subLen then begin
          {$IFDEF NEXTGEN}
          Result := IntPtr(p) - IntPtr(src) + 1;
          {$ELSE}
          Result := p - src + 1;
          {$ENDIF}
          Exit;
        end;
      end;
      Dec(p);
      Dec(srcLen);
    end;
  end;
end;

function LengthAsDWordToHex(const Value: Cardinal): Integer;
begin
  if Value < $10 then
    Result := 1
  else if Value < $100 then
    Result := 2
  else if Value < $1000 then
    Result := 3
  else if Value < $10000 then
    Result := 4
  else if Value < $100000 then
    Result := 5
  else if Value < $1000000 then
    Result := 6
  else if Value < $10000000 then
    Result := 7
  else
    Result := 8;
end;

{$IFDEF USE_URLFUNC}
function UrlDecode(const Src: PCharA; OutBuf: PCharA; RaiseError: Boolean): Integer;
const
  H_BYTE:array[0..255] of Smallint =
  (
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,$00,$10,$20,$30,$40,$50,$60,$70,$80,$90,-1,-1,-1,-1,-1,-1
    ,-1,$A0,$B0,$C0,$D0,$E0,$F0,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  );

  L_BYTE: array[0..255] of Smallint =
  (
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,-1,-1,-1,-1,-1,-1
  ,-1,$0A,$0B,$0C,$0D,$0E,$0F,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  ,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  );
var
  Sp, Rp: PAnsichar;
  HB, LB: SmallInt;
begin
  Result := -1;
  if (Src = nil) or (OutBuf = nil) then
    Exit;
  Sp := Src;
  Rp := OutBuf;
  LB := -1;
  while Sp^ <> #0 do begin
    case Sp^ of
      '+': Rp^ := #32;
      '%': begin
             // Look for an escaped % (%%) or %<hex> encoded character
             Inc(Sp);
             if Sp^ = '%' then
               Rp^ := '%'
             else begin
               HB := H_BYTE[Byte(Sp^)];
               if HB <> 0 then               
                LB := L_BYTE[Byte((Sp+1)^)];
               if (HB <> -1) and (LB <> -1) then begin
                 Rp^ := AnsiChar(HB + LB);
                 Inc(Sp);
               end else begin
                 if RaiseError then
                   raise Exception.Create(Format(sErrorDecodingURLText, [Sp - Src]))
                 else
                   Exit;
               end;
             end;
           end;
    else
      Rp^ := Sp^;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  Result := Rp - OutBuf;
end;

function UrlDecode(const AStr: StringA; RaiseError: Boolean): StringA;
var
  I: Integer;
begin
  if Length(AStr) > 0 then begin
    SetLength(Result, Length(AStr));
    I := UrlDecode(Pointer(AStr), Pointer(Result), RaiseError);
    if I = -1 then
      Result := ''
    else if I <> Length(Result) then
      SetLength(Result, I);   
  end else
    Result := '';
end;

function UrlEncodeA(const AStr: PCharA; OutBuf: PCharA): Integer;
const
  HTTP_CONVERT: array[0..255] of PCharA = (
    ' %00#','%01#','%02#','%03#','%04#','%05#','%06#','%07#'
    ,'%08#','%09#','%0A#','%0B#','%0C#','%0D#','%0E#','%0F#'
    ,'%10#','%11#','%12#','%13#','%14#','%15#','%16#','%17#'
    ,'%18#','%19#','%1A#','%1B#','%1C#','%1D#','%1E#','%1F#'
    ,'%20#',''    ,'%22#','%23#',''    ,'%25#','%26#',''
    ,''    ,''    ,''    ,'%2B#','%2C#',''    ,''    ,'%2F#'
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,'%3A#','%3B#','%3C#','%3D#','%3E#','%3F#'
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,'%5B#','%5C#','%5D#','%5E#',''
    ,'%60#',''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''     ,'%7B#','%7C#','%7D#','%7E#','%7F#'
    ,'%80#','%81#','%82#','%83#','%84#','%85#','%86#','%87#'
    ,'%88#','%89#','%8A#','%8B#','%8C#','%8D#','%8E#','%8F#'
    ,'%90#','%91#','%92#','%93#','%94#','%95#','%96#','%97#'
    ,'%98#','%99#','%9A#','%9B#','%9C#','%9D#','%9E#','%9F#'
    ,'%A0#','%A1#','%A2#','%A3#','%A4#','%A5#','%A6#','%A7#'
    ,'%A8#','%A9#','%AA#','%AB#','%AC#','%AD#','%AE#','%AF#'
    ,'%B0#','%B1#','%B2#','%B3#','%B4#','%B5#','%B6#','%B7#'
    ,'%B8#','%B9#','%BA#','%BB#','%BC#','%BD#','%BE#','%BF#'
    ,'%C0#','%C1#','%C2#','%C3#','%C4#','%C5#','%C6#','%C7#'
    ,'%C8#','%C9#','%CA#','%CB#','%CC#','%CD#','%CE#','%CF#'
    ,'%D0#','%D1#','%D2#','%D3#','%D4#','%D5#','%D6#','%D7#'
    ,'%D8#','%D9#','%DA#','%DB#','%DC#','%DD#','%DE#','%DF#'
    ,'%E0#','%E1#','%E2#','%E3#','%E4#','%E5#','%E6#','%E7#'
    ,'%E8#','%E9#','%EA#','%EB#','%EC#','%ED#','%EE#','%EF#'
    ,'%F0#','%F1#','%F2#','%F3#','%F4#','%F5#','%F6#','%F7#'
    ,'%F8#','%F9#','%FA#','%FB#','%FC#','%FD#','%FE#','%FF#'
  );
var
  Sp, Rp, P: PCharA;
begin
  Sp := AStr;
  Rp := OutBuf;
  while Sp^ <> #0 do begin
    if Sp^ = ' ' then
      Rp^ := '+'
    else begin
      P := HTTP_CONVERT[Ord(Sp^)];
      if P^ = #0 then
        Rp^ := Sp^
      else begin
        PInteger(Rp)^ := PInteger(P)^;
        Inc(Rp, 2);
      end;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  Result := Rp - OutBuf;
end;

function UrlEncodeW(const AStr: PCharW; OutBuf: PCharW): Integer;
const
  HTTP_CONVERT: array[0..255] of PCharW = (
    ' %00#','%01#','%02#','%03#','%04#','%05#','%06#','%07#'
    ,'%08#','%09#','%0A#','%0B#','%0C#','%0D#','%0E#','%0F#'
    ,'%10#','%11#','%12#','%13#','%14#','%15#','%16#','%17#'
    ,'%18#','%19#','%1A#','%1B#','%1C#','%1D#','%1E#','%1F#'
    ,'%20#',''    ,'%22#','%23#',''    ,'%25#','%26#',''
    ,''    ,''    ,''    ,'%2B#','%2C#',''    ,''    ,'%2F#'
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,'%3A#','%3B#','%3C#','%3D#','%3E#','%3F#'
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''    ,''    ,''    ,'%5B#','%5C#','%5D#','%5E#',''
    ,'%60#',''    ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''    ,''    ,''    ,''    ,''    ,''
    ,''     ,''   ,''     ,'%7B#','%7C#','%7D#','%7E#','%7F#'
    ,'%80#','%81#','%82#','%83#','%84#','%85#','%86#','%87#'
    ,'%88#','%89#','%8A#','%8B#','%8C#','%8D#','%8E#','%8F#'
    ,'%90#','%91#','%92#','%93#','%94#','%95#','%96#','%97#'
    ,'%98#','%99#','%9A#','%9B#','%9C#','%9D#','%9E#','%9F#'
    ,'%A0#','%A1#','%A2#','%A3#','%A4#','%A5#','%A6#','%A7#'
    ,'%A8#','%A9#','%AA#','%AB#','%AC#','%AD#','%AE#','%AF#'
    ,'%B0#','%B1#','%B2#','%B3#','%B4#','%B5#','%B6#','%B7#'
    ,'%B8#','%B9#','%BA#','%BB#','%BC#','%BD#','%BE#','%BF#'
    ,'%C0#','%C1#','%C2#','%C3#','%C4#','%C5#','%C6#','%C7#'
    ,'%C8#','%C9#','%CA#','%CB#','%CC#','%CD#','%CE#','%CF#'
    ,'%D0#','%D1#','%D2#','%D3#','%D4#','%D5#','%D6#','%D7#'
    ,'%D8#','%D9#','%DA#','%DB#','%DC#','%DD#','%DE#','%DF#'
    ,'%E0#','%E1#','%E2#','%E3#','%E4#','%E5#','%E6#','%E7#'
    ,'%E8#','%E9#','%EA#','%EB#','%EC#','%ED#','%EE#','%EF#'
    ,'%F0#','%F1#','%F2#','%F3#','%F4#','%F5#','%F6#','%F7#'
    ,'%F8#','%F9#','%FA#','%FB#','%FC#','%FD#','%FE#','%FF#'
  );
var
  Sp, Rp, P: PCharW;
  Buf: array [0..4] of Byte;
  I, J: Integer;
begin
  Sp := AStr;
  Rp := OutBuf;
  while Sp^ <> #0 do begin
    if Sp^ = ' ' then
      Rp^ := '+'
    else begin
      if Ord(Sp^) > $FF then begin
        I := WideCharToMultiByte(CP_ACP, 0, Sp, 1, @Buf[0], 4, nil, nil);
        for J := 0 to I - 1 do begin
          P := HTTP_CONVERT[Buf[J]];
          PInt64(Rp)^ := PInt64(P)^;
          Inc(Rp, 3);
        end;
        Inc(Sp);
        Continue;
      end else begin
        P := HTTP_CONVERT[Ord(Sp^)];
        if P^ = #0 then
          Rp^ := Sp^
        else begin
          PInt64(Rp)^ := PInt64(P)^;
          Inc(Rp, 2);
        end;
      end;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  Result := Rp - OutBuf;
end;

function UrlEncode(const AUrl: StringA): StringA;
var
  I: Integer;
begin
  if Length(AUrl) > 0 then begin
    SetLength(Result, Length(AUrl) * 3);
    I := UrlEncodeA(PAnsiChar(AUrl), @Result[1]);
    if Length(Result) <> I then
      SetLength(Result, I);
  end else
    Result := '';
end;

function UrlEncode(const AUrl: StringW): StringW;
var
  I: Integer;
begin
  if Length(AUrl) > 0 then begin
    SetLength(Result, Length(AUrl) * 3);
    I := UrlEncodeW(PWideChar(AUrl), @Result[1]);
    if Length(Result) <> I then
      SetLength(Result, I);
  end else
    Result := '';
end;
{$ENDIF}

{$IFDEF USE_URLFUNC}
function XDigit(Ch : AnsiChar) : Integer;
begin
  {$IFDEF NEXTGEN}
  if (Ch >= Ord('0')) and (Ch <= Ord('9')) then
  {$ELSE}
  if (Ch >= '0') and (Ch <= '9') then
  {$ENDIF}
      Result := Ord(Ch) - Ord('0')
  else
      Result := (Ord(Ch) and 15) + 9;
end;

function UTFStrToUnicode(UTFStr: StringA): StringW;
var
  I:Integer;
  Index:Integer;
  HexStr:String;
  LowerCaseUTFStr:String;
  WChar:WideChar;
  WCharWord:Word;
  AChar:AnsiChar;
begin
  ////\u60a8\u7684\u9a8c\u8bc1\u7801\u9519\u8bef
  Result:='';
  LowerCaseUTFStr := LowerCase(string(UTFStr));
  Index:=PosEx('\u',LowerCaseUTFStr,1);
  while Index>0 do
  begin
    HexStr:=Copy(LowerCaseUTFStr,Index+2,4);
    WCharWord:=0;
    //HexStr=60a8
    for I := 1 to Length(HexStr) do
    begin
      AChar:=AnsiChar(HexStr[I]);
      WCharWord:=WCharWord+XDigit(AChar)*Ceil(Power(16,4-I));
    end;
    WChar:=WideChar(WCharWord);
    //WChar=��
    Result:=Result+WChar;
    Index:=PosEx('\u',LowerCaseUTFStr,Index+6);
  end;
end;
{$ENDIF}

{$IFNDEF NEXTGEN}
procedure CalcCharLengthA(var Lens: TIntArray; list: PAnsiChar);
var
  i, l: Integer;
begin
  i := 0;
  System.SetLength(Lens, Length(List));
  while i< Length(List) do begin
    l := CharSizeA(@list[i]);
    lens[i] := l;
    Inc(i, l);
  end;
end;
{$ENDIF}

{$IFNDEF NEXTGEN}
procedure CalcCharLengthU(var Lens: TIntArray; list: PAnsiChar);
var
  i, l: Integer;
begin
  i := 0;
  System.SetLength(Lens, Length(List));
  while i< Length(List) do begin
    l := CharSizeU(@list[i]);
    lens[i] := l;
    Inc(i, l);
  end;
end;
{$ENDIF}

// ����ַ��Ƿ���ָ�����б���
function CharIn(const c, list: PChar; ACharLen:PInteger = nil): Boolean;
begin
{$IFDEF UNICODE}
  Result := CharInW(c, list, ACharLen);
{$ELSE}
  Result := CharInA(c, list, ACharLen);
{$ENDIF}
end;

{$IFNDEF NEXTGEN}
function CharInA(c, list: PAnsiChar; ACharLen: PInteger = nil): Boolean;
var
  i: Integer;
  lens: TIntArray;
begin
  Result := False;
  CalcCharLengthA(lens, list);
  i := 0;
  while i < Length(list) do begin
    if CompareMem(c, @list[i], lens[i]) then begin
      if ACharLen <> nil then
        ACharLen^:=lens[i];
      Result := True;
      Break;
    end else
      Inc(i, lens[i]);
  end;
end;
{$ENDIF}

function CharInW(c, list: PWideChar; ACharLen: PInteger = nil): Boolean;
var
  p: PWideChar;
begin
  Result:=False;
  p := list;
  while p^ <> #0 do begin
    if p^ = c^ then begin
      if (p[0]>=#$DB00) and (p[0]<=#$DBFF) then begin
        if p[1]=c[1] then begin
          Result := True;
          if ACharLen <> nil then
            ACharLen^ := 2;
          Break;
        end;
      end else begin
        Result := True;
        if ACharLen <> nil then
          ACharLen^ := 1;
        Break;
      end;
    end;
    Inc(p);
  end;
end;

{$IFNDEF NEXTGEN}
function CharInU(c, list: PAnsiChar; ACharLen: PInteger = nil): Boolean;
var
  i: Integer;
  lens: TIntArray;
begin
  Result := False;
  CalcCharLengthU(lens, list);
  i := 0;
  while i < Length(list) do begin
    if CompareMem(c, @list[i], lens[i]) then begin
      if ACharLen <> nil then
        ACharLen^ := lens[i];
      Result := True;
      Break;
    end else
      Inc(i, lens[i]);
  end;
end;
{$ENDIF}

//���㵱ǰ�ַ��ĳ���
// GB18030,����GBK��GB2312
// ���ֽڣ���ֵ��0��0x7F��
// ˫�ֽڣ���һ���ֽڵ�ֵ��0x81��0xFE���ڶ����ֽڵ�ֵ��0x40��0xFE��������0x7F����
// ���ֽڣ���һ���ֽڵ�ֵ��0x81��0xFE���ڶ����ֽڵ�ֵ��0x30��0x39���������ֽڴ�0x81��0xFE�����ĸ��ֽڴ�0x30��0x39��
function CharSizeA(c: PAnsiChar): Integer;
begin
  if SysACP = 936 then begin
    Result:=1;
    {$IFDEF NEXTGEN}
    if (c^>=$81) and (c^<=$FE) then begin
      Inc(c);
      if (c^>=$40) and (c^<=$FE) and (c^<>$7F) then
        Result:=2
      else if (c^>=$30) and (c^<=$39) then begin
        Inc(c);
        if (c^>=$81) and (c^<=$FE) then begin
          Inc(c);
          if (c^>=$30) and (c^<=$39) then
            Result:=4;
        end;
      end;
    end;
    {$ELSE}
    if (c^>=#$81) and (c^<=#$FE) then begin
      Inc(c);
      if (c^>=#$40) and (c^<=#$FE) and (c^<>#$7F) then
        Result:=2
      else if (c^>=#$30) and (c^<=#$39) then begin
        Inc(c);
        if (c^>=#$81) and (c^<=#$FE) then begin
          Inc(c);
          if (c^>=#$30) and (c^<=#$39) then
            Result:=4;
        end;
      end;
    end;
    {$ENDIF}
  end else
    {$IFDEF UNICODE}
    {$IFDEF NEXTGEN}
    if TEncoding.ANSI.CodePage = CP_UTF8 then
      Result := CharSizeU(c)
    else if (c^<128) or (TEncoding.ANSI.CodePage=437) then
      Result:=1
    else
      Result:=2;
    {$ELSE}
    {$IF RTLVersion>26}
    Result := AnsiStrings.StrCharLength(PAnsiChar(c));
    {$ELSE}
    Result := Sysutils.StrCharLength(PAnsiChar(c));
    {$IFEND}
    {$ENDIF}
    {$ELSE}
    Result := StrCharLength(PAnsiChar(c));
    {$ENDIF}
end;

function CharSizeU(c: PAnsiChar): Integer;
begin
  if (Ord(c^) and $80) = 0 then
    Result := 1
  else begin
    if (Ord(c^) and $FC) = $FC then //4000000+
      Result := 6
    else if (Ord(c^) and $F8)=$F8 then//200000-3FFFFFF
      Result := 5
    else if (Ord(c^) and $F0)=$F0 then//10000-1FFFFF
      Result := 4
    else if (Ord(c^) and $E0)=$E0 then//800-FFFF
      Result := 3
    else if (Ord(c^) and $C0)=$C0 then//80-7FF
      Result := 2
    else
      Result := 1;
  end
end;

function CharSizeW(c: PWideChar): Integer;
begin
  if (c[0]>=#$DB00) and (c[0]<=#$DBFF) and (c[1] >= #$DC00) and (c[1] <= #$DFFF) then
    Result := 2
  else
    Result := 1;
end;

function DetectTextEncoding(const p: Pointer; L: Integer; var b: Boolean): TTextEncoding;
const
  NoUtf8Char: array [0 .. 3] of Byte = ($C1, $AA, $CD, $A8); // ANSI�������ͨ
var
  pAnsi: PByte;
  pWide: PWideChar;
  I, AUtf8CharSize: Integer;

  function IsUtf8Order(var ACharSize:Integer):Boolean;
  var
    I: Integer;
    ps: PByte;
  const
    Utf8Masks:array [0..4] of Byte=($C0, $E0, $F0, $F8, $FC);
  begin
    ps := pAnsi;
    ACharSize := CharSizeU(PAnsiChar(ps));
    Result := False;
    if ACharSize > 1 then begin
      I := ACharSize-2;
      if ((Utf8Masks[I] and ps^) = Utf8Masks[I]) then begin
        Inc(ps);
        Result:=True;
        for I := 1 to ACharSize-1 do begin
          if (ps^ and $80)<>$80 then begin
            Result:=False;
            Break;
          end;
          Inc(ps);
        end;
      end;
    end;
  end;

begin
  Result := teAnsi;
  b := false;
  if L >= 2 then begin
    pAnsi := PByte(p);
    pWide := PWideChar(p);
    b := True;
    if pWide^ = #$FEFF then
      Result := teUnicode16LE
    else if pWide^ = #$FFFE then
      Result := teUnicode16BE
    else if L >= 3 then begin
      if (pAnsi^ = $EF) and (PByte(IntPtr(pAnsi) + 1)^ = $BB) and
        (PByte(IntPtr(pAnsi) + 2)^ = $BF) then // UTF-8����
        Result := teUTF8
      else begin// ����ַ����Ƿ��з���UFT-8���������ַ���11...
        b := false;
        Result := teUnknown;//�����ļ�ΪUTF8���룬Ȼ�����Ƿ��в�����UTF-8���������
        I := 0;
        Dec(L, 2);
        while I<=L do begin
          if (pAnsi^ and $80) <> 0 then begin // ��λΪ1
            if (l - I >= 4) then begin
              if CompareMem(pAnsi, @NoUtf8Char[0], 4) then begin
                // ��ͨ��������Ե�������UTF-8������ж�����
                Inc(pAnsi, 4);
                Inc(I, 4);
                continue;
              end;
            end;
            if IsUtf8Order(AUtf8CharSize) then begin
              if AUtf8CharSize>2 then begin//���ִ���2���ֽڳ��ȵ�UTF8���У�99%����UTF-8�ˣ������ж�
                Result := teUTF8;
                Break;
              end;
              Inc(pAnsi,AUtf8CharSize);
              Inc(I, AUtf8CharSize);
            end else begin
              Result:=teAnsi;
              Break;
            end;
          end else begin
            if pAnsi^=0 then begin //00 xx (xx<128) ��λ��ǰ����BE����
              if PByte(IntPtr(pAnsi)+1)^<128 then begin
                Result := teUnicode16BE;
                Break;
              end;
            end else if PByte(IntPtr(pAnsi)+1)^=0 then begin//xx 00 ��λ��ǰ����LE����
              Result:=teUnicode16LE;
              Break;
            end;
            Inc(pAnsi);
            Inc(I);
          end;
        end;
        if Result = teUnknown then
          Result := teAnsi;
      end;
    end;
  end;
end;

{$IFDEF USE_STRENCODEFUNC}
function AnsiEncode(p:PWideChar; l:Integer): AnsiString;
var
  ps: PWideChar;
  {$IFDEF MSWINDOWS}
  len: Integer;
  {$ENDIF}
begin
  if l<=0 then begin
    ps:=p;
    while ps^<>#0 do Inc(ps);
    l:=ps-p;
  end;
  if l>0 then  begin
    {$IFDEF MSWINDOWS}
    len := WideCharToMultiByte(CP_ACP,0,p,l,nil,0,nil,nil);
    SetLength(Result, len);
    WideCharToMultiByte(CP_ACP,0,p,l,PAnsiChar(Result), len, nil, nil);
    {$ELSE}
    Result.Length:=l shl 1;
    Result.FValue[0]:=0;
    Move(p^,PAnsiChar(Result)^,l shl 1);
    Result:=TEncoding.Convert(TEncoding.Unicode,TEncoding.ANSI,Result.FValue,1,l shl 1);
    {$ENDIF}
  end else
    Result := '';
end;
{$ENDIF}

function LeftStr(const AText: AnsiString; const ACount: Integer): AnsiString; 
begin
  Result := Copy(AText, 1, ACount);
end;

function LeftStr(const AText: WideString; const ACount: Integer): WideString;
begin
  Result := Copy(AText, 1, ACount);
end;

function RightStr(const AText: AnsiString; const ACount: Integer): AnsiString;
begin
  Result := Copy(AText, Length(AText) + 1 - ACount, ACount);
end;

function RightStr(const AText: WideString; const ACount: Integer): WideString;
begin
  Result := Copy(AText, Length(AText) + 1 - ACount, ACount);
end;

function MidStr(const AText: AnsiString; const AStart, ACount: Integer): AnsiString;
begin
  Result := Copy(AText, AStart, ACount);
end;

function MidStr(const AText: WideString; const AStart, ACount: Integer): WideString;
begin
  Result := Copy(AText, AStart, ACount);
end;

{$IFDEF USE_STRENCODEFUNC}
function AnsiEncode(const p: StringW):AnsiString;
begin
  Result := AnsiEncode(PWideChar(p), Length(p));
end;
{$ENDIF}

{$IFDEF USE_STRENCODEFUNC} {$IFNDEF MSWINDOWS}
function AnsiDecode(const S: AnsiString): StringW;
begin
  if S.IsUtf8 then
    Result := Utf8Decode(S)
  else
    Result := TEncoding.ANSI.GetString(S.FValue, 1, S.Length);
end;
{$ENDIF} {$ENDIF}

{$IFDEF USE_STRENCODEFUNC}
function AnsiDecode(p: PAnsiChar; l:Integer): StringW;
var
  ps: PAnsiChar;
{$IFNDEF MSWINDOWS}
  ABytes:TBytes;
{$ENDIF}
begin
  if l<=0 then begin
    ps := p;
    while ps^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do Inc(ps);
    l:=IntPtr(ps)-IntPtr(p);
  end;
  if l>0 then begin
    {$IFDEF MSWINDOWS}
    System.SetLength(Result, MultiByteToWideChar(CP_ACP,0,PAnsiChar(p),l,nil,0));
    MultiByteToWideChar(CP_ACP, 0, PAnsiChar(p),l,PWideChar(Result),Length(Result));
    {$ELSE}
    System.SetLength(ABytes, l);
    Move(p^, PByte(@ABytes[0])^, l);
    Result := TEncoding.ANSI.GetString(ABytes);
    {$ENDIF}
  end else
    System.SetLength(Result,0);
end;
{$ENDIF}

{$IFDEF USE_STRENCODEFUNC}
function Utf8Encode(const p: StringW): AnsiString;
begin
  Result := Utf8Encode(PWideChar(p), Length(p));
end;

function Utf8Encode(p:PWideChar; l:Integer): AnsiString;
var
  ps:PWideChar;
  pd,pds:PAnsiChar;
  c:Cardinal;
begin
  if p=nil then
    Result := ''
  else begin
    if l<=0 then begin
      ps:=p;
      while ps^<>#0 do
        Inc(ps);
      l:=ps-p;
      end;
    {$IFDEF NEXTGEN}
    Result.Length:=l*6;
    {$ELSE}
    SetLength(Result, l*6);//UTF8ÿ���ַ����6�ֽڳ�,һ���Է����㹻�Ŀռ�
    {$ENDIF}
    if l>0 then begin
      Result[1] := {$IFDEF NEXTGEN}1{$ELSE}#1{$ENDIF};
      ps:=p;
      pd:=PAnsiChar(Result);
      pds:=pd;
      while l>0 do begin
        c:=Cardinal(ps^);
        Inc(ps);
        if (c>=$D800) and (c<=$DFFF) then begin//Unicode ��չ���ַ�
          c:=(c-$D800);
          if (ps^>=#$DC00) and (ps^<=#$DFFF) then begin
            c:=$10000+((c shl 10) + (Cardinal(ps^)-$DC00));
            Inc(ps);
            Dec(l);
          end else
            raise Exception.Create(Format(SBadUnicodeChar,[IntPtr(ps^)]));
        end;
        Dec(l);
        if c=$0 then begin
          if JavaFormatUtf8 then begin//����Java��ʽ���룬��#$0�ַ�����Ϊ#$C080
            pd^:={$IFDEF NEXTGEN}$C0{$ELSE}#$C0{$ENDIF};
            Inc(pd);
            pd^:={$IFDEF NEXTGEN}$80{$ELSE}#$80{$ENDIF};
            Inc(pd);
          end else begin
            pd^:=AnsiChar(c);
            Inc(pd);
          end;
        end else if c<=$7F then begin //1B
          pd^:=AnsiChar(c);
          Inc(pd);
        end else if c<=$7FF then begin//$80-$7FF,2B
          pd^:=AnsiChar($C0 or (c shr 6));
          Inc(pd);
          pd^:=AnsiChar($80 or (c and $3F));
          Inc(pd);
        end else if c<=$FFFF then begin //$8000 - $FFFF,3B
          pd^:=AnsiChar($E0 or (c shr 12));
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 6) and $3F));
          Inc(pd);
          pd^:=AnsiChar($80 or (c and $3F));
          Inc(pd);
        end else if c<=$1FFFFF then begin //$01 0000-$1F FFFF,4B
          pd^:=AnsiChar($F0 or (c shr 18));//1111 0xxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 12) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 6) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or (c and $3F));//10 xxxxxx
          Inc(pd);
        end else if c<=$3FFFFFF then begin//$20 0000 - $3FF FFFF,5B
          pd^:=AnsiChar($F8 or (c shr 24));//1111 10xx
          Inc(pd);
          pd^:=AnsiChar($F0 or ((c shr 18) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 12) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 6) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or (c and $3F));//10 xxxxxx
          Inc(pd);
        end else if c<=$7FFFFFFF then begin //$0400 0000-$7FFF FFFF,6B
          pd^:=AnsiChar($FC or (c shr 30));//1111 11xx
          Inc(pd);
          pd^:=AnsiChar($F8 or ((c shr 24) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($F0 or ((c shr 18) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 12) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or ((c shr 6) and $3F));//10 xxxxxx
          Inc(pd);
          pd^:=AnsiChar($80 or (c and $3F));//10 xxxxxx
          Inc(pd);
        end;
      end;
      pd^:={$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF};
      {$IFDEF NEXTGEN}
      Result.Length := IntPtr(pd)-IntPtr(pds);
      {$ELSE}
      SetLength(Result, IntPtr(pd)-IntPtr(pds));
      {$ENDIF}
    end;
  end;
end;
{$ENDIF}

{$IFDEF USE_STRENCODEFUNC} {$IFNDEF MSWINDOWS}
function Utf8Decode(const S: AnsiString): StringW; overload;
begin
  if S.IsUtf8 then
    Result := Utf8Decode(PAnsiChar(S), S.Length)
  else
    Result := AnsiDecode(S);
end;
{$ENDIF} {$ENDIF}

{$IFDEF USE_STRENCODEFUNC}
function Utf8Decode(p: PAnsiChar; l: Integer): StringW;
var
  ps,pe: PByte;
  pd,pds: PWord;
  c: Cardinal;
begin
  if l<=0 then begin
    ps:=PByte(p);
    while ps^<>0 do Inc(ps);
    l := Integer(ps) - Integer(p);
  end;
  ps := PByte(p);
  pe := ps;
  Inc(pe, l);
  System.SetLength(Result, l);
  pd := PWord(PWideChar(Result));
  pds := pd;
  while Integer(ps)<Integer(pe) do begin
    if (ps^ and $80)<>0 then begin
      if (ps^ and $FC)=$FC then begin //4000000+
        c:=(ps^ and $03) shl 30;
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 24);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 18);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 12);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 6);
        Inc(ps);
        c:=c or (ps^ and $3F);
        Inc(ps);
        c:=c-$10000;
        pd^:=$D800+((c shr 10) and $3FF);
        Inc(pd);
        pd^:=$DC00+(c and $3FF);
        Inc(pd);
      end else if (ps^ and $F8)=$F8 then begin //200000-3FFFFFF
        c:=(ps^ and $07) shl 24;
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 18);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 12);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 6);
        Inc(ps);
        c:=c or (ps^ and $3F);
        Inc(ps);
        c:=c-$10000;
        pd^:=$D800+((c shr 10) and $3FF);
        Inc(pd);
        pd^:=$DC00+(c and $3FF);
        Inc(pd);
      end else if (ps^ and $F0)=$F0 then begin //10000-1FFFFF
        c:=(ps^ and $0F) shr 18;
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 12);
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 6);
        Inc(ps);
        c:=c or (ps^ and $3F);
        Inc(ps);
        c:=c-$10000;
        pd^:=$D800+((c shr 10) and $3FF);
        Inc(pd);
        pd^:=$DC00+(c and $3FF);
        Inc(pd);
      end else if (ps^ and $E0)=$E0 then begin //800-FFFF
        c:=(ps^ and $1F) shl 12;
        Inc(ps);
        c:=c or ((ps^ and $3F) shl 6);
        Inc(ps);
        c:=c or (ps^ and $3F);
        Inc(ps);
        pd^:=c;
        Inc(pd);
      end else if (ps^ and $C0)=$C0 then begin //80-7FF
        pd^:=(ps^ and $3F) shl 6;
        Inc(ps);
        pd^:=pd^ or (ps^ and $3F);
        Inc(pd);
        Inc(ps);
      end else
        raise Exception.Create(Format('��Ч��UTF8�ַ�:%d',[Integer(ps^)]));
    end else begin
      pd^ := ps^;
      Inc(ps);
      Inc(pd);
    end;
  end;
  System.SetLength(Result, (Integer(pd)-Integer(pds)) shr 1);
end;
{$ENDIF}

{$IFDEF USE_STRENCODEFUNC}
function LoadTextA(AStream: TStream; AEncoding: TTextEncoding): StringA;
var
  ASize: Integer;
  ABuffer: TBytes;
  ABomExists: Boolean;
begin
  ASize := AStream.Size - AStream.Position;
  if ASize > 0 then begin
    SetLength(ABuffer, ASize);
    AStream.ReadBuffer((@ABuffer[0])^, ASize);
    if AEncoding in [teUnknown,teAuto] then
      AEncoding := DetectTextEncoding(@ABuffer[0], ASize, ABomExists);
    if AEncoding=teAnsi then
      Result := AnsiString(ABuffer)
    else if AEncoding = teUTF8 then begin
      if ABomExists then
        Result := AnsiEncode(Utf8Decode(@ABuffer[3], ASize-3))
      else
        Result := AnsiEncode(Utf8Decode(@ABuffer[0], ASize));
      end
    else begin
      if AEncoding = teUnicode16BE then
        ExchangeByteOrder(@ABuffer[0],ASize);
      if ABomExists then
        Result := AnsiEncode(PWideChar(@ABuffer[2]), (ASize-2) shr 1)
      else
        Result := AnsiEncode(PWideChar(@ABuffer[0]), ASize shr 1);
    end;
  end else
    Result := '';
end;

function LoadTextU(AStream: TStream; AEncoding: TTextEncoding): StringA;
var
  ASize: Integer;
  ABuffer: TBytes;
  ABomExists: Boolean;
  P: PAnsiChar;
begin
  ASize := AStream.Size - AStream.Position;
  if ASize>0 then begin
    SetLength(ABuffer, ASize);
    AStream.ReadBuffer((@ABuffer[0])^, ASize);
    if AEncoding in [teUnknown, teAuto] then
      AEncoding:=DetectTextEncoding(@ABuffer[0],ASize,ABomExists)
    else if ASize>=2 then begin
      case AEncoding of
        teUnicode16LE:
          ABomExists:=(ABuffer[0]=$FF) and (ABuffer[1]=$FE);
        teUnicode16BE:
          ABomExists:=(ABuffer[1]=$FE) and (ABuffer[1]=$FF);
        teUTF8:
          begin
            if ASize>3 then
              ABomExists:=(ABuffer[0]=$EF) and (ABuffer[1]=$BB) and (ABuffer[2]=$BF)
            else
              ABomExists:=False;
          end;
      end;
    end else
      ABomExists:=False;
    if AEncoding=teAnsi then
      Result := YxdStr.Utf8Encode(AnsiDecode(@ABuffer[0], ASize))
    else if AEncoding = teUTF8 then begin
      if ABomExists then begin
        Dec(ASize, 3);
        {$IFDEF NEXTGEN}
        Result.From(@ABuffer[0], 3, ASize);
        {$ELSE}
        SetLength(Result, ASize);
        P := @ABuffer[0];
        Inc(P, 3);
        Move(P^, PAnsiChar(@Result[1])^, ASize);
        {$ENDIF}
      end else
        Result := AnsiString(ABuffer);
    end else begin
      if AEncoding=teUnicode16BE then
        ExchangeByteOrder(@ABuffer[0],ASize);
      if ABomExists then
        Result := Utf8Encode(PWideChar(@ABuffer[2]), (ASize-2) shr 1)
      else
        Result := Utf8Encode(PWideChar(@ABuffer[0]), ASize shr 1);
      end;
    end
  else
    Result := '';
end;

function LoadTextW(AStream: TStream; AEncoding: TTextEncoding): StringW;
var
  ASize: Integer;
  ABuffer: TBytes;
  ABomExists: Boolean;
begin
  ASize := AStream.Size - AStream.Position;
  if ASize>0 then begin
    SetLength(ABuffer, ASize);
    AStream.ReadBuffer((@ABuffer[0])^, ASize);
    ABomExists := False;
    // �����Ƿ�ָ�����룬ǿ�Ƽ��BOMͷ���������ڱ���ָ�������������
    if (ABuffer[0]=$FF) and (ABuffer[1]=$FE) then begin
      ABomExists := True;
      AEncoding := teUnicode16LE;
    end else if (ABuffer[1]=$FE) and (ABuffer[1]=$FF) then begin
      ABomExists := True;
      AEncoding := teUnicode16BE;
    end else if (ASize > 3) and (ABuffer[0]=$EF) and (ABuffer[1]=$BB) and (ABuffer[2]=$BF) then begin
      ABomExists := True;
      AEncoding := teUTF8;
    end else if AEncoding in [teUnknown, teAuto] then
      AEncoding := DetectTextEncoding(@ABuffer[0], ASize, ABomExists);

    if AEncoding = teAnsi then
      Result := AnsiDecode(@ABuffer[0], ASize)
    else if AEncoding = teUTF8 then begin
      if ABomExists then
        Result := Utf8Decode(@ABuffer[3], ASize-3)
      else
        Result := Utf8Decode(@ABuffer[0], ASize);
    end else begin
      if AEncoding = teUnicode16BE then
        ExchangeByteOrder(@ABuffer[0], ASize);
      if ABomExists then begin
        Dec(ASize, 2);
        SetLength(Result, ASize shr 1);
        Move(ABuffer[2], PWideChar(Result)^, ASize);
      end else begin
        SetLength(Result, ASize shr 1);
        Move(ABuffer[0], PWideChar(Result)^, ASize);
      end;
    end;
  end else
    Result := '';
end;
{$ENDIF}

{$IFDEF NEXTGEN}
{ AnsiString }
procedure AnsiString.From(p: PAnsiChar; AOffset, ALen: Integer);
begin
  SetLength(ALen);
  Inc(P, AOffset);
  Move(P^, PAnsiChar(@FValue[1])^,ALen);
end;

function AnsiString.GetChars(AIndex: Integer): AnsiChar;
begin
  if (AIndex<0) or (AIndex >= Length) then
    raise Exception.CreateFmt(SOutOfIndex, [AIndex, 0, Length - 1]);
  Result:=FValue[AIndex+1];
end;

class operator AnsiString.Implicit(const S: WideString): AnsiString;
begin
  Result := AnsiEncode(S);
end;

class operator AnsiString.Implicit(const S: AnsiString): PAnsiChar;
begin
  Result:=PansiChar(@S.FValue[1]);
end;

function AnsiString.GetIsUtf8: Boolean;
begin
  if System.Length(FValue)>0 then
    Result:=(FValue[0]=1)
  else
    Result:=False;
end;

function AnsiString.GetLength: Integer;
begin
  //FValue[0]�����������ͣ�0-ANSI,1-UTF8��ĩβ�����ַ�����\0������
  Result := System.Length(FValue);
  if Result>=2 then
    Dec(Result,2)
  else
    Result:=0;
end;

class operator AnsiString.Implicit(const S: AnsiString): TBytes;
var
  L:Integer;
begin
  L:=System.Length(S.FValue)-1;
  System.SetLength(Result,L);
  if L>0 then
    Move(S.FValue[1],Result[0],L);
end;

procedure AnsiString.SetChars(AIndex: Integer; const Value: AnsiChar);
begin
  if (AIndex<0) or (AIndex>=Length) then
    raise Exception.CreateFmt(SOutOfIndex,[AIndex,0,Length-1]);
  FValue[AIndex+1]:=Value;
end;

procedure AnsiString.SetLength(const Value: Integer);
begin
  if Value<0 then begin
    if System.Length(FValue)>0 then
      System.SetLength(FValue,1)
    else begin
      System.SetLength(FValue,1);
      FValue[0]:=0;//ANSI
    end;
  end else begin
    System.SetLength(FValue,Value+2);
    FValue[Value+1]:=0;
  end;
end;

class operator AnsiString.Implicit(const ABytes: TBytes): AnsiString;
var
  L:Integer;
begin
  L:=System.Length(ABytes);
  Result.Length:=L;
  if L>0 then
    Move(ABytes[0],Result.FValue[1],L);
end;

class operator AnsiString.Implicit(const S: AnsiString): WideString;
begin
  Result := AnsiDecode(S);
end;
{$ENDIF}

{ TStringCatHelper }

function TStringCatHelper.Back(ALen: Integer): TStringCatHelper;
begin
  Result := Self;
  Dec(FDest, ALen);
  if FDest < PChar(FValue) then
    FDest := PChar(FValue);
end;

function TStringCatHelper.BackIf(const s: PChar): TStringCatHelper;
var
  ps: PChar;
begin
  Result := Self;
  ps := PChar(FValue);
  while FDest > ps do begin
    {$IFDEF UNICODE}
    if (FDest[-1] >= #$DC00) and (FDest[-1] <= #$DFFF) then begin
      if CharIn(FDest-2, s) then
        Dec(FDest, 2)
      else
        Break;
    end else if CharIn(FDest-1,s) then
      Dec(FDest)
    else
      Break;
    {$ELSE}
    if CharIn(FDest-1, s) then
      Dec(FDest)
    else
      Break;
    {$ENDIF}
  end;
end;

function TStringCatHelper.Cat(const s: string): TStringCatHelper;
begin
  Result := Cat(PChar(s), Length(s));
end;

function TStringCatHelper.Cat(c: Char): TStringCatHelper;
begin
  if (FDest-FStart)=FSize then
    NeedSize(-1);
  FDest^ := c;
  Inc(FDest);
  Result := Self;
end;

function TStringCatHelper.Cat(p: PChar;
  len: Integer): TStringCatHelper;
begin
  Result := Self;
  if len < 0 then begin
    while p^ <> #0 do begin
      if FDest-FStart >= FSize then
        NeedSize(FSize + FBlockSize);
      FDest^ := p^;
      Inc(p);
      Inc(FDest);
    end;
  end else begin
    NeedSize(-len);
    Move(p^, FDest^, len{$IFDEF UNICODE} shl 1{$ENDIF});
    Inc(FDest, len);
  end;
end;

function TStringCatHelper.Cat(const V: Boolean): TStringCatHelper;
begin
  Result := Cat(BoolToStr(V));
end;

function TStringCatHelper.Cat(const V: Double): TStringCatHelper;
begin
  Result := Cat(FloatToStr(V));
end;

function TStringCatHelper.Cat(const V: Int64): TStringCatHelper;
begin
  Result := Cat(IntToStr(V));
end;

function TStringCatHelper.Cat(const V: Variant): TStringCatHelper;
begin
  Result := Cat(VarToStr(V));
end;

function TStringCatHelper.Cat(const V: TGuid): TStringCatHelper;
begin
  Result := Cat(GuidToString(V));
end;

function TStringCatHelper.Cat(const V: Currency): TStringCatHelper;
begin
  Result := Cat(CurrToStr(V));
end;

constructor TStringCatHelper.Create(ASize: Integer);
begin
  inherited Create;
  FBlockSize := ASize;
  NeedSize(FBlockSize);
end;

destructor TStringCatHelper.Destroy;
begin
  SetLength(FValue, 0);
  inherited;
end;

constructor TStringCatHelper.Create;
begin
  inherited Create;
  FBlockSize := 4096;
  NeedSize(FBlockSize);
end;

function TStringCatHelper.GetChars(AIndex: Integer): Char;
begin
  Result := FStart[AIndex];
end;

function TStringCatHelper.GetPosition: Integer;
begin
  Result := FDest - PChar(FValue);
end;

function TStringCatHelper.GetValue: string;
var
  L: Integer;
begin
  L := FDest - PChar(FValue);
  SetLength(Result, L);
  Move(FStart^, PChar(Result)^, L{$IFDEF UNICODE} shl 1{$ENDIF});
end;

procedure TStringCatHelper.NeedSize(ASize: Integer);
var
  offset:Integer;
begin
  offset := FDest-FStart;
  if ASize < 0 then
    ASize := offset - ASize;
  if ASize > FSize then begin
    FSize := ((ASize + FBlockSize) div FBlockSize) * FBlockSize;
    SetLength(FValue, FSize);
    FStart := PChar(@FValue[0]);
    FDest := FStart + offset;
  end;
end;

procedure TStringCatHelper.Reset;
begin
  FDest := FStart;
end;

function TStringCatHelper.Space(count: Integer): TStringCatHelper;
begin
{$IFDEF UNICODE}
  Result := Self;
  if Count > 0 then begin
    while Count>0 do begin
      Cat(' ');
      Dec(Count);
    end;
  end;
{$ELSE}
  Result := Self;
  if Count > 0 then begin
    while Count>0 do begin
      Cat(' ');
      Dec(Count);
    end;
  end;
{$ENDIF}
end;

procedure TStringCatHelper.SetPosition(const Value: Integer);
begin
  if Value <= 0 then
    FDest := PChar(FValue)
  else if Value>Length(FValue) then begin
    NeedSize(Value);
    FDest := PChar(FValue) + Value;
  end else
    FDest := PChar(FValue) + Value;
end;

function TStringCatHelper.Cat(const V: TStream): TStringCatHelper;
const
  BufSize = 4096;
var
  I: Integer;
  Buf: array [0..BufSize-1] of Byte;
begin
  Result := Self;
  if Assigned(V) then begin
    I := Length(Buf);
    while I = BufSize do begin
      I := V.Read(Buf, BufSize);
      if I > 0 then
        Cat(@Buf[0], I);
    end;
  end;
end;

{ TStringArray }

function TStringArray.Add(const P: PChar; const Len: Integer): Integer;
begin
  if (not Assigned(FOnFilter)) or (FOnFilter(Self, P, Len)) then begin
    Result := FCount;
    if Result = FCapacity then
      Grow;
    FList[Result].P := P;
    FList[Result].Len := Len;
    Inc(FCount);
  end else
    Result := -1;
end;

procedure TStringArray.CheckIndex(const Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then
    raise Exception.Create(Format(SOutOfIndex,[Index, 0, FCount - 1]));
end;

procedure TStringArray.Clear;
begin
  FCount := 0;
end;

const
  Convert: array[0..127] of Integer =
    (
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
     );
     
function PCharToFloat(const S: PChar; Len: Integer): Double;
var
  I, K, V, M: Integer;
begin
  Result := 0;
  K := 0;
  M := 10;
  for i := 0 to len - 1 do begin
    V := Convert[Ord(s[i])];
    if (s[i] = '.') and (k = 0) then Inc(k);
    if (V < 0) then begin
      if (k > 1) then begin
        Result := 0;
        Exit;
      end;
    end else begin
      if k = 0 then
        Result := (result * 10) + V
      else begin
        Result := Result + V / M;
        M := M * 10;
      end;
    end;
  end;
end;

function TStringArray.GetFloat(const Index: Integer): Double;
var
  P: PStringArrayItem;
begin
  P := @FList[index];
  if P.P = nil then
    Result := 0
  else
    Result := PCharToFloat(P.P, P.Len);
end;

function TStringArray.GetItem(const Index: Integer): string;
begin
  CheckIndex(Index);
  GetString(Index, Result);
end;

function TStringArray.GetItemValue(const Index: Integer): PStringArrayItem;
begin
  Result := @FList[index];
end;

procedure TStringArray.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then Delta := FCapacity div 4 else
    if FCapacity > 8 then Delta := 16 else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

function TStringArray.GetValue(const Index: Integer): PStringArrayItem;
begin
  CheckIndex(Index);
  Result := @FList[index];
end;

procedure TStringArray.GetString(const Index: Integer; var Data: string);
var
  P: PStringArrayItem;
begin
  P := @FList[index];
  if P.P = nil then
    Data := ''
  else
    SetString(Data, P.P, P.Len);
end;

function TStringArray.GetText(const ADelimiter: string): string;
var
  S: TStringCatHelper;
  I: Integer;
begin
  if Length(FList) > 0 then begin
    S := TStringCatHelper.Create;
    for I := 0 to FCount - 1 do begin
      S.Cat(FList[I].P, FList[I].Len);
      if I < FCount - 1 then
        S.Cat(ADelimiter);
    end;
    Result := S.Value;
    S.Free;
  end else
    Result := '';
end;

procedure TStringArray.SetCapacity(NewCapacity: Integer);
begin
  SetLength(FList, NewCapacity);
  FCapacity := NewCapacity;
end;

procedure TStringArray.SetDelimitedData(const Value: Pointer; const Len: Integer);
var
  P, P1, PMax: PChar;
  C: Char;
begin
  if Value = nil then Exit;
  FCount := 0;
  FData := '';
  P := Value;
  C := FDelimiter;
  P1 := P;
  PMax := P + Len;
  while True do begin
    if P = PMax then begin
      Add(P1, P - P1);
      Break;
    end else if P^ = C then begin
      Add(P1, P - P1);
      Inc(P);
      P1 := P;
    end else
      Inc(P);
  end;
end;

procedure TStringArray.SetDelimitedText(const Value: string);
var
  P, P1, PMax: PChar;
  C: Char;
begin
  FCount := 0;
  FData := Value;
  P := Pointer(Value);
  if P = nil then Exit;
  C := FDelimiter;
  P1 := P;
  PMax := P + Length(Value);
  while True do begin
    if P = PMax then begin
      Add(P1, P - P1);
      Break;
    end else if P^ = C then begin
      Add(P1, P - P1);
      Inc(P);
      P1 := P;
    end else
      Inc(P);
  end;
end;

procedure TStringArray.SetText(const Value: string);
var
  P, P1, PMax: PChar;
begin
  FCount := 0;
  FData := Value;
  P := Pointer(Value);
  if P = nil then Exit;
  P1 := P;
  PMax := P + Length(Value);
  while True do begin
    if P = PMax then begin
      Add(P1, P - P1);
      Break;
    end else if (P^ = #13) then begin
      Add(P1, P - P1);
      Inc(P);
      if (P^ = #10) then
        Inc(P);
      P1 := P;
    end else if (P^ = #10) then begin
      Add(P1, P - P1);
      Inc(P);
      if (P^ = #13) then
        Inc(P);
      P1 := P;
    end else
      Inc(P);
  end; 
end;

{ TStringArrayS }

function TStringArrayS.Add(const S: string): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  FList[Result] := S;
  Inc(FCount);
end;

function TStringArrayS.Add(const P: PChar; const Len: Integer): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  SetString(FList[Result], P, Len);
  Inc(FCount);
end;

procedure TStringArrayS.Clear;
begin
  FCount := 0;
end;

function TStringArrayS.GetItem(const Index: Integer): string;
begin
  if (Index < 0) or (Index >= FCount) then
    raise Exception.Create(Format(SOutOfIndex,[Index, 0, FCount - 1]));
  Result := FList[index];
end;

procedure TStringArrayS.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then Delta := FCapacity div 4 else
    if FCapacity > 8 then Delta := 16 else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

procedure TStringArrayS.SetCapacity(NewCapacity: Integer);
begin
  SetLength(FList, NewCapacity);
  FCapacity := NewCapacity;
end;

procedure TStringArrayS.SetDelimitedText(const Value: string);
var
  P, P1: PChar;
  C: Char;
begin
  FCount := 0;
  FData := Value;
  C := FDelimiter;
  P := PChar(Value);
  P1 := P;
  while True do begin
    if P^ = #0 then begin
      Add(P1, P - P1);
      Break;
    end else if P^ = C then begin
      Add(P1, P - P1);
      Inc(P);
      P1 := P;
    end else
      Inc(P);
  end;
end;

procedure TStringArrayS.SetItem(const Index: Integer; const Value: string);
begin
  FList[Index] := Value;
end; 

function IsHexChar(c: Char): Boolean; inline;
begin
  Result:=((c>='0') and (c<='9')) or
    ((c>='a') and (c<='f')) or
    ((c>='A') and (c<='F'));
end;

function HexValue(c: Char): Integer;
begin
  if (c>='0') and (c<='9') then
    Result := Ord(c) - Ord('0')
  else if (c>='a') and (c<='f') then
    Result := 10+ Ord(c)-Ord('a')
  else
    Result := 10+ Ord(c)-Ord('A');
end;

function HexChar(v: Byte): Char;
begin
  if v<10 then
    Result := Char(v + Ord('0'))
  else
    Result := Char(v-10 + Ord('A'));
end;

function BinToHex(p:Pointer;l:Integer): String;
const
  B2HConvert: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  pd: PChar;
  pb: PByte;
begin
  SetLength(Result, l shl 1);
  pd := PChar(Result);
  pb := p;
  while l>0 do begin
    pd^ := B2HConvert[pb^ shr 4];
    Inc(pd);
    pd^ := B2HConvert[pb^ and $0F];
    Inc(pd);
    Inc(pb);
    Dec(l);
  end;
end;

function BinToHex(const ABytes:TBytes): String;
begin
  Result:=BinToHex(@ABytes[0], Length(ABytes));
end;

procedure HexToBin(p: pointer; l: Integer; var AResult: TBytes);
var
  ps: PChar;
  pd: PByte;
begin
  SetLength(AResult, l shr 1);
  ps := p;
  pd := @AResult[0];
  while ps - p < l do begin
    if IsHexChar(ps[0]) and IsHexChar(ps[1]) then begin
      pd^:=(HexValue(ps[0]) shl 4) + HexValue(ps[1]);
      Inc(pd);
      Inc(ps, 2);
    end else begin
      SetLength(AResult, 0);
      Exit;
    end;
  end;
end;

function HexToBin(const S: String): TBytes;
begin
  HexToBin(PChar(S), System.Length(S), Result);
end;

procedure HexToBin(const S: String; var AResult: TBytes);
begin
  HexToBin(PChar(S), System.Length(S), AResult);
end;

function StrPosA(start, current: PAnsiChar; var ACol, ARow:Integer): PAnsiChar;
begin
  ACol := 1;
  ARow := 1;
  Result := start;
  while IntPtr(start) < IntPtr(current) do begin
    if start^={$IFDEF NEXTGEN}10{$ELSE}#10{$ENDIF} then begin
      Inc(ARow);
      ACol := 1;
      Inc(start);
      Result := start;
    end else begin
      Inc(start, CharSizeA(start));
      Inc(ACol);
    end;
  end;
end;

function StrPosU(start, current: PAnsiChar; var ACol, ARow:Integer): PAnsiChar;
begin
  ACol := 1;
  ARow := 1;
  Result := start;
  while IntPtr(start)<IntPtr(current) do begin
    if start^={$IFDEF NEXTGEN}10{$ELSE}#10{$ENDIF} then begin
      Inc(ARow);
      ACol := 1;
      Inc(start);
      Result := start;
    end else begin
      Inc(start, CharSizeU(start));
      Inc(ACol);
    end;
  end;
end;

function StrPosW(start, current: PWideChar; var ACol, ARow:Integer): PWideChar;
begin
  ACol := 1;
  ARow := 1;
  Result := start;
  while start < current do begin
    if start^=#10 then begin
      Inc(ARow);
      ACol := 1;
      Inc(start);
      Result := start;
    end else begin
      Inc(start, CharSizeW(start));
      Inc(ACol);
    end;
  end;
end;

function DecodeLineA(var p: PAnsiChar; ASkipEmpty: Boolean): StringA;
var
  ps: PAnsiChar;
  i: Integer;
begin
  ps := p;
  while p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if (PWORD(p)^ = $0D0A) or (PWORD(p)^ = $0A0D) then
      i := 2
    else if (p^ = {$IFDEF NEXTGEN}13{$ELSE}#13{$ENDIF}) then
      i := 1
    else
      i := 0;
    if i > 0 then begin
      if ps = p then begin
        if ASkipEmpty then begin
          Inc(p, i);
          ps := p;
        end else begin
          Result := '';
          Exit;
        end;
      end else begin
        {$IFDEF NEXTGEN}
        Result.Length := IntPtr(p)-IntPtr(ps);
        {$ELSE}
        SetLength(Result, p-ps);
        {$ENDIF}
        Move(ps^, PAnsiChar(Result)^, IntPtr(p)-IntPtr(ps));
        Inc(p, i);
        Exit;
      end;
    end else
      Inc(p);
  end;
  if ps = p then
    Result := ''
  else begin
    {$IFDEF NEXTGEN}
    Result.Length := IntPtr(p)-IntPtr(ps);
    {$ELSE}
    SetLength(Result, p-ps);
    {$ENDIF}
    Move(ps^, PAnsiChar(Result)^, IntPtr(p)-IntPtr(ps));
  end;
end;

function DecodeLineW(var p: PWideChar; ASkipEmpty: Boolean): StringW;
var
  ps: PWideChar;
  i: Integer;
begin
  ps := p;
  while p^<>#0 do begin
    if (PCardinal(p)^ = $000D000A) or (PCardinal(p)^ = $000A000D) then
      i := 2
    else if (p^ = #13) then
      i := 1
    else
      i := 0;
    if i > 0 then begin
      if ps = p then begin
        if ASkipEmpty then begin
          Inc(p, i);
          ps := p;
        end else begin
          Result := '';
          Exit;
        end;
      end else begin
        SetLength(Result, p-ps);
        Move(ps^, PWideChar(Result)^, p-ps);
        Inc(p, i);
        Exit;
      end;
    end else
      Inc(p);
  end;
  if ps = p then
    Result := ''
  else begin
    SetLength(Result, p-ps);
    Move(ps^, PWideChar(Result)^, p-ps);
  end;
end;

function IsSpaceA(const c: PAnsiChar; ASpaceSize: PInteger): Boolean;
begin
  {$IFDEF NEXTGEN}
  if c^ in [9, 10, 13, 32] then begin
  {$ELSE}
  if c^ in [#9, #10, #13, #32] then begin
  {$ENDIF}
    Result := True;
    if ASpaceSize <> nil then
      ASpaceSize^ := 1;
  end else if PWORD(c)^ = $A1A1 then begin
    Result := True;
    if ASpaceSize <> nil then
      ASpaceSize^ := 2;
  end else
    Result:=False;
end;

function IsSpaceW(const c: PWideChar; ASpaceSize: PInteger): Boolean;
begin
  Result := (c^=#9) or (c^=#10) or (c^=#13) or (c^=#32) or (c^=#$3000);
  if Result and (ASpaceSize <> nil) then
    ASpaceSize^ := 1;
end;

//ȫ�ǿո�$3000��UTF-8������227,128,128
function IsSpaceU(const c: PAnsiChar; ASpaceSize: PInteger): Boolean;
begin
  {$IFDEF NEXTGEN}
  if c^ in [9, 10, 13, 32] then begin
  {$ELSE}
  if c^ in [#9, #10, #13, #32] then begin
  {$ENDIF}
    Result := True;
    if (ASpaceSize <> nil) then
      ASpaceSize^ := 1;
  end else if (c^={$IFDEF NEXTGEN}227{$ELSE}#227{$ENDIF}) and (PWORD(IntPtr(c)+1)^ = $8080) then begin
    Result := True;
    if (ASpaceSize <> nil) then
      ASpaceSize^ := 3;
  end else
    Result:=False;
end;

function SkipSpaceA(var p: PAnsiChar): Integer;
var
  ps: PAnsiChar;
  L: Integer;
begin
  ps := p;
  while p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if IsSpaceA(p, @L) then
      Inc(p, L)
    else
      Break;
  end;
  Result:= IntPtr(p) - IntPtr(ps);
end;

function SkipSpaceU(var p: PAnsiChar): Integer;
var
  ps: PAnsiChar;
  L: Integer;
begin
  ps := p;
  while p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if IsSpaceU(p, @L) then
      Inc(p, L)
    else
      Break;
  end;
  Result:= IntPtr(p) - IntPtr(ps);
end;

function SkipSpaceW(var p: PWideChar): Integer;
var
  ps: PWideChar;
  L:Integer;
begin
  ps := p;
  while p^<>#0 do begin
    if IsSpaceW(p, @L) then
      Inc(p, L)
    else
      Break;
  end;
  Result := p - ps;
end;

function SkipLineA(var p: PAnsiChar): Integer;
var
  ps: PAnsiChar;
begin
  ps := p;
  while p^ <> {$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if (PWORD(p)^ = $0D0A) or (PWORD(p)^ = $0A0D) then begin
      Inc(p, 2);
      Break;
    end else if  (p^ = {$IFDEF NEXTGEN}13{$ELSE}#13{$ENDIF}) then begin
      Inc(p);
      Break;
    end else
      Inc(p);
  end;
  Result := IntPtr(p) - IntPtr(ps);
end;

function SkipLineU(var p: PAnsiChar): Integer;
begin
  Result := SkipLineA(p);
end;

function SkipLineW(var p: PWideChar): Integer;
var
  ps: PWideChar;
begin
  ps := p;
  while p^ <> #0 do begin
    if (PCardinal(p)^ = $000D000A) or (PCardinal(p)^ = $000A000D) then begin
      Inc(p, 2);
      Break;
    end else if  (p^ = #13) then begin
      Inc(p);
      Break;
    end else
      Inc(p);
  end;
  Result := p - ps;
end;

{$IFNDEF NEXTGEN}
function SkipUntilA(var p: PAnsiChar; AExpects: PAnsiChar; AQuoter: AnsiChar): Integer;
var
  ps: PAnsiChar;
begin
  ps := p;
  while p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
    if (p^ = AQuoter) then begin
      Inc(p);
      while p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} do begin
        if p^ = {$IFDEF NEXTGEN}$5C{$ELSE}#$5C{$ENDIF} then begin
          Inc(p);
          if p^<>{$IFDEF NEXTGEN}0{$ELSE}#0{$ENDIF} then
            Inc(p);
        end else if p^ = AQuoter then begin
          Inc(p);
          if p^ = AQuoter then
            Inc(p)
          else
            Break;
        end else
          Inc(p);
      end;
    end else if CharInA(p, AExpects) then
      Break
    else
      Inc(p, CharSizeA(p));
  end;
  Result := IntPtr(p) - IntPtr(ps);
end;
{$ENDIF}
{$IFNDEF NEXTGEN}
function SkipUntilU(var p: PAnsiChar; AExpects: PAnsiChar; AQuoter: AnsiChar): Integer;
var
  ps: PAnsiChar;
begin
  ps := p;
  while p^<>#0 do begin
    if (p^ = AQuoter) then begin
      Inc(p);
      while p^<>#0 do begin
        if p^=#$5C then begin
          Inc(p);
          if p^<>#0 then
            Inc(p);
        end else if p^=AQuoter then begin
          Inc(p);
          if p^=AQuoter then
            Inc(p)
          else
            Break;
        end else
          Inc(p);
      end;
    end else if CharInU(p, AExpects) then
      Break
    else
      Inc(p, CharSizeU(p));
  end;
  Result := p - ps;
end;
{$ENDIF}

function SkipUntilW(var p: PWideChar; AExpects: PWideChar; AQuoter: WideChar): Integer;
var
  ps: PWideChar;
begin
  ps := p;
  while p^<>#0 do begin
    if (p^=AQuoter) then begin
      Inc(p);
      while p^<>#0 do begin
        if p^=#$5C then begin
          Inc(p);
          if p^<>#0 then
            Inc(p);
        end else if p^=AQuoter then begin
          Inc(p);
          if p^=AQuoter then
            Inc(p)
          else
            Break;
        end else
          Inc(p);
      end;
    end else if CharInW(p, AExpects) then
      Break
    else
      Inc(p, CharSizeW(p));
  end;
  Result := p - ps;
end;

function StartWith(s, startby: PChar; AIgnoreCase: Boolean): Boolean;
begin
  while (s^<>#0) and (startby^<>#0) do begin
    if AIgnoreCase then begin
      {$IFDEF UNICODE}
      if CharUpperW(s^) <> CharUpperW(startby^) then
      {$ELSE}
      if CharUpperA(s^) <> CharUpperA(startby^) then
      {$ENDIF}
        Break;
    end else if s^ <> startby^ then
      Break;
    Inc(s);
    Inc(startby);
  end;
  Result := startby^ = #0;
end;

function StartWithIgnoreCase(s, startby: PChar): Boolean;
begin
  while (s^<>#0) and (startby^<>#0) do begin
    {$IFDEF UNICODE}
    if CharUpperW(s^) <> CharUpperW(startby^) then
    {$ELSE}
    if CharUpperA(s^) <> CharUpperA(startby^) then
    {$ENDIF}
      Break;
    Inc(s);
    Inc(startby);
  end;
  Result := startby^ = #0;
end;

procedure SaveTextA(AStream: TStream; const S: AnsiString);
begin
  AStream.WriteBuffer(PAnsiChar(S)^, Length(S))
end;

procedure SaveTextU(AStream: TStream; const S: AnsiString; AWriteBom: Boolean);

  procedure WriteBom;
  var
    ABom:TBytes;
  begin
    SetLength(ABom,3);
    ABom[0]:=$EF;
    ABom[1]:=$BB;
    ABom[2]:=$BF;
    AStream.WriteBuffer(ABom[0],3);
  end;

  procedure SaveAnsi;
  var
    T: AnsiString;
  begin
    T := YxdStr.Utf8Encode({$IFDEF NEXTGEN}AnsiDecode(S){$ELSE}string(S){$ENDIF});
    AStream.WriteBuffer(PAnsiChar(T)^, Length(T));
  end;

begin
  if AWriteBom then
    WriteBom;
  SaveAnsi;
end;

procedure SaveTextW(AStream: TStream; const S: StringW; AWriteBom: Boolean);
  procedure WriteBom;
  var
    bom: Word;
  begin
    bom := $FEFF;
    AStream.WriteBuffer(bom, 2);
  end;
begin
  if AWriteBom then
    WriteBom;
  AStream.WriteBuffer(PWideChar(S)^, System.Length(S) shl 1);
end;

procedure SaveTextWBE(AStream: TStream; const S: StringW; AWriteBom: Boolean);
var
  pw, pe: PWord;
  w: Word;
  ABuilder: TStringCatHelper;
begin
  pw := PWord(PWideChar(S));
  pe := pw;
  Inc(pe, Length(S));
  ABuilder := TStringCatHelper.Create(IntPtr(pe)-IntPtr(pw));
  try
    while IntPtr(pw)<IntPtr(pe) do begin
      w := (pw^ shr 8) or (pw^ shl 8);
      ABuilder.Cat(@w, 1);
      Inc(pw);
    end;
    if AWriteBom then
      AStream.WriteBuffer(#$FE#$FF, 2);
    AStream.WriteBuffer(ABuilder.Start^, Length(S) shl 1);
  finally
    ABuilder.Free;
  end;
end;


initialization
 {$IFDEF MSWINDOWS}
  hMsvcrtl := LoadLibrary('msvcrt.dll');
  if hMsvcrtl <> 0 then begin
    VCStrStr := TMSVCStrStr(GetProcAddress(hMsvcrtl, 'strstr'));
    VCStrStrW := TMSVCStrStrW(GetProcAddress(hMsvcrtl, 'wcsstr'));
    VCMemCmp := TMSVCMemCmp(GetProcAddress(hMsvcrtl, 'memcmp'));
  end else begin
    VCStrStr := nil;
    VCStrStrW := nil;
    VCMemCmp := nil;
  end;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  SysACP := GetACP();
  {$ELSE}
  SysACP := TEncoding.ANSI.CodePage
  {$ENDIF}

finalization
  {$IFDEF MSWINDOWS}
  if hMsvcrtl <> 0 then
    FreeLibrary(hMsvcrtl);
  {$ENDIF}

end.
 