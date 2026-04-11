// Created: 2026.03.08
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSysVcl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils, Forms, Controls, TypInfo, LR_Class, LazUTF8, fpjson, jsonparser,
  uSys, uHelper;

procedure ResourceLoadReport(const aName: string; aReport: TfrReport);
function ResourceLoadString(const aName: string; aEncoding: TEncoding = Nil): string;
function ResourceLoadString(const aName, aExt: string; aEncoding: TEncoding = Nil): string;
function ResourceLoadJson(const aName: string): TJSONData;
function LatinToUkr(const aStr: string): string;
function RemoveChars(const aStr, aRemove: string): string;
procedure Working(aState: boolean);

implementation

function GetResPath(const aName, aExt: string): string;
begin
  Result := ConcatPaths(['res', aExt, aName + '.' + aExt]);
end;

procedure ResourceLoadReport(const aName: string; aReport: TfrReport);
var
  RS: TResourceStream;
begin
  RS := TResourceStream.Create(HInstance, aName, RT_RCDATA);
  try
    aReport.LoadFromXMLStream(RS);
  finally
    RS.Free();
  end;
end;

function ResourceLoadString(const aName: string; aEncoding: TEncoding): string;
var
  RStream: TResourceStream;
  SStream: TStringStream;
begin
  if (aEncoding = Nil) then
    aEncoding := TEncoding.UTF8;
  SStream := TStringStream.Create('', aEncoding);
  
  RStream := TResourceStream.Create(HInstance, aName, RT_RCDATA);
  try
    SStream.CopyFrom(RStream, RStream.Size);
    SStream.Position := 0;
    Result := SStream.DataString;
  finally
    RStream.Free();
    SStream.Free();
  end;
end;

function ResourceLoadString(const aName, aExt: string; aEncoding: TEncoding): string;
var
  Path: string;
begin
  Path := GetResPath(aName, aExt);
  if (Path.FileExists()) then
    Result := StrFromFile(Path)
  else
    Result := ResourceLoadString(aExt + '_' + aName, aEncoding);
end;

function ResourceLoadJson(const aName: string): TJSONData;
const
  cExt = 'json';
var
  Str, Path: string;
begin
  Path := GetResPath(aName, cExt);
  if (Path.FileExists()) then
    Result := FileLoadJson(Path)
  else begin
    Str := ResourceLoadString(cExt + '_' + aName);
    Result := GetJSON(Str.DelBOM());
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
  if (UTF8Length(StrIn) <> UTF8Length(StrOut)) then
    Exit();

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

function RemoveChars(const aStr, aRemove: string): string;
var
  i: integer;
  Str: string;
begin
  Result := '';
  for i := 1 to UTF8Length(aStr) do
  begin
    Str := UTF8Copy(aStr, i, 1);
    if (Pos(Str, aRemove) = 0) then
      Result := Result + Str;
  end;
end;

procedure Working(aState: boolean);
begin
  if (aState) then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

end.

