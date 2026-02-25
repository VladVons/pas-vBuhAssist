// Created: 2026.02.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uUserData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  uSys;

type
  TUserData = class
  protected
    fFile: string;
  public
    function IsFile(): boolean;
    constructor Create(const aFile: string);
  end;

implementation

constructor TUserData.Create(const aFile: string);
begin
  fFile := GetAppFile(aFile);
end;

function TUserData.IsFile(): boolean;
begin
  Result := FileExists(fFile);
end;

end.

