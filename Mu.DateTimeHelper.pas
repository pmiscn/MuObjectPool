{ *************************************************************************** }
{ }
{ DateTimeHelper }
{ }
{ Copyright (C) Colin Johnsun }
{ }
{ https://github.com/colinj }
{ }
{ }
{ *************************************************************************** }
{ }
{ Licensed under the Apache License, Version 2.0 (the "License"); }
{ you may not use this file except in compliance with the License. }
{ You may obtain a copy of the License at }
{ }
{ http://www.apache.org/licenses/LICENSE-2.0 }
{ }
{ Unless required by applicable law or agreed to in writing, software }
{ distributed under the License is distributed on an "AS IS" BASIS, }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{ See the License for the specific language governing permissions and }
{ limitations under the License. }
{ 碧水航工作室修改 }
{ *************************************************************************** }

unit Mu.DateTimeHelper;

interface

uses
  System.SysUtils, System.Types, System.TimeSpan, System.DateUtils;

// TTimeStamp
type
  TDateTimeHelper = record helper for TDateTime
  private
    function GetDay: Word; inline;
    function GetDate: TDate; inline;
    function GetDayOfWeek: Word; inline;
    function GetDayOfYear: Word; inline;
    function GetWeekOfYear: Word; inline;
    function GetTimeSpanOfDay: TTimeSpan; overload; inline;
    function GetTimeOfDay: TTime; overload; inline;
    function GetHour: Word; inline;
    function GetMillisecond: Word; inline;
    function GetMinute: Word; inline;
    function GetMonth: Word; inline;
    function GetSecond: Word; inline;
    function GetTime: TTime; inline;
    function GetYear: Integer; inline;
    class function GetNow: TDateTime; static; inline;
    class function GetToday: TDateTime; static; inline;
    class function GetTomorrow: TDateTime; static; inline;
    class function GetYesterDay: TDateTime; static; inline;
    class function GetMinValue: TDateTime; static; inline;
    class function GetMaxValue: TDateTime; static; inline;

    procedure SetSecond(const Value: Word);
    procedure SetDay(const Value: Word);
    procedure setHour(const Value: Word);
    procedure SetMillisecond(const Value: Word);
    procedure SetMinute(const Value: Word);
    procedure SetMonth(const Value: Word);
    procedure SetYear(const Value: Integer);
    function GetDays: Int64;
    function GetHours: Int64;
    function GetSeconds: Int64;
    function GetMinutes: Int64;
    function GetMSeconds: Int64;

    function GetTicks: Int64;
    procedure SetTicks(aValue: Int64);
  public

    class function create(const aTicks: Double): TDateTime; overload;
      static; inline;

    class function create(const aYear, aMonth, aDay: Word): TDateTime; overload;
      static; inline;
    class function create(const aYear, aMonth, aDay, aHour, aMinute,
      aSecond: Word): TDateTime; overload; static; inline;
    class function create(const aYear, aMonth, aDay, aHour, aMinute, aSecond,
      aMillisecond: Word): TDateTime; overload; static; inline;

    class property Now: TDateTime read GetNow;
    class property Today: TDateTime read GetToday;
    class property Yesterday: TDateTime read GetYesterDay;
    class property Tomorrow: TDateTime read GetTomorrow;
    class property MinValue: TDateTime read GetMinValue;
    class property MaxValue: TDateTime read GetMaxValue;

    property Ticks: Int64 read GetTicks write SetTicks;
    property Date: TDate read GetDate;
    property Time: TTime read GetTime;

    property DayOfWeek: Word read GetDayOfWeek;
    property DayOfYear: Word read GetDayOfYear;
    property WeekOfYear: Word read GetWeekOfYear;
    property TimeSpanOfDay: TTimeSpan read GetTimeSpanOfDay;
    property TimeOfDay: TTime read GetTimeOfDay;

    property Year: Integer read GetYear write SetYear;
    property Month: Word read GetMonth write SetMonth;
    property Week: Word read GetWeekOfYear;
    property Day: Word read GetDay write SetDay;

    property Hour: Word read GetHour write setHour;
    property Minute: Word read GetMinute write SetMinute;
    property Second: Word read GetSecond write SetSecond;
    property Millisecond: Word read GetMillisecond write SetMillisecond;
    // Alias of millisecond
    property MS: Word read GetMillisecond write SetMillisecond;
    // tintinsoft
    property Days: Int64 read GetDays;
    property Hours: Int64 read GetHours;
    property Minutes: Int64 read GetMinutes;
    property Seconds: Int64 read GetSeconds;
    property MSeconds: Int64 read GetMSeconds;

    procedure ParseFrom(s: String); overload; inline;
    class function Parse(s: String): TDateTime; overload; static;
    function TryParse(s: String): boolean; overload; inline;
    class function TryParse(s: String; var aDateTime: TDateTime): boolean;
      overload; inline; static;

    function ToString(const aFormatStr: string = ''): string; overload; inline;
    function ToString(const aFormatStr: string;
      AFormatSettings: TFormatSettings): String; overload; inline;
    function Format(const aFormatStr: string = ''): string; inline;

    procedure FromString(s: String); overload; inline;
    procedure FromString(const s: string;
      const AFormatSettings: TFormatSettings); overload; inline;
    procedure FromStringDef(s: String; const Default: TDateTime);
      overload; inline;
    procedure FromStringDef(const s: string; const Default: TDateTime;
      const AFormatSettings: TFormatSettings); overload;

    class function TryStrToDateTime(const s: string; out Value: TDateTime)
      : boolean; overload; static; inline;
    class function TryStrToDateTime(const s: string; out Value: TDateTime;
      const AFormatSettings: TFormatSettings): boolean; overload; static;

    procedure FromFloat(const Value: Extended); inline;
    function ToFloat(): Extended; inline;
    property AsFloat: Extended read ToFloat write FromFloat;

    function StartOfYear: TDateTime; inline;
    function EndOfYear: TDateTime; inline;
    function StartOfMonth: TDateTime; inline;
    function EndOfMonth: TDateTime; inline;
    function StartOfWeek: TDateTime; inline;
    function EndOfWeek: TDateTime; inline;
    function StartOfDay: TDateTime; inline;
    function EndOfDay: TDateTime; inline;

    function Add(const aValue: TTimeSpan): TDateTime; inline;
    function AddYears(const aNumberOfYears: Integer = 1): TDateTime; inline;
    function AddMonths(const aNumberOfMonths: Integer = 1): TDateTime; inline;
    function AddDays(const aNumberOfDays: Integer = 1): TDateTime; inline;
    function AddHours(const aNumberOfHours: Int64 = 1): TDateTime; inline;
    function AddMinutes(const aNumberOfMinutes: Int64 = 1): TDateTime; inline;
    function AddSeconds(const aNumberOfSeconds: Int64 = 1): TDateTime; inline;
    function AddMilliseconds(const aNumberOfMilliseconds: Int64 = 1)
      : TDateTime; inline;
    function AddTicks(const aValue: Int64): TDateTime; inline;
    function Subtract(const aValue: TTimeSpan): TDateTime; inline;

    function CompareTo(const aDateTime: TDateTime): TValueRelationship; inline;
    class function Compare(const aDateTime, aDateTime2: TDateTime)
      : TValueRelationship; static; inline;

    class function DaysInMonth(const aYear, aMonth: Integer): Integer; overload;
      static; inline;
    class function DaysInMonth(const aDateTime: TDateTime): Integer; overload;
      static; inline;

    function Equals(const aDateTime: TDateTime): boolean; overload; inline;
    class function Equals(const aDateTime1, aDateTime2: TDateTime): boolean;
      overload; static; inline;
    function IsSameDay(const aDateTime: TDateTime): boolean; inline;

    function InRange(const aStartDateTime, aEndDateTime: TDateTime;
      const aInclusive: boolean = True): boolean; inline;
    function IsInLeapYear: boolean; inline;
    function IsToday: boolean; inline;
    function IsTomorrow: boolean; inline;
    function IsYesterday: boolean; inline;
    function IsDayAfterTomorrow: boolean; inline;
    function IsAM: boolean; inline;
    function IsPM: boolean; inline;

    function YearsBetween(const aDateTime: TDateTime): Integer; inline;
    function MonthsBetween(const aDateTime: TDateTime): Integer; inline;
    function WeeksBetween(const aDateTime: TDateTime): Integer; inline;
    function DaysBetween(const aDateTime: TDateTime): Integer; inline;
    function HoursBetween(const aDateTime: TDateTime): Int64; inline;
    function MinutesBetween(const aDateTime: TDateTime): Int64; inline;
    function SecondsBetween(const aDateTime: TDateTime): Int64; inline;
    function MilliSecondsBetween(const aDateTime: TDateTime): Int64; inline;

    function WithinYears(const aDateTime: TDateTime; const aYears: Integer)
      : boolean; inline;
    function WithinMonths(const aDateTime: TDateTime; const aMonths: Integer)
      : boolean; inline;
    function WithinWeeks(const aDateTime: TDateTime; const aWeeks: Integer)
      : boolean; inline;
    function WithinDays(const aDateTime: TDateTime; const aDays: Integer)
      : boolean; inline;
    function WithinHours(const aDateTime: TDateTime; const aHours: Int64)
      : boolean; inline;
    function WithinMinutes(const aDateTime: TDateTime; const aMinutes: Int64)
      : boolean; inline;
    function WithinSeconds(const aDateTime: TDateTime; const aSeconds: Int64)
      : boolean; inline;
    function WithinMilliseconds(const aDateTime: TDateTime;
      const AMilliseconds: Int64): boolean; inline;

    Procedure FromFileDate(aValue: Integer);
    function ToFileDate(): Integer;
    property AsFileDate: Integer read ToFileDate write FromFileDate;

  end;

implementation

uses qstring;

{ TDateTimeHelper }

function TDateTimeHelper.Add(const aValue: TTimeSpan): TDateTime;
begin
  Result := self + aValue.TotalDays;
end;

function TDateTimeHelper.Subtract(const aValue: TTimeSpan): TDateTime;
begin
  Result := self - aValue.TotalDays;
end;

function TDateTimeHelper.AddDays(const aNumberOfDays: Integer): TDateTime;
begin
  Result := IncDay(self, aNumberOfDays);
end;

function TDateTimeHelper.AddHours(const aNumberOfHours: Int64): TDateTime;
begin
  Result := IncHour(self, aNumberOfHours);
end;

function TDateTimeHelper.AddMilliseconds(const aNumberOfMilliseconds: Int64)
  : TDateTime;
begin
  Result := IncMilliSecond(self, aNumberOfMilliseconds);
end;

function TDateTimeHelper.AddMinutes(const aNumberOfMinutes: Int64): TDateTime;
begin
  Result := IncMinute(self, aNumberOfMinutes);
end;

function TDateTimeHelper.AddMonths(const aNumberOfMonths: Integer): TDateTime;
begin
  Result := IncMonth(self, aNumberOfMonths);
end;

function TDateTimeHelper.AddSeconds(const aNumberOfSeconds: Int64): TDateTime;
begin
  Result := IncSecond(self, aNumberOfSeconds);
end;

function TDateTimeHelper.AddTicks(const aValue: Int64): TDateTime;
begin
  Result := self + aValue / TTimeSpan.TicksPerDay
end;

function TDateTimeHelper.AddYears(const aNumberOfYears: Integer): TDateTime;
begin
  Result := IncYear(self, aNumberOfYears);
end;

class function TDateTimeHelper.Compare(const aDateTime, aDateTime2: TDateTime)
  : TValueRelationship;
begin
  Result := CompareDateTime(aDateTime, aDateTime2);
end;

function TDateTimeHelper.CompareTo(const aDateTime: TDateTime)
  : TValueRelationship;
begin
  Result := CompareDateTime(self, aDateTime);
end;

class function TDateTimeHelper.create(const aTicks: Double): TDateTime;
begin
  if (aTicks > TDateTime.MaxValue) then
    raise Exception.create('Out of TDatetime range');
  if (aTicks < TDateTime.MinValue) then
    raise Exception.create('Out of TDatetime range');
  Result := aTicks;
end;

class function TDateTimeHelper.create(const aYear, aMonth, aDay: Word)
  : TDateTime;
begin
  Result := EncodeDate(aYear, aMonth, aDay);
end;

class function TDateTimeHelper.create(const aYear, aMonth, aDay, aHour, aMinute,
  aSecond, aMillisecond: Word): TDateTime;
begin
  Result := EncodeDateTime(aYear, aMonth, aDay, aHour, aMinute, aSecond,
    aMillisecond);
end;

class function TDateTimeHelper.create(const aYear, aMonth, aDay, aHour, aMinute,
  aSecond: Word): TDateTime;
begin
  Result := EncodeDateTime(aYear, aMonth, aDay, aHour, aMinute, aSecond, 0);
end;

function TDateTimeHelper.DaysBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.DaysBetween(self, aDateTime);
end;

class function TDateTimeHelper.DaysInMonth(const aYear,
  aMonth: Integer): Integer;
begin
  if aMonth in [1, 3, 5, 7, 8, 10, 12] then
    Result := 31
  else if aMonth in [4, 6, 9, 11] then
    Result := 30
  else if aMonth = 2 then
  begin
    if aYear mod 4 = 0 then
      Result := 29
    else
      Result := 28;
  end
  else
    raise Exception.create('Out of month range');
end;

class function TDateTimeHelper.DaysInMonth(const aDateTime: TDateTime): Integer;
begin
  Result := DaysInMonth(aDateTime.Year, aDateTime.Month);
end;

function TDateTimeHelper.EndOfDay: TDateTime;
begin
  Result := EndOfTheDay(self);
end;

function TDateTimeHelper.EndOfMonth: TDateTime;
begin
  Result := EndOfTheMonth(self);
end;

function TDateTimeHelper.EndOfWeek: TDateTime;
begin
  Result := EndOfTheWeek(self);
end;

function TDateTimeHelper.EndOfYear: TDateTime;
begin
  Result := EndOfTheYear(self);
end;

class function TDateTimeHelper.Equals(const aDateTime1,
  aDateTime2: TDateTime): boolean;
begin
  Result := SameDateTime(aDateTime1, aDateTime2);
end;

function TDateTimeHelper.Equals(const aDateTime: TDateTime): boolean;
begin
  Result := SameDateTime(self, aDateTime);
end;

function TDateTimeHelper.Format(const aFormatStr: string): string;
begin
  Result := ToString(aFormatStr);
end;

procedure TDateTimeHelper.ParseFrom(s: String);
begin
  if not qstring.ParseDateTime(PChar(s), self) then
    qstring.ParseWebTime(PChar(s), self);
end;

class function TDateTimeHelper.Parse(s: String): TDateTime;
begin
  if not qstring.ParseDateTime(PChar(s), Result) then
    qstring.ParseWebTime(PChar(s), Result);
end;

function TDateTimeHelper.TryParse(s: String): boolean;
begin
  Result := qstring.ParseDateTime(PChar(s), self);
  if not Result then
    Result := qstring.ParseWebTime(PChar(s), self);
end;

class function TDateTimeHelper.TryParse(s: String;
  var aDateTime: TDateTime): boolean;
begin
  Result := qstring.ParseDateTime(PChar(s), aDateTime);
  if not Result then
    Result := qstring.ParseWebTime(PChar(s), aDateTime);
end;

procedure TDateTimeHelper.FromString(s: String);
begin
  self := StrToDateTime(s);
end;

procedure TDateTimeHelper.FromString(const s: string;
  const AFormatSettings: TFormatSettings);
begin
  self := StrToDateTime(s, AFormatSettings);
end;

procedure TDateTimeHelper.FromStringDef(s: String; const Default: TDateTime);
begin
  self := StrToDateTimeDef(s, Default);
end;

procedure TDateTimeHelper.FromStringDef(const s: string;
  const Default: TDateTime; const AFormatSettings: TFormatSettings);
begin
  self := StrToDateTimeDef(s, Default, AFormatSettings);
end;

class function TDateTimeHelper.TryStrToDateTime(const s: string;
  out Value: TDateTime): boolean;
begin
  Result := TryStrToDateTime(s, Value);
end;

class function TDateTimeHelper.TryStrToDateTime(const s: string;
  out Value: TDateTime; const AFormatSettings: TFormatSettings): boolean;
begin
  Result := TryStrToDateTime(s, Value, AFormatSettings);
end;

procedure TDateTimeHelper.FromFloat(const Value: Extended);
begin
  self := FloatToDateTime(Value);
end;

function TDateTimeHelper.ToFloat(): Extended;
begin
  Result := self;
end;

function TDateTimeHelper.GetDate: TDate;
begin
  Result := DateOf(self);
end;

function TDateTimeHelper.GetDay: Word;
begin
  Result := DayOf(self);
end;

function TDateTimeHelper.GetDayOfWeek: Word;
begin
  Result := DayOfTheWeek(self);
end;

function TDateTimeHelper.GetDayOfYear: Word;
begin
  Result := DayOfTheYear(self);
end;

function TDateTimeHelper.GetWeekOfYear: Word;
begin
  Result := WeekOfTheYear(self);
end;

function TDateTimeHelper.GetTimeSpanOfDay: TTimeSpan;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(self, Hour, Min, Sec, MSec);
  Result := TTimeSpan.create(0, Hour, Min, Sec, MSec);
end;

function TDateTimeHelper.GetTimeOfDay: TTime;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(self, Hour, Min, Sec, MSec);
  Result := EncodeTime(Hour, Min, Sec, MSec);
end;

function TDateTimeHelper.GetDays: Int64;
begin
  Result := Trunc(Date);
end;

function TDateTimeHelper.GetHour: Word;
begin
  Result := HourOf(self);
end;

function TDateTimeHelper.GetHours: Int64;
begin
  Result := Days * 24 + Hour;
end;

function TDateTimeHelper.GetMillisecond: Word;
begin
  Result := MilliSecondOf(self);
end;

function TDateTimeHelper.GetMinute: Word;
begin
  Result := MinuteOf(self);
end;

function TDateTimeHelper.GetMinutes: Int64;
begin
  Result := Days * 24 * 60 + Minute;
end;

function TDateTimeHelper.GetMonth: Word;
begin
  Result := MonthOf(self);
end;

function TDateTimeHelper.GetMSeconds: Int64;
begin
  Result := Seconds * 1000 + Millisecond;
end;

class function TDateTimeHelper.GetNow: TDateTime;
begin
  Result := System.SysUtils.Now;
end;

function TDateTimeHelper.GetSecond: Word;
begin
  Result := SecondOf(self);
end;

function TDateTimeHelper.GetSeconds: Int64;
begin
  Result := Days * 24 * 3600 + Second;
end;

function TDateTimeHelper.GetTicks: Int64;
begin
  Result := Trunc(self * TTimeSpan.TicksPerDay);
end;

function TDateTimeHelper.GetTime: TTime;
begin
  Result := TimeOf(self);
end;

class function TDateTimeHelper.GetToday: TDateTime;
begin
  Result := System.SysUtils.Date;
end;

class function TDateTimeHelper.GetTomorrow: TDateTime;
begin
  Result := System.SysUtils.Date + 1;
end;

function TDateTimeHelper.GetYear: Integer;
begin
  Result := YearOf(self);
end;

class function TDateTimeHelper.GetYesterDay: TDateTime;
begin
  Result := System.SysUtils.Date - 1;
end;

class function TDateTimeHelper.GetMinValue: TDateTime;
begin
  Result := MinDateTime;
end;

class function TDateTimeHelper.GetMaxValue: TDateTime;
begin
  Result := MaxDateTime;
end;

function TDateTimeHelper.HoursBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.HoursBetween(self, aDateTime);
end;

function TDateTimeHelper.InRange(const aStartDateTime, aEndDateTime: TDateTime;
  const aInclusive: boolean): boolean;
begin
  Result := DateTimeInRange(self, aStartDateTime, aEndDateTime, aInclusive);
end;

function TDateTimeHelper.IsAM: boolean;
begin
  Result := System.DateUtils.IsAM(self);
end;

function TDateTimeHelper.IsDayAfterTomorrow: boolean;
begin
  Result := IsSameDay(self.AddDays(2));
end;

function TDateTimeHelper.IsInLeapYear: boolean;
begin
  Result := System.DateUtils.IsInLeapYear(self);
end;

function TDateTimeHelper.IsPM: boolean;
begin
  Result := System.DateUtils.IsPM(self);
end;

function TDateTimeHelper.IsSameDay(const aDateTime: TDateTime): boolean;
begin
  Result := System.DateUtils.IsSameDay(self, aDateTime);
end;

function TDateTimeHelper.IsToday: boolean;
begin
  Result := System.DateUtils.IsToday(self);
end;

function TDateTimeHelper.IsTomorrow: boolean;
begin
  Result := IsSameDay(TDateTime.Tomorrow);
end;

function TDateTimeHelper.IsYesterday: boolean;
begin
  Result := IsSameDay(TDateTime.Yesterday);
end;

function TDateTimeHelper.MilliSecondsBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.MilliSecondsBetween(self, aDateTime);
end;

function TDateTimeHelper.MinutesBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.MinutesBetween(self, aDateTime);
end;

function TDateTimeHelper.MonthsBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.MonthsBetween(self, aDateTime);
end;

procedure TDateTimeHelper.SetSecond(const Value: Word);
begin
  self := RecodeSecond(self, Value);
end;

procedure TDateTimeHelper.SetTicks(aValue: Int64);
begin
  self := aValue / TTimeSpan.TicksPerDay;
end;

function TDateTimeHelper.SecondsBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.SecondsBetween(self, aDateTime);
end;

procedure TDateTimeHelper.SetDay(const Value: Word);
begin
  self := RecodeDay(self, Value);
end;

procedure TDateTimeHelper.setHour(const Value: Word);
begin
  self := RecodeHour(self, Value);
end;

procedure TDateTimeHelper.SetMillisecond(const Value: Word);
begin
  self := RecodeMilliSecond(self, Value);
end;

procedure TDateTimeHelper.SetMinute(const Value: Word);
begin
  self := RecodeMinute(self, Value);
end;

procedure TDateTimeHelper.SetMonth(const Value: Word);
begin
  self := RecodeMonth(self, Value);
end;

procedure TDateTimeHelper.SetYear(const Value: Integer);
begin
  self := RecodeYear(self, Value);
end;

function TDateTimeHelper.StartOfDay: TDateTime;
begin
  Result := StartOfTheDay(self);
end;

function TDateTimeHelper.StartOfMonth: TDateTime;
begin
  Result := StartOfTheMonth(self);
end;

function TDateTimeHelper.StartOfWeek: TDateTime;
begin
  Result := StartOfTheWeek(self);
end;

function TDateTimeHelper.StartOfYear: TDateTime;
begin
  Result := StartOfTheYear(self);
end;

function TDateTimeHelper.ToString(const aFormatStr: string): string;
begin
  if aFormatStr = '' then
    Result := DateTimeToStr(self)
  else
    Result := FormatDateTime(aFormatStr, self);
end;

function TDateTimeHelper.ToString(const aFormatStr: string;
  AFormatSettings: TFormatSettings): String;
begin
  Result := FormatDateTime(aFormatStr, self, AFormatSettings);
end;

function TDateTimeHelper.WeeksBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.WeeksBetween(self, aDateTime);
end;

function TDateTimeHelper.WithinDays(const aDateTime: TDateTime;
  const aDays: Integer): boolean;
begin
  Result := System.DateUtils.WithinPastDays(self, aDateTime, aDays);
end;

function TDateTimeHelper.WithinHours(const aDateTime: TDateTime;
  const aHours: Int64): boolean;
begin
  Result := System.DateUtils.WithinPastHours(self, aDateTime, aHours);
end;

function TDateTimeHelper.WithinMilliseconds(const aDateTime: TDateTime;
  const AMilliseconds: Int64): boolean;
begin
  Result := System.DateUtils.WithinPastMilliSeconds(self, aDateTime,
    AMilliseconds);
end;

function TDateTimeHelper.WithinMinutes(const aDateTime: TDateTime;
  const aMinutes: Int64): boolean;
begin
  Result := System.DateUtils.WithinPastMinutes(self, aDateTime, aMinutes);
end;

function TDateTimeHelper.WithinMonths(const aDateTime: TDateTime;
  const aMonths: Integer): boolean;
begin
  Result := System.DateUtils.WithinPastMonths(self, aDateTime, aMonths);
end;

function TDateTimeHelper.WithinSeconds(const aDateTime: TDateTime;
  const aSeconds: Int64): boolean;
begin
  Result := System.DateUtils.WithinPastSeconds(self, aDateTime, aSeconds);
end;

function TDateTimeHelper.WithinWeeks(const aDateTime: TDateTime;
  const aWeeks: Integer): boolean;
begin
  Result := System.DateUtils.WithinPastWeeks(self, aDateTime, aWeeks);
end;

function TDateTimeHelper.WithinYears(const aDateTime: TDateTime;
  const aYears: Integer): boolean;
begin
  Result := System.DateUtils.WithinPastYears(self, aDateTime, aYears);
end;

function TDateTimeHelper.YearsBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.YearsBetween(self, aDateTime);
end;

Procedure TDateTimeHelper.FromFileDate(aValue: Integer);
begin
  self := FileDateToDateTime(aValue);
end;

function TDateTimeHelper.ToFileDate(): Integer;
begin
  Result := DateTimeToFileDate(self);
end;

end.
