// Created: 2026.03.08
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSysVcl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils, StrUtils, FileInfo, Process, LR_Class;

procedure ResourceLoadReport(const aName: string; aReport: TfrReport);
function ResourceLoadString(const aName: string; aEncoding: TEncoding = Nil): string;

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
  RS: TResourceStream;
  SS: TStringStream;
begin
  if (aEncoding = Nil) then
    aEncoding := TEncoding.GetEncoding(1251);
  SS := TStringStream.Create('', aEncoding);

  RS := TResourceStream.Create(HInstance, aName, RT_RCDATA);
  try
    SS.CopyFrom(RS, RS.Size);
    SS.Position := 0;
    Result := SS.DataString;
  finally
    RS.Free();
    SS.Free();
  end;
end;

function TestPas(): string;
var
  i: integer;
begin
  for i := 1 to 10 do
      WriteLn(i);
end;

initialization
  //SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

end.

