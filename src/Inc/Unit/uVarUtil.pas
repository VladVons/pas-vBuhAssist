// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uVarUtil;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, Variants;

function ExtractLatin(const aString: string): string;
function LatinToUkr(const aStr: string): string;
function RemoveChars(const aStr, aRemove: string): string;
function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
function ReplMacros(const aText: string; aDict: TStringList): string;
function Between(aVal, aMin, aMax: integer): boolean;
function PrevPeriodDate(aPerType: char; aYear, aMonth: Integer): TDate;
function IntToRoman10(aVal: Integer): String;
procedure StringListQuoted(aSL: TStringList);

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;


implementation

uses RegExpr;

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

function LatinToUkr(const aStr: string): string;
const
  StrIn: string  = 'ABCDEFGHIKLMNOPQRSTUVWYZabcdefghiklmnopqrstuvwyz';
  StrOut: string = 'АБЦДЕФГХІКЛМНОПКРСТУВВЙЗабцдефгхіклмнопкрстуввйз';
var
  i, Idx: integer;
  c: string;
begin
  Result := '';
  if (UTF8Length(StrIn) = UTF8Length(StrOut)) then
  begin
    for i := 1 to UTF8Length(aStr) do
    begin
      c := UTF8Copy(aStr, i, 1);
      Idx := Pos(c, StrIn);
      if (Idx) > 0 then
        Result := Result + UTF8Copy(StrOut, Idx, 1)
      else
        case c of
          'X': Result := Result + 'КС';
          'x': Result := Result + 'кс';
          'J': Result := Result + 'ДЖ';
          'j': Result := Result + 'дж';
        else
          Result := Result + c;
        end;
    end;
  end;
end;

function RemoveChars(const aStr, aRemove: string): string;
var
  i: integer;
  c: string;
begin
  Result := '';
  for i := 1 to UTF8Length(aStr) do
  begin
    c := UTF8Copy(aStr, i, 1);
    if (Pos(c, aRemove) = 0) then
      Result := Result + c;
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

procedure StringListQuoted(aSL: TStringList);
var
  i: integer;
begin
  for i := 0 to aSL.Count - 1 do
    aSL[i] := QuotedStr(aSL[i])
end;

end.

