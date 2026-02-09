unit uWinReg;

{$mode ObjFPC}{$H+}

interface

uses
  Registry, SysUtils, Classes, Windows,
  uGenericMatrix;

function FindMedocDB(): TStringList;

implementation

function FindMedocDB(): TStringList;
var
  Reg: TRegistry;
  Keys: TStringList;
  i: Integer;
  FileDb, Port: string;
begin
  Result := TStringList.Create();

  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService') then
    begin
      Reg.GetKeyNames(Keys);
      Reg.CloseKey();

      for i := 0 to Keys.Count - 1 do
      begin
        if Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService\' + Keys[i]) then
        begin
          if Reg.ValueExists('APPDATA') then
          begin
            FileDb := Reg.ReadString('APPDATA') + '/db/zvit.fdb';
            if FileExists(FileDb) then
               //Reg.ReadString('fbPort');
               Result.Add(FileDb);
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

