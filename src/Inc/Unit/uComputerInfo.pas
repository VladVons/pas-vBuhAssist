// Created: 2026.02.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uComputerInfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, ActiveX, ComObj, Variants;

type
  TWMI = class
  private
    function GetValue(const WmiClass, WmiField: string): string;
  public
    constructor Create();
    destructor Destroy(); override;
    function GetAll(): TStringList;
    function GetAllAsJson(): TJSONObject;
    function GetCPU(): string;
    function GetRAM(): string;
    function GetDisk(): string;
    function GetName(): string;
    function GetOS(): string;
    function GetUUID(): string;
  end;

implementation

constructor TWMI.Create();
begin
  CoInitialize(nil);
end;

destructor TWMI.Destroy();
begin
  CoUninitialize();
end;

function TWMI.GetValue(const WmiClass, WmiField: string): string;
var
  Locator, Services, ObjSet, Obj: Variant;
  Query: string;
begin
  Result := '';

  Locator := CreateOleObject('WbemScripting.SWbemLocator');
  Services := Locator.ConnectServer(WideString('.'), 'root\CIMV2');
  Query := Format('SELECT %s FROM %s', [WmiField, WmiClass]);
  ObjSet := Services.ExecQuery(Query);
  if (ObjSet.Count > 0) then
  begin
    Obj := ObjSet.ItemIndex(0);
    Result := Trim(VarToStr(Obj.Properties_.Item(WmiField).Value));
  end;
end;

function TWMI.GetName(): string;
begin
  Result := GetValue('Win32_ComputerSystem', 'Name');
end;

function TWMI.GetUUID(): string;
begin
  Result := GetValue('Win32_ComputerSystemProduct', 'UUID');
end;

function TWMI.GetOS(): string;
begin
  Result := GetValue('Win32_OperatingSystem', 'Caption') + ' | ' +
            GetValue('Win32_OperatingSystem', 'Version') + ' | ' +
            Copy(GetValue('Win32_OperatingSystem', 'InstallDate'), 1, 8);
end;

function TWMI.GetCPU(): string;
begin
  Result := GetValue('Win32_Processor', 'Name') + ' | ' +
            GetValue('Win32_Processor', 'NumberOfCores');
end;

function TWMI.GetRAM(): string;
begin
  Result := FormatFloat('#,##0 MB', StrToInt64Def(GetValue('Win32_ComputerSystem', 'TotalPhysicalMemory'),0)/1024/1024);
end;

function TWMI.GetDisk(): string;
begin
  Result := GetValue('Win32_DiskDrive', 'Model') + ' | '+
            FormatFloat('#,##0 GB', StrToInt64Def(GetValue('Win32_DiskDrive', 'Size'),0)/1024/1024/1024);
end;

function TWMI.GetAll(): TStringList;
begin
  Result := TStringList.Create();
  Result.NameValueSeparator := '=';

  Result.Values['Name'] := GetName();
  Result.Values['OS'] := GetOS();
  Result.Values['CPU'] := GetCPU();
  Result.Values['RAM'] := GetRAM();
  Result.Values['Disk'] := GetDisk();
end;

function TWMI.GetAllAsJson():TJSONObject;
var
  i: integer;
  SL: TStringList;
begin
  SL := GetAll();
  try
    Result := TJSONObject.Create();
    for i := 0 to SL.Count - 1 do
      Result.Add(SL.Names[i], SL.ValueFromIndex[i]);
  finally
    SL.Free();
  end;
end;

end.

