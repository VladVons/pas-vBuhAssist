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
    function Replace(const aStr, aFind, aRepl: string): string;
  public
    constructor Create(const aPrefix: string = '{{'; const aSuffix: string = '}}');
    function Exec(const aStr: string; const aNames, aValues: TStringArray): string;
    function Exec(const aStr: string; aDict: TStringList): string;
    function Exec(const aStr: string; aObj: TJSONObject): string;
  end;

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
  Shift: Integer;
begin
  case aPerType of
    'm': Shift := 1;
    'q': Shift := 3;
    'h': Shift := 6;
    'y': Shift := 12;
  else
    Shift := 1;
  end;

  Result := IncMonth(EncodeDate(aYear, aMonth, 1), -Shift);
end;

generic function IIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;
begin
  if (aCond) then
    Result := aValTrue
  else
    Result := aValFalse;
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

function TMacros.Replace(const aStr, aFind, aRepl: string): string;
begin
  if (aRepl.IsEmpty()) then
    Result := aStr
  else
    Result := StringReplace(aStr, fPrefix + aFind + fSuffix, aRepl, [rfReplaceAll]);
end;

function TMacros.Exec(const aStr: string; const aNames, aValues: TStringArray): string;
var
  i: integer;
begin
  if (System.Length(aNames) <> System.Length(aValues)) then
    raise Exception.Create('arrays length mismatch');

  Result := aStr;
  for i := 0 to System.Length(aNames) - 1do
    Result := Replace(Result, aNames[i], aValues[i]);
end;

function TMacros.Exec(const aStr: string; aDict: TStringList): string;
var
  i: integer;
begin
  Result := aStr;
  for i := 0 to aDict.Count - 1 do
    Result := Replace(Result, aDict.Names[i], aDict.ValueFromIndex[i]);
end;

function TMacros.Exec(const aStr: string; aObj: TJSONObject): string;
var
  i: integer;
  Find, Repl: string;
begin
  Result := aStr;
  for i := 0 to aObj.Count - 1 do
  begin
    Find := aObj.Names[i];
    Repl := string(aObj.Get(Find, '')).Replace('"', '`');
    Result := Replace(Result, Find, Repl);
  end;
end;

end.

