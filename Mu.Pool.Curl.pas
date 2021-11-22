unit Mu.Pool.Curl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  curl_d, QSimplePool,

  System.Classes;

type
  TCurlHttpPool = class(TObject)
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
    function get(): TCurlHttpRequest;
    procedure return(ajs: TCurlHttpRequest);
    procedure release(ajs: TCurlHttpRequest);

  end;

type
  TCurlhttpsPool = class(TObject)
  private
    FPool: TQSimplePool;
    procedure FOnCUrlCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);

    procedure httpsPoolCreate(Sender: TObject; var aObject: TObject);
  protected

  public
    constructor Create(Poolsize: integer = 20);
    destructor Destroy; override;
    function get(): TCurlhttpsRequest;
    procedure return(ajs: TCurlhttpsRequest);
    procedure release(ajs: TCurlhttpsRequest);

  end;

var

  CurlHttpPool: TCurlHttpPool;
  CurlhttpsPool: TCurlhttpsPool;

implementation

{ TCurlHttpRequestPool }

constructor TCurlHttpPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnCUrlCreate, FOnCUrlFree,
    FOnCUrlReset);

end;

destructor TCurlHttpPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TCurlHttpPool.FOnCUrlCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  AData := TCurlHttpRequest.Create();
end;

procedure TCurlHttpPool.FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
begin
  TCurlHttpRequest(AData).Free;;
end;

procedure TCurlHttpPool.FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function TCurlHttpPool.get: TCurlHttpRequest;
begin
  result := TCurlHttpRequest(FPool.pop);
end;

procedure TCurlHttpPool.HttpPoolCreate(Sender: TObject; var aObject: TObject);
begin
  aObject := TCurlHttpRequest.Create();
end;

procedure TCurlHttpPool.release(ajs: TCurlHttpRequest);
begin
  FPool.push(ajs);
end;

procedure TCurlHttpPool.return(ajs: TCurlHttpRequest);
begin
  FPool.push(ajs);
end;

{ TCurlhttpsRequestPool }

constructor TCurlhttpsPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnCUrlCreate, FOnCUrlFree,
    FOnCUrlReset);

end;

destructor TCurlhttpsPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TCurlhttpsPool.FOnCUrlCreate(Sender: TQSimplePool;
  var AData: Pointer);
begin
  AData := TCurlhttpsRequest.Create();
end;

procedure TCurlhttpsPool.FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
begin
  TCurlhttpsRequest(AData).Free;;
end;

procedure TCurlhttpsPool.FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function TCurlhttpsPool.get: TCurlhttpsRequest;
begin
  result := TCurlhttpsRequest(FPool.pop);
end;

procedure TCurlhttpsPool.httpsPoolCreate(Sender: TObject; var aObject: TObject);
begin
  aObject := TCurlhttpsRequest.Create();
end;

procedure TCurlhttpsPool.release(ajs: TCurlhttpsRequest);
begin
  FPool.push(ajs);
end;

procedure TCurlhttpsPool.return(ajs: TCurlhttpsRequest);
begin
  FPool.push(ajs);
end;

initialization

CurlHttpPool := TCurlHttpPool.Create(100);
CurlhttpsPool := TCurlhttpsPool.Create(100);

finalization

CurlHttpPool.Free;
CurlhttpsPool.Free;

end.
