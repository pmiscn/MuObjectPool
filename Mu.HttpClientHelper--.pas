unit Mu.HttpClientHelper;

interface

uses
  // Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants,
  System.Classes, qstring,
  System.Net.URLClient, System.NetConsts, System.Net.Mime,
  System.Net.HttpClient;

type
  TURLRequest_ = class helper for TURLRequest
  private
    function getSourceStream(): TStream;
    procedure setSourceStream(aStm: TStream);

    function getURL(): TURI;
    procedure setURL(aURL: TURI);
  protected
    // function DecodeCharset(p: PAnsiChar; ASize: Integer): string;
  public
    property SourceStream: TStream read getSourceStream write setSourceStream;
    property URL: TURI read getURL write setURL;
  end;

  THTTPRequest_ = class helper for THTTPRequest
  private
  protected
    // function DecodeCharset(p: PAnsiChar; ASize: Integer): string;
  public
    procedure DoPrepare;
  end;

  THTTPResponse_ = class helper for THTTPResponse
  private
    function getCharsetFromBody: string;
    function getStream(): TStream;
    procedure setStream(aStm: TStream);
  protected
    // function DecodeCharset(p: PAnsiChar; ASize: Integer): string;
  public
    property Stream: TStream read getStream write setStream;
    function GetContentCharSet: string; virtual;
    function ContentAsString(const AnEncoding: TEncoding = nil)
      : string; virtual;
  end;

  THttpClient_ = class helper for THttpClient
  private
    function getReferer(): String;
    procedure setReferer(aValue: string);
  protected

    function DoExecute(const ARequestMethod: string; const AURI: TURI;
      const ASourceStream, AContentStream: TStream; const AHeaders: TNetHeaders)
      : IURLResponse;

    function GetLastURL(): String;
    function GetDirectTimes(): Integer;

  public

    function Delete(const aURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;

    /// <summary>Send 'OPTIONS' command to url</summary>
    function Options(const aURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;

    /// <summary>Send 'GET' command to url</summary>
    function Get(const aURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;

    /// <summary>Send 'TRACE' command to url</summary>
    function Trace(const aURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;

    /// <summary>Send 'HEAD' command to url</summary>
    function Head(const aURL: string; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse;

    /// <summary>Post a raw file without multipart info</summary>
    function Post(const aURL: string; const ASourceFile: string;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse; overload;
    /// <summary>Post TStrings values adding multipart info</summary>
    function Post(const aURL: string; const ASource: TStrings;
      const AResponseContent: TStream = nil; const AEncoding: TEncoding = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Post a stream without multipart info</summary>
    function Post(const aURL: string; const ASource: TStream;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse; overload;
    /// <summary>Post a multipart form data object</summary>
    function Post(const aURL: string; const ASource: TMultipartFormData;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse; overload;

    /// <summary>Send 'PUT' command to url</summary>
    function Put(const aURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse;

    // Non standard command procedures ...
    /// <summary>Send 'MERGE' command to url</summary>
    function Merge(const aURL: string; const ASource: TStream;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send a special 'MERGE' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function MergeAlternative(const aURL: string; const ASource: TStream;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send 'PATCH' command to url</summary>
    function Patch(const aURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse;
    /// <summary>Send a special 'PATCH' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function PatchAlternative(const aURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse;

    /// <summary>You have to use this function to Execute a given Request</summary>
    /// <param name="ARequest">The request that is going to be Executed</param>
    /// <param name="AContentStream">The stream to store the response data. If provided the user is responsible
    /// of releasing it. If not provided will be created internally and released when not needed.</param>
    /// <param name="AHeaders">Additional Headers to pass to the request that is going to be Executed</param>
    /// <returns>The platform dependant response object associated to the given request. It's an Interfaced object and
    /// It's released automatically.</returns>
    { function Execute(const ARequest: IHTTPRequest;
      const AContentStream: TStream = nil; const AHeaders: TNetHeaders = nil)
      : IHTTPResponse; overload;
    }
    property Referer: string read getReferer write setReferer;
    Property URL: string read GetLastURL;
    property DirectTimes: Integer read GetDirectTimes;

  end;

function DecodeCharset(pp: pwidechar; ASize: Integer): string; overload;
function DecodeCharset(pp: pAnsichar; ASize: Integer): string; overload;

function getCharsetFromXmlBody(pp: QStringW): string; overload;
function getCharsetFromXmlBody(pp: QStringA): string; overload;

implementation

function ParseCharset(AName: AnsiString): Integer;
const
  CharsetNames: array [0 .. 140] of AnsiString = ('IBM037', 'IBM437', 'IBM500',
    'ASMO-708', 'DOS-720', 'ibm737', 'ibm775', 'ibm850', 'ibm852', 'IBM855',
    'ibm857', 'IBM00858', 'IBM860', 'ibm861', 'DOS-862', 'IBM863', 'IBM864',
    'IBM865', 'cp866', 'ibm869', 'IBM870', 'windows-874', 'cp875', 'shift_jis',
    'gb2312', 'ks_c_5601-1987', 'big5', 'IBM1026', 'IBM01047', 'IBM01140',
    'IBM01141', 'IBM01142', 'IBM01143', 'IBM01144', 'IBM01145', 'IBM01146',
    'IBM01147', 'IBM01148', 'IBM01149', 'utf-16', 'UnicodeFFFE', 'windows-1250',
    'windows-1251', 'Windows-1252', 'windows-1253', 'windows-1254',
    'windows-1255', 'windows-1256', 'windows-1257', 'windows-1258', 'Johab',
    'macintosh', 'x-mac-japanese', 'x-mac-chinesetrad', 'x-mac-korean',
    'x-mac-arabic', 'x-mac-hebrew', 'x-mac-greek', 'x-mac-cyrillic',
    'x-mac-chinesesimp', 'x-mac-romanian', 'x-mac-ukrainian', 'x-mac-thai',
    'x-mac-ce', 'x-mac-icelandic', 'x-mac-turkish', 'x-mac-croatian',
    'x-Chinese-CNS', 'x-cp20001', 'x-Chinese-Eten', 'x-cp20003', 'x-cp20004',
    'x-cp20005', 'x-IA5', 'x-IA5-German', 'x-IA5-Swedish', 'x-IA5-Norwegian',
    'us-ascii', 'x-cp20261', 'x-cp20269', 'IBM273', 'IBM277', 'IBM278',
    'IBM280', 'IBM284', 'IBM285', 'IBM290', 'IBM297', 'IBM420', 'IBM423',
    'IBM424', 'x-EBCDIC-KoreanExtended', 'IBM-Thai', 'koi8-r', 'IBM871',
    'IBM880', 'IBM905', 'IBM00924', 'EUC-JP', 'x-cp20936', 'x-cp20949',
    'cp1025', 'koi8-u', 'iso-8859-1', 'iso-8859-2', 'iso-8859-3', 'iso-8859-4',
    'iso-8859-5', 'iso-8859-6', 'iso-8859-7', 'iso-8859-8', 'iso-8859-9',
    'iso-8859-13', 'iso-8859-15', 'x-Europa', 'iso-8859-8-i', 'iso-2022-jp',
    'csISO2022JP', 'iso-2022-jp', 'iso-2022-kr', 'x-cp50227', 'euc-jp',
    'EUC-CN', 'euc-kr', 'hz-gb-2312', 'GB18030', 'x-iscii-de', 'x-iscii-be',
    'x-iscii-ta', 'x-iscii-te', 'x-iscii-as', 'x-iscii-or', 'x-iscii-ka',
    'x-iscii-ma', 'x-iscii-gu', 'x-iscii-pa', 'utf-7', 'utf-8', 'utf-32',
    'utf-32BE', 'gbk');
  CharsetIds: array [0 .. 140] of Word = (37, 437, 500, 708, 720, 737, 775, 850,
    852, 855, 857, 858, 860, 861, 862, 863, 864, 865, 866, 869, 870, 874, 875,
    932, 936, 949, 950, 1026, 1047, 1140, 1141, 1142, 1143, 1144, 1145, 1146,
    1147, 1148, 1149, 1200, 1201, 1250, 1251, 1252, 1253, 1254, 1255, 1256,
    1257, 1258, 1361, 10000, 10001, 10002, 10003, 10004, 10005, 10006, 10007,
    10008, 10010, 10017, 10021, 10029, 10079, 10081, 10082, 20000, 20001, 20002,
    20003, 20004, 20005, 20105, 20106, 20107, 20108, 20127, 20261, 20269, 20273,
    20277, 20278, 20280, 20284, 20285, 20290, 20297, 20420, 20423, 20424, 20833,
    20838, 20866, 20871, 20880, 20905, 20924, 20932, 20936, 20949, 21025, 21866,
    28591, 28592, 28593, 28594, 28595, 28596, 28597, 28598, 28599, 28603, 28605,
    29001, 38598, 50220, 50221, 50222, 50225, 50227, 51932, 51936, 51949, 52936,
    54936, 57002, 57003, 57004, 57005, 57006, 57007, 57008, 57009, 57010, 57011,
    65000, 65001, 65005, 65006, 936);

var

  aValue: AnsiString;

  p, ps: pAnsichar;

  function getCharSet(AAName: AnsiString): Integer;
  var
    I: Integer;
  begin
    Result := -1;

    for I := low(CharsetNames) to high(CharsetNames) do
    begin
      if StrIComp(pAnsichar(CharsetNames[I]), pAnsichar(AAName)) = 0 then
      begin
        Result := CharsetIds[I];
        Break;
      end;
    end;
  end;

begin
  Result := -1; // CP_ACP;
  if trim(AName) = '' then
    exit;
  p := pAnsichar(AName);
  ps := p;
  // charset name 可能有逗号隔开
  if (p^ <> #0) then
    while True do
    begin
      if (p^ = ',') or (p^ = #0) then
      begin
        aValue := trim(lowercase(copy(ps, 1, (p - ps))));
        if length(aValue) > 2 then
        begin
          Result := getCharSet(aValue);

          if Result <> -1 then
            Break;
        end;
        if p^ <> #0 then
        begin
          inc(p);
          ps := p;
        end
        else
          Break;
      end;
      inc(p);
    end;
end;

{ THTTPResponse_ }

function getCharsetFromXmlBody(pp: QStringA): string;
const
  ValueDelimiters: pAnsichar = '''" )?>,;'#9#10#13;
var
  S, ss: QStringA;

  l, I: Integer;
  Token: QCharA;
  p: PQCharA;

  AValueDelimiters: TBytes;
begin
  Result := '';
  AValueDelimiters := bytesof(ValueDelimiters);
  p := PQCharA(pp);
  ss := 'encoding';
  I := PosA(PQCharA(ss), p, True, 1);
  if I = 0 then
    exit;
  inc(p, I + 8 - 1);
  SkipSpaceA(p);
  if p^ = ord('=') then
  begin
    inc(p);
    SkipSpaceA(p);
    if char(p^) in ['''', '"'] then
      Token := p^
    else
      Token := 0;
    // <?xml version="1.0" encoding="Shift_JIS"?>
    S := DequotedStrA(DecodeTokenA(p, AValueDelimiters, Token, True), Token);
    if length(S) > 0 then
    begin
      Result := S;
    end;
  end;
end;

function getCharsetFromXmlBody(pp: QStringW): string;
const
  ValueDelimiters: pwidechar = '''" )?>,;'#9#10#13;
var
  S, ss: QStringW;

  l, I: Integer;
  Token: QCharW;
  p: PQCharW;

begin
  Result := '';
  p := PQCharW(pp);
  ss := 'encoding';
  I := PosA(PQCharW(ss), p, True, 1);
  if I = 0 then
    exit;
  inc(p, I + 8 - 1);
  SkipSpaceW(p);
  if p^ = ('=') then
  begin
    inc(p);
    SkipSpaceW(p);
    if p^ in ['''', '"'] then
      Token := p^
    else
      Token := #0;
    // <?xml version="1.0" encoding="Shift_JIS"?>
    S := DequotedStrW(DecodeTokenW(p, ValueDelimiters, Token, True), Token);
    if length(S) > 0 then
    begin
      Result := S;
    end;
  end;
end;

function DecodeCharset(pp: pAnsichar; ASize: Integer): string;
const
  ValueDelimiters: pAnsichar = '''" )?/>,;'#9#10#13;
var
  S, ss: QStringA;

  l, I: Integer;
  Token: QCharA;
  p: PQCharA;

  AValueDelimiters: TBytes;
begin
  Result := '';
  AValueDelimiters := bytesof(ValueDelimiters);

  p := PQCharA(pp);
  ss := DecodeLineA(p, True, 100);

  if lowercase(copy(ss, 1, 5)) = '<?xml' then
  begin
    Result := getCharsetFromXmlBody(ss);
    if Result <> '' then
    begin
      exit;
    end;
  end;

  ss := '<head';
  I := PosA(PQCharA(ss), p, True, 1);

  if (I < 1) or (I > ASize) then
    exit;

  inc(p, I);

  while p^ <> 0 do
  begin
    if (p^ = ord('>')) then
    begin
      inc(p);
      Break;
    end;
    inc(p);
  end;

  if (p^ = 0) or (I > ASize) then
    exit;

  I := PosA(pAnsichar('<meta'), p, True, 1);
  while (I > 0) and (p - pp < ASize) do
  begin
    inc(p, I);
    SkipSpaceA(p);
    I := PosA(pAnsichar('charset'), p, True, 1);
    if I > 0 then
    begin
      inc(p, I + 7 - 1);
      SkipSpaceA(p);
      if p^ = ord('=') then
      begin
        inc(p);
        SkipSpaceA(p);
        if char(p^) in ['''', '"'] then
          Token := p^
        else
          Token := 0;
        // content="text/html; charset='Shift_JIS'"
        S := DecodeTokenA(p, AValueDelimiters, Token, True);
        S := DequotedStrA(S, Token);
        if length(S) > 0 then
        begin
          Result := S;
          Break;
        end;
      end;
    end;
    // I := PosA(pAnsichar('charset'), p, True, 1);
    I := PosA(pAnsichar('<meta'), p, True, 1);
  end;

end;

// <?xml version="1.0" encoding="Shift_JIS"?>
function DecodeCharset(pp: pwidechar; ASize: Integer): string;
const
  ValueDelimiters: pwidechar = '''" )?/>,;'#9#10#13;
var
  S, ss: QStringW;
  l, I: Integer;
  ps: pwidechar;

  p: PQCharW;
  // ANameValueDelimiters: TBytes;
  Token: QCharW;

begin

  // ANameValueDelimiters := BytesOf(NameValueDelimiters);
  Result := '';
  p := PQCharW(pp);
  ps := pp;
  ss := DecodeLineW(p, True, 100);

  if lowercase(copy(ss, 1, 5)) = '<?xml' then
  begin
    Result := getCharsetFromXmlBody(ss);
    if Result <> '' then
    begin
      exit;
    end;
  end;

  I := PosW(pwidechar('<head'), p, True, 1);

  if (I < 1) or (I > ASize) then
    exit;

  inc(p, I);

  while p^ <> #0 do
  begin
    if (p^ = ('>')) then
    begin
      inc(p);
      Break;
    end;
    inc(p);
  end;
  if (p^ = #0) or (I > ASize) then
    exit;

  I := PosW(pwidechar('<meta'), p, True, 1);
  while (I > 0) and (p - ps < ASize) do
  begin
    inc(p, I);
    SkipSpaceW(p);
    I := PosW(pwidechar('charset'), p, True, 1);
    if I > 0 then
    begin
      inc(p, I + 7 - 1);
      SkipSpaceW(p);
      if p^ = ('=') then
      begin
        inc(p);
        SkipSpaceW(p);
        if p^ in ['''', '"'] then
          Token := p^
        else
          Token := #0;
        // content="text/html; charset='Shift_JIS'"
        S := DequotedStrW(DecodeTokenW(p, ValueDelimiters, Token, True,
          True), Token);
        if length(S) > 0 then
        begin
          Result := S;
          Break;
        end;
      end;
    end;
    // I := PosW(pwidechar('charset'), p, True, 1);
    I := PosW(pAnsichar('<meta'), p, True, 1);
  end;
  // StrLIComp
end;

function THTTPResponse_.ContentAsString(const AnEncoding: TEncoding): string;
var
  LReader: TStringStream;
  LCharset: string;
  LCharsetCode: Integer;
  Encoding: TEncoding;
begin
  Result := '';
  if AnEncoding = nil then
  begin
    LCharset := GetContentCharSet;
    if (LCharset <> '') and (string.CompareText(LCharset, 'utf-8') <> 0) then
    // do not translate
    begin
      LCharsetCode := ParseCharset(LCharset);
      if LCharsetCode > 0 then
      begin
        Encoding := TEncoding.GetEncoding(LCharsetCode);
      end
      else
        Encoding := TEncoding.GetEncoding(LCharset);

      LReader := TStringStream.Create('', Encoding, True)
    end
    else
    begin
      LReader := TStringStream.Create('', TEncoding.UTF8, False);
    end;
  end
  else
    LReader := TStringStream.Create('', AnEncoding, False);

  try
    LReader.CopyFrom(FStream, 0);
    Result := LReader.DataString;
  finally
    LReader.Free;
  end;

end;

function THTTPResponse_.getCharsetFromBody: string;
var
  S: AnsiString;
  // ws: Widestring;
  // pbody: PChar;
  l: Integer;
begin

  FInternalStream.Position := 0;
  l := FInternalStream.Size;
  if l > 2048 then
    l := 2048;

  SetLength(S, l);
  FInternalStream.ReadBuffer(pAnsichar(S)^, length(S));
  // ws := S;
  // pbody := pwidechar(ws);

  Result := DecodeCharset(pAnsichar(S), length(S));

end;

function THTTPResponse_.GetContentCharSet: string;
var
  LCharset: string;
  LSplitted: TArray<string>;
  LValues: TArray<string>;
  S: string;
begin
  Result := '';
  LCharset := GetHeaderValue(sContentType);
  LSplitted := LCharset.Split([';']);
  for S in LSplitted do
  begin
    if S.TrimLeft.StartsWith('charset', True) then // do not translate
    begin
      LValues := S.Split(['=']);
      if length(LValues) = 2 then
        Result := LValues[1].trim;
      Break;
    end;
  end;
  // inherited GetContentCharSet;
  if Result = '' then
  begin
    Result := trim(getCharsetFromBody);
  end;
end;

function THTTPResponse_.getStream: TStream;
begin
  Result := FStream;
end;

procedure THTTPResponse_.setStream(aStm: TStream);
begin
  FStream := aStm;
end;
{ TURLRequest_ }

function TURLRequest_.getSourceStream: TStream;
begin
  Result := FSourceStream;
end;

procedure TURLRequest_.setSourceStream(aStm: TStream);
begin
  FSourceStream := aStm;
end;

function TURLRequest_.getURL: TURI;
begin
  Result := FURL;
end;

procedure TURLRequest_.setURL(aURL: TURI);
begin
  FURL := aURL;
end;

{ THTTPRequest_ }

procedure THTTPRequest_.DoPrepare;
begin
  self.DoPrepare;
end;

function THttpClient_.DoExecute(const ARequestMethod: string; const AURI: TURI;
  const ASourceStream, AContentStream: TStream; const AHeaders: TNetHeaders)
  : IURLResponse;
var
  LRequest: IHTTPRequest;
  AResp: IHTTPResponse;
  AHandleRedirects: Boolean;

  FMaxRedirects_: Integer;
  DirectTimes: Integer;
  AURI_: TURI;
  FLastUrl: string;
begin

  FMaxRedirects_ := FMaxRedirects;
  if FMaxRedirects_ = 0 then
    FMaxRedirects_ := 1;
  DirectTimes := 0;
  AHandleRedirects := self.HandleRedirects;
  if HandleRedirects then
    HandleRedirects := False;

  LRequest := GetRequest(ARequestMethod, AURI);
  LRequest.SourceStream := ASourceStream;
  Result := Execute(LRequest, AContentStream, AHeaders);

  FLastUrl := LRequest.URL.ToString;

  while DirectTimes < FMaxRedirects_ do
  begin
    AResp := Execute(LRequest, AContentStream, AHeaders);
    Result := AResp;
    if assigned(AResp) and AHandleRedirects then
    begin
      if ((AResp.StatusCode >= 301) and (AResp.StatusCode <= 304)) or
        (AResp.StatusCode = 307) then
      begin
        FLastUrl := TURI.PathRelativeToAbs(AResp.GetHeaderValue('Location'),
          TURI.Create(FLastUrl));
        AURI_ := TURI.Create(FLastUrl);
        // LRequest.URL := TURI.Create(FLastUrl);
        LRequest := GetRequest(ARequestMethod, AURI_);
        LRequest.SourceStream := ASourceStream;

      end
      else
        Break;
    end
    else
      Break;
    inc(DirectTimes);
    if DirectTimes > FMaxRedirects_ then
      Break;
  end;
  // AResp.HeaderValue['DirectTimes'] := DirectTimes.ToString;
  // AResp.HeaderValue['LastUrl'] := FLastUrl;
  self.CustomHeaders['DirectTimes'] := DirectTimes.ToString;
  self.CustomHeaders['Url'] := FLastUrl;
  HandleRedirects := AHandleRedirects;

end;

function THttpClient_.Delete(const aURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodDelete, TURI.Create(aURL), nil,
    AResponseContent, AHeaders));
end;

function THttpClient_.Get(const aURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodGet, TURI.Create(aURL), nil,
    AResponseContent, AHeaders));
end;

function THttpClient_.Trace(const aURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodTrace, TURI.Create(aURL), nil,
    AResponseContent, AHeaders));
end;

function THttpClient_.Head(const aURL: string; const AHeaders: TNetHeaders)
  : IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodHead, TURI.Create(aURL), nil,
    nil, AHeaders));
end;

function THttpClient_.Merge(const aURL: string; const ASource: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodMerge, TURI.Create(aURL),
    ASource, nil, AHeaders));
end;

function THttpClient_.MergeAlternative(const aURL: string;
  const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch),
    TNetHeader.Create('PATCHTYPE', sHTTPMethodMerge)] + AHeaders;
  // Do not translate
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(aURL), ASource,
    nil, LHeaders));
end;

function THttpClient_.Options(const aURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodOptions, TURI.Create(aURL), nil,
    AResponseContent, AHeaders));
end;

function THttpClient_.Patch(const aURL: string;
  const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders)
  : IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPatch, TURI.Create(aURL),
    ASource, AResponseContent, AHeaders));
end;

function THttpClient_.PatchAlternative(const aURL: string;
  const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders)
  : IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch)] +
    AHeaders;
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(aURL), ASource,
    AResponseContent, LHeaders));
end;

function THttpClient_.Post(const aURL: string; const ASource: TStrings;
  const AResponseContent: TStream; const AEncoding: TEncoding;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LSourceStream: TStringStream;
  LParams: string;
  LHeaders: TNetHeaders;
  LEncodingName: string;
  LEncoding: TEncoding;
  I: Integer;
  Pos: Integer;
begin
  LParams := '';
  for I := 0 to ASource.Count - 1 do
  begin
    Pos := ASource[I].IndexOf('=');
    if Pos > 0 then
      LParams := LParams + ASource[I].Substring(0, Pos) + '=' +
        TURI.URLEncode(ASource[I].Substring(Pos + 1), True) + '&';
  end;
  LParams := LParams.Substring(0, LParams.length - 1); // Remove last &

  if AEncoding = nil then
  begin
    LEncoding := TEncoding.UTF8;
    LEncodingName := 'UTF-8'; // do not localize
  end
  else
  begin
    LEncoding := AEncoding;
    LEncodingName := AEncoding.EncodingName;
  end;
  LEncodingName := EncodingNameToHttpEncodingName(LEncodingName);
  LSourceStream := TStringStream.Create(LParams, LEncoding, False);
  try

    LHeaders := [TNetHeader.Create(sContentType,
      'application/x-www-form-urlencoded; charset=' + LEncodingName)];
    // do not translate
    LHeaders := LHeaders + AHeaders;
    // LHeaders := [TNetHeader.Create(sContentType, 'application/x-www-form-urlencoded; charset=' + LEncodingName)] + AHeaders;  // do not translate
    Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(aURL),
      LSourceStream, AResponseContent, LHeaders));
  finally
    LSourceStream.Free;
  end;
end;

function THttpClient_.Post(const aURL: string;
  const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders)
  : IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(aURL), ASource,
    AResponseContent, AHeaders));
end;

function THttpClient_.Post(const aURL: string; const ASourceFile: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LSourceStream: TStream;
begin
  LSourceStream := TFileStream.Create(ASourceFile, fmOpenRead);
  try
    Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(aURL),
      LSourceStream, AResponseContent, AHeaders));
  finally
    LSourceStream.Free;
  end;
end;

function THttpClient_.Post(const aURL: string;
  const ASource: TMultipartFormData; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(sHTTPMethodPost, aURL);
  LRequest.SourceStream := ASource.Stream;
  LRequest.SourceStream.Position := 0;
  LRequest.AddHeader(sContentType, ASource.MimeTypeHeader);
  Result := Execute(LRequest, AResponseContent, AHeaders);
end;

function THttpClient_.Put(const aURL: string;
  const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders)
  : IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(aURL), ASource,
    AResponseContent, AHeaders));
end;

{
  function THttpClient_.Execute(const ARequest: IHTTPRequest;
  const AContentStream: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
  var
  LHeader: TNetHeader;
  begin
  if AHeaders <> nil then
  for LHeader in AHeaders do
  ARequest.SetHeaderValue(LHeader.Name, LHeader.Value);
  Result := ExecuteHTTP(ARequest, AContentStream);
  end;
}
function THttpClient_.getReferer: String;
begin
  Result := self.CustomHeaders['Referer'];
end;

procedure THttpClient_.setReferer(aValue: string);
begin
  self.CustomHeaders['Referer'] := aValue;
end;

function THttpClient_.GetLastURL: String;
begin
  Result := self.CustomHeaders['Url'];
end;

function THttpClient_.GetDirectTimes: Integer;
var
  dst: Integer;
  dss: string;
begin
  dss := self.CustomHeaders['DirectTimes'];
  dst := strtointdef(dss, 0);
  Result := dst;
end;

initialization

// TURLSchemes.RegisterURLClientScheme(TMuHTTPClient_, 'MUHTTP');

finalization

end.
