// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uVarUtil;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Variants,
  uHelper;

function Between(aVal, aMin, aMax: integer): boolean;
function PrevPeriodDate(aPerType: char; aYear, aMonth: Integer): TDate;
function IntToRoman10(aVal: Integer): String;
procedure Swap(var aA, aB: Integer); inline;

generic function gIIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;
function IIF(aCond: boolean; const aValTrue, aValFalse: string): string; inline;


implementation

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

generic function gIIF<T>(aCond: boolean; const aValTrue, aValFalse: T): T; inline;
begin
  if (aCond) then
    Result := aValTrue
  else
    Result := aValFalse;
end;

function IIF(aCond: boolean; const aValTrue, aValFalse: string): string; inline;
begin
  Result := specialize gIIF<string>(aCond, aValTrue, aValFalse);
end;

function Between(aVal, aMin, aMax: integer): boolean;
begin
  Result := (aVal >= aMin) and (aVal <= aMax)
end;

function IntToRoman10(aVal: Integer): String;
begin
  case aVal of
    1: Result := 'I';
    2: Result := 'II';
    3: Result := 'III';
    4: Result := 'IV';
    5: Result := 'V';
    6: Result := 'VI';
    7: Result := 'VII';
    8: Result := 'VIII';
    9: Result := 'IX';
   10: Result := 'X';
  else
    Result := '';
  end;
end;

end.
