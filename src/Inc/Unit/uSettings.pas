// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles,
  uUserData;

type
  TSettings = class(TUserData)
  public
    procedure DelItem(const aSect, aKey: string);
    function GetItem(const aSect, aKey: string; aDef: string = ''): string;
    function GetItem(const aSect, aKey: string; aDef: integer = 0): integer;
    procedure SetItem(const aSect, aKey, aValue: string);
    procedure SetItem(const aSect, aKey: string; aValue: integer);
    function GetSection(const aSect: string): TStringList;
    function GetSections(): TStringList;
  end;

var
  Settings: TSettings;

implementation

procedure TSettings.DelItem(const aSect, aKey: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  Ini.DeleteKey(aSect, aKey);
  Ini.Free();
end;

function TSettings.GetItem(const aSect, aKey: string; aDef: integer = 0): integer;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  Result := Ini.ReadInteger(aSect, aKey, aDef);
  Ini.Free();
end;

function TSettings.GetItem(const aSect, aKey: string; aDef: string = ''): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  Result := Ini.ReadString(aSect, aKey, aDef);
  Ini.Free();
end;

procedure TSettings.SetItem(const aSect, aKey, aValue: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  Ini.WriteString(aSect, aKey, aValue);
  Ini.Free();
end;

procedure TSettings.SetItem(const aSect, aKey: string; aValue: integer);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  Ini.WriteInteger(aSect, aKey, aValue);
  Ini.Free();
end;

function TSettings.GetSections(): TStringList;
var
  Ini: TIniFile;
begin
  Result := TStringList.Create();
  Ini := TIniFile.Create(fFile);
  Ini.ReadSections(Result);
  Ini.Free();
end;

function TSettings.GetSection(const aSect: string): TStringList;
var
  Ini: TIniFile;
begin
  Result := TStringList.Create();
  Ini := TIniFile.Create(fFile);
  Ini.ReadSection(aSect, Result);
  Ini.Free();
end;

end.

