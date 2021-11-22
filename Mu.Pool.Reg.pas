unit Mu.Pool.Reg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  QSimplePool, System.RegularExpressionsCore, // RegularExpressions,
  System.Classes;

type
  TRegPool = class(TObject)
    private
      FPool: TQSimplePool;
      procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
      procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
      procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);

    protected

    public
      constructor Create(Poolsize: integer = 20);
      destructor Destroy; override;
      function get(): TPerlRegEx;
      procedure return(ajs: TPerlRegEx);
      procedure release(ajs: TPerlRegEx);

  end;

var
  regPool: TRegPool;

function CheckRegExp(AInput: String; AExp: String): bool;
function GetExpString(AInput: String; AExp: String; aGroupIndex: integer = 1): String;
function GetExpStringArray(AInput: String; AExp: String; aGroupIndex: integer = 1): TArray<string>;

function RegReplace(AInput: String; AExp: String; ARep: String): String;

implementation

function CheckRegExp(AInput: String; AExp: String): bool;
var
  preg: TPerlRegEx;
begin
  preg := (regPool.get);
  try
    preg.Subject := AInput;
    preg.RegEx   := AExp;
    result       := preg.Match;
  finally
    regPool.return(preg);
  end;

end;

function RegReplace(AInput: String; AExp: String; ARep: String): String;
var
  preg: TPerlRegEx;
begin
  preg := (regPool.get);
  try
    preg.Subject     := AInput;
    preg.RegEx       := AExp;
    preg.Replacement := ARep;
    preg.ReplaceAll;
    result := preg.Subject;
  finally
    regPool.return(preg);
  end;

end;

function GetExpStringArray(AInput: String; AExp: String; aGroupIndex: integer = 1): TArray<string>;
var
  preg: TPerlRegEx;
  procedure adds(s: string);
  var
    l: integer;
  begin
    l := length(result);
    setlength(result, l + 1);
    result[l] := s;
  end;

begin

  setlength(result, 0);

  preg := (regPool.get);
  try
    preg.Subject := AInput;
    preg.RegEx   := AExp;
    preg.Options := [preCaseLess, preSingleLine];
    if preg.Match then
    begin
      repeat
        if aGroupIndex = 0 then
          adds(preg.MatchedText)
        else if preg.GroupCount >= aGroupIndex then
        begin
          adds(preg.Groups[aGroupIndex]);
        end else begin
          adds(preg.MatchedText)
        end;
      until not preg.MatchAgain;

    end;
  finally
    regPool.return(preg);
  end;

end;

function GetExpString(AInput: String; AExp: String; aGroupIndex: integer = 1): String;
var
  preg: TPerlRegEx;
begin
  result := '';
  preg   := (regPool.get);
  try
    preg.Subject := AInput;
    preg.RegEx   := AExp;
    preg.Options := [preCaseLess, preSingleLine];
    if preg.Match then
    begin
      if aGroupIndex = 0 then
        result := preg.MatchedText
      else if preg.GroupCount >= aGroupIndex then
      begin
        result := preg.Groups[aGroupIndex];
      end else begin
        result := preg.MatchedText;
      end;
    end;
  finally
    regPool.return(preg);
  end;

end;
{ TPerlRegExPool }

constructor TRegPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnObjectCreate, FOnObjectFree, FOnObjectReset);
end;

destructor TRegPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TRegPool.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  TPerlRegEx(AData) := TPerlRegEx.Create
end;

procedure TRegPool.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  TPerlRegEx(AData).Free;
end;

procedure TRegPool.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin
  with TPerlRegEx(AData) do
  begin
    Subject     := '';
    RegEx       := '';
    Replacement := '';
  end;
end;

function TRegPool.get: TPerlRegEx;
begin
  result := TPerlRegEx(FPool.pop);
end;

procedure TRegPool.release(ajs: TPerlRegEx);
begin
  FPool.push(ajs);
end;

procedure TRegPool.return(ajs: TPerlRegEx);
begin
  FPool.push(ajs);
end;

initialization

regPool := TRegPool.Create(10);

finalization

regPool.Free;

end.
