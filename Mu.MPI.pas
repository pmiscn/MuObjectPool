unit Mu.MPI;

interface

uses
  Windows, Messages,
  AdvOfficeTabSet, System.SysUtils, dialogs, AdvOfficePager,
  System.Variants, Classes, Graphics, Controls, ExtCtrls, Forms;

Type
  TMuChildFormclass = class of TMuChildForm;

  TMuChildForm = class(Tform)
  public

  published
    property Action;
    property ActiveControl;
    property Align;
    property AlphaBlend default False;
    property AlphaBlendValue default 255;
    property Anchors;
    property AutoScroll;
    property AutoSize;
    property BiDiMode;
    property BorderIcons;
    property BorderStyle;
    property BorderWidth;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property TransparentColor default False;
    property TransparentColorValue default 0;
    property Constraints;
    property Ctl3D;
    property UseDockManager;
    property DefaultMonitor;
    property DockSite;
    property DoubleBuffered default False;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentFont default False;
    property Font;
    property FormStyle;
    property GlassFrame;
    property Height;
    property HelpFile;
    property HorzScrollBar;
    property Icon;
    property KeyPreview;
    property Padding;
    property Menu;
{$IF NOT DEFINED(CLR)}
    property OldCreateOrder;
{$ENDIF}
    property ObjectMenuItem;
    property ParentBiDiMode;
    property PixelsPerInch;
    property PopupMenu;
    property PopupMode;
    property PopupParent;
    property Position;
    property PrintScale;
    property Scaled;
    property ScreenSnap default False;
    property ShowHint;
    property SnapBuffer default 10;
    property Touch;
    property TipMode;
    property VertScrollBar;
    property Visible;
    property Width;
    property WindowState;
    property WindowMenu;
    property StyleElements;
    property OnActivate;
    property OnAlignInsertBefore;
    property OnAlignPosition;
    property OnCanResize;
    property OnClick;
    property OnClose;
    property OnCloseQuery;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnCreate;
    property OnDblClick;
    property OnDestroy;
    property OnDeactivate;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnGesture;
    property OnGetSiteInfo;
    property OnHide;
    property OnHelp;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPaint;
    property OnResize;
    property OnShortCut;
    property OnShow;
    property OnStartDock;
    property OnUnDock;
  end;

type
  PSubForm = ^tSubForm;

  tSubForm = record
    aForm: TMuChildForm;
    aFormClass: string[255];
    aHandle: integer;
    amarkValue: integer;
    PageIndex: integer;
  end;

var

  hisforms: array of tSubForm; // 历史，还没有加入，似乎没啥用

Type
  TSimMPI = class(TObject)
  private
    // FParentPanel: TWinControl;
    FParentTab: TAdvOfficePager;
    SubForms: TList; // <tSubForm> ; // array of tSubForm;

    // procedure TabClose(Sender: TObject; TabIndex: integer; var Allow: boolean);
    procedure onClosePage(Sender: TObject; PageIndex: integer;
      var Allow: boolean);

    procedure PagerChanging(Sender: TObject; FromPage, ToPage: integer;
      var AllowChange: boolean);
    // procedure TabChanging(Sender: TObject; FromTab, ToTab: integer;
    // var AllowChange: boolean);
  protected

  public
    constructor Create(aParentTab: TAdvOfficePager);
    destructor Destroy; override;
    function CreateCusForm(TCusForm: TMuChildFormclass; isnew: bool = False;
      showOnTab: bool = true; markValue: integer = 0): TMuChildForm;
    function getSubFormByHandle(aHandle: integer; var idx: integer): Tform;
    procedure getinfos();
    function addForm(Form: TMuChildForm; showOnTab: bool = true;
      amarkValue: integer = 0): TMuChildForm;
    function showform(Form: TMuChildForm): TMuChildForm;
    property ParentTab: TAdvOfficePager read FParentTab;
  end;

implementation

{ TSimMPI }
procedure TSimMPI.getinfos;
var
  i: integer;
  s: string;
begin
  s := '';
  for i := 0 to self.SubForms.Count - 1 do
    s := s + inttostr(PSubForm(SubForms[i]).aHandle) + ' ' +
      inttostr(PSubForm(SubForms[i]).aForm.Handle) + #13#10;
  s := s + '------' + #13#10;
  for i := 0 to FParentTab.AdvPageCount - 1 do
  begin
    s := s + inttostr(FParentTab.AdvPages[i].Tag) + #13#10;
  end;
  showmessage(s);
end;

function TSimMPI.getSubFormByHandle(aHandle: integer; var idx: integer): Tform;
var
  i: integer;
begin
  result := nil;
  idx := -1;
  for i := 0 to SubForms.Count - 1 do
  begin
    if PSubForm(SubForms[i]).aHandle = aHandle then
    begin
      result := (PSubForm(SubForms[i]).aForm);
      idx := i;
      break;
    end;
  end;
end;

function TSimMPI.showform(Form: TMuChildForm): TMuChildForm;
begin

  result := Form;
  if Form.BorderStyle <> bsSizeable then
  begin
    Form.left := (Form.Parent.Width - Form.Width) div 2;
    Form.top := (Form.Parent.Height - Form.Height) div 2;
    Form.BorderStyle := bsSizeable;

  end
  else
  begin
    Form.Align := alClient; //
  end;
  // SetWindowLong(Form.Handle, GWL_STYLE, GetWindowLong(Form.Handle, GWL_STYLE) and
  // (not WS_CAPTION));
  Form.BorderStyle := bsNone;

  // Form.Width := Form.Parent.Width;
  // Form.Height := Form.Parent.Height;
  Form.show;
  Form.Visible := true;
  application.MainForm.Caption := Form.Caption + ' -【' +
    application.Title + '】';

end;

function TSimMPI.CreateCusForm(TCusForm: TMuChildFormclass; isnew: bool = False;
  showOnTab: bool = true; markValue: integer = 0): TMuChildForm;
var
  i: integer;
  nowidx: integer;
  tab: TOfficeTabCollectionItem;
  sf: PSubForm;
  Pos: TPoint;
  pp: TAdvOfficePage;
begin
  result := nil;
  nowidx := -1;
  if not isnew then
  begin
    for i := 0 to (SubForms.Count - 1) do
    begin
      if markValue = 0 then
      begin
        if PSubForm(SubForms[i]).aFormClass = TCusForm.ClassName then
        begin
          result := PSubForm(SubForms[i]).aForm;
          nowidx := i;
          break;
        end;
      end
      else
      begin
        if PSubForm(SubForms[i]).amarkValue = markValue then
        begin
          result := PSubForm(SubForms[i]).aForm;
          nowidx := i;
          break;
        end;
      end;
    end;
  end;

  if nowidx >= 0 then
  begin
    ParentTab.ActivePageIndex := nowidx;
    exit;
  end;

  result := TCusForm.Create(application);
  result.FormStyle := fsNormal;
  result.Visible := False;
  result.Hide;
  addForm(result, showOnTab, markValue);
  result.show;
end;

function TSimMPI.addForm(Form: TMuChildForm; showOnTab: bool = true;
  amarkValue: integer = 0): TMuChildForm;
var
  nowidx, i: integer;
  sf: PSubForm;
  pp: TAdvOfficePage;
  Pos: TPoint;
begin
  result := Form;
  nowidx := -1;
  for i := 0 to (SubForms.Count - 1) do
  begin
    if PSubForm(SubForms[i]).aHandle = Form.Handle then
    begin
      nowidx := i;
      result := PSubForm(SubForms[i]).aForm;
      ParentTab.ActivePageIndex := nowidx;
      exit;
    end;
  end;

  pp := TAdvOfficePage.Create(self.FParentTab.Owner);
  nowidx := FParentTab.AddAdvPage(pp);

  result.Hide;
  with result do
  begin
    Width := 0;
    Height := 0;
    Pos.X := pp.left;
    Pos.Y := pp.top;
    Pos := pp.ClientToScreen(Pos);
    left := Pos.X;
    top := Pos.Y;
    Visible := False;
    Parent := pp;
  end;
  pp.Caption := result.Caption;
  pp.Tag := result.Handle;

  new(sf);
  sf.aForm := result;
  sf.aFormClass := Form.ClassName;
  sf.aHandle := result.Handle;
  sf.amarkValue := amarkValue;
  self.SubForms.Add(sf);

  pp.TabVisible := showOnTab;
  pp.show;
  pp.Visible := true;
  ParentTab.ActivePageIndex := nowidx;

  if result <> nil then
  begin
    showform(result);
  end;

end;

constructor TSimMPI.Create(aParentTab: TAdvOfficePager);
begin
  SubForms := TList.Create;
  FParentTab := aParentTab;
  FParentTab.OnChanging := self.PagerChanging;
  FParentTab.onClosePage := self.onClosePage;
end;

destructor TSimMPI.Destroy;
var
  i: integer;
begin
  for i := 0 to SubForms.Count - 1 do
  begin
    with PSubForm(SubForms[i]).aForm do
    begin
      Close;
      Free;
    end;
    dispose(PSubForm(SubForms[i]));
  end;
  SubForms.Free;
  inherited;
end;

procedure TSimMPI.PagerChanging(Sender: TObject; FromPage, ToPage: integer;
  var AllowChange: boolean);
begin
  application.MainForm.Caption := self.FParentTab.AdvPages[ToPage].Caption +
    ' - [' + application.Title + '] ';
end;

procedure TSimMPI.onClosePage(Sender: TObject; PageIndex: integer;
  var Allow: boolean);
var
  fm: Tform;
  idx: integer;
begin

  if PageIndex <= 0 then
  begin
    // application.MainForm.Close;
    // exit;
  end;
  fm := getSubFormByHandle(TAdvOfficePager(Sender).AdvPages[PageIndex]
    .Tag, idx);
  if fm <> nil then
  begin
    fm.Close;
    fm.Free;
    SubForms.Delete(idx);
    Allow := true;
  end;
  if self.FParentTab.AdvPageCount = 2 then
    FParentTab.ActivePageIndex := 0;
end;

end.
