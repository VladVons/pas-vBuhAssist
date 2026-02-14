// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFLicense;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uGenericMatrix, uLicence, uLog, uConst;

type

  { TFLicense }

  TFLicense = class(TForm)
  private
    procedure LicRead();
  public
  end;

var
  FLicense: TFLicense;

implementation

{$R *.lfm}

procedure TFLicense.LicRead();
var
  i: Integer;
  Lic: String;
  Matrix: TStringMatrix;
begin
  if not FileExists(cFileLic) then
  begin
      Log.Print('Не знайдено файл ліцензій ' + cFileLic);
      Exit;
  end;

  try
    Matrix := MatrixCryptFromFile(cFileLic, cFileLicPassw);
    if (Matrix.Count = 0) then
    begin
       Log.Print('Немає ліцензій');
       Log.Print('Зверніться в обслуговуючу організацію');
       Exit;
    end;

    for i := 0 to High(Matrix.Matrix) do
    begin
      Lic := 'Ліцензія для ЄДРПУО: ' + Matrix.Cells[i, 0] + ', модуль: ' + Matrix.Cells[i, 1] + ', дійсна до: ' + Matrix.Cells[i, 2];
      Log.Print(Lic);
    end;
  finally
    Matrix.Free();
  end;
end;


end.

