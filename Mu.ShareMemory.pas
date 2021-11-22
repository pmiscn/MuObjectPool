unit Mu.ShareMemory;

interface

uses
  windows, sysutils;

Type

  TMuShareMem<TRecord> = class
  type
    PRecord = ^TRecord;
  private
    FNewIns: boolean;
    FFileName: string;
    hMapFile: THandle;
    FValue: PRecord;
    FIsNewFile: boolean;
    function CreateMapFile(aMapFile: string): String;


    function GetGUID: string;
  protected

  public
    constructor create(aFileName: String = '');
    destructor Destroy; override;
    function getValue(): TRecord;
    procedure setValue(aValue: TRecord);

    procedure clear;
    property Value: TRecord read getValue write setValue;
    procedure FreeMapFile;
    property FileName: String read FFileName;
    property IsNewFile: boolean read FIsNewFile;
    property NewIns: boolean read FNewIns;
  end;

implementation

function TMuShareMem<TRecord>.GetGUID: string;
var
  LTep: TGUID;
begin
  CreateGUID(LTep);
  Result := GUIDToString(LTep);
end;

procedure TMuShareMem<TRecord>.clear;
begin
  zeromemory(FValue, sizeof(TRecord));
end;

constructor TMuShareMem<TRecord>.create(aFileName: String);
begin
  CreateMapFile(aFileName);
end;

function TMuShareMem<TRecord>.CreateMapFile(aMapFile: string): string;
var
  hfile: THandle;
begin
  FNewIns := false;
  FFileName := aMapFile;
  if FFileName = '' then
    FFileName := GetGUID;
  FIsNewFile := false;
  hMapFile := OpenFileMapping(FILE_MAP_ALL_Access, false, PChar(FFileName));

  if hMapFile = 0 then
  begin

    // {$IFDEF WIN64}
    // hfile := $FFFFFFFFFFFFFFFF;
    // {$ELSE}
    // hfile := $FFFFFFFF;
    // {$ENDIF}

    hMapFile := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
      sizeof(TRecord), PChar(FFileName));
    FIsNewFile := true;
    FNewIns := true;
  end;
  FValue := MapViewOfFile(hMapFile, FILE_MAP_WRITE or FILE_MAP_READ, 0, 0, 0);
  Result := FFileName;
end;

destructor TMuShareMem<TRecord>.Destroy;
begin
 // FreeMapFile;
  inherited;
end;

procedure TMuShareMem<TRecord>.FreeMapFile;
begin
  if FValue <> nil then
  begin
    UnMapViewOfFile(FValue);
    CloseHandle(hMapFile);
  end;
end;

function TMuShareMem<TRecord>.getValue: TRecord;
begin
  Result := PRecord(FValue)^;
end;

procedure TMuShareMem<TRecord>.setValue(aValue: TRecord);
begin
  // move(aValue, FValue^, SizeOf(TRecord));
  PRecord(FValue)^ := aValue;
end;

initialization

finalization

end.
