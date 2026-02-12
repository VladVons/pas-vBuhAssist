unit uWinReg;

{$mode ObjFPC}{$H+}

interface

uses
  Registry, SysUtils, Classes, Windows, fpjson, jsonparser;

function GetMedocInfoFromReg(): TJSONArray;

implementation


function GetMedocInfoFromReg(): TJSONArray;
var
  Obj: TJSONObject;
  Reg: TRegistry;
  Keys: TStringList;
  i: Integer;
  StrDB: string;
begin
  Result := TJSONArray.Create();

  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create();
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
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
               Result.Add(Obj);
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



end.

