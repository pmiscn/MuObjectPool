unit Mu.StringGrid;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Grids, ClipBrd, printers, Generics.Collections,
  Dialogs, StdCtrls;

const
  OddLineColor = $00EBEBEB;
  EvenLineColor = $00FFFFFF;

procedure SetComboboxToStringGridCell(cb: TComboBox; SG: tStringgrid;
  ACol, ARow: integer);

type
  TComboboxes = array of TComboBox;
  PComboBoxCol = ^TComboBoxCol;

  TComboBoxCol = record
    Combobox: TComboBox;
    Col: integer;
    onSelectItem: TNotifyEvent;
  end;

  TComboBoxCols = array of PComboBoxCol;
  TOperationType = (OTDelete, OTAdd, OTEdit, OTCustom);

  TOperationCol = record
    Caption: string;
    Col: integer;
    OperationType: TOperationType;
    DoEvent: TNotifyEvent;
  end;

  TOperationCols = array of TOperationCol;

  TStringGridMng = class(TObject)
  private
    FStringGrid: tStringgrid;
    FAutoAddEmtpyLine: Bool;
    FComboBoxCols: TComboBoxCols;
    FReadOnlyCols: TList<integer>;
    FOnDrawCell: TDrawCellEvent;
    FOnDrawCell_old: TDrawCellEvent;
    FOnMouseUp: TMouseEvent;
    FOnMouseUp_old: TMouseEvent;
    FOnComboboxSelect: TNotifyEvent;
    FOnSelectCell: TSelectCellEvent;
    FOnSelectCell_old: TSelectCellEvent;
    FLineColor: Bool;
    FOperationCols: TOperationCols;

    function isOptionCol(c: integer; var acaption: string): Bool;

    procedure ComboboxExit(Sender: TObject);
    procedure ComboboxSelect(Sender: TObject);

    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: integer;
      Rect: TRect; State: TGridDrawState);
    procedure StringGridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: integer;
      var CanSelect: Boolean);
  public
    constructor create(aStringGrid: tStringgrid);
    destructor destroy; override;

    procedure setCaptions(captions: array of string);
    procedure setWidths(wds: array of integer);
    procedure addReadOnlyCols(cols: array of integer);
    procedure addOperationCol(ACol: integer; Caption: string;
      aOperationType: TOperationType; aOnEvent: TNotifyEvent = nil);

    function addCombobox(Col: integer; items: Tstrings): PComboBoxCol; overload;
    function addCombobox(Col: integer; itemstring: string)
      : PComboBoxCol; overload;
    function getCombobox(Col: integer): TComboBox;
    procedure setCombobox(Col: integer; aCombobox: TComboBox);

    property AutoAddEmtpyLine: Bool read FAutoAddEmtpyLine
      write FAutoAddEmtpyLine;
    property StringGrid: tStringgrid read FStringGrid write FStringGrid;
    property LineColor: Bool read FLineColor write FLineColor;
    property OnDrawCell: TDrawCellEvent read FOnDrawCell write FOnDrawCell;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnSelectCell: TSelectCellEvent read FOnSelectCell
      write FOnSelectCell;
    property OnComboboxSelect: TNotifyEvent read FOnComboboxSelect
      write FOnComboboxSelect;
  end;

procedure GridRemoveCell(StrGrid: tStringgrid; ACol, ARow: integer);
procedure GridRemoveCells(StrGrid: tStringgrid;
  left, top, right, bottom: integer); overload;
procedure GridRemoveCells(StrGrid: tStringgrid; GridRect: TGridRect)
  stdcall; overload;
procedure GridAddCell(StrGrid: tStringgrid; ACol, ARow: integer);

procedure GridRemoveColumn(StrGrid: tStringgrid; DelColumn: integer);
procedure GridRemoveRow(StrGrid: tStringgrid; DelRow: integer);

procedure GridAddRow(StrGrid: tStringgrid; NewRow: integer);
procedure GridAddColumn(StrGrid: tStringgrid; NewColumn: integer);

// procedure QuickSort(var SortNum: array of single; p, r: integer);
procedure GridColSort(StrGrid: tStringgrid; ACol: integer; isDesc: Boolean);
procedure BubbleSortStr(fstr: Tstringlist); // 冒泡排序
//
procedure GridClearCells(StrGrid: tStringgrid);
procedure GridCopyToClipBrd(StrGrid: tStringgrid; IsCun: Bool = false);
procedure GridPasteFromClipBrd(StrGrid: tStringgrid; ACol, ARow: integer);

procedure GridGetColData(StrGrid: tStringgrid; ACol: integer; ST: Tstrings);

procedure SaveStringGrid(StringGrid: tStringgrid; const FileName: TFileName);
procedure LoadStringGrid(StringGrid: tStringgrid; const FileName: TFileName);

procedure PrintGrid(sGrid: tStringgrid; sTitle: string);

implementation

uses qstring;

function split(s, de: String; ST: Tstrings): integer;
begin
  result := SplitTokenW(ST, s, PQCharW(de), '"', false);
end;

procedure SaveStringGrid(StringGrid: tStringgrid; const FileName: TFileName);
var
  f: TextFile;
  i, k: integer;
  LineStr: string;
begin
  AssignFile(f, FileName);
  Rewrite(f);
  LineStr := '';
  with StringGrid do
  begin
    for k := 0 to RowCount - 1 do
    begin
      LineStr := '';
      for i := 0 to ColCount - 1 do
        if i = ColCount - 1 then
          LineStr := LineStr + Cells[i, k]
        else
          LineStr := LineStr + Cells[i, k] + ',';
      Writeln(f, LineStr);
    end;
  end;
  CloseFile(f);
end;

procedure LoadStringGrid(StringGrid: tStringgrid; const FileName: TFileName);
var
  aa, bb: Tstringlist;
  i: integer;
begin
  aa := Tstringlist.create;
  bb := Tstringlist.create;
  aa.LoadFromFile(FileName);
  for i := 0 to aa.Count - 1 do
  begin
    SplitTokenW(bb, (aa.Strings[i]), ',', '"', true);
    StringGrid.Rows[i] := bb;
  end;
  aa.Free;
  bb.Free;
end;
/// ///////////////////////////////

procedure swap(var a, b: string); // ??
var
  tmp: string;
begin
  tmp := a;
  a := b;
  b := tmp;
end;

procedure BubbleSortStr(fstr: Tstringlist);
var
  i, J: integer;
  T: string;
begin
  for i := fstr.Count - 1 downto 0 do
    for J := 0 to fstr.Count - 2 do
      if strtofloat(fstr.Strings[J]) > strtofloat(fstr.Strings[J + 1]) then
      begin
        T := fstr.Strings[J];
        fstr.Strings[J] := fstr.Strings[J + 1];
        fstr.Strings[J + 1] := T;
      end;
end;

// 删除单元格,下面的上移

procedure GridRemoveCell(StrGrid: tStringgrid; ACol, ARow: integer);
var
  nRow: integer;
begin
  with StrGrid do
  begin
    for nRow := ARow to RowCount - 2 do
      Cells[ACol, nRow] := Cells[ACol, nRow + 1];
    Cells[ACol, RowCount - 1] := ''; // 最后一行为空
  end;
end;

procedure GridRemoveCells(StrGrid: tStringgrid;
  left, top, right, bottom: integer); overload;
var
  nRow, nCol: integer;
begin
  for nCol := right downto left do
    for nRow := bottom downto top do
      GridRemoveCell(StrGrid, nCol, nRow);
end;

procedure GridRemoveCells(StrGrid: tStringgrid; GridRect: TGridRect);
  stdcall; overload;
var
  nRow, nCol: integer;
begin
  for nCol := GridRect.right downto GridRect.left do
    for nRow := GridRect.bottom downto GridRect.top do
      GridRemoveCell(StrGrid, nCol, nRow);
end;

// 插入单元格,下移

procedure GridAddCell(StrGrid: tStringgrid; ACol, ARow: integer);
var
  nRow: integer;
begin
  with StrGrid do
  begin
    for nRow := RowCount - 1 downto ARow do
      Cells[ACol, nRow] := Cells[ACol, nRow - 1];
    Cells[ACol, ARow] := ''; // 最后一行为空
  end;
end;

// 删除列

procedure GridRemoveColumn(StrGrid: tStringgrid; DelColumn: integer);
var
  Column: integer;
begin
  if DelColumn <= StrGrid.ColCount then
    for Column := DelColumn to StrGrid.ColCount - 1 do
      StrGrid.cols[Column].Assign(StrGrid.cols[Column + 1]);
end;

// 插入列

procedure GridAddColumn(StrGrid: tStringgrid; NewColumn: integer);
var
  Column: integer;
begin
  StrGrid.ColCount := StrGrid.ColCount + 1;
  for Column := StrGrid.ColCount - 1 downto NewColumn do
    StrGrid.cols[Column].Assign(StrGrid.cols[Column - 1]);
  StrGrid.cols[NewColumn].Text := '';
end;

// 删除行

procedure GridRemoveRow(StrGrid: tStringgrid; DelRow: integer);
var
  nRow: integer;
begin
  if DelRow <= StrGrid.RowCount then
  begin
    for nRow := DelRow to StrGrid.RowCount - 1 do
      StrGrid.Rows[nRow].Assign(StrGrid.Rows[nRow + 1]);
  end;
end;

// 插入行

procedure GridAddRow(StrGrid: tStringgrid; NewRow: integer);
var
  nRow: integer;
begin
  StrGrid.RowCount := StrGrid.RowCount + 1;
  for nRow := StrGrid.RowCount - 1 downto NewRow do
    StrGrid.Rows[nRow].Assign(StrGrid.Rows[nRow - 1]);
  StrGrid.Rows[NewRow].Text := '';
end;

procedure GridGetColData(StrGrid: tStringgrid; ACol: integer; ST: Tstrings);
var
  i: integer;
begin
  try
    ST.Clear;
    with StrGrid do
    begin
      for i := 1 to ColCount - 1 do // .读取所有数据
      begin
        if trim(Cells[ACol, i]) <> '' then
          // if isFloat(trim(Cells[ACol, i])) then
          ST.Add(trim(Cells[ACol, i]));
      end;
    end;
  finally

  end;
end;

// 列排序,仅适应于当列数值,其他列数值不改变

procedure GridColSort(StrGrid: tStringgrid; ACol: integer; isDesc: Boolean);
var
  i: integer;
  dataStr: Tstringlist;
  StringStr: Tstringlist;
  cellstr: string;
  FieldN: string;
begin
  dataStr := Tstringlist.create;
  StringStr := Tstringlist.create;
  try
    with StrGrid do
    begin
      for i := 1 to ColCount - 1 do // .读取所有数据
      begin
        if trim(Cells[ACol, i]) <> '' then
          // if isFloat(trim(Cells[ACol, i])) then
          dataStr.Add(trim(Cells[ACol, i]))
        else
          StringStr.Add(trim(Cells[ACol, i]));
      end;
    end;
    if (dataStr.Count < 1) and (StringStr.Count < 1) then
      exit;

    BubbleSortStr(dataStr);
    StringStr.sort;
    FieldN := StrGrid.Cells[ACol, 0];
    StrGrid.cols[ACol].Clear;
    StrGrid.Cells[ACol, 0] := FieldN;
    if isDesc then
    begin

      if StringStr.Count > 0 then
        for i := 0 to StringStr.Count - 1 do // dataStr.add(StringStr.Text);
          dataStr.Add(StringStr.Strings[i]);
      for i := dataStr.Count - 1 downto 0 do
        StrGrid.Cells[ACol, dataStr.Count - i] := dataStr.Strings[i];
    end
    else
    begin

      if StringStr.Count > 0 then
        for i := 0 to StringStr.Count - 1 do
          dataStr.Add(StringStr.Strings[i]);
      for i := 0 to dataStr.Count - 1 do
        StrGrid.Cells[ACol, i + 1] := dataStr.Strings[i];
    end;
  finally
    dataStr.Free;
    StringStr.Free;
  end;
end;

/// ///////////////
// 清除选择的单元格

procedure GridClearCells(StrGrid: tStringgrid);
var
  ARow, ACol: integer;
begin
  with StrGrid do
  begin
    for ARow := selection.top to selection.bottom do
    begin
      for ACol := selection.left to selection.right do
        if (ACol <> 0) and (ARow <> 0) then
          Cells[ACol, ARow] := '';
    end;
  end;
end;

procedure GridCopyToClipBrd(StrGrid: tStringgrid; IsCun: Bool = false);
var
  StringTemp: string;
  i, J: integer;
begin
  StringTemp := '';
  with StrGrid do
  begin
    for i := selection.top to selection.bottom do
    begin
      for J := selection.left to selection.right do
        if J <> selection.right then
          StringTemp := StringTemp + Cells[J, i] + #9
        else
          StringTemp := StringTemp + Cells[J, i];
      if i <> selection.bottom then
        StringTemp := StringTemp + #13
    end;
  end;
  if IsCun then
    GridRemoveCells(StrGrid, StrGrid.selection);
  with clipboard do
  begin
    Clear;
    Open;
    astext := StringTemp;
    Close;
  end;
end;

procedure GridPasteFromClipBrd(StrGrid: tStringgrid; ACol, ARow: integer);
var
  Buffer: array [0 .. 9999] of Char;
  nCol, nRow, i, J: integer;
  tmpstr: string;
  RectStr, LineStr: Tstringlist;

begin
  clipboard.GetTextBuf(@Buffer, SizeOf(Buffer));
  nCol := ACol;
  nRow := ARow;

  tmpstr := Buffer;
  RectStr := Tstringlist.create;
  LineStr := Tstringlist.create;

  SplitTokenW(RectStr, QStringW(tmpstr), PQCharW(#13), QCharW('"'), false);
  // 分解行
  try
    with StrGrid do
    begin
      Cells[nCol, nRow] := '';
      for i := 0 to RectStr.Count - 1 do
      begin
        // LineStr := Split(RectStr.Strings[i], #9); // 分解列
        SplitTokenW(LineStr, RectStr[i], #9, '"', false); // 分解行
        for J := 0 to LineStr.Count - 1 do
          Cells[nCol + J, nRow + i] := LineStr.Strings[J];
      end;
    end;
  finally
    LineStr.Free;
    RectStr.Free;
  end;
end;

procedure PrintGrid(sGrid: tStringgrid; sTitle: string);
var
  X1, X2: integer;
  Y1, Y2: integer;
  TmpI: integer;
  f: integer;
  TR: TRect;
begin
  Printer.Title := sTitle;
  Printer.BeginDoc;
  Printer.Canvas.Pen.Color := 0;
  Printer.Canvas.Font.Name := 'Times   New   Roman';
  Printer.Canvas.Font.Size := 12;
  Printer.Canvas.Font.Style := [fsBold, fsUnderline];
  Printer.Canvas.TextOut(0, 100, Printer.Title);
  for f := 1 to sGrid.ColCount - 1 do
  begin
    X1 := 0;
    for TmpI := 1 to (f - 1) do
      X1 := X1 + 5 * (sGrid.ColWidths[TmpI]);
    Y1 := 300;
    X2 := 0;
    for TmpI := 1 to f do
      X2 := X2 + 5 * (sGrid.ColWidths[TmpI]);
    Y2 := 450;
    TR := Rect(X1, Y1, X2 - 30, Y2);
    Printer.Canvas.Font.Style := [fsBold];
    Printer.Canvas.Font.Size := 7;
    Printer.Canvas.TextRect(TR, X1 + 50, 350, sGrid.Cells[f, 0]);
    Printer.Canvas.Font.Style := [];
    for TmpI := 1 to sGrid.RowCount - 1 do
    begin
      Y1 := 150 * TmpI + 300;
      Y2 := 150 * (TmpI + 1) + 300;
      TR := Rect(X1, Y1, X2 - 30, Y2);
      Printer.Canvas.TextRect(TR, X1 + 50, Y1 + 50, sGrid.Cells[f, TmpI]);
    end;
  end;
  Printer.EndDoc;
end;

constructor TStringGridMng.create(aStringGrid: tStringgrid);
begin
  FReadOnlyCols := TList<integer>.create;
  FStringGrid := aStringGrid;
  self.FLineColor := true;
  if assigned(FStringGrid.OnDrawCell) then
  begin
    FOnDrawCell_old := FStringGrid.OnDrawCell;
  end;
  if assigned(FStringGrid.OnMouseUp) then
  begin
    FOnMouseUp_old := FStringGrid.OnMouseUp;
  end;
  if assigned(FStringGrid.OnSelectCell) then
  begin
    FOnSelectCell_old := FStringGrid.OnSelectCell;
  end;
  FStringGrid.OnDrawCell := self.StringGridDrawCell;
  FStringGrid.OnMouseUp := self.StringGridMouseUp;
  FStringGrid.OnSelectCell := StringGridSelectCell;
end;

destructor TStringGridMng.destroy;
var
  i: integer;
begin
  FReadOnlyCols.Free;
  for i := low(FComboBoxCols) to high(FComboBoxCols) do
    dispose(PComboBoxCol(FComboBoxCols[i]));
  inherited;
end;

function TStringGridMng.isOptionCol(c: integer; var acaption: string): Bool;
var
  i: integer;
begin
  result := false;
  for i := low(FOperationCols) to high(FOperationCols) do
  begin
    if FOperationCols[i].Col = c then
    begin
      acaption := FOperationCols[i].Caption;
      result := true;
      break;
    end;
  end;
end;

procedure TStringGridMng.StringGridDrawCell(Sender: TObject;
  ACol, ARow: integer; Rect: TRect; State: TGridDrawState);
var
  r: TRect;
  SG: tStringgrid;
  oc: TOperationCol;
var
  s1: string;

begin
  SG := tStringgrid(Sender);

  if (ACol = 0) and (ARow > 0) then
  begin
    r := SG.CellRect(ACol, ARow);
    SG.Canvas.TextOut(r.left + 2, r.top + 2, inttostr(ARow));
  end;
  if FLineColor then
  begin
    with SG do
    begin
      Canvas.Brush.Color := clwindow ;

      if ((ACol > 0) and (ARow > 0)) and (Cells[1, ARow] <> '') then
      begin
        r := CellRect(ACol, ARow);
        if (ARow mod 2) = 0 then
          Canvas.Brush.Color := EvenLineColor
        else
          Canvas.Brush.Color := OddLineColor;

        if not(goEditing in SG.Options) then
          Canvas.Brush.Color := Canvas.Brush.Color - $00202020;
        if (gdFocused in State) or (gdSelected in State) then
        begin
          Canvas.Brush.Color := clHighlight;
          Canvas.Font.Color := clHighlightText;
        end;
        Canvas.FillRect(r);
        Canvas.TextOut(r.left + 5, r.top + 2, Cells[ACol, ARow]);

      end;
    end;
  end;
  if isOptionCol(ACol, s1) and (ARow > 0) then
  begin
    r := SG.CellRect(ACol, ARow);
    SG.Canvas.Brush.Color := clbtnface;
    r.top := r.top + 2;
    r.left := r.left + 2;
    r.right := r.right - 2;
    r.bottom := r.bottom - 2;
    with SG.Canvas do
    begin
      FillRect(r);
      Pen.Color := clblack;
      MoveTo(r.left, r.bottom);
      lineTo(r.right, r.bottom);
      lineTo(r.right, r.top + 1);
      Font.Color := clblack;
      TextOut(r.left + 5, r.top, s1);
    end;
  end;

  if assigned(FOnDrawCell) then
  begin
    FOnDrawCell(Sender, ACol, ARow, Rect, State);
  end;
  if assigned(FOnDrawCell_old) then
    FOnDrawCell_old(Sender, ACol, ARow, Rect, State);
end;

procedure TStringGridMng.StringGridMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  ACol, ARow: integer;
var
  SG: tStringgrid;
  OperationCol: TOperationCol;
  function GetOperationType(c: integer; var aOperationCol: TOperationCol): Bool;
  var
    i: integer;
  begin
    result := false;
    // aOperationType
    for i := low(FOperationCols) to high(FOperationCols) do
    begin

      if FOperationCols[i].Col = c then
      begin
        result := true;
        aOperationCol.Col := c;
        aOperationCol.Caption := FOperationCols[i].Caption;
        aOperationCol.OperationType := FOperationCols[i].OperationType;
        aOperationCol.DoEvent := FOperationCols[i].DoEvent;
        break;
      end;
    end;
  end;

begin
  SG := tStringgrid(Sender);
  SG.MouseToCell(X, Y, ACol, ARow);
  if GetOperationType(ACol, OperationCol) and (ARow > 0) then
  begin
    case OperationCol.OperationType of
      OTDelete:
        begin
          if messagebox(SG.Parent.Handle, '确认要删除行吗？', '确认', MB_ICONQUESTION or
            MB_YESNO) = id_yes then
            GridRemoveRow(SG, ARow);
        end;
      OTAdd:
        begin

        end;
      OTEdit:
        begin

        end;
      OTCustom:
        begin
          if assigned(OperationCol.DoEvent) then
            OperationCol.DoEvent(Sender);
        end;
    end;
  end;
  if self.FAutoAddEmtpyLine then
    if trim(SG.Cells[1, SG.RowCount - 1]) <> '' then
      SG.RowCount := SG.RowCount + 1;

  if assigned(FOnMouseUp) then
    FOnMouseUp(Sender, Button, Shift, X, Y);
  if assigned(FOnMouseUp_old) then
    FOnMouseUp_old(Sender, Button, Shift, X, Y);
end;

procedure TStringGridMng.StringGridSelectCell(Sender: TObject;
  ACol, ARow: integer; var CanSelect: Boolean);
var
  SG: tStringgrid;
  r: TRect;
  org: TPoint;
  i: integer;
  s1: string;
begin
  SG := tStringgrid(Sender);

  if (self.FReadOnlyCols.IndexOf((ACol)) <> -1) or isOptionCol(ACol, s1) then
    SG.Options := SG.Options - [goEditing]
  else
    SG.Options := SG.Options + [goEditing];

  if assigned(self.FOnSelectCell) then
    FOnSelectCell(Sender, ACol, ARow, CanSelect);

  // if sg.Name = 'SG_TaskType' then
  begin
    for i := low(FComboBoxCols) to high(FComboBoxCols) do
    begin
      if (FComboBoxCols[i].Col = ACol) and (goEditing in SG.Options) then
        SetComboboxToStringGridCell(FComboBoxCols[i].Combobox, SG, ACol, ARow);
    end;
  end;

  if assigned(FOnSelectCell_old) then
    FOnSelectCell_old(Sender, ACol, ARow, CanSelect);
end;

procedure TStringGridMng.ComboboxExit(Sender: TObject);
begin
  TComboBox(Sender).hide;
end;

procedure TStringGridMng.ComboboxSelect(Sender: TObject);
var
  i: integer;
begin
  with Sender as TComboBox do
  begin
    hide;
    if itemindex >= 0 then
      with self.FStringGrid do
        Cells[Col, row] := items[itemindex];
  end;
  for i := low(FComboBoxCols) to high(FComboBoxCols) do
  begin
    if FComboBoxCols[i].Combobox.Name = TComboBox(Sender).Name then
    begin
      if assigned(FComboBoxCols[i].onSelectItem) then
        FComboBoxCols[i].onSelectItem(Sender);
    end;
  end;
  if assigned(FOnComboboxSelect) then
    FOnComboboxSelect(Sender);
end;

function TStringGridMng.addCombobox(Col: integer; items: Tstrings)
  : PComboBoxCol;
var
  i, J: integer;
begin
  i := length(FComboBoxCols);
  setlength(FComboBoxCols, i + 1);
  FComboBoxCols[i] := new(PComboBoxCol);
  FComboBoxCols[i].Col := Col;
  FComboBoxCols[i].Combobox := TComboBox.create(FStringGrid.Owner);
  FComboBoxCols[i].Combobox.Name := format('%s_%s_%d_%d',
    [FStringGrid.Name, 'Combobox', Col, i]);
  FComboBoxCols[i].Combobox.Parent := FStringGrid.Parent;
  FComboBoxCols[i].Combobox.Tag := Col;
  FComboBoxCols[i].Combobox.Visible := false;
  FComboBoxCols[i].Combobox.OnExit := ComboboxExit;
  FComboBoxCols[i].Combobox.OnSelect := ComboboxSelect;
  FComboBoxCols[i].Combobox.items.Clear;
  FComboBoxCols[i].Combobox.Text := '';
  for J := 0 to items.Count - 1 do
    if trim(items[J]) <> '' then
      FComboBoxCols[i].Combobox.items.Add(trim(items[J]));
  result := FComboBoxCols[i]; // FComboBoxCols[i].Combobox;

end;

function TStringGridMng.addCombobox(Col: integer; itemstring: string)
  : PComboBoxCol;
var
  ST: Tstringlist;
begin
  ST := Tstringlist.create;
  try
    split(itemstring, ',', ST);
    result := addCombobox(Col, ST);
  finally
    ST.Free;
  end;
end;

procedure TStringGridMng.setCombobox(Col: integer; aCombobox: TComboBox);
var
  i, c: integer;
begin
  for i := low(FComboBoxCols) to high(FComboBoxCols) do
  begin
    if FComboBoxCols[i].Col = Col then
    begin
      FComboBoxCols[i].Combobox := aCombobox;
      exit;
    end;
  end;
  // addCombobox(col, acombobox.Items);
end;

function TStringGridMng.getCombobox(Col: integer): TComboBox;
var
  i: integer;
begin
  result := nil;
  for i := low(FComboBoxCols) to high(FComboBoxCols) do
  begin
    if FComboBoxCols[i].Col = Col then
    begin
      result := FComboBoxCols[i].Combobox;
      break;
    end;
  end;
end;

procedure TStringGridMng.setCaptions(captions: array of string);
var

  i: integer;
begin
  try
    for i := low(captions) to high(captions) do
    begin
      if i >= FStringGrid.ColCount then
        break;
      FStringGrid.Cells[i, 0] := captions[i];
    end;
  finally
  end;
end;

procedure TStringGridMng.setWidths(wds: array of integer);
var
  i: integer;
begin
  try
    for i := low(wds) to high(wds) do
    begin
      if i >= FStringGrid.ColCount then
        break;
      FStringGrid.ColWidths[i] := wds[i];
    end;
  finally

  end;
end;

procedure TStringGridMng.addReadOnlyCols(cols: array of integer);
var
  i: integer;
begin
  try
    for i := low(cols) to high(cols) do
    begin
      if self.FReadOnlyCols.IndexOf(cols[i]) < 0 then
        FReadOnlyCols.Add(cols[i]);
    end;
  finally

  end;
end;

procedure TStringGridMng.addOperationCol(ACol: integer; Caption: string;
  aOperationType: TOperationType; aOnEvent: TNotifyEvent);
var
  i: integer;
begin
  i := length(FOperationCols);
  setlength(FOperationCols, i + 1);
  FOperationCols[i].Caption := Caption;
  FOperationCols[i].Col := ACol;
  FOperationCols[i].OperationType := aOperationType;
  FOperationCols[i].DoEvent := aOnEvent;

end;

procedure SetComboboxToStringGridCell(cb: TComboBox; SG: tStringgrid;
  ACol, ARow: integer);
var
  r: TRect;
  org: TPoint;
begin
  with SG do
  begin
    r := CellRect(ACol, ARow);
    perform(WM_CANCELMODE, 0, 0);
    org := SG.Parent.ScreenToClient(ClientToScreen(r.topleft));
    with cb do
    begin
      Text := SG.Cells[ACol, ARow];
      left := org.X;
      top := org.Y;
      width := r.right - r.left;
      height := r.bottom - r.top;
      itemindex := items.IndexOf(Cells[ACol, ARow]);
      Show;
      BringTofront;
      SetFocus;
      DroppedDown := true;
    end;
  end;
end;

end.
