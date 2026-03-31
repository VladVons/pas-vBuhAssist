// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uVarUtil;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Variants;

type
  TMacros = class
  private
    fPrefix, fSuffix: string;
  public
    constructor Create(const aPrefix: string = '{{'; const aSuffix: string = '}}');
    function Exec(const aStr: string; const aNames, aValues: TStringArray): string;
    function Exec(const aStr: string; aDict: TStrings): string;
    function Exec(const aStr: string; aObj: TJSONObject): string;
  end;

function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
function Between(aVal, aMin, aMax: integer): boolean;
function PrevPeriodDate(aPerType: char; aYear, aMonth: Integer): TDate;
function IntToRoman10(aVal: Integer): String;
procedure Swap(var aA, aB: Integer); inline;

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;


implementation

uses RegExpr;

procedure Swap(var aA, aB: Integer);
var
  T: Integer;
begin
  T := aA;
  aA := aB;
  aB := T;
end;

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

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;
begin
  if (aCond) then
    Result := aValTrue
  else
    Result := aValFalse;
end;

function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
  function JsonToVariant(const aJData: TJSONData): Variant;
  begin
    {$NOTES OFF}
    Result := Nil;
    if (aJData <> nil) then
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
      Exit();
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

//--- TMacros

constructor TMacros.Create(const aPrefix: string = '{{'; const aSuffix: string = '}}');
begin
  fPrefix := aPrefix;
  fSuffix := aSuffix;
end;

function TMacros.Exec(const aStr: string; const aNames, aValues: TStringArray): string;
var
  i: integer;
begin
  if (System.Length(aNames) <> System.Length(aValues)) then
    raise Exception.Create('arrays length mismatch');

  Result := aStr;
  for i := 0 to System.Length(aNames) - 1do
    Result := StringReplace(Result, '{{' + aNames[i] + '}}', aValues[i], [rfReplaceAll]);
end;

function TMacros.Exec(const aStr: string; aDict: TStrings): string;
var
  i: integer;
begin
  Result := aStr;
  for i := 0 to aDict.Count - 1 do
    Result := StringReplace(Result, '{{' + aDict.Names[i] + '}}', aDict.ValueFromIndex[i], [rfReplaceAll]);
end;

function TMacros.Exec(const aStr: string; aObj: TJSONObject): string;
var
  i: integer;
  Str: string;
begin
  Result := aStr;
  for i := 0 to aObj.Count - 1 do
  begin
    Str := aObj.Names[i];
    Result := StringReplace(Result, '{{' + Str + '}}', aObj.Get(Str, ''), [rfReplaceAll]);
  end;
end;

end.

