unit SIMouseKeyboard;

//
//����SendInputģ�������̵�����
//���ߣ�yeye55��2009��1��13��
//
//��Ȩ 2008���� yeye55 ӵ�У���������Ȩ����
//���ļ��еĴ�������ѳ��������κ���Ȩ����ɼ������ڸ��˺���ҵĿ�ġ�ʹ����һ�к���Ը���
//
//�����ת���˱��ļ��еĴ��룬��ע����������ʹ������ߣ�
//������޸��˱��ļ��еĴ��룬��ע���޸�λ�ú��޸����ߡ�
//
//���ļ�������http://www.programbbs.com/bbs/�Ϸ���
//

interface

uses
    Windows,System.SysUtils,Winapi.Messages,System.classes,Vcl.Forms;

const
    //����붨��
    VK_LBUTTON        = $01;
    VK_RBUTTON        = $02;
    VK_CANCEL         = $03;
    VK_MBUTTON        = $04;    //* NOT contiguous with L & RBUTTON */

    VK_BACK           = $08;
    VK_TAB            = $09;

    VK_CLEAR          = $0C;
    VK_RETURN         = $0D;

    VK_SHIFT          = $10;
    VK_CONTROL        = $11;
    VK_MENU           = $12;
    VK_PAUSE          = $13;
    VK_CAPITAL        = $14;

    VK_KANA           = $15;
    VK_HANGEUL        = $15;  //* old name - should be here for compatibility */
    VK_HANGUL         = $15;
    VK_JUNJA          = $17;
    VK_FINAL          = $18;
    VK_HANJA          = $19;
    VK_KANJI          = $19;

    VK_ESCAPE         = $1B;

    VK_CONVERT        = $1C;
    VK_NONCONVERT     = $1D;
    VK_ACCEPT         = $1E;
    VK_MODECHANGE     = $1F;

    VK_SPACE          = $20;
    VK_PRIOR          = $21;
    VK_NEXT           = $22;
    VK_END            = $23;
    VK_HOME           = $24;
    VK_LEFT           = $25;
    VK_UP             = $26;
    VK_RIGHT          = $27;
    VK_DOWN           = $28;
    VK_SELECT         = $29;
    VK_PRINT          = $2A;
    VK_EXECUTE        = $2B;
    VK_SNAPSHOT       = $2C;
    VK_INSERT         = $2D;
    VK_DELETE         = $2E;
    VK_HELP           = $2F;

    VK_C0             = $C0; //��`���͡�~��
    VK_BD             = $BD; //��-���͡�_��
    VK_BB             = $BB; //��=���͡�+��
    VK_DC             = $DC; //��\���͡�|��
    VK_DB             = $DB; //��[���͡�{��
    VK_DD             = $DD; //��]���͡�}��
    VK_BA             = $BA; //��;���͡�:��
    VK_DE             = $DE; //��'���͡�"��
    VK_BC             = $BC; //��,���͡�<��
    VK_BE             = $BE; //��.���͡�>��
    VK_BF             = $BF; //��/���͡�?��

{* VK_0 thru VK_9 are the same as ASCII '0' thru '9' (0x30 - 0x39) *}
    VK_0              = $30;
    VK_1              = $31;
    VK_2              = $32;
    VK_3              = $33;
    VK_4              = $34;
    VK_5              = $35;
    VK_6              = $36;
    VK_7              = $37;
    VK_8              = $38;
    VK_9              = $39;

{* VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (0x41 - 0x5A) *}
    VK_A              = $41;
    VK_B              = $42;
    VK_C              = $43;
    VK_D              = $44;
    VK_E              = $45;
    VK_F              = $46;
    VK_G              = $47;
    VK_H              = $48;
    VK_I              = $49;
    VK_J              = $4A;
    VK_K              = $4B;
    VK_L              = $4C;
    VK_M              = $4D;
    VK_N              = $4E;
    VK_O              = $4F;
    VK_P              = $50;
    VK_Q              = $51;
    VK_R              = $52;
    VK_S              = $53;
    VK_T              = $54;
    VK_U              = $55;
    VK_V              = $56;
    VK_W              = $57;
    VK_X              = $58;
    VK_Y              = $59;
    VK_Z              = $5A;

    VK_LWIN           = $5B;
    VK_RWIN           = $5C;
    VK_APPS           = $5D;

    VK_NUMPAD0        = $60;
    VK_NUMPAD1        = $61;
    VK_NUMPAD2        = $62;
    VK_NUMPAD3        = $63;
    VK_NUMPAD4        = $64;
    VK_NUMPAD5        = $65;
    VK_NUMPAD6        = $66;
    VK_NUMPAD7        = $67;
    VK_NUMPAD8        = $68;
    VK_NUMPAD9        = $69;
    VK_MULTIPLY       = $6A;
    VK_ADD            = $6B;
    VK_SEPARATOR      = $6C;
    VK_SUBTRACT       = $6D;
    VK_DECIMAL        = $6E;
    VK_DIVIDE         = $6F;
    VK_F1             = $70;
    VK_F2             = $71;
    VK_F3             = $72;
    VK_F4             = $73;
    VK_F5             = $74;
    VK_F6             = $75;
    VK_F7             = $76;
    VK_F8             = $77;
    VK_F9             = $78;
    VK_F10            = $79;
    VK_F11            = $7A;
    VK_F12            = $7B;
    VK_F13            = $7C;
    VK_F14            = $7D;
    VK_F15            = $7E;
    VK_F16            = $7F;
    VK_F17            = $80;
    VK_F18            = $81;
    VK_F19            = $82;
    VK_F20            = $83;
    VK_F21            = $84;
    VK_F22            = $85;
    VK_F23            = $86;
    VK_F24            = $87;

    VK_NUMLOCK        = $90;
    VK_SCROLL         = $91;

{*
 * VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
 * Used only as parameters to GetAsyncKeyState() and GetKeyState().
 * No other API or message will distinguish left and right keys in this way.
 *}
    VK_LSHIFT         = $A0;
    VK_RSHIFT         = $A1;
    VK_LCONTROL       = $A2;
    VK_RCONTROL       = $A3;
    VK_LMENU          = $A4;
    VK_RMENU          = $A5;

    VK_PROCESSKEY     = $E5;

    VK_ATTN           = $F6;
    VK_CRSEL          = $F7;
    VK_EXSEL          = $F8;
    VK_EREOF          = $F9;
    VK_PLAY           = $FA;
    VK_ZOOM           = $FB;
    VK_NONAME         = $FC;
    VK_PA1            = $FD;
    VK_OEM_CLEAR      = $FE;

    //���ܺ���
    //ǰ̨
    procedure SIKeyDown(Key : WORD);
    procedure SIKeyUp(Key : WORD);
    procedure SIKeyPress(Key : WORD; Interval : Cardinal = 0);
    procedure SIKeyInput(const Text : String; Interval : Cardinal = 0);
    procedure SIMouseDown(Key : WORD);
    procedure SIMouseUp(Key : WORD);
    procedure SIMouseClick(Key : WORD; Interval : Cardinal = 0);
    procedure SIMouseWheel(dZ : Integer);
    procedure SIMouseMoveTo(X,Y : Integer; MaxMove : Integer = 20; Interval : Cardinal = 0);
    //��̨
    procedure PMKeyDown(MyHwnd:THandle;Key:Word);
    procedure PMKeyUp(MyHwnd:THandle;Key:Word);
    procedure PMKeyPress(MyHwnd:THandle;Key : WORD; Interval : Cardinal = 0);
    procedure PMMouseLeftClick(MyHwnd:THandle;X,Y:Integer);
    procedure PMMouseRightClick(MyHwnd:THandle;X,Y:Integer);

    procedure SendKey(H: Hwnd; Key: Word);overload;
    procedure SendKey(H: Hwnd; Key: Char);overload;
    procedure SendText(h:THandle; str:string);


implementation

var
    PerWidth : Integer; //ÿ���ؿ�ȵ�λ
    PerHeight : Integer; //ÿ���ظ߶ȵ�λ


procedure SendCtrl(H: HWnd; Down: Boolean);
var
  vKey, ScanCode : Word;
  lParam: longint;
begin
  vKey:= $11;
  ScanCode:= MapVirtualKey(vKey, 0);
  lParam:= longint(ScanCode) shl 16 or 1;
  if not(Down) then lParam:= lParam or $C0000000;
  SendMessage(H, WM_KEYDOWN, vKey, lParam);
end;

procedure SendShift(H: HWnd; Down: Boolean);
var
   vKey, ScanCode: Word;
   lParam: longint;
begin
    vKey:= $10;
    ScanCode:= MapVirtualKey(vKey, 0);
    lParam:= longint(ScanCode) shl 16 or 1;
    if not(Down) then
       lParam:= lParam or $C0000000;
    SendMessage(H,WM_KEYDOWN, vKey, lParam);
end;


procedure SendKey(H: Hwnd; Key: char);overload;
var
  vKey, ScanCode, wParam: Word;
  lParam, ConvKey: longint;
  Shift, Ctrl: boolean;
begin
    ConvKey:= OemKeyScan(ord(Key));
    Shift:= (ConvKey and $00020000) <> 0;
    Ctrl:= (ConvKey and $00040000) <> 0;
    ScanCode:= ConvKey and $000000FF or $FF00;
    vKey:= ord(Key);
    wParam:= vKey;
    lParam:= longint(ScanCode) shl 16 or 1;
    if Shift then SendShift(H, true);
    if Ctrl then SendCtrl(H, true);
    SendMessage(H, WM_KEYDOWN, vKey, lParam);
    SendMessage(H, WM_CHAR, vKey, lParam);

    Sleep(50);
    lParam:= lParam or $C0000000;
    SendMessage(H, WM_KEYUP, vKey, lParam);

    if Shift then SendShift(H, false);
    if Ctrl then SendCtrl(H, false);
end;

//--ģ���������
procedure SendText(h:THandle; str:string);
var
  n:integer;
begin
  n:=1;
  while n<>length(str)+1 do
  begin
    if ord(str[n])<130 then
      begin
        SendMessage(h, $0286,ord(str[n]),0);
        n:=n+1;
      end
    else
      begin
        SendMessage(h, $0286,(ord(Str[n]) shl 8)+ord(Str[n+1]),0);
        n:=n+2;
      end;
  end;
end;

procedure SendKey(H: Hwnd; Key: word);overload;
var
  vKey, ScanCode : Word;
  lParam, ConvKey: longint;
  Ctrl,Shift: boolean;
begin
  ConvKey:= OemKeyScan(Key);
  Shift:= (ConvKey and $00020000) <> 0;
  Ctrl:= (ConvKey and $00040000) <> 0;
  ScanCode:= ConvKey and $000000FF or $FF00;
  vKey:= Key;
  lParam:= longint(ScanCode) shl 16 or 1;
  if Ctrl then SendCtrl(H, true);
  if Shift then SendShift(H, true);
  SendMessage(H, WM_KEYDOWN, vKey, lParam);
  SendMessage(H, WM_CHAR, vKey, lParam);
;
  Sleep(50);
  lParam:= lParam or $C0000000;
  SendMessage(H, WM_KEYUP, vKey, lParam);
  if Ctrl then SendCtrl(H, false);
  if Shift then SendShift(H, False);
end;

function VKB_param(VirtualKey:Integer;flag:Integer):Integer; //������
var
  s,Firstbyte,Secondbyte:String;
  S_code:Integer;
Begin
  if flag=1 then  //���¼�
    begin
      Firstbyte :='00'
    end
  else                  //�����
  begin
    Firstbyte :='C0'
  end;
  S_code:= MapVirtualKey(VirtualKey, 0);
  Secondbyte:='00'+inttostr(s_code);
  Secondbyte:=copy(Secondbyte,Length(Secondbyte)-1,2);
  s:='$'+Firstbyte + Secondbyte + '0001';
  Result:=strtoint(s);
End;

//��̨
procedure PMKeyDown(MyHwnd:THandle;Key:Word);
var
  vlparam:lparam;
  ScanCode : Word;

begin
  vlparam := VKB_param(key, 1);      {���¼�}
  SendMessage (MyHwnd, WM_KEYDOWN, key, 0);
end;

procedure PMKeyUp(MyHwnd:THandle;Key:Word);
var
  vlparam:lparam;
begin
  vlparam := VKB_param(key, 0);      {�ɿ���}
  SendMessage (MyHwnd, WM_KEYUP, key, 0);
end;

procedure PMKeyPress(MyHwnd:THandle; Key : WORD; Interval : Cardinal = 0);
begin
  PMKeyDown(MyHwnd,Key);
  if Interval<>0 then Sleep(Interval);
  PMKeyUp(MyHwnd,Key);
end;

procedure PMMouseLeftClick(MyHwnd:THandle;X,Y:Integer);
var
  lparam:DWORD;
  p1:TPoint;
begin
  p1.X := X;
  p1.Y := Y;
  lparam := p1.X +p1.Y shl 16;
  Randomize;
  SendMessage(MyHwnd,WM_LBUTTONDOWN,0,lparam);
  Sleep(Random(100));
  SendMessage(MyHwnd,WM_LBUTTONUP,0,lparam);
end;

procedure PMMouseRightClick(MyHwnd:THandle;X,Y:Integer);
var
  lparam:DWORD;
  p1:TPoint;
begin
  p1.X := X;
  p1.Y := Y;
  lparam := p1.X +p1.Y shl 16;
  Randomize;
  SendMessage(MyHwnd,WM_RBUTTONDOWN,0,lparam);
  Sleep(Random(100));
  SendMessage(MyHwnd,WM_RBUTTONUP,0,lparam);
end;

{���ܺ���}

//����ָ���ļ���
procedure SIKeyDown(Key : WORD);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_KEYBOARD;
    with Input.ki do
    begin
        wVk:=Key;
        wScan:=0;
        dwFlags:=0;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//�ſ�ָ���ļ���
procedure SIKeyUp(Key : WORD);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_KEYBOARD;
    with Input.ki do
    begin
        wVk:=Key;
        wScan:=0;
        dwFlags:=KEYEVENTF_KEYUP;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//���²��ſ�ָ���ļ���IntervalΪ���ºͷſ�֮���ʱ������
procedure SIKeyPress(Key : WORD; Interval : Cardinal);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_KEYBOARD;
    with Input.ki do
    begin
        wVk:=Key;
        wScan:=0;
        dwFlags:=0;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
    if Interval<>0 then Sleep(Interval);
    Input.Itype:=INPUT_KEYBOARD;
    with Input.ki do
    begin
        wVk:=Key;
        wScan:=0;
        dwFlags:=KEYEVENTF_KEYUP;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//ģ���������ָ�����ı����ı���ֻ���ǵ��ֽ��ַ���#32~#126��
//�Լ�Tab��#9�����ͻس�����#13���������ַ��ᱻ���ԣ�
//IntervalΪ����ÿ���ַ�֮���ʱ������
procedure SIKeyInput(const Text : String; Interval : Cardinal);
type
    TCharTable = record
        Key : WORD;
        Char : array [0..1] of AnsiChar;
    end;

const
    CharCount = 50;
    CharTable : array [0..CharCount-1] of TCharTable = (
    (Key : VK_A;  Char : 'aA'), (Key : VK_B;  Char : 'bB'),
    (Key : VK_C;  Char : 'cC'), (Key : VK_D;  Char : 'dD'),
    (Key : VK_E;  Char : 'eE'), (Key : VK_F;  Char : 'fF'),
    (Key : VK_G;  Char : 'gG'), (Key : VK_H;  Char : 'hH'),
    (Key : VK_I;  Char : 'iI'), (Key : VK_J;  Char : 'jJ'),
    (Key : VK_K;  Char : 'kK'), (Key : VK_L;  Char : 'lL'),
    (Key : VK_M;  Char : 'mM'), (Key : VK_N;  Char : 'nN'),
    (Key : VK_O;  Char : 'oO'), (Key : VK_P;  Char : 'pP'),
    (Key : VK_Q;  Char : 'qQ'), (Key : VK_R;  Char : 'rR'),
    (Key : VK_S;  Char : 'sS'), (Key : VK_T;  Char : 'tT'),
    (Key : VK_U;  Char : 'uU'), (Key : VK_V;  Char : 'vV'),
    (Key : VK_W;  Char : 'wW'), (Key : VK_X;  Char : 'xX'),
    (Key : VK_Y;  Char : 'yY'), (Key : VK_Z;  Char : 'zZ'),
    (Key : VK_0;  Char : '0)'), (Key : VK_1;  Char : '1!'),
    (Key : VK_2;  Char : '2@'), (Key : VK_3;  Char : '3#'),
    (Key : VK_4;  Char : '4$'), (Key : VK_5;  Char : '5%'),
    (Key : VK_6;  Char : '6^'), (Key : VK_7;  Char : '7&'),
    (Key : VK_8;  Char : '8*'), (Key : VK_9;  Char : '9('),
    (Key : VK_C0; Char : '`~'), (Key : VK_BD; Char : '-_'),
    (Key : VK_BB; Char : '=+'), (Key : VK_DC; Char : '\|'),
    (Key : VK_DB; Char : '[{'), (Key : VK_DD; Char : ']}'),
    (Key : VK_BA; Char : ';:'), (Key : VK_DE; Char : #39+'"'),
    (Key : VK_BC; Char : ',<'), (Key : VK_BE; Char : '.>'),
    (Key : VK_BF; Char : '/?'), (Key : VK_SPACE; Char : ' '+#0),
    (Key : VK_TAB; Char : #9#0), (Key : VK_RETURN; Char : #13#0));

var
    Inputs : array [0..3] of TInput;
    CapsState,NeedShift : Boolean;
    i,id,Count : Integer;
begin
    CapsState:=((GetKeyState(VK_CAPITAL) and 1)<>0);
    for i:=1 to Length(Text) do
    begin
        for id:=0 to CharCount-1 do
            if (CharTable[id].Char[0]=AnsiChar(Text[i])) or
               (CharTable[id].Char[1]=AnsiChar(Text[i])) then
                break;
        if id>=CharCount then continue;
        NeedShift:=(CharTable[id].Char[1]=AnsiChar(Text[i]));
        if (CharTable[id].Char[0]>='a') and
           (CharTable[id].Char[0]<='z') and CapsState then
            NeedShift:=not NeedShift;
        Count:=0;
        //�����ϵ���
        if NeedShift then
        begin
            Inputs[Count].Itype:=INPUT_KEYBOARD;
            with Inputs[Count].ki do
            begin
                wVk:=VK_SHIFT;
                wScan:=0;
                dwFlags:=0;
                time:=GetTickCount;
                dwExtraInfo:=GetMessageExtraInfo;
            end;
            Count:=Count+1;
        end;
        //����ָ����
        Inputs[Count].Itype:=INPUT_KEYBOARD;
        with Inputs[Count].ki do
        begin
            wVk:=CharTable[id].Key;
            wScan:=0;
            dwFlags:=0;
            time:=GetTickCount;
            dwExtraInfo:=GetMessageExtraInfo;
        end;
        Count:=Count+1;
        //�ſ�ָ����
        Inputs[Count].Itype:=INPUT_KEYBOARD;
        with Inputs[Count].ki do
        begin
            wVk:=CharTable[id].Key;
            wScan:=0;
            dwFlags:=KEYEVENTF_KEYUP;
            time:=GetTickCount;
            dwExtraInfo:=GetMessageExtraInfo;
        end;
        Count:=Count+1;
        //�ſ��ϵ���
        if NeedShift then
        begin
            Inputs[Count].Itype:=INPUT_KEYBOARD;
            with Inputs[Count].ki do
            begin
                wVk:=VK_SHIFT;
                wScan:=0;
                dwFlags:=KEYEVENTF_KEYUP;
                time:=GetTickCount;
                dwExtraInfo:=GetMessageExtraInfo;
            end;
            Count:=Count+1;
        end;
        SendInput(Count,Inputs[0],SizeOf(TInput));
        if Interval<>0 then Sleep(Interval);
    end;
end;

//��������ָ������
procedure SIMouseDown(Key : WORD);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_MOUSE;
    with Input.mi do
    begin
        dx:=0;
        dy:=0;
        mouseData:=0;
        case Key of
            VK_LBUTTON : dwFlags:=MOUSEEVENTF_LEFTDOWN;
            VK_RBUTTON : dwFlags:=MOUSEEVENTF_RIGHTDOWN;
            VK_MBUTTON : dwFlags:=MOUSEEVENTF_MIDDLEDOWN;
            else exit;
        end;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//�ſ�����ָ������
procedure SIMouseUp(Key : WORD);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_MOUSE;
    with Input.mi do
    begin
        dx:=0;
        dy:=0;
        mouseData:=0;
        case Key of
            VK_LBUTTON : dwFlags:=MOUSEEVENTF_LEFTUP;
            VK_RBUTTON : dwFlags:=MOUSEEVENTF_RIGHTUP;
            VK_MBUTTON : dwFlags:=MOUSEEVENTF_MIDDLEUP;
            else exit;
        end;
        time:=GetTickCount;
        dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//��������ָ������IntervalΪ���ºͷſ�֮���ʱ������
procedure SIMouseClick(Key : WORD; Interval : Cardinal);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_MOUSE;
    with Input.mi do
    begin
      dx:=0;
      dy:=0;
      mouseData:=0;
      case Key of
        VK_LBUTTON : dwFlags:=MOUSEEVENTF_LEFTDOWN;
        VK_RBUTTON : dwFlags:=MOUSEEVENTF_RIGHTDOWN;
        VK_MBUTTON : dwFlags:=MOUSEEVENTF_MIDDLEDOWN;
      else
       exit;
      end;
      time:=GetTickCount;
      dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
    if Interval<>0 then Sleep(Interval);
    Input.Itype:=INPUT_MOUSE;
    with Input.mi do
    begin
      dx:=0;
      dy:=0;
      mouseData:=0;
      case Key of
        VK_LBUTTON : dwFlags:=MOUSEEVENTF_LEFTUP;
        VK_RBUTTON : dwFlags:=MOUSEEVENTF_RIGHTUP;
        VK_MBUTTON : dwFlags:=MOUSEEVENTF_MIDDLEUP;
      else
        exit;
      end;
      time:=GetTickCount;
      dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//�������Ĺ��֡�
procedure SIMouseWheel(dZ : Integer);
var
    Input : TInput;
begin
    Input.Itype:=INPUT_MOUSE;
    with Input.mi do
    begin
      dx:=0;
      dy:=0;
      mouseData:=DWORD(dZ);
      dwFlags:=MOUSEEVENTF_WHEEL;
      time:=GetTickCount;
      dwExtraInfo:=GetMessageExtraInfo;
    end;
    SendInput(1,Input,SizeOf(TInput));
end;

//�����ָ���ƶ���ָ��λ�ã������Ƿ�ɹ���
//X��YΪ����ֵ��X��Y��ֵ�ķ�Χ���ܳ�����Ļ��
//MaxMoveΪ�ƶ�ʱ��dX��dY�����ֵ��
//IntervalΪ�����ƶ�֮���ʱ������
procedure SIMouseMoveTo(X,Y : Integer; MaxMove : Integer; Interval : Cardinal);
var
    Input : TInput;
    p : TPoint;
    n : Integer;
begin
    if MaxMove<=0 then MaxMove:=$7FFFFFFF;
    GetCursorPos(p);
    while (p.X<>X) or (p.Y<>Y) do
    begin
        n:=X-p.X;
        if Abs(n)>MaxMove then
        begin
          if n>0 then n:=MaxMove
          else        n:=-MaxMove;
        end;
        p.X:=p.X+n;
        //
        n:=Y-p.Y;
        if Abs(n)>MaxMove then
        begin
          if n>0 then n:=MaxMove
          else        n:=-MaxMove;
        end;
        p.Y:=p.Y+n;
        //
        Input.Itype:=INPUT_MOUSE;
        with Input.mi do
        begin
          dx:=p.X*PerWidth;
          dy:=p.Y*PerHeight;
          mouseData:=0;
          dwFlags:=MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE;
          time:=GetTickCount;
          dwExtraInfo:=GetMessageExtraInfo;
        end;
        SendInput(1,Input,SizeOf(TInput));
        if Interval<>0 then Sleep(Interval);
    end;
end;

initialization
begin
    PerWidth:=($FFFF div (GetSystemMetrics(SM_CXSCREEN)-1)); //ÿ���ؿ�ȵ�λ
    PerHeight:=($FFFF div (GetSystemMetrics(SM_CYSCREEN)-1)); //ÿ���ظ߶ȵ�λ
end;

end.

