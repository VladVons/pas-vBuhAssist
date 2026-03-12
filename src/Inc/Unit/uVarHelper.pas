// Created: 2026.03.11
// Author: Vladimir Vons <VladVons@gmail.com>

unit uVarHelper;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson;

type
  TStringMapFunc = function(const aStr: string): string;

  TStringListHelper = class helper for TStringList
  public
    function AddArray(const aArr : TStringArray): TStringList;
    function AddJson(const aArr : TJSONArray): TStringList;
    function AddExtDelim(const aStr: string; const aDelim: string = '-'): TStringList;
    function AddExtDelim(const aSL: TStringList; const aDelim: string = '-'): TStringList;
    function DelArray(const aArr : TStringArray): TStringList;
    function DelEmpty(): TStringList;
    function GetArray(): TStringArray;
    function GetJoin(const aDelim: string): string;
    function GetJson(): TJSONArray;
    function GetLast(aIdx: integer = 0): string;
    function Formated(const aFormat: string): TStringList;
    function Intersect(const aSL: TStrings): TStringList;
    function Left(aLen: integer): TStringList;
    function Map(aFunc: TStringMapFunc): TStringList;
    function Merge(const aSL: TStrings): TStringList;
    function Quoted(): TStringList;
    function Quoted(const aChar: char): TStringList;
    function Replace(const aFind, aRep: string): TStringList;
    function Uniq(): TStringList;
  end;

implementation

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

function TStringListHelper.DelEmpty(): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (Self[i].IsEmpty) then
      Delete(i);

  Result := Self;
end;

function TStringListHelper.GetLast(aIdx: integer): string;
begin
  aIdx := Self.Count - 1 - aIdx;
  if (aIdx >= 0) and (aIdx < Self.Count) then
    Result := Self[aIdx]
  else
    Result := '';
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

function TStringListHelper.Quoted(const aChar: char): TStringList;
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

function TStringListHelper.GetArray(): TStringArray;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := 0 to Count - 1 do
    Result[i] := Self[i];
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

function TStringListHelper.Intersect(const aSL: TStrings): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (aSL.IndexOf(Self[i]) = -1) then
      Delete(i);

  Result := self;
end;

function TStringListHelper.Merge(const aSL: TStrings): TStringList;
var
  i: Integer;
begin
  for i := 0 to aSL.Count - 1 do
    if (IndexOf(aSL[i]) = -1) then
      Add(aSL[i]);

  Result := self;
end;

// Map(@LowerCase),
function TStringListHelper.Map(aFunc: TStringMapFunc): TStringList;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Self[i] := aFunc(Self[i]);

  Result := Self;
end;

end.

