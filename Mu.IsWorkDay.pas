unit Mu.IsWorkDay;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Generics.Collections,

  qworker, qstring, qjson, dateutils;

type
  TCheckWorkDay = class(TObject)
  private
    FFIleName: string;
    FJson: TQJSOn;
    FWorkdays: Tlist<Tdatetime>;
    FUnWorkdays: Tlist<Tdatetime>;

  protected

  public
    constructor Create(aFn: String = '');
    destructor Destroy; override;
    procedure loadfromfile(fn: String);
    function isWorkDay(aDate: Tdatetime): boolean;
  end;

var
  CheckWorkDay: TCheckWorkDay;

implementation

uses qtimetypes;
{ TCheckWorkDay }

constructor TCheckWorkDay.Create(aFn: String);
begin
  FJson := TQJSOn.Create;
  FWorkdays := Tlist<Tdatetime>.Create;
  FUnWorkdays := Tlist<Tdatetime>.Create;
  FFIleName := aFn;
  if FFIleName = '' then
    FFIleName := Trim(ExtractFilePath(ParamStr(0))) + 'config\workday.js';
  loadfromfile(FFIleName);
end;

destructor TCheckWorkDay.Destroy;
begin
  FWorkdays.Free;
  FUnWorkdays.Free;
  FJson.Free;
  inherited;
end;

function TCheckWorkDay.isWorkDay(aDate: Tdatetime): boolean;
begin
  if FWorkdays.IndexOf(aDate) <> -1 then
    exit(true);
  if FUnWorkdays.IndexOf(aDate) <> -1 then
    exit(false);
  result := DefaultIsWorkDay(aDate);
end;

procedure TCheckWorkDay.loadfromfile(fn: String);
var
  qjs, js: TQJSOn;
  i: integer;
begin
  if not fileexists(fn) then
    exit;
  FJson.loadfromfile(fn);
  FWorkdays.Clear;
  FUnWorkdays.Clear;
  if FJson.HasChild('WorkDays', qjs) then
  begin
    for i := 0 to qjs.count - 1 do
    begin
      FWorkdays.Add(qjs[i].AsDateTime);
    end;
  end;
  if FJson.HasChild('UnWorkderDays', qjs) then
  begin
    for i := 0 to qjs.count - 1 do
    begin
      FUnWorkdays.Add(qjs[i].AsDateTime);
    end;
  end;
end;

function isWorkDay(aDate: Tdatetime): boolean;
var
  AYear: Word;
begin
  if assigned(CheckWorkDay) then
  begin
    result := CheckWorkDay.isWorkDay(aDate);
  end
  else
    result := DefaultIsWorkDay(aDate);
end;

initialization

CheckWorkDay := TCheckWorkDay.Create;

finalization

CheckWorkDay.Free;

end.
