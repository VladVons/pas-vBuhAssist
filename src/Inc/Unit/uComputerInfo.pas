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
  public
    constructor Create();
    destructor Destroy(); override;
    function GetValue(const WmiClass, WmiField: string): string;
    function GetInfo(): TStringList;
    function GetInfoAsJson(): TJSONObject;
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
  Query: String;
begin
  Result := '';

  Locator := CreateOleObject('WbemScripting.SWbemLocator');
  Services := Locator.ConnectServer(WideString('.'), 'root\CIMV2');
  Query := Format('SELECT %s FROM %s', [WmiField, WmiClass]);
  ObjSet := Services.ExecQuery(Query);
  if (ObjSet.Count > 0) then
  begin
    Obj := ObjSet.ItemIndex(0);
    Result := VarToStr(Obj.Properties_.Item(WmiField).Value);
  end;
end;

function TWMI.GetInfo(): TStringList;
begin
  Result := TStringList.Create();
  Result.NameValueSeparator := '=';

  Result.Values['Processor'] := GetValue('Win32_Processor', 'Name') + ' | ' +
                                GetValue('Win32_Processor', 'NumberOfCores');
  Result.Values['Memory'] := FormatFloat('#,##0 MB', StrToInt64Def(GetValue('Win32_ComputerSystem', 'TotalPhysicalMemory'),0)/1024/1024);
  Result.Values['DiskDrive'] := GetValue('Win32_DiskDrive', 'Model') + ' | '+
                                FormatFloat('#,##0 GB', StrToInt64Def(GetValue('Win32_DiskDrive', 'Size'),0)/1024/1024/1024);
  Result.Values['Video'] := GetValue('Win32_VideoController', 'Name');
  Result.Values['OS'] := GetValue('Win32_OperatingSystem', 'Caption') + ' | ' +
                         GetValue('Win32_OperatingSystem', 'Version') + ' | ' +
                         Copy(GetValue('Win32_OperatingSystem', 'InstallDate'), 1, 8);
  Result.Values['Motherboard'] := GetValue('Win32_ComputerSystemProduct', 'Vendor') + ' | ' +
                                  GetValue('Win32_ComputerSystemProduct', 'Name') + ' | ' +
                                  GetValue('Win32_ComputerSystem', 'Model');
  Result.Values['UUID'] := GetValue('Win32_ComputerSystemProduct', 'UUID');
  Result.Values['System Manufacturer'] := GetValue('Win32_ComputerSystem', 'Manufacturer');
end;

function TWMI.GetInfoAsJson():TJSONObject;
var
  i: Integer;
  SL: TStringList;
begin
  SL := GetInfo();
  try
    Result := TJSONObject.Create();
    for i := 0 to SL.Count - 1 do
      Result.Add(SL.Names[i], SL.ValueFromIndex[i]);
  finally
    SL.Free();
  end;
end;
end.

