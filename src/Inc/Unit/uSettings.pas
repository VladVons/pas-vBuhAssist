// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, IniFiles,
  uSys;

type
  TConf = class
  private
    FileConf: string;
  public
    constructor Create();
    function KeyRead(const aSect, aItem: string): string;
    procedure KeyWrite(const aSect, aItem, aValue: string);
  end;

var
  Conf: TConf;

implementation

constructor TConf.Create();
begin
  FileConf := GetAppFile('app.ini');
end;

function TConf.KeyRead(const aSect, aItem: string): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileConf);
  try
    Result := Ini.ReadString(aSect, aItem, '');
  finally
    Ini.Free();
  end;
end;

procedure TConf.KeyWrite(const aSect, aItem, aValue: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileConf);
  try
    Ini.WriteString(aSect, aItem, aValue);
  finally
    Ini.Free();
  end;
end;

end.

