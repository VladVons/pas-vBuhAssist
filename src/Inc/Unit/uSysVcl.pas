// Created: 2026.03.08
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSysVcl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils, LR_Class, LazUTF8, fpjson, jsonparser,
  uSys, uHelper;

procedure ResourceLoadReport(const aName: string; aReport: TfrReport);
function ResourceLoadString(const aName: string; aEncoding: TEncoding = Nil): string;
function ResourceLoadJson(const aName: string): TJSONObject;
function LatinToUkr(const aStr: string): string;
function RemoveChars(const aStr, aRemove: string): string;

implementation

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

function ResourceLoadString(const aName: string; aEncoding: TEncoding = Nil): string;
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

function ResourceLoadJson(const aName: string): TJSONObject;
var
  Str, Path: string;
  Raw: RawByteString;
  Parser: TJSONParser;
  JD: TJSONData;
begin
  Path := ConcatPaths(['Res', 'Json', aName + '.json']);
  if (FileExists(Path)) then
    Result := TJSONObject(FileLoadJson(Path))
  else begin
    Path := 'Json_' + aName;
    Str := ResourceLoadString(Path);
    Result := TJSONObject(GetJSON(Str.DelBOM()));
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

initialization
  //SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

end.

