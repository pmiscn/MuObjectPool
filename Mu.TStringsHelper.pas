unit Mu.TStringsHelper;

interface

uses System.SysUtils, System.Classes, System.ZLib, Mu.Aes, qaes;

type

  TStringsHelper = Class helper for TStrings
  private

  public
    function LoadFromFileAes(aFileName: string): boolean;
    procedure SaveToFileAes(aFileName: string);
  end;

implementation

uses System.NetEncoding;

{ TStringsHelper }

function TStringsHelper.LoadFromFileAes(aFileName: string): boolean;
begin
  PubMuAES.LoadFromFile(aFileName,self);
end;

procedure TStringsHelper.SaveToFileAes(aFileName: string);
begin
  PubMuAES.SaveToFile(aFileName,self);
end;

end.
