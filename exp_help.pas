unit exp_help;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Mu.ObjectPool,
  System.Classes, PerlRegEx;

var
  RegExpPool: TMuObjectPool;

function CheckRegExp(AInput: String; AExp: String): bool;

implementation

function CheckRegExp(AInput: String; AExp: String): bool;
var
  preg: TPerlRegEx;
begin
  // preg := TPerlRegEx.Create;
  preg := TPerlRegEx(RegExpPool.borrowObject);
  try
    preg.Subject := AInput;
    preg.RegEx := AExp;
    result := preg.Match;
  finally
    RegExpPool.releaseObject(preg);
  end;
end;

initialization

RegExpPool := TMuObjectPool.Create(TPerlRegEx);

finalization

RegExpPool.Free;

end.
