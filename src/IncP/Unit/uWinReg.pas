// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWinReg;

{$mode ObjFPC}{$H+}

interface

uses
  Registry, SysUtils, Classes, Windows, fpjson, jsonparser;

function RegFindMedocInfo(): TJSONArray;


implementation


function RegGetMedocInfo(aKey: HKEY; aJArray: TJSONArray): Integer;
var
  i: Integer;
  StrDB: string;
  Obj: TJSONObject;
  Reg: TRegistry;
  Keys: TStringList;
begin
  Result := 0;
  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create();
  try
    Reg.RootKey := aKey;
    if Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService') then
    begin
      Reg.GetKeyNames(Keys);
      Reg.CloseKey();

      for i := 0 to Keys.Count - 1 do
      begin
        if (Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService\' + Keys[i])) then
        begin
          if (Reg.ValueExists('APPDATA')) then
          begin
            StrDB := Reg.ReadString('APPDATA') + '\db\zvit.fdb';
            if (FileExists(StrDB)) then
            begin
               Obj := TJSONObject.Create();
               Obj.Add('db', StrDB);
               Obj.Add('path', Reg.ReadString('PATH'));
               Obj.Add('port', StrToIntDef(Reg.ReadString('fbPort'), 0));
               aJArray.Add(Obj);
               inc(Result);
            end;
          end;
          Reg.CloseKey();
        end;
      end;
    end;
  finally
    Keys.Free();
    Reg.Free();
  end;
end;

function RegFindMedocInfo(): TJSONArray;
begin
  Result := TJSONArray.Create();
  RegGetMedocInfo(HKEY_LOCAL_MACHINE, Result);
  RegGetMedocInfo(HKEY_CURRENT_USER, Result);
end;

end.

