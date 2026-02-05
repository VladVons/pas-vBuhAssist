unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids,
  uDmFbConnect, uLicence, uMatrix, uType;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
    DBGrid1: TDBGrid;
    SQLQuery1: TSQLQuery;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FMedocCheckDocs: TFMedocCheckDocs;

implementation

{$R *.lfm}

{ TFMedocCheckDocs }

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  Firms: TStringList;
  MatrixString, MatrixString2: TMatrixString;
begin
  MatrixString := [
    ['one', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'],
    ['two', '1111111111111111111111111111111'],
    ['three', 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz']
  ];
  MatrixCryptToFile('lic.dat', '123', MatrixString);
  MatrixString2 := MatrixCryptFromFile('lic.dat', '123');

  Firms := TStringList.Create();
  Firms.AddStrings(['88888801']);
  GetLicence(Firms);


  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;
  //SQLQuery1.SQL.Text := 'SELECT EDRPOU, SHORTNAME, INDTAXNUM, DEPT FROM ORG';

  DmFbConnect.DataSource1.DataSet := SQLQuery1;
  DBGrid1.DataSource := DmFbConnect.DataSource1;

  SQLQuery1.Open();
end;

end.

