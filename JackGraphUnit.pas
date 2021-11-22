unit JackGraphUnit;


//这些都是图形和计算的函数。 命名的开头是Jgu
// 请不要问我从哪里来，到处抄来的。谢谢

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Graphics, Vcl.Controls,
  System.Math, System.SysUtils;

type
  TJGuPoints = array of TPoint;

  // 图形
procedure JguCopyParentImage(Control: TControl; DC: HDC; X, Y: Integer);

 // CANVAS中的文字
function JguWrapText(Canvas: TCanvas; const Text: string; MaxWidth: Integer): string;

function JguMinimizeText(Canvas: TCanvas; const Text: string; const Rect: TRect): string;


 // 转换， TXFORM 看WIN的GDI的结构
function JguTransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;
 // x平方
function JguSqr(const X: Double): Double;
 // Value 是否在两个参数之间
function JguIsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;

// 两个坐标是否相等
function JguEqualPoint(const Pt1, Pt2: TPoint): Boolean;

 // 转换 ,跟WIN计算的一样
//  X := Round(X * eM11 + Y * eM21 + eDx);
 // Y := Round(X * eM12 + Y * eM22 + eDy);

procedure JguTransformPoints(var Points: array of TPoint; const XForm: TXForm);
 //旋转
procedure JquRotatePoints(var Points: array of TPoint; const Angle: Double; const OrgPt: TPoint);
 // 偏移
procedure JquOffsetPoints(var Points: array of TPoint; dX, dY: Integer);

procedure JguScalePoints(var Points: array of TPoint; const Factor: Double; const RefPt: TPoint);

procedure JguShifTPoints(var Points: array of TPoint; dX, dY: Integer; const RefPt: TPoint);

function JguCenterOfPoints(const Points: array of TPoint): TPoint;

function JguBoundsRectOfPoints(const Points: array of TPoint): TRect;

function JguNearestPoint(const Points: array of TPoint; const RefPt: TPoint; out NearestPt: TPoint): Integer;

function JquMakeSquare(const Center: TPoint; Radius: Integer): TRect;

function JquMakeRect(const Corner1, Corner2: TPoint): TRect;
 // 矩形的中心
function JguCenterOfRect(const Rect: TRect): TPoint;

procedure JguUnionRect(var DstRect: TRect; const SrcRect: TRect);

procedure JquIntersectRect(var DstRect: TRect; const SrcRect: TRect);

 // 去圆周
function JguNormalizeAngle(const Angle: Double): Double;
 // 两个点直接的直线距离
function JguLineLength(const LinePt1, LinePt2: TPoint): Double;

function JguLineSlopeAngle(const LinePt1, LinePt2: TPoint): Double;

function JquDistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): Double;

function JguNextPointOfLine(const LineAngle: Double; const ThisPt: TPoint; const DistanceFromThisPt: Double): TPoint;

function JguNearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;

function JguIntersectLines(const Line1Pt: TPoint; const Line1Angle: Double; const Line2Pt: TPoint; const Line2Angle: Double; out Intersect: TPoint): Boolean;

function JguIntersectLineRect(const LinePt: TPoint; const LineAngle: Double; const Rect: TRect): TJGuPoints;

function JguIntersectLineEllipse(const LinePt: TPoint; const LineAngle: Double; const Bounds: TRect): TJGuPoints;

function JquntersectLineRoundRect(const LinePt: TPoint; const LineAngle: Double; const Bounds: TRect; CW, CH: Integer): TJGuPoints;

function JguIntersectLinePolygon(const LinePt: TPoint; const LineAngle: Double; const Vertices: array of TPoint): TJGuPoints;

function JguIntersectLinePolyline(const LinePt: TPoint; const LineAngle: Double; const Vertices: array of TPoint): TJGuPoints;

function JguOverlappedRect(const Rect1, Rect2: TRect): Boolean;

implementation

type
  TJguParentControl = class(TWinControl);

procedure JguCopyParentImage(Control: TControl; DC: HDC; X, Y: Integer);
var
  I, SaveIndex: Integer;
  SelfR, CtlR: TRect;
  NextControl: TControl;
begin
  if (Control = nil) or (Control.Parent = nil) then
    Exit;
  with Control.Parent do
    ControlState := ControlState + [csPaintCopy];
  try
    SelfR := Control.BoundsRect;
    Inc(X, SelfR.Left);
    Inc(Y, SelfR.Top);
    SaveIndex := SaveDC(DC);
    try
      SetViewportOrgEx(DC, -X, -Y, nil);
      with TJguParentControl(Control.Parent) do
      begin
        with ClientRect do
          IntersectClipRect(DC, Left, Top, Right, Bottom);
        {$IFDEF COMPILER9_UP}
        Perform(WM_PRINT, DC, PRF_CHECKVISIBLE or WM_ERASEBKGND or PRF_CHILDREN);
        {$ELSE}
        Perform(WM_ERASEBKGND, DC, 0);
        PaintWindow(DC);
        {$ENDIF}
      end;
    finally
      RestoreDC(DC, SaveIndex);
    end;
    for I := 0 to Control.Parent.ControlCount - 1 do
    begin
      NextControl := Control.Parent.Controls[I];
      if NextControl = Control then
        Break
      else if (NextControl <> nil) and (NextControl is TGraphicControl) then
      begin
        with TGraphicControl(NextControl) do
        begin
          CtlR := BoundsRect;
          if Visible and JguOverlappedRect(SelfR, CtlR) then
          begin
            ControlState := ControlState + [csPaintCopy];
            SaveIndex := SaveDC(DC);
            try
              SetViewportOrgEx(DC, Left - X, Top - Y, nil);
              IntersectClipRect(DC, 0, 0, Width, Height);
              Perform(WM_ERASEBKGND, DC, 0);
              Perform(WM_PAINT, DC, 0);
            finally
              RestoreDC(DC, SaveIndex);
              ControlState := ControlState - [csPaintCopy];
            end;
          end;
        end;
      end;
    end;
  finally
    with Control.Parent do
      ControlState := ControlState - [csPaintCopy];
  end;
end;

function JguWrapText(Canvas: TCanvas; const Text: string; MaxWidth: Integer): string;
var
  DC: HDC;
  TextExtent: TSize;
  S, P, E: PChar;
  Line: string;
  IsFirstLine: Boolean;
begin
  Result := '';
  DC := Canvas.Handle;
  IsFirstLine := True;
  P := PChar(Text);
  while P^ = ' ' do
    Inc(P);
  while P^ <> #0 do
  begin
    S := P;
    E := nil;
    while (P^ <> #0) and (P^ <> #13) and (P^ <> #10) do
    begin
      GetTextExtentPoint32(DC, S, P - S + 1, TextExtent);
      if (TextExtent.CX > MaxWidth) and (E <> nil) then
      begin
        if (P^ <> ' ') and (P^ <> ^I) then
        begin
          while (E >= S) do
            case E^ of
              '.', ',', ';', '?', '!', '-', ':', ')', ']', '}', '>', '/', '\', ' ':
                break;
            else
              Dec(E);
            end;
          if E < S then
            E := P - 1;
        end;
        Break;
      end;
      E := P;
      Inc(P);
    end;
    if E <> nil then
    begin
      while (E >= S) and (E^ = ' ') do
        Dec(E);
    end;
    if E <> nil then
      SetString(Line, S, E - S + 1)
    else
      SetLength(Line, 0);
    if (P^ = #13) or (P^ = #10) then
    begin
      Inc(P);
      if (P^ <> (P - 1)^) and ((P^ = #13) or (P^ = #10)) then
        Inc(P);
      if P^ = #0 then
        Line := Line + #13#10;
    end
    else if P^ <> ' ' then
      P := E + 1;
    while P^ = ' ' do
      Inc(P);
    if IsFirstLine then
    begin
      Result := Line;
      IsFirstLine := False;
    end
    else
      Result := Result + #13#10 + Line;
  end;
end;

function JguMinimizeText(Canvas: TCanvas; const Text: string; const Rect: TRect): string;
const
  EllipsisSingle: string = '?';
  EllipsisTriple: string = '...';
var
  DC: HDC;
  S, E: PChar;
  TextExtent: TSize;
  TextHeight: Integer;
  LastLine: string;
  Ellipsis: PString;
  MaxWidth, MaxHeight: Integer;
  GlyphIndex: WORD;
begin
  MaxWidth := Rect.Right - Rect.Left;
  MaxHeight := Rect.Bottom - Rect.Top;
  Result := WrapText(Canvas, Text, MaxWidth);
  DC := Canvas.Handle;
  TextHeight := 0;
  S := PChar(Result);
  while S^ <> #0 do
  begin
    E := S;
    while (E^ <> #0) and (E^ <> #13) and (E^ <> #10) do
      Inc(E);
    if E > S then
      GetTextExtentPoint32(DC, S, E - S, TextExtent)
    else
      GetTextExtentPoint32(DC, ' ', 1, TextExtent);
    Inc(TextHeight, TextExtent.CY);
    if TextHeight <= MaxHeight then
    begin
      S := E;
      if S^ <> #0 then
      begin
        Inc(S);
        if (S^ <> (S - 1)^) and ((S^ = #13) or (S^ = #10)) then
          Inc(S);
      end;
    end
    else
    begin
      repeat
        Dec(S);
      until (S < PChar(Result)) or ((S^ <> #13) and (S^ <> #10));
      SetLength(Result, S - PChar(Result) + 1);
      if S >= PChar(Result) then
      begin
        E := StrEnd(PChar(Result));
        S := E;
        repeat
          Dec(S)
        until (S < PChar(Result)) or ((S^ = #13) or (S^ = #10));
        SetString(LastLine, S + 1, E - S - 1);
        SetLength(Result, S - PChar(Result) + 1);
        GetGlyphIndices(DC, PChar(EllipsisSingle), 1, @GlyphIndex, GGI_MARK_NONEXISTING_GLYPHS);
        if GlyphIndex = $FFFF then
          Ellipsis := @EllipsisTriple
        else
          Ellipsis := @EllipsisSingle;
        LastLine := LastLine + Ellipsis^;
        GetTextExtentPoint32(DC, PChar(LastLine), Length(LastLine), TextExtent);
        while (TextExtent.CX > MaxWidth) and (Length(LastLine) > Length(Ellipsis^)) do
        begin
          Delete(LastLine, Length(LastLine) - Length(Ellipsis^), 1);
          GetTextExtentPoint32(DC, PChar(LastLine), Length(LastLine), TextExtent);
        end;
        Result := Result + LastLine;
      end;
      Break;
    end;
  end;
end;

function JguSqr(const X: Double): Double;
begin
  Result := X * X;
end;

function JguIsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;
begin
  if Bound1 <= Bound2 then
    Result := (Value >= Bound1) and (Value <= Bound2)
  else
    Result := (Value >= Bound2) and (Value <= Bound1);
end;

function JguEqualPoint(const Pt1, Pt2: TPoint): Boolean;
begin
  Result := (Pt1.X = Pt2.X) and (Pt1.Y = Pt2.Y);
end;

procedure JguTransformPoints(var Points: array of TPoint; const XForm: TXForm);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I], XForm do
    begin
      X := Round(X * eM11 + Y * eM21 + eDx);
      Y := Round(X * eM12 + Y * eM22 + eDy);
    end;
end;

procedure JquRotatePoints(var Points: array of TPoint; const Angle: Double; const OrgPt: TPoint);
var
  Sin, Cos: Extended;
  Prime: TPoint;
  I: Integer;
begin
  SinCos(JguNormalizeAngle(Angle), Sin, Cos);
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Prime.X := X - OrgPt.X;
      Prime.Y := Y - OrgPt.Y;
      X := Round(Prime.X * Cos - Prime.Y * Sin) + OrgPt.X;
      Y := Round(Prime.X * Sin + Prime.Y * Cos) + OrgPt.Y;
    end;
end;

procedure JquOffsetPoints(var Points: array of TPoint; dX, dY: Integer);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(X, dX);
      Inc(Y, dY);
    end;
end;

procedure JguScalePoints(var Points: array of TPoint; const Factor: Double; const RefPt: TPoint);
var
  I: Integer;
  Angle: Double;
  Distance: Double;
begin
  for I := Low(Points) to High(Points) do
  begin
    Angle := JguLineSlopeAngle(Points[I], RefPt);
    Distance := JguLineLength(Points[I], RefPt);
    Points[I] := JguNextPointOfLine(Angle, RefPt, Distance * Factor);
  end;
end;

procedure JguShifTPoints(var Points: array of TPoint; dX, dY: Integer; const RefPt: TPoint);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      if X < RefPt.X then
        Dec(X, dX)
      else if X > RefPt.X then
        Inc(X, dX);
      if Y < RefPt.Y then
        Dec(Y, dY)
      else if Y > RefPt.Y then
        Inc(Y, dY);
    end;
end;

function JguCenterOfPoints(const Points: array of TPoint): TPoint;
var
  I: Integer;
  Sum: TPoint;
begin
  Sum.X := 0;
  Sum.Y := 0;
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(Sum.X, X);
      Inc(Sum.Y, Y);
    end;
  Result.X := Sum.X div Length(Points);
  Result.Y := Sum.Y div Length(Points);
end;

function JguBoundsRectOfPoints(const Points: array of TPoint): TRect;
var
  I: Integer;
begin
  SetRect(Result, MaxInt, MaxInt, -MaxInt, -MaxInt);
  for I := Low(Points) to High(Points) do
    with Points[I], Result do
    begin
      if X < Left then
        Left := X;
      if Y < Top then
        Top := Y;
      if X > Right then
        Right := X;
      if Y > Bottom then
        Bottom := Y;
    end;
end;

function JguNearestPoint(const Points: array of TPoint; const RefPt: TPoint; out NearestPt: TPoint): Integer;
var
  I: Integer;
  Distance: Double;
  NearestDistance: Double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := Low(Points) to High(Points) do
  begin
    Distance := JguLineLength(Points[I], RefPt);
    if Distance < NearestDistance then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
  if Result >= 0 then
    NearestPt := Points[Result];
end;

function JquMakeSquare(const Center: TPoint; Radius: Integer): TRect;
begin
  Result.TopLeft := Center;
  Result.BottomRight := Center;
  InflateRect(Result, Radius, Radius);
end;

function JquMakeRect(const Corner1, Corner2: TPoint): TRect;
begin
  if Corner1.X > Corner2.X then
  begin
    Result.Left := Corner2.X;
    Result.Right := Corner1.X;
  end
  else
  begin
    Result.Left := Corner1.X;
    Result.Right := Corner2.X;
  end;
  if Corner1.Y > Corner2.Y then
  begin
    Result.Top := Corner2.Y;
    Result.Bottom := Corner1.Y;
  end
  else
  begin
    Result.Top := Corner1.Y;
    Result.Bottom := Corner2.Y;
  end
end;

function JguCenterOfRect(const Rect: TRect): TPoint;
begin
  Result.X := (Rect.Left + Rect.Right) div 2;
  Result.Y := (Rect.Top + Rect.Bottom) div 2;
end;

procedure JguUnionRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left > SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top > SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right < SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom < SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

procedure JquIntersectRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left < SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top < SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right > SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom > SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

function JguOverlappedRect(const Rect1, Rect2: TRect): Boolean;
begin
  Result := (Rect1.Right >= Rect2.Left) and (Rect2.Right >= Rect1.Left) and (Rect1.Bottom >= Rect2.Top) and (Rect2.Bottom >= Rect1.Top);
end;

function JguTransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;
var
  RgnData: PRgnData;
  RgnDataSize: DWORD;
begin
  Result := 0;
  RgnDataSize := GetRegionData(Rgn, 0, nil);
  if RgnDataSize > 0 then
  begin
    GetMem(RgnData, RgnDataSize);
    try
      GetRegionData(Rgn, RgnDataSize, RgnData);
      Result := ExtCreateRegion(@Xform, RgnDataSize, RgnData^);
    finally
      FreeMem(RgnData);
    end;
  end;
end;

function JguNormalizeAngle(const Angle: Double): Double;
begin
  Result := Angle;
  while Result > Pi do
    Result := Result - 2 * Pi;
  while Result < -Pi do
    Result := Result + 2 * Pi;
end;

function JguLineLength(const LinePt1, LinePt2: TPoint): Double;
begin
  Result := Sqrt(Sqr(LinePt2.X - LinePt1.X) + Sqr(LinePt2.Y - LinePt1.Y));
end;

function JguLineSlopeAngle(const LinePt1, LinePt2: TPoint): Double;
begin
  if LinePt1.X <> LinePt2.X then
    Result := ArcTan2(LinePt2.Y - LinePt1.Y, LinePt2.X - LinePt1.X)
  else if LinePt1.Y > LinePt2.Y then
    Result := -Pi / 2
  else if LinePt1.Y < LinePt2.Y then
    Result := +Pi / 2
  else
    Result := 0;
end;

function JquDistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): Double;
var
  Pt: TPoint;
begin
  Pt := JguNearestPointOnLine(LinePt1, LinePt2, QueryPt);
  Result := JguLineLength(QueryPt, Pt);
end;

function JguNextPointOfLine(const LineAngle: Double; const ThisPt: TPoint; const DistanceFromThisPt: Double): TPoint;
var
  X, Y, M: Double;
  Angle: Double;
begin
  Angle := JguNormalizeAngle(LineAngle);
  if Abs(Angle) <> Pi / 2 then
  begin
    M := Tan(LineAngle);
    if Abs(Angle) < Pi / 2 then
      X := ThisPt.X - DistanceFromThisPt / Sqrt(1 + Sqr(M))
    else
      X := ThisPt.X + DistanceFromThisPt / Sqrt(1 + Sqr(M));
    Y := ThisPt.Y + M * (X - ThisPt.X);
    Result.X := Round(X);
    Result.Y := Round(Y);
  end
  else
  begin
    Result.X := ThisPt.X;
    if Angle > 0 then
      Result.Y := ThisPt.Y - Round(DistanceFromThisPt)
    else
      Result.Y := ThisPt.Y + Round(DistanceFromThisPt);
  end;
end;

function JguNearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;
var
  LoPt, HiPt: TPoint;
  LoDis, HiDis: Double;
begin
  LoPt := LinePt1;
  HiPt := LinePt2;
  Result.X := (LoPt.X + HiPt.X) div 2;
  Result.Y := (LoPt.Y + HiPt.Y) div 2;
  while ((Result.X <> LoPt.X) or (Result.Y <> LoPt.Y)) and ((Result.X <> HiPt.X) or (Result.Y <> HiPt.Y)) do
  begin
    LoDis := Sqrt(Sqr(RefPt.X - (LoPt.X + Result.X) div 2) + Sqr(RefPt.Y - (LoPt.Y + Result.Y) div 2));
    HiDis := Sqrt(Sqr(RefPt.X - (HiPt.X + Result.X) div 2) + Sqr(RefPt.Y - (HiPt.Y + Result.Y) div 2));
    if LoDis < HiDis then
      HiPt := Result
    else
      LoPt := Result;
    Result.X := (LoPt.X + HiPt.X) div 2;
    Result.Y := (LoPt.Y + HiPt.Y) div 2;
  end;
end;

function JguIntersectLines(const Line1Pt: TPoint; const Line1Angle: Double; const Line2Pt: TPoint; const Line2Angle: Double; out Intersect: TPoint): Boolean;
var
  M1, M2: Double;
  C1, C2: Double;
begin
  Result := True;
  if (Abs(Line1Angle) = Pi / 2) and (Abs(Line2Angle) = Pi / 2) then
    // Lines have identical slope, so they are either parallel or identical
    Result := False
  else if Abs(Line1Angle) = Pi / 2 then
  begin
    M2 := Tan(Line2Angle);
    C2 := Line2Pt.Y - M2 * Line2Pt.X;
    Intersect.X := Line1Pt.X;
    Intersect.Y := Round(M2 * Intersect.X + C2);
  end
  else if Abs(Line2Angle) = Pi / 2 then
  begin
    M1 := Tan(Line1Angle);
    C1 := Line1Pt.Y - M1 * Line1Pt.X;
    Intersect.X := Line2Pt.X;
    Intersect.Y := Round(M1 * Intersect.X + C1);
  end
  else
  begin
    M1 := Tan(Line1Angle);
    M2 := Tan(Line2Angle);
    if M1 = M2 then
      // Lines have identical slope, so they are either parallel or identical
      Result := False
    else
    begin
      C1 := Line1Pt.Y - M1 * Line1Pt.X;
      C2 := Line2Pt.Y - M2 * Line2Pt.X;
      Intersect.X := Round((C1 - C2) / (M2 - M1));
      Intersect.Y := Round((M2 * C1 - M1 * C2) / (M2 - M1));
    end;
  end;
end;

function JguIntersectLineRect(const LinePt: TPoint; const LineAngle: Double; const Rect: TRect): TJGuPoints;
var
  Corners: array[0..3] of TPoint;
begin
  Corners[0].X := Rect.Left;
  Corners[0].Y := Rect.Top;
  Corners[1].X := Rect.Right;
  Corners[1].Y := Rect.Top;
  Corners[2].X := Rect.Right;
  Corners[2].Y := Rect.Bottom;
  Corners[3].X := Rect.Left;
  Corners[3].Y := Rect.Bottom;
  Result := JguIntersectLinePolygon(LinePt, LineAngle, Corners);
end;

function JguIntersectLineEllipse(const LinePt: TPoint; const LineAngle: Double; const Bounds: TRect): TJGuPoints;
var
  M, C: Double;
  A2, B2, a, b, d: Double;
  Xc, Yc, X, Y: Double;
begin
  SetLength(Result, 0);
  if IsRectEmpty(Bounds) then
    Exit;
  Xc := (Bounds.Left + Bounds.Right) / 2;
  Yc := (Bounds.Top + Bounds.Bottom) / 2;
  A2 := Sqr((Bounds.Right - Bounds.Left) / 2);
  B2 := Sqr((Bounds.Bottom - Bounds.Top) / 2);
  if Abs(LineAngle) = Pi / 2 then
  begin
    d := 1 - (Sqr(LinePt.X - Xc) / A2);
    if d >= 0 then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc);
      end
      else
      begin
        C := Sqrt(B2) * Sqrt(d);
        SetLength(Result, 2);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc - C);
        Result[1].X := LinePt.X;
        Result[1].Y := Round(Yc + C);
      end;
    end;
  end
  else
  begin
    M := Tan(LineAngle);
    C := LinePt.Y - M * LinePt.X;
    a := (B2 + A2 * Sqr(M));
    b := (A2 * M * (C - Yc)) - B2 * Xc;
    d := Sqr(b) - a * (B2 * Sqr(Xc) + A2 * Sqr(C - Yc) - A2 * B2);
    if (d >= 0) and (a <> 0) then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        X := -b / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
      end
      else
      begin
        SetLength(Result, 2);
        X := (-b - Sqrt(d)) / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
        X := (-b + Sqrt(d)) / a;
        Y := M * X + C;
        Result[1].X := Round(X);
        Result[1].Y := Round(Y);
      end;
    end;
  end;
end;

function JquntersectLineRoundRect(const LinePt: TPoint; const LineAngle: Double; const Bounds: TRect; CW, CH: Integer): TJGuPoints;
var
  I: Integer;
  CornerBounds: TRect;
  CornerIntersects: TJGuPoints;
  W, H, Xc, Yc, dX, dY: Integer;
begin
  Result := JguIntersectLineRect(LinePt, LineAngle, Bounds);
  if Length(Result) > 0 then
  begin
    W := Bounds.Right - Bounds.Left;
    H := Bounds.Bottom - Bounds.Top;
    Xc := (Bounds.Left + Bounds.Right) div 2;
    Yc := (Bounds.Top + Bounds.Bottom) div 2;
    for I := 0 to Length(Result) - 1 do
    begin
      dX := Result[I].X - Xc;
      dY := Result[I].Y - Yc;
      if ((W div 2) - (Abs(dX)) < (CW div 2)) and (((H div 2) - Abs(dY)) < (CH div 2)) then
      begin
        SetRect(CornerBounds, Bounds.Left, Bounds.Top, Bounds.Left + CW, Bounds.Top + CH);
        if dX > 0 then
          OffsetRect(CornerBounds, W - CW, 0);
        if dY > 0 then
          OffsetRect(CornerBounds, 0, H - CH);
        CornerIntersects := JguIntersectLineEllipse(LinePt, LineAngle, CornerBounds);
        try
          if Length(CornerIntersects) = 2 then
            if dX < 0 then
              Result[I] := CornerIntersects[0]
            else
              Result[I] := CornerIntersects[1];
        finally
          SetLength(CornerIntersects, 0);
        end;
      end;
    end;
  end;
end;

function JguIntersectLinePolygon(const LinePt: TPoint; const LineAngle: Double; const Vertices: array of TPoint): TJGuPoints;
var
  I: Integer;
  V1, V2: Integer;
  EdgeAngle: Double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to High(Vertices) do
  begin
    V1 := I;
    V2 := Succ(I) mod Length(Vertices);
    EdgeAngle := JguLineSlopeAngle(Vertices[V1], Vertices[V2]);
    if JguIntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and JguIsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and JguIsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

function JguIntersectLinePolyline(const LinePt: TPoint; const LineAngle: Double; const Vertices: array of TPoint): TJGuPoints;
var
  I: Integer;
  V1, V2: Integer;
  EdgeAngle: Double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to Pred(High(Vertices)) do
  begin
    V1 := I;
    V2 := Succ(I);
    EdgeAngle := JguLineSlopeAngle(Vertices[V1], Vertices[V2]);
    if JguIntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and JguIsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and JguIsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

end.

