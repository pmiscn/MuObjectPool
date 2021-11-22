unit QDBhelp;
//

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.TypInfo, System.Rtti,
  dialogs, QString,
  qValue, QDB, qconverter_stds, qconverter_fdac, qconverter_csv,
  qaes, Mu.CharsHelper, Mu.Varchar, Mu.Aes, {Mu.BytesHelper,}
  qsp_aes, zlib, qsp_zlib,
  DateUtils, Mu.QDatasethelper, QSimplePool,
  Data.DB, QJSON;

const
  QDBCVT_Binary = 1;
  QDBCVT_MsgPack = 2;
  QDBCVT_Json = 3;
  QDBCVT_FDBinary = 4;
  QDBCVT_FDJson = 5;
  QDBCVT_FDXML = 6;
  QDBCVT_Text = 7;

type

  TQDBConverter = class(TObject)

    FDataset: TQDataset;
    FConverter: TQConverter;

    FCompress: boolean;
    FZLibProcessor: TQZlibStreamProcessor;
    FConpressLevel: Integer;

    FAESProcessor: TQAESStreamProcessor;
    FEncrypt: boolean;
    FEncryptMode: Integer;
    FAESInitVector: string;
    FAESKeyType: TQAESKeyType;
    FAESPassWord: string;

    FFileType: Integer;

    FmerMeta: boolean;
    FmerInserted: boolean;
    FmerUnmodified: boolean;
    FmerDeleted: boolean;
    FmerModified: boolean;

  private
    function CreateConverter(ATypeIndex: Integer = QDBCVT_Binary): TQConverter;
    function getConverter(): TQConverter;
  public
    constructor create(adataset: TQDataset);
    destructor Destroy; override;

    property Converter: TQConverter read getConverter; // 一旦调用，无法更改加密和压缩类型；

    property Dataset: TQDataset read FDataset write FDataset;
    property Compress: boolean read FCompress write FCompress;
    property ConpressLevel: Integer read FConpressLevel write FConpressLevel;

    property Encrypt: boolean read FEncrypt write FEncrypt;
    property EncryptMode: Integer read FEncryptMode write FEncryptMode;
    property AESInitVector: string read FAESInitVector write FAESInitVector;
    property AESKeyType: TQAESKeyType read FAESKeyType write FAESKeyType;
    property AESPassWord: string read FAESPassWord write FAESPassWord;

    property erMeta: boolean read FmerMeta write FmerMeta;
    property erInserted: boolean read FmerInserted write FmerInserted;
    property erUnmodified: boolean read FmerUnmodified write FmerUnmodified;
    property erDeleted: boolean read FmerDeleted write FmerDeleted;
    property erModified: boolean read FmerModified write FmerModified;

    property FileType: Integer read FFileType write FFileType;
  end;

  TQDBSet = class(TObject)

  private
    FDataset: TQDataset;
    FConverter: TQDBConverter;
    FRWSyn: TMultiReadExclusiveWriteSynchronizer;
    // FDatasetPool: TQSimplePool;
    FPoolsize: Integer;
    function GetDBConvert(): TQDBConverter;
    function GetConvert(): TQConverter;

    procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);

  public
    constructor create();
    destructor Destroy; override;

    function SaveTofile(aFn: string): boolean;
    function LoadFromFile(aFn: string): boolean;
    //
    // function Get(): TQDataset;
    // procedure Return(adataset: TQDataset);
    //
    function BeginRead: TQDataset;
    procedure EndRead(adataset: TQDataset);
    //
    function BeginWrite: TQDataset;
    procedure EndWrite(adataset: TQDataset = nil);
    //
    function Where(aWhere: String; aIsClone: boolean = false)
      : TQDataset; overload;
    function Update(AException, aWhere: String): TQDataset; overload;

    //
    property Dataset: TQDataset read FDataset;
    property DBConverter: TQDBConverter read GetDBConvert;
    property Converter: TQConverter read GetConvert;

  end;

implementation

// -- TQDBSet  --------------------------------------------------------

constructor TQDBSet.create;
begin
  FPoolsize := 10;
  FDataset := TQDataset.create(nil);
  FRWSyn := TMultiReadExclusiveWriteSynchronizer.create;

  // FDatasetPool := TQSimplePool.create(FPoolsize, FOnObjectCreate, FOnObjectFree,
  // FOnObjectReset);
end;

destructor TQDBSet.Destroy;
begin
  if FConverter <> nil then
    FConverter.Free;

  if FDataset.Active then
  begin
    FDataset.Filter := '';
    FDataset.Filtered := false;
    FDataset.Close;
  end;
  FDataset.Free;
  FRWSyn.Free;
  // FDatasetPool.Free;
  inherited;
end;

function TQDBSet.BeginRead: TQDataset;
begin
  FRWSyn.BeginRead;
  result := self.FDataset;
  // result := self.Get;
  // result.Clone(FDataset);
end;

procedure TQDBSet.EndRead(adataset: TQDataset);
begin
  // self.Return(adataset);
  FRWSyn.EndRead;
end;

function TQDBSet.BeginWrite: TQDataset;
begin
  FRWSyn.BeginWrite;
  result := self.FDataset;
end;

procedure TQDBSet.EndWrite(adataset: TQDataset);
begin
  FRWSyn.EndWrite;
end;

procedure TQDBSet.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  AData := TQDataset.create(nil);
end;

procedure TQDBSet.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  TQDataset(AData).Free;
end;

procedure TQDBSet.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

// function TQDBSet.Get: TQDataset;
// begin
/// /  result := TQDataset(FDatasetPool.pop);
// end;
//
// procedure TQDBSet.Return(adataset: TQDataset);
// begin
/// /  FDatasetPool.Push(adataset);
// end;

function TQDBSet.GetConvert: TQConverter;
begin
  if not Assigned(FConverter) then
    FConverter := TQDBConverter.create(FDataset);
  result := FConverter.Converter;
end;

function TQDBSet.GetDBConvert: TQDBConverter;
begin
  if not Assigned(FConverter) then
    FConverter := TQDBConverter.create(FDataset);
  result := FConverter;
end;

function TQDBSet.LoadFromFile(aFn: string): boolean;
begin
  result := false;
  // FDataset.Close;
  // FDataset.RecreateDataSet;
  FDataset.LoadFromFile(aFn, Converter);
  result := true;
end;

function TQDBSet.SaveTofile(aFn: string): boolean;
begin
  result := false;
  if not FDataset.Active then
    FDataset.Open;
  FDataset.ApplyChanges;

  FDataset.SaveTofile(aFn, Converter);
  result := true;
end;

function TQDBSet.Update(AException, aWhere: String): TQDataset;
var
  ds: TQDataset;
begin
  ds := self.BeginWrite;
  try
    result := ds.Where(aWhere, false);
    result.Update(AException);
   // result.Filtered := false;
  finally
    self.EndWrite(ds);
  end;

end;

function TQDBSet.Where(aWhere: String; aIsClone: boolean): TQDataset;
begin
  result := self.FDataset.Where(aWhere, aIsClone);
end;

{ TQDBConverter }

constructor TQDBConverter.create(adataset: TQDataset);
begin

  FEncrypt := false;
  FCompress := false;
  FAESInitVector := MuAesOptions.InitVector;
  FAESKeyType := MuAesOptions.KeyType; // kt256;
  FAESPassWord := MuAesOptions.Key;
  if MuAesOptions.CBCOrECB then
    FEncryptMode := 1
  else
    FEncryptMode := 0;

  FmerMeta := true;
  // FmerInserted := true;
  FmerUnmodified := true;
  // FmerDeleted := true;
  // 我是插入的，我改了这个后，就能够保存
  // FmerModified := true;

  FFileType := 1;
end;

destructor TQDBConverter.Destroy;
begin
  if Assigned(FZLibProcessor) then
    FZLibProcessor.Free;
  if Assigned(FAESProcessor) then
    FAESProcessor.Free;
  if Assigned(FConverter) then
    FConverter.Free;
  inherited;
end;

function TQDBConverter.getConverter: TQConverter;
var
  ARange: TQExportRanges;
begin
  ARange := [];
  if FmerMeta then
    ARange := [merMeta];
  if FmerInserted then
    ARange := ARange + [merInserted];
  if FmerUnmodified then
    ARange := ARange + [merUnmodified];
  if FmerDeleted then
    ARange := ARange + [merDeleted];
  if FmerModified then
    ARange := ARange + [merModified];
  if not Assigned(FConverter) then
    FConverter := CreateConverter();

  if FConverter <> nil then
  begin
    FConverter.ExportRanges := ARange;
  end;
  result := FConverter;
end;

function TQDBConverter.CreateConverter(ATypeIndex: Integer = QDBCVT_Binary)
  : TQConverter;
begin
  result := nil;
  if ATypeIndex <> 0 then
    FFileType := ATypeIndex;

  case FFileType of
    QDBCVT_Binary:
      result := TQBinaryConverter.create(nil);
    QDBCVT_MsgPack:
      result := TQMsgPackConverter.create(nil);
    QDBCVT_Json:
      result := TQJsonConverter.create(nil);
    QDBCVT_FDBinary:
      result := TQFDBinaryConverter.create(nil);
    QDBCVT_FDJson:
      result := TQFDJsonConverter.create(nil);
    QDBCVT_FDXML:
      result := TQFDXMLConverter.create(nil);
    QDBCVT_Text:
      result := TQTextConverter.create(nil);
  end;

  if FCompress then
  begin
    if not Assigned(FZLibProcessor) then
      FZLibProcessor := TQZlibStreamProcessor.create(nil);
    FZLibProcessor.CompressionLevel := TZCompressionLevel(FConpressLevel);
    result.StreamProcessors.Add.Processor := FZLibProcessor;
  end;
  if FEncrypt then
  begin
    if not Assigned(FAESProcessor) then
    begin
      FAESProcessor := TQAESStreamProcessor.create(nil);
      // 演示程序，所以直接硬设置了初始向量和密码
      FAESProcessor.InitVector := FAESInitVector;
      if FEncryptMode = 0 then
        FAESProcessor.EncryptMode := emECB
      else
        FAESProcessor.EncryptMode := emCBC;

      FAESProcessor.KeyType := FAESKeyType;
      FAESProcessor.Password := FAESPassWord;
      FAESProcessor.EncryptMode := emCBC;
    end;
    result.StreamProcessors.Add.Processor := FAESProcessor;
  end;

end;

end.
