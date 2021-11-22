unit JstreamOp;

// 懒是一切折腾的动力
// 主要为了STRING和 BOOLEAN在STREAM中的存取 写了此代码
// JACK XU
//2015年9月 IN NINGBO
//

interface

uses SysUtils,Classes;

type
TJstreamOp = class(TObject)
Public
class procedure SaveDataToStream(const Data; DataSize: Integer; Stream: TStream; Errcode:Integer=0);
class procedure LoadDataFromStream(var Data; DataSize: Integer; Stream: TStream;Errcode:Integer=0);
// string

class procedure  SaveStringtosteam(const Value: String; Stream:Tstream );
class procedure  LoadStringfromstream(Var Value: string; Stream: TStream);
 // widestring
class procedure  SavewideStringtosteam(const Value: WideString; Stream:Tstream );
class procedure  LoadwideStringfromstream(Var Value: widestring; Stream: TStream);
 // ansistring
class procedure  SaveAnsiStringtosteam(const Value: AnsiString; Stream:Tstream );
class procedure  LoadansiStringfromstream(Var Value: AnsiString; Stream: TStream);

// integer
class procedure  Saveintegertosteam(const Value: Integer ; Stream:Tstream );
class procedure  Loadintegerfromstream(Var Value: integer; Stream: TStream);
 // boolean
class procedure  Savebooleantosteam(const Value: boolean ; Stream:Tstream);
class procedure  Loadbooleanfromstream(Var Value: boolean; Stream: TStream);

// cardianl
class procedure  Savecardinaltosteam(const Value: Cardinal; Stream:Tstream);
class procedure  Loadcardinalfromstream(Var Value: Cardinal; Stream: TStream);
// 根据实际情况在加吧.,我差不多了


end;

const JstreamErrcode: array [1..12]  of Integer =(
1,2,3,4,5,6,7,8,9,10,11,12 );      // 错误编号定义 ,
//为了OO,项目中统一的错误编号
//项目中统一的错误编号,可以在SAVEDATA 和LOADDATA中讲JSTREAMERROCODE转成项目的ERRCODE.


implementation


class procedure TJstreamOp.SaveDataToStream(const Data; DataSize: Integer; Stream: TStream;Errcode:Integer =0);
var OldPos:     Int64;
    WriteBytes: Integer;
begin
    OldPos := Stream.Position;
    WriteBytes := Stream.Write(Data,DataSize);
   //if (WriteBytes <> DataSize) then
   // 有场景参数,有错误号, 错误处理以后扩展
  //

end;

class procedure TJstreamOp.LoadDataFromStream(var Data; DataSize: Integer; Stream: TStream;Errcode:Integer);
 var OldPos:     Int64;
    readBytes: Integer;
begin
  OldPos := Stream.Position;
  ReadBytes := Stream.read(Data,DataSize);
  // if (ReadBytes <> DataSize) then
  // 有场景参数,有错误号, 错误处理以后扩展

end;

//widestring
class procedure  TJstreamOp.SavewideStringtosteam(const Value: WideString; Stream:Tstream );
var l: Integer;
    j: Integer;
begin
  l := Length(Value) * 2;
  SaveDataToStream(l,SizeOf(l),Stream,JstreamErrcode[1]);
  if (l > 0) then
  begin
   j:=Low(Value);     // 为了跨平台
  SaveDataToStream(Value[j],l,Stream,JstreamErrcode[1]);
  end;
  end;

class procedure  TJstreamOp.LoadwideStringfromstream(Var Value: WideString; Stream: TStream);
var l: Integer;
var J: Integer;
begin
 LoadDataFromStream(l,SizeOf(l),Stream,JstreamErrcode[2]);

  SetLength(Value,(l div 2));
  if (l > 0) then
  begin
    J:=Low(Value);    // 为了跨平台
   LoadDataFromStream(Value[j],l,Stream,JstreamErrcode[2]);
  end;
end;

  // :STRING转换成 widestring
class procedure  TJstreamOp.SaveStringtosteam(const Value: String; Stream:Tstream );
var i:WideString;
begin
     I:= widestring(Value);
    SavewideStringtosteam(widestring(i), Stream);
end;

class procedure  TJstreamOp.LoadStringfromstream(Var Value: string; Stream: TStream);
var I:WideString;
begin

   LoadwideStringfromstream(i,stream);
   value:=string(i)
end;

//ANSISTRING


class procedure  TJstreamOp.SaveAnsiStringtosteam(const Value: AnsiString; Stream:Tstream );
var l: Integer;
    j: Integer;
begin
  l := Length(Value);
  SaveDataToStream(l,SizeOf(l),Stream,JstreamErrcode[3]);
  if (l > 0) then
  begin
   j:=Low(Value);  // 为了跨平台
  SaveDataToStream(Value[j],l,Stream,JstreamErrcode[3]);
  end;
  end;

class procedure  TJstreamOp.LoadAnsiStringfromstream(Var Value: AnsiString; Stream: TStream);
var I: Integer;
var J: Integer;
begin
 LoadDataFromStream(I,SizeOf(I),Stream,JstreamErrcode[4]);
  SetLength(Value,I);
  if (I > 0) then
  begin
    J:=Low(Value);  // 为了跨平台
   LoadDataFromStream(Value[j],I ,Stream,JstreamErrcode[4]);
  end;
end;

// integer
class procedure  TJstreamOp.Saveintegertosteam(const Value: Integer ; Stream:Tstream );
var I:Integer;
begin
   I:=Value;
   SaveDataToStream(I,SizeOf(I),Stream,JstreamErrcode[5]);

end;

class procedure  TJstreamOp.Loadintegerfromstream(Var Value: integer; Stream: TStream);
Var I:Integer;
begin
   LoadDataFromStream(I,SizeOf(I),Stream,JstreamErrcode[6]);
   Value:=I;
end;

//Boolean

class procedure  TJstreamOp.Savebooleantosteam(const Value: Boolean ; Stream:Tstream );
var I:ByteBool;
begin
   I:=Value;
   SaveDataToStream(I,SizeOf(I),Stream,JstreamErrcode[7]);

end;

class procedure  TJstreamOp.Loadbooleanfromstream(Var Value: Boolean; Stream: TStream);
Var I:ByteBool;
begin
   LoadDataFromStream(I,SizeOf(I),Stream,JstreamErrcode[8]);
   Value:=I;
end;


// integer
class procedure  TJstreamOp.Savecardinaltosteam(const Value: Cardinal ; Stream:Tstream );
var I:Cardinal;
begin
   I:=Value;
   SaveDataToStream(I,SizeOf(I),Stream,JstreamErrcode[9]);

end;

class procedure  TJstreamOp.Loadcardinalfromstream(Var Value: Cardinal; Stream: TStream);
Var I:Cardinal;
begin
   LoadDataFromStream(I,SizeOf(I),Stream,JstreamErrcode[10]);
   Value:=I;
end;



end.
