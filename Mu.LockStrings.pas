unit Mu.LockStrings;

interface

uses
  classes, SyncObjs;

type
  TLockedStringlist = class(TObject)
    private
      FLock   : TCriticalSection;
      FStrings: Tstringlist;
      function getCount(): integer;
    public
      constructor create;
      destructor destroy; override;
      function GetOne(var S: string): boolean;
      function GetAll(st: Tstrings): boolean;
      function add(S: string): boolean; overload;
      function add(st: Tstrings): boolean; overload;
      function put(S: string): boolean;
      property count: integer read getCount;

      procedure loadFromFile(afn: String);
      procedure loadFromStream(astm: TStream);

  end;

implementation

{ TLockedStringlist }

function TLockedStringlist.add(st: Tstrings): boolean;
begin
  FLock.Enter;
  try
    FStrings.AddStrings(st);
  finally
    FLock.Leave;
  end;
end;

constructor TLockedStringlist.create;
begin
  FLock    := TCriticalSection.create;
  FStrings := Tstringlist.create;
  inherited;
end;

destructor TLockedStringlist.destroy;
begin
  // FLock.Enter;
  FLock.Free;
  FStrings.Free;
  inherited destroy;
end;

function TLockedStringlist.GetAll(st: Tstrings): boolean;
begin
  FLock.Enter;
  try
    try
      if FStrings.count > 0 then
      begin
        st.Assign(FStrings);
        FStrings.Clear;
        result := true;
      end else begin
        // FStrings.Clear;
        result := false;
      end;
    except
    end;

  finally
    FLock.Leave;
  end;
end;

function TLockedStringlist.GetOne(var S: string): boolean;
begin
  FLock.Enter;
  try
    try
      if FStrings.count > 0 then
      begin
        S := FStrings[0];
        FStrings.Delete(0);
        result := true;
      end else begin
        // FStrings.Clear;
        result := false;
      end;
    except
    end;

  finally
    FLock.Leave;
  end;
end;

procedure TLockedStringlist.loadFromFile(afn: String);
begin
  FLock.Enter;
  try
    FStrings.loadFromFile(afn);
  finally
    FLock.Leave;
  end;
end;

procedure TLockedStringlist.loadFromStream(astm: TStream);
begin
  FLock.Enter;
  try
    FStrings.loadFromStream(astm);
  finally
    FLock.Leave;
  end;
end;

function TLockedStringlist.getCount(): integer;
begin
  FLock.Enter;
  try
    result := FStrings.count;
  finally
    FLock.Leave;
  end;
end;

function TLockedStringlist.add(S: string): boolean;
begin
  FLock.Enter;
  try
    FStrings.add(S);
  finally
    FLock.Leave;
  end;
end;

function TLockedStringlist.put(S: string): boolean;
begin
  FLock.Enter;
  try
    FStrings.Insert(0, S);
  finally
    FLock.Leave;
  end;
end;

end.
