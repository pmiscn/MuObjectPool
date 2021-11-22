unit Mu.QDBFileHelp;

{

}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, strutils,
  Data.DB,
 // Unit_pub_pool,
 // Mu.task, Mu.GetTask, Mu.HttpGetTask,
  qdbhelp,
  QDB, //qconverter_stds, qconverter_fdac, qconverter_csv,
  qaes, Mu.BytesHelper, Mu.Varchar, Mu.CharsHelper, {}
  qsp_aes, zlib, qsp_zlib,
  DateUtils, Mu.QDatasethelper
  // QSimplePool, QJSON, qlog,  QString
  ;

type
  TQDBFile = class(TObject)
  private

  protected
    FFilePath: String;
    FFileName: String;
    FFiles: tStringlist;
    FDBSet: TQDBSet;
    FFileDesp: String;
    procedure initDataset(); virtual;
    procedure beforeInsert(DataSet: TDataSet); virtual;
    function GetFullFileName(): string;
  public
    constructor Create(aPath: String = ''); virtual;
    destructor Destroy; override;

    function GetFiles(aSt: TStrings; aAllPath: boolean = false): integer;
    function AddFile(aFileName: String): boolean;
    //
    procedure LoadPath(aPath: String = '');
    function Refresh(): TQDataSet;
    function Save(): TQDataSet;
    function Delete(aFileName: String = ''): boolean;
    function GetFullPathFile(aFileName: String = ''): string;
    function SelectFile(aFileName: String): TQDataSet;
    property Files: tStringlist read FFiles;
    function Rename(aFileName: string; aNewFileName: String): boolean;
    //
    property DBSet: TQDBSet read FDBSet;
    property FileName: String read FFileName;
    property FullFileName: String read GetFullFileName;
    property FilePath: string read FFilePath write FFilePath;
    property FileDesp: string read FFileDesp write FFileDesp;

  end;

  TQDBRecordFile<TRecord> = class(TQDBFile)
  protected
    procedure initDataset(); virtual;
    procedure beforeInsert(DataSet: TDataSet); virtual;
  public

  end;

implementation

uses publicfun2;

{ TQDBFile }

procedure TQDBFile.initDataset;
begin

end;

constructor TQDBFile.Create(aPath: String);
begin
  FFiles := tStringlist.Create;
  FDBSet := TQDBSet.Create;
  FFileDesp := '文件';
  initDataset;

  if aPath = '' then
    aPath := getexepath + 'db\';
  if aPath[length(aPath)] <> '\' then
    aPath := aPath + '\';
  FFilePath := aPath;
  LoadPath();
  FDBSet.DataSet.AfterInsert := beforeInsert;
end;

function TQDBFile.Delete(aFileName: String): boolean;
var
  fn: String;
begin
  result := false;
  if messagebox(0, pchar('确认删除' + FFileDesp + '：' + aFileName + ' 吗？'), '确认',
    mb_YESNO or MB_ICONQUESTION or MB_DefButton2) <> id_YES then
    exit;
  fn := GetFullPathFile(aFileName);
  if deletefile(fn) then
  begin
    result := true;
    FFiles.Delete(FFiles.IndexOf(aFileName));
  end;
end;

destructor TQDBFile.Destroy;
begin
  inherited;
  FFiles.Free;
  FDBSet.Free;
end;

function TQDBFile.AddFile(aFileName: String): boolean;
var
  afn: String;
  i: integer;
begin
  // FFileName := aFileName;
  result := false;
  afn := self.GetFullPathFile(aFileName);
  if fileExists(afn) then
  begin
    if messagebox(0, pchar('' + FFileDesp + '： ' + aFileName + ' 已经存在，确认要替换吗？'),
      '确认', mb_YESNO or MB_ICONQUESTION or MB_DefButton2) <> id_YES then
      exit;
  end;
  FFileName := aFileName;
  self.FFiles.Add(FFileName);
  FDBSet.DataSet.DisableControls;
  FDBSet.BeginWrite;
  try
    // FDBSet.Dataset.Close;
    FDBSet.DataSet.recreatedataset;
    initDataset;

    FDBSet.SaveTofile(afn);

  finally
    FDBSet.EndWrite();
    FDBSet.DataSet.EnableControls;
  end;
  result := true;
end;

procedure TQDBFile.beforeInsert(DataSet: TDataSet);
begin

end;

function TQDBFile.GetFullPathFile(aFileName: String): string;
begin
  if (aFileName.IndexOf(':') > 0) then
  begin
    result := aFileName;
    exit;
  end;
  if aFileName = '' then
    aFileName := FFileName;
  result := FFilePath + aFileName + '.mtdb';
end;

function TQDBFile.GetFullFileName(): string;
begin
  result := FFilePath + FFileName + '.mtdb';
end;

function TQDBFile.GetFiles(aSt: TStrings; aAllPath: boolean): integer;
var
  i: integer;
begin
  aSt.Assign(self.FFiles);
  if aAllPath then
    for i := 0 to aSt.Count - 1 do
      aSt[i] := GetFullPathFile(aSt[i]);
end;

procedure TQDBFile.LoadPath(aPath: string);
var
  st: tStringlist;
  i: integer;
begin
  if aPath <> '' then
  begin
    if aPath[length(aPath)] <> '\' then
      aPath := aPath + '\';
    FFilePath := aPath;
  end;
  st := tStringlist.Create;
  FFiles.Clear;
  try
    FileFind(FFilePath, '*.mtdb', st);
    for i := 0 to st.Count - 1 do
    begin
      st[i] := StringReplace(st[i], FFilePath, '',
        [rfReplaceAll, rfIgnoreCase]);
      FFiles.Add((ChangeFileExt(st[i], '')));
    end;
  finally
    st.Free;
  end;
end;

function TQDBFile.Refresh: TQDataSet;
var aFileName:string;
begin
  if FFileName <> '' then
  begin
    result := FDBSet.DataSet;
    aFileName := GetFullPathFile(FFileName);

    if fileExists(aFileName) then
      with FDBSet do
      begin
        LoadFromFile(aFileName);
      end;
  end;
end;

function TQDBFile.Rename(aFileName, aNewFileName: String): boolean;
var
  OldFn, NewFn: String;
  i: integer;
begin
  result := false;
  if (aFileName = aNewFileName) then
    exit;
  if (aFileName = '') or (aNewFileName = '') then
    exit;

  OldFn := self.GetFullPathFile(aFileName);
  NewFn := self.GetFullPathFile(aNewFileName);
  if renamefile(OldFn, NewFn) then
  begin
    for i := 0 to FFiles.Count - 1 do
    begin
      if FFiles[i] = aFileName then
      begin
        FFiles[i] := aNewFileName;
        break;
      end;
    end;
    if FileName = OldFn then
      FFileName := NewFn;
    result := true;
  end;
end;

function TQDBFile.Save: TQDataSet;
var
  fn: String;
begin
  if self.FFilePath = '' then
    exit;
  fn := GetFullPathFile();
  DBSet.SaveTofile(fn);
  result := DBSet.DataSet;
end;

function TQDBFile.SelectFile(aFileName: String): TQDataSet;
begin

  if FFileName <> aFileName then
  begin

    FFileName := aFileName;
    result := FDBSet.DataSet;
    aFileName := GetFullPathFile(aFileName);

    if fileExists(aFileName) then
      with FDBSet do
      begin
        LoadFromFile(aFileName);
      end;
  end;
end;

{ TQDBRecordFile<TRecord> }

procedure TQDBRecordFile<TRecord>.beforeInsert(DataSet: TDataSet);
begin

end;

procedure TQDBRecordFile<TRecord>.initDataset;
begin
  FDBSet.DataSet.FieldDefs.Clear;
  FDBSet.DataSet.FieldsFromRecordType<TRecord>();
end;

end.
