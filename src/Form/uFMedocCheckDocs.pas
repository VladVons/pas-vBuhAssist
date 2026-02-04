unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids,
  uDmFbConnect;

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
begin
  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;
  //SQLQuery1.SQL.Text := 'SELECT EDRPOU, SHORTNAME, INDTAXNUM, DEPT FROM ORG';

  DmFbConnect.DataSource1.DataSet := SQLQuery1;
  DBGrid1.DataSource := DmFbConnect.DataSource1;

  SQLQuery1.Open();
end;

end.

