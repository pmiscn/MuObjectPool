unit Mu.Pool.HttpClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  QSimplePool,
  System.Net.URLClient, System.NetConsts, System.Net.Mime,
  System.Net.HttpClient,

  System.Classes;

type
  THttpClientPool = class(TObject)
  private
    FPool: TQSimplePool;
    procedure FOnCUrlCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);

    procedure HttpPoolCreate(Sender: TObject; var aObject: TObject);
  protected

  public
    constructor Create(Poolsize: integer = 20);
    destructor Destroy; override;
    function get(): THttpClient;
    procedure return(ajs: THttpClient);
    procedure release(ajs: THttpClient);

  end;

var
  HttpClientPool: THttpClientPool;

implementation

{ THttpClientPool }

constructor THttpClientPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnCUrlCreate, FOnCUrlFree,
    FOnCUrlReset);

end;

destructor THttpClientPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure THttpClientPool.FOnCUrlCreate(Sender: TQSimplePool;
  var AData: Pointer);
begin
  THttpClient(AData) := THttpClient.Create();
end;

procedure THttpClientPool.FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
begin
  THttpClient(AData).Free;;
end;

procedure THttpClientPool.FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function THttpClientPool.get: THttpClient;
begin
  result := THttpClient(FPool.pop);
end;

procedure THttpClientPool.HttpPoolCreate(Sender: TObject; var aObject: TObject);
begin
  aObject := THttpClient.Create();
end;

procedure THttpClientPool.release(ajs: THttpClient);
begin
  FPool.push(ajs);
end;

procedure THttpClientPool.return(ajs: THttpClient);
begin
  FPool.push(ajs);
end;

initialization

HttpClientPool := THttpClientPool.Create(10);

finalization

HttpClientPool.Free;

end.
