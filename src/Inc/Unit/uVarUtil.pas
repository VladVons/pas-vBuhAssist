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
generic function IIF<T>(aCond: Boolean; const aValTrue, aValFalse: T): T; inline;


implementation

uses RegExpr;

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
  i, Idx: Integer;
  c: String;
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
  i: Integer;
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

generic function IIF<T>(aCond: Boolean; const aValTrue, aValFalse: T): T; inline;
begin
  if (aCond) then
    Result := aValTrue
  else
    Result := aValFalse;
end;

function GetJsonNested(const aJObj: TJSONObject; const Path: string; aDef: Variant): Variant;
  function JsonToVariant(const aJData: TJSONData): Variant;
  begin
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
  end;

var
  i: Integer;
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


end.

