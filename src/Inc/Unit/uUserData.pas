// Created: 2026.02.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uUserData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TUserData = class
  private
    function GetAppFile(const aFile: string): String;
    function GetFileName(): string;
  protected
    fFile: string;
  public
    function IsFile(): boolean;
    constructor Create(const aFile: string);
    property FileName: String read GetFileName;
  end;

implementation

constructor TUserData.Create(const aFile: string);
begin
  fFile := GetAppFile(aFile);
end;

function TUserData.GetFileName(): string;
begin
  Result := fFile;
end;

function TUserData.IsFile(): boolean;
begin
  Result := FileExists(fFile);
end;

function TUserData.GetAppFile(const aFile: string): String;
var
  Dir: string;
begin
  Dir := GetAppConfigDir(False);
  if (not DirectoryExists(Dir)) then
     ForceDirectories(Dir);

  Result := ConcatPaths([Dir, aFile]);
end;

end.

