// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uVarUtil;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Variants;

type
  TStringListHelper = class helper for TStringList
  public
    function AddArray(const aArr : TStringArray): TStringList;
    function AddJson(const aArr : TJSONArray): TStringList;
    function AddExtDelim(const aStr: string; const aDelim: string = '-'): TStringList;
    function AddExtDelim(const aSL: TStringList; const aDelim: string = '-'): TStringList;
    function DelArray(const aArr : TStringArray): TStringList;
    function GetJoin(const aDelim: string): string;
    function GetJson(): TJSONArray;
    function Formated(const aFormat: string): TStringList;
    function Left(aLen: integer): TStringList;
    function Quoted(): TStringList;
    function Quoted(aChar: char): TStringList;
    function Replace(const aFind, aRep: string): TStringList;
    function Uniq(): TStringList;
  end;

function ExtractLatin(const aString: string): string;
function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
function ReplMacros(const aText: string; aDict: TStringList): string;
function Between(aVal, aMin, aMax: integer): boolean;
function PrevPeriodDate(aPerType: char; aYear, aMonth: Integer): TDate;
function IntToRoman10(aVal: Integer): String;

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;


implementation

uses RegExpr;

function TStringListHelper.AddArray(const aArr: TStringArray): TStringList;
var
  i:  integer;
begin
  for i := 0 to Length(aArr) - 1 do
      Add(aArr[i]);

  Result := self;
end;

function TStringListHelper.AddJson(const aArr: TJSONArray): TStringList;
var
  i:  integer;
begin
  for i := 0 to aArr.Count - 1 do
     Add(aArr[i].AsString);

  Result := self;
end;

function TStringListHelper.AddExtDelim(const aStr: string; const aDelim: string = '-'): TStringList;
var
  Prefix, Num: string;
  i: Integer;
begin
  Prefix := Copy(aStr, 1, Pos(aDelim, aStr) - 1);
  if (Prefix.IsEmpty()) then
    self.Add(aStr)
  else begin
    Num := Copy(aStr, Pos(aDelim, aStr) + 1, Length(aStr));
    for i := 1 to Length(Prefix) do
      self.Add(Prefix[i] + Num);
  end;

  Result := self;
end;

function TStringListHelper.AddExtDelim(const aSL: TStringList; const aDelim: string = '-'): TStringList;
var
  i: Integer;
begin
  for i := 0 to aSL.Count - 1 do
    AddExtDelim(aSL[i], aDelim);

  Result := self;
end;

function TStringListHelper.DelArray(const aArr : TStringArray): TStringList;
var
  Idx: integer;
  Str: string;
begin
  for Str in aArr do
  begin
    Idx := IndexOf(Str);
    if (Idx <> -1) then
      Delete(Idx);
  end;

  Result := self;
end;

function TStringListHelper.Uniq(): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (IndexOf(self[i]) <> i) then
      Delete(i);

  Result := self;
end;

function TStringListHelper.Quoted(): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := QuotedStr(self[i]);

  Result := self;
end;

function TStringListHelper.Quoted(aChar: char): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := aChar + self[i] + aChar;

  Result := self;
end;


function TStringListHelper.Formated(const aFormat: string): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := Format(aFormat, [self[i]]);

  Result := self;
end;

function TStringListHelper.Left(aLen: integer): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    if (Self[i].Length > aLen) then
      self[i] := Copy(self[i], 1, aLen);

  Result := self;
end;

function TStringListHelper.GetJoin(const aDelim: string): string;
var
  i: integer;
begin
  if (Count = 0) then
    Exit('');

  Result := Self[0];
  for i := 1 to Count - 1 do
    Result := Result + aDelim + Self[i];
end;

function TStringListHelper.Replace(const aFind, aRep: string): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := StringReplace(self[i], aFind, aRep, [rfReplaceAll]);

  Result := self;
end;

function TStringListHelper.GetJson(): TJSONArray;
var
  i: integer;
begin
  Result := TJSONArray.Create();
  for i := 0 to Count - 1 do
    Result.Add(self[i]);
end;


//---

function PrevPeriodDate(aPerType: char; aYear, aMonth: Integer): TDate;
var
  ShiftMonths: Integer;
begin
  case aPerType of
    'm': ShiftMonths := 1;
    'q': ShiftMonths := 3;
    'h': ShiftMonths := 6;
    'y': ShiftMonths := 12;
  else
    ShiftMonths := 1;
  end;

  Result := IncMonth(EncodeDate(aYear, aMonth, 1), -ShiftMonths);
end;

function ExtractLatin(const aString: string): string;
var
  R: TRegExpr;
begin
  Result := '';
  R := TRegExpr.Create();
  try
    R.Expression := '[A-Za-z]';
    if R.Exec(aString) then
      repeat
        Result := Result + R.Match[0];
      until not R.ExecNext;
  finally
    R.Free();
  end;
end;

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;
begin
  if (aCond) then
    Result := aValTrue
  else
    Result := aValFalse;
end;

function ReplMacros(const aText: string; aDict: TStringList): string;
var
  i: integer;
begin
  Result := aText;
  for i := 0 to aDict.Count - 1 do
    Result := StringReplace(Result, '{' + aDict.Names[i] + '}', aDict.ValueFromIndex[i], [rfReplaceAll]);
end;

function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
  function JsonToVariant(const aJData: TJSONData): Variant;
  begin
    {$NOTES OFF}
    Result := Nil;
    if Assigned(aJData) then
      case aJData.JSONType of
        jtString:
          Result := aJData.AsString;
        jtNumber:
          Result := aJData.AsInteger;
        jtBoolean:
          Result := aJData.AsBoolean;
      end;
    {$NOTES ON}
  end;

var
  i: integer;
  Parts: TStringArray;
  JObjCur: TJSONObject;
  JData: TJSONData;
begin
  Result := aDef;

  JObjCur := aJObj;
  Parts := Path.Split(['/']);

  for i := 0 to High(Parts) - 1 do
  begin
    JData := JObjCur.Find(Parts[i]);
    if (JData = nil) or not (JData is TJSONObject) then
      Exit;
    JObjCur := TJSONObject(JData);
  end;

  JData := JObjCur.Find(Parts[High(Parts)]);
  Result := JsonToVariant(JData)
end;

function Between(aVal, aMin, aMax: integer): boolean;
begin
  Result := (aVal >= aMin) and (aVal <= aMax)
end;


function IntToRoman10(aVal: Integer): String;
begin
  case aVal of
    1:  Result := 'I';
    2:  Result := 'II';
    3:  Result := 'III';
    4:  Result := 'IV';
    5:  Result := 'V';
    6:  Result := 'VI';
    7:  Result := 'VII';
    8:  Result := 'VIII';
    9:  Result := 'IX';
    10: Result := 'X';
  else
    Result := '';
  end;
end;

end.

