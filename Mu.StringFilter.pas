unit Mu.StringFilter;

interface

uses windows, classes, sysutils, Generics.Collections, TypInfo,
  qjson, qstring,
  // PerlRegEx,
  System.RegularExpressionsCore,
  Mu.pool.st, Mu.pool.Reg;

Type

  TFilterType    = (ftDelete, ftReplace, ftCopy, ftMatch);
  TFilterOption  = (foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine);
  TFilterOptions = set of TFilterOption;

  TOneFilter = record
    Parallel: boolean;
    FilterType: TFilterType;
    RegException: boolean;
    Exception1: String;
    Exception2: string;
    FilterOptions: TFilterOptions;
    MultiValueSpliter: String;
    BeforeStr: string;
    AfterStr: string;
  end;

  TFilters = TArray<TOneFilter>;

  TFilterConfig = record
    FullToHalf: boolean;
    HtmlUnescape: boolean;
    MultiValueSpliter: String;
    Filters: TFilters;
  end;

  TMuStringFilter = class(TObject)
    private
      FConfigFileName: string;
      FStringlist    : Tstringlist;
      FRegPool       : TRegPool;
      FFilterConfig  : TFilterConfig;
      FInput         : String;
      FOutput        : qstringw;
      // FMultiValueSpliter: String;
      function RegReplace(Str: string; fromstr: string; tostr: string; aReplaceFlags: TFilterOptions): string; overload;

      function RegReplace(Reg: TPerlRegEx; Str: string; fromstr: string; tostr: string; aReplaceFlags: TFilterOptions)
        : string; overload;
      function RegPos(Reg: TPerlRegEx; Sub, Str: string; var MatchLength: Integer): Integer;
      function DoOneFilter(aOneFilter: TOneFilter): String;
      function GetOutput(): String;
    protected

    public
      constructor Create(aConfigFileName: string = ''; aInput: string = ''); overload;
      constructor Create(aConfigJson: Tqjson; aInput: string = ''); overload;

      destructor Destroy; override;

      class function RegMatch(aInput, aException: String; MultiValueSpliter: Char = ';'): string;

      function loadConfigFromFile(aFileName: string): boolean;
      function loadConfigFromStream(aStream: TStream): boolean;
      function loadConfigFromJson(aJson: Tqjson): boolean;
      function loadConfigFromString(s: String): boolean;
      procedure HtmlUnescape();
      procedure FullToHalf();

      procedure Filter(aInput: String = '');

      property Input: String read FInput write FInput;
      property Output: qstringw read GetOutput;

      // property MultiValueSpliter: String read FMultiValueSpliter
      // write FMultiValueSpliter;

      property FilterConfig: TFilterConfig read FFilterConfig;

    published

  end;

implementation

uses strutils;
{ TMuHttpFilter }

procedure SetRegOptions(Reg: TPerlRegEx; FilterOptions: TFilterOptions);
begin
  if foIgnoreCase in FilterOptions then
    Reg.Options := Reg.Options + [preCaseLess]
  else
    Reg.Options := Reg.Options - [preCaseLess];

  if foRegMultiLine in FilterOptions then
  begin
    Reg.Options := Reg.Options + [preMultiLine];
    Reg.Options := Reg.Options - [preSingleLine];
  end else begin
    Reg.Options := Reg.Options - [preMultiLine];
    Reg.Options := Reg.Options + [preSingleLine];
  end;
  if foRegSingleLine in FilterOptions then
    Reg.Options := Reg.Options + [preSingleLine]
end;

function TMuStringFilter.RegReplace(Reg: TPerlRegEx; Str: string; fromstr: string; tostr: string;
  aReplaceFlags: TFilterOptions): string;
begin
  Result := Str;
  SetRegOptions(Reg, aReplaceFlags);
  Reg.RegEx       := fromstr;
  Reg.Replacement := tostr;
  Reg.Subject     := (Str);
  Result          := Str;
  if foAll in aReplaceFlags then
  begin
    if Reg.replaceall then
      Result := Reg.Subject;
  end else begin
    if Reg.Match then
      Result := Reg.Replace;
  end;
end;

function TMuStringFilter.RegReplace(Str: string; fromstr: string; tostr: string; aReplaceFlags: TFilterOptions): string;
var
  Reg: TPerlRegEx;
begin
  Result := Str;
  Reg    := FRegPool.get;
  try
    RegReplace(Reg, Str, fromstr, tostr, aReplaceFlags)
  finally
    FRegPool.return(Reg);
  end;
end;

class function TMuStringFilter.RegMatch(aInput, aException: String; MultiValueSpliter: Char): string;
var
  Reg: TPerlRegEx;
  st : Tstringlist;
  R  : String;
begin
  Result := '';
  Reg    := regPool.get;
  st     := stpool.get;
  try

    Reg.Options := Reg.Options + [preCaseLess, preSingleLine];
    Reg.RegEx   := aException;
    Reg.Subject := aInput;
    if (Reg.Match) then
    begin

      repeat
        R := Reg.MatchedText;
        if st.IndexOf(R) < 0 then
          st.Add(R);
        {
          if Result <> '' then
          begin
          Result := Result + MultiValueSpliter;
          end;
          Result := Result + R;
        }
      until not Reg.MatchAgain;
    end;
    st.Delimiter := MultiValueSpliter;
    Result       := st.DelimitedText;
  finally
    regPool.return(Reg);
    stpool.return(st);
  end;
end;

function TMuStringFilter.RegPos(Reg: TPerlRegEx; Sub, Str: string; var MatchLength: Integer): Integer;
begin
  Result      := 0;
  MatchLength := 0;
  Reg.RegEx   := Sub;
  Reg.Subject := Str;
  if (Reg.Match) then
  begin
    Result      := Reg.MatchedOffset;
    MatchLength := Reg.MatchedLength;
  end;
end;

constructor TMuStringFilter.Create(aConfigFileName, aInput: string);
begin
  FStringlist := Tstringlist.Create;
  FRegPool    := TRegPool.Create(100);
  // FMultiValueSpliter := #13#10;
  FConfigFileName := aConfigFileName;
  if aConfigFileName <> '' then
    self.loadConfigFromFile(aConfigFileName);
  FStringlist.Text := aInput;
  FInput           := FStringlist.Text;
end;

constructor TMuStringFilter.Create(aConfigJson: Tqjson; aInput: string);
begin
  FStringlist := Tstringlist.Create;
  FRegPool    := TRegPool.Create(100);
  // FMultiValueSpliter := #13#10;
  FConfigFileName := '';
  if aConfigJson <> nil then
    self.loadConfigFromJson(aConfigJson);
  FStringlist.Text := aInput;
  self.FInput      := FStringlist.Text;
end;

destructor TMuStringFilter.Destroy;
begin
  FStringlist.Free;
  FRegPool.Free;
  inherited;
end;

function TMuStringFilter.DoOneFilter(aOneFilter: TOneFilter): String;
  function getMultiValueSpliter(): String;
  begin
    if aOneFilter.MultiValueSpliter <> '' then
      Result := aOneFilter.MultiValueSpliter
    else
      Result := FFilterConfig.MultiValueSpliter;
  end;
  function doReplace(): String;
  var
    Reg: TPerlRegEx;
  var
    aReplaceFlags: TReplaceFlags;
  begin
    if aOneFilter.RegException then
    begin
      Reg := FRegPool.get;
      try
        Result := RegReplace(Reg, FOutput, aOneFilter.Exception1, aOneFilter.Exception2, aOneFilter.FilterOptions);
      finally
        FRegPool.return(Reg);
      end;
    end else begin
      aReplaceFlags := [];
      if foIgnoreCase in aOneFilter.FilterOptions then
        aReplaceFlags := aReplaceFlags + [rfIgnoreCase];
      if foAll in aOneFilter.FilterOptions then
        aReplaceFlags := aReplaceFlags + [rfReplaceAll];

      Result := qstring.StringReplaceW(FOutput, aOneFilter.Exception1, aOneFilter.Exception2, aReplaceFlags)
    end;
  end;
  function DoDeleteBetween(): String;
  var
    strstart, strstart2, strend, l: Integer;
    AIgnoreCase                   : boolean;
    Reg                           : TPerlRegEx;
    MatchLength                   : Integer;
    s, s1                         : String;
  begin
    Result := '';
    if aOneFilter.RegException then
    begin
      Reg := FRegPool.get;

      SetRegOptions(Reg, aOneFilter.FilterOptions);

      try

        l           := length(FOutput);
        strend      := 1;
        MatchLength := 0;
        s           := FOutput;
        while strend <> 0 do
        begin
          // if strend > 1 then
          // s := copy(s, strend, length(s) - strend + 1)
          // else
          s := FOutput;

          l := length(s);
          if aOneFilter.Exception1 = '' then // 开头开始读取
          begin
            strstart := strend;
          end else begin
            strstart := RegPos(Reg, aOneFilter.Exception1, s, MatchLength);
            if strstart = 0 then
              break;
          end;

          if aOneFilter.Exception2 = '' then // 直到结尾
          begin
            // 再一次出现开头的位置，就是结束
            strstart2 := strstart + MatchLength;
            s1        := copy(s, strstart2, length(s) - strstart2);
            strend    := RegPos(Reg, aOneFilter.Exception1, s1, MatchLength);
            if strend = 0 then
              strend := l
            else
              strend := strend + strstart2 - 1;
          end else begin
            strstart2 := strstart + MatchLength;
            // 此时，要从遇到的第一次后面的数据提取了。
            s1     := copy(s, strstart2, length(s) - strstart2);
            strend := RegPos(Reg, aOneFilter.Exception2, s1, MatchLength);
            if strend = 0 then
              break;
            strend := strend + strstart2 + MatchLength - 1;
          end;

          delete(FOutput, strstart, strend - strstart);
          if not(foAll in aOneFilter.FilterOptions) then
            break;
          if strend = l then
            break;
        end;
        Result := FOutput;
      finally
        FRegPool.return(Reg);
      end;
    end else begin // 不是正则表达式的。

      // 如果开始结束都是空白，返回原值。
      if aOneFilter.Exception1 + aOneFilter.Exception2 = '' then
      begin
        Result := FOutput;
        exit;
      end;

      if foIgnoreCase in aOneFilter.FilterOptions then
        AIgnoreCase := true;
      strend        := 1;
      // 全部 是把所有符合条件的复制出来。
      l := length(FOutput);

      while (strend <> 0) do
      begin
        if aOneFilter.Exception1 = '' then // 开头开始读取
        begin
          strstart := strend;
        end else begin
          strstart := Posw(aOneFilter.Exception1, FOutput, AIgnoreCase, strend);
          if strstart = 0 then
            break;
        end;
        if aOneFilter.Exception2 = '' then // 直到结尾
        begin
          // 再一次出现开头的位置，就是结束
          strend := Posw(aOneFilter.Exception1, FOutput, AIgnoreCase, strstart + 1 + length(aOneFilter.Exception1));
          if strend = 0 then
            strend := l
          else
            strend := strend; // + length(aOneFilter.Exception1);
        end else begin
          strend := Posw(aOneFilter.Exception2, FOutput, AIgnoreCase, strstart + 1);
          if strend = 0 then
            break;
          strend := strend + length(aOneFilter.Exception2);
        end;

        delete(FOutput, strstart, strend - strstart);

        if not(foAll in aOneFilter.FilterOptions) then
          break;
        if strend = l then
          break;
      end;
    end;

    Result := FOutput;

  end;
  function doDelete(): String;
  begin
    if aOneFilter.Exception2 = '' then
    begin
      aOneFilter.Exception2 := '';
      Result                := doReplace();
    end else begin
      Result := DoDeleteBetween;
    end;
  end;
  function doCopy(): String;
  var
    strstart, strstart2, strend, l: Integer;
    AIgnoreCase                   : boolean;
    Reg                           : TPerlRegEx;
    MatchLength                   : Integer;
    s, s1                         : String;
  begin
    Result := '';
    if aOneFilter.RegException then
    begin
      Reg := FRegPool.get;

      SetRegOptions(Reg, aOneFilter.FilterOptions);

      try

        l           := length(FOutput);
        strend      := 1;
        MatchLength := 0;
        s           := FOutput;
        while strend <> 0 do
        begin
          if strend > 1 then
            s := copy(s, strend, length(s) - strend + 1)
          else
            s := FOutput;

          l := length(s);
          if aOneFilter.Exception1 = '' then // 开头开始读取
          begin
            strstart := strend;
          end else begin
            strstart := RegPos(Reg, aOneFilter.Exception1, s, MatchLength);
            if strstart = 0 then
              break;
          end;

          if aOneFilter.Exception2 = '' then // 直到结尾
          begin
            // 再一次出现开头的位置，就是结束
            strstart2 := strstart + MatchLength;
            s1        := copy(s, strstart2, length(s) - strstart2);
            strend    := RegPos(Reg, aOneFilter.Exception1, s1, MatchLength);
            if strend = 0 then
              strend := l
            else
              strend := strend + strstart2 - 1;
          end else begin
            strstart2 := strstart + MatchLength;
            // 此时，要从遇到的第一次后面的数据提取了。
            s1     := copy(s, strstart2, length(s) - strstart2);
            strend := RegPos(Reg, aOneFilter.Exception2, s1, MatchLength);
            if strend = 0 then
              break;
            strend := strend + strstart2 + MatchLength - 1;
          end;
          if Result <> '' then
          begin
            Result := Result + getMultiValueSpliter;
          end;
          Result := Result + copy(s, strstart, strend - strstart);
          if not(foAll in aOneFilter.FilterOptions) then
            break;
          if strend = l then
            break;
        end;
      finally
        FRegPool.return(Reg);
      end;
    end else begin // 不是正则表达式的。

      // 如果开始结束都是空白，返回原值。
      if aOneFilter.Exception1 + aOneFilter.Exception2 = '' then
      begin
        Result := FOutput;
        exit;
      end;

      if foIgnoreCase in aOneFilter.FilterOptions then
        AIgnoreCase := true;
      strend        := 1;
      // 全部 是把所有符合条件的复制出来。
      l := length(FOutput);

      while (strend <> 0) do
      begin
        if aOneFilter.Exception1 = '' then // 开头开始读取
        begin
          strstart := strend;
        end else begin
          strstart := Posw(aOneFilter.Exception1, FOutput, AIgnoreCase, strend);
          if strstart = 0 then
            break;
        end;
        if aOneFilter.Exception2 = '' then // 直到结尾
        begin
          // 再一次出现开头的位置，就是结束
          strend := Posw(aOneFilter.Exception1, FOutput, AIgnoreCase, strstart + 1 + length(aOneFilter.Exception1));
          if strend = 0 then
            strend := l
          else
            strend := strend; // + length(aOneFilter.Exception1);
        end else begin
          strend := Posw(aOneFilter.Exception2, FOutput, AIgnoreCase, strstart + 1);
          if strend = 0 then
            break;
          strend := strend + length(aOneFilter.Exception2);
        end;
        if Result <> '' then
        begin
          Result := Result + getMultiValueSpliter;
        end;
        Result := Result + copy(FOutput, strstart, strend - strstart);
        if not(foAll in aOneFilter.FilterOptions) then
          break;
        if strend = l then
          break;
      end;
    end;

    Result := aOneFilter.BeforeStr + Result + aOneFilter.AfterStr;
  end;

  function doMatch(): String;
  var
    Reg: TPerlRegEx;
    R  : string;
    function GetMatched(ms: String): String;
    var
      RR      : qstringw;
      p, s, s1: PQCharW;
      gi, l   : Integer;
      function getInteger(var p: PQCharW; var i: Integer): boolean;
      var
        p1: PQCharW;
        si: string;
      begin
        Result := false;
        p1     := p;
        si     := '';
        while p^ <> #0 do
        begin
          if (p^ >= '0') and (p^ <= '9') then
          begin
            si := si + p^;
          end
          else
            break;
          inc(p);
        end;
        if si <> '' then
        begin
          i      := strtoint(si);
          Result := true;
        end;
      end;

    begin
      Result := '';
      p      := PQCharW(ms);
      s      := p;
      s1     := 0;
      RR     := '';
      while p^ <> #0 do
      begin
        if (p^ = '$') then
        begin
          // 看看是不是第二个或者厚度

          s1 := p;
          l  := ((p) - (s));
          if l > 0 then
          begin
            setlength(RR, l);
            Move(s^, PQCharW(RR)^, l shl 1);
          end
          else
            RR := '';
          inc(p);
          if (getInteger(p, gi)) then
          begin
            Result := Result + RR + Reg.Groups[gi];
          end;
          s := p;
        end
        else
          inc(p);
      end;
      // 判断后面是否还有。
      l := ((p) - (s));
      if l > 0 then
      begin
        setlength(RR, l);
        Move(s^, PQCharW(RR)^, l shl 1);
        Result := Result + RR
      end;

    end;

  begin

    Reg := FRegPool.get;
    try
      SetRegOptions(Reg, aOneFilter.FilterOptions);
      Reg.RegEx   := aOneFilter.Exception1;
      Reg.Subject := FOutput;
      if (Reg.Match) then
      begin

        repeat

          if aOneFilter.Exception2 = '' then
            R := Reg.MatchedText
          else
          begin

            R := GetMatched(aOneFilter.Exception2);
          end;
          if Result <> '' then
          begin
            Result := Result + getMultiValueSpliter;
          end;
          Result := Result + R;
        until not Reg.MatchAgain;
      end;
      Result := aOneFilter.BeforeStr + Result + aOneFilter.AfterStr;
    finally
      FRegPool.return(Reg);
    end;
  end;

begin

  case aOneFilter.FilterType of
    ftDelete:
      begin
        if aOneFilter.Parallel then
          FOutput := FOutput + FFilterConfig.MultiValueSpliter + doDelete
        else
          FOutput := doDelete;
      end;
    ftReplace:
      begin
        if aOneFilter.Parallel then
          FOutput := FOutput + FFilterConfig.MultiValueSpliter + doReplace
        else
          FOutput := doReplace;
      end;
    ftCopy:
      begin
        if aOneFilter.Parallel then
          FOutput := FOutput + FFilterConfig.MultiValueSpliter + doCopy
        else
          FOutput := doCopy;
      end;
    ftMatch:
      if aOneFilter.Parallel then
        FOutput := FOutput + FFilterConfig.MultiValueSpliter + doMatch
      else
      begin
        FOutput := doMatch;
      end;
  end;

  Result := FOutput;
end;

procedure TMuStringFilter.Filter(aInput: String = '');
var
  i: Integer;
begin
  if (aInput <> '') then
    FInput := aInput;
  FOutput  := FInput;

  if FilterConfig.HtmlUnescape then
    HtmlUnescape;
  if FilterConfig.FullToHalf then
    FullToHalf;
  for i     := 0 to length(FilterConfig.Filters) - 1 do
    FOutput := self.DoOneFilter(FilterConfig.Filters[i]);

end;

procedure TMuStringFilter.FullToHalf;
begin
  FOutput := qstring.CNFullToHalf(FOutput);
end;

procedure TMuStringFilter.HtmlUnescape;
begin
  FOutput := qstring.HtmlUnescape(FOutput);
end;

function TMuStringFilter.GetOutput: String;
begin
  Result := FOutput;
end;

function TMuStringFilter.loadConfigFromFile(aFileName: string): boolean;
var
  aJson: Tqjson;
begin
  aJson := Tqjson.Create;
  try
    aJson.LoadFromFile(aFileName);
    Result := self.loadConfigFromJson(aJson);

  finally
    aJson.Free;
  end;
end;

function TMuStringFilter.loadConfigFromJson(aJson: Tqjson): boolean;
var
  AType: PTypeInfo;
begin
  AType := (TypeInfo(TFilters));
  aJson.ToRecord<TFilterConfig>(FFilterConfig);
  Result := true;
end;

function TMuStringFilter.loadConfigFromStream(aStream: TStream): boolean;
var
  aJson: Tqjson;
begin
  aJson := Tqjson.Create;
  try
    aJson.LoadFromStream(aStream);
    self.loadConfigFromJson(aJson)
  finally
    aJson.Free;
  end;
end;

function TMuStringFilter.loadConfigFromString(s: String): boolean;
var
  aJson: Tqjson;
begin
  aJson := Tqjson.Create;
  try
    aJson.Parse(s);
    Result := self.loadConfigFromJson(aJson)
  finally
    aJson.Free;
  end;

end;

end.

{
  FullToHalf:true,
  HtmlUnescape:true,
  Filters:[
  {
  FilterType:"ftMatch",// ftDelete, ftReplace, ftCopy
  RegException:true,
  Exception1:"[\\d]+",
  Exception2:"$0",
  FilterOptions:"[foIgnoreCase, foAll,foRegMultiLine]" //foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine
} ,
{
  FilterType:"ftCopy",// ftDelete, ftReplace, ftCopy
  RegException:false,
  Exception1:"",
  Exception2:"</tr>",
  FilterOptions:"[foIgnoreCase, foAll]" //foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine
} ,
{
  FilterType:"ftDelete",// ftDelete, ftReplace, ftCopy
  RegException:true,
  Exception1:"<img[^>]*\/?>",
  Exception2:"",
  FilterOptions:"[foIgnoreCase, foAll]" //foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine
} ,
{
  FilterType:"ftDelete",// ftDelete, ftReplace, ftCopy
  RegException:true,
  Exception1:"<[^>]*\/?>",
  Exception2:"",
  FilterOptions:"[foIgnoreCase, foAll]" //foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine
} ,
{
  FilterType:"ftReplace",// ftDelete, ftReplace, ftCopy
  RegException:true,
  Exception1:"<html>",
  Exception2:"",
  FilterOptions:"[foIgnoreCase, foAll]" //foIgnoreCase, foAll, foRegMultiLine, foRegSingleLine
}
]}
