// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, IniFiles,
  uSys;

const
  cConfFile = 'app.ini';

function ConfKeyRead(const aSect, aItem: string): string;
procedure ConfKeyWrite(const aSect, aItem, aValue: string);


implementation

function ConfKeyRead(const aSect, aItem: string): string;
var
  Ini: TIniFile;
  ConfFile: String;
begin
  ConfFile := GetAppFile(cConfFile);
  Ini := TIniFile.Create(ConfFile);
  try
    Result := Ini.ReadString(aSect, aItem, '');
  finally
    Ini.Free();
  end;
end;

procedure ConfKeyWrite(const aSect, aItem, aValue: string);
var
  Ini: TIniFile;
  ConfFile: String;
begin
  ConfFile := GetAppFile(cConfFile);
  Ini := TIniFile.Create(ConfFile);
  try
    Ini.WriteString(aSect, aItem, aValue);
  finally
    Ini.Free();
  end;
end;

end.

