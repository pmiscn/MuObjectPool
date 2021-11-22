unit Mu.Pool.QMacro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  QSimplePool, qMacros,
  System.Classes;

type
  TQMacroHelp = class
  private

    qMacroPool: TQSimplePool;
    procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
    procedure ObjectCreate(Sender: TObject; var aObject: TObject);
    procedure ObjectFree(Sender: TObject; var aObject: TObject);

  public
    constructor Create(apoolsize: integer = 20);
    destructor Destroy; override;
    function getMacro(): TQMacroManager;
    procedure returnMacro(o: TQMacroManager);
    function get(): TQMacroManager;
    procedure return(o: TQMacroManager);
  end;

var
  QMacroHelp: TQMacroHelp;

implementation

constructor TQMacroHelp.Create(apoolsize: integer = 20);
begin
  qMacroPool := TQSimplePool.Create(apoolsize, FOnObjectCreate, FOnObjectFree,
    FOnObjectReset);
end;

destructor TQMacroHelp.Destroy;
begin
  qMacroPool.Free;
  inherited;
end;

procedure TQMacroHelp.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  TQMacroManager(AData) := TQMacroManager.Create;
end;

procedure TQMacroHelp.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  TQMacroManager(AData).Clear;
  Freeandnil(TQMacroManager(AData));
end;

procedure TQMacroHelp.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function TQMacroHelp.get: TQMacroManager;
begin

  result := TQMacroManager(qMacroPool.pop());
end;

function TQMacroHelp.getMacro: TQMacroManager;
begin
  result := TQMacroManager(qMacroPool.pop());
end;

procedure TQMacroHelp.ObjectCreate(Sender: TObject; var aObject: TObject);
begin

end;

procedure TQMacroHelp.ObjectFree(Sender: TObject; var aObject: TObject);
begin

end;

procedure TQMacroHelp.return(o: TQMacroManager);
begin
  qMacroPool.push(o);
end;

procedure TQMacroHelp.returnMacro(o: TQMacroManager);
begin
  qMacroPool.push(o);
end;

initialization

QMacroHelp := TQMacroHelp.Create;
// qMacroPool := TMuObjectPool.Create(TQMacroManager);
// qMacroPool.OnObjectCreate := ObjectCreate;

finalization

QMacroHelp.Free;
// qMacroPool.Free;

end.
