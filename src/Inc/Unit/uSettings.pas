// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, IniFiles;

function ConfReadKey(const aSect, aItem: string): string;
procedure ConfWriteKey(const aSect, aItem, aValue: string);


implementation

function ConfReadKey(const aSect, aItem: string): string;
var
  Ini: TIniFile;
  ConfFile: String;
begin
  ConfFile := GetAppConfigFile(False);
  Ini := TIniFile.Create(ConfFile);
  try
    Result := Ini.ReadString(aSect, aItem, '');
  finally
    Ini.Free();
  end;
end;

procedure ConfWriteKey(const aSect, aItem, aValue: string);
var
  Ini: TIniFile;
  ConfFile: String;
begin
  ConfFile := GetAppConfigFile(False);
  Ini := TIniFile.Create(ConfFile);
  try
    Ini.WriteString(aSect, aItem, aValue);
  finally
    Ini.Free();
  end;
end;

end.

