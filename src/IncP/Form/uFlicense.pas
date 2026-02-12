unit uFLicense;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uGenericMatrix, uLicence, uLog, uConst;

type

  { TFLicense }

  TFLicense = class(TForm)
    ButtonGetLicense: TButton;
    LabeledEditActivationCode: TLabeledEdit;
    Panel1: TPanel;
    procedure ButtonGetLicenseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
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

procedure TFLicense.FormShow(Sender: TObject);
begin
  LicRead();
end;

procedure TFLicense.ButtonGetLicenseClick(Sender: TObject);
var
  Firms: TStringList;
  Matrix: TStringMatrix;
begin
  try
    Log.Print('Запит на отримання ліцензій відправлено');

    Firms := TStringList.Create();
    Firms.AddStrings(['88888801']);
    Matrix := GetLicenceFromHttp(Firms, 'MedocCheckDoc', '');
    MatrixCryptToFile(cFileLic, cFileLicPassw, Matrix);
    LicRead();
  finally
    Matrix.Free();
    Firms.Free();
  end;
end;

end.

