unit uFLicense;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uGenericMatrix, uLicence, uForms;

type

  { TFLicense }

  TFLicense = class(TForm)
    ButtonGetLicense: TButton;
    Panel1: TPanel;
    procedure ButtonGetLicenseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FileLic: String;
    FileLicPassw: String;
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
  if not FileExists(FileLic) then
  begin
      Log('Не знайдено файл ліцензій ' + FileLic);
      Exit;
  end;

  try
    Matrix := MatrixCryptFromFile(FileLic, FileLicPassw);
    if (Matrix.Count = 0) then
    begin
       Log('Немає ліцензій');
       Log('Зверніться в обслуговуючу організацію');
       Exit;
    end;

    for i := 0 to High(Matrix.Matrix) do
    begin
      Lic := 'Ліцензія для ЄДРПУО: ' + Matrix.Cells[i, 0] + ', модуль: ' + Matrix.Cells[i, 1] + ', дійсна до: ' + Matrix.Cells[i, 2];
      Log(Lic);
    end;
  finally
    Matrix.Free();
  end;
end;

procedure TFLicense.FormShow(Sender: TObject);
begin
  LicRead();
end;

procedure TFLicense.FormCreate(Sender: TObject);
begin
   FileLic := 'license.dat';
   FileLicPassw := 'BuhAssist';
end;

procedure TFLicense.ButtonGetLicenseClick(Sender: TObject);
var
  Firms: TStringList;
  Matrix: TStringMatrix;
begin
  try
    Log('Запит на отримання ліцензій відправлено');

    Firms := TStringList.Create();
    Firms.AddStrings(['88888801']);
    Matrix := GetLicence(Firms, 'MedocCheckDoc');
    MatrixCryptToFile(FileLic, FileLicPassw, Matrix);
    LicRead();
  finally
    Matrix.Free();
    Firms.Free();
  end;
end;

end.

