// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, IniFiles,
  uUserData;

type
  TSettings = class(TUserData)
  public
    function GetItem(const aSect, aKey: string; aDef: string = ''): string;
    function GetItem(const aSect, aKey: string; aDef: integer = 0): integer;
    procedure SetItem(const aSect, aKey, aValue: string);
    procedure SetItem(const aSect, aKey: string; aValue: integer);
  end;

var
  Settings: TSettings;

implementation

function TSettings.GetItem(const aSect, aKey: string; aDef: integer = 0): integer;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  try
    Result := Ini.ReadInteger(aSect, aKey, aDef);
  finally
    Ini.Free();
  end;
end;

function TSettings.GetItem(const aSect, aKey: string; aDef: string = ''): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  try
    Result := Ini.ReadString(aSect, aKey, aDef);
  finally
    Ini.Free();
  end;
end;

procedure TSettings.SetItem(const aSect, aKey, aValue: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  try
    Ini.WriteString(aSect, aKey, aValue);
  finally
    Ini.Free();
  end;
end;

procedure TSettings.SetItem(const aSect, aKey: string; aValue: integer);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  try
    Ini.WriteInteger(aSect, aKey, aValue);
  finally
    Ini.Free();
  end;
end;

end.

