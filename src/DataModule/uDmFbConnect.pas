unit uDmFbConnect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, SQLDB, DB;

type

  { TConnect }

  { TDmFbConnect }

  TDmFbConnect = class(TDataModule)
    DataSource1: TDataSource;
    IBConnection1: TIBConnection;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  private

  public

  end;

var
  DmFbConnect: TDmFbConnect;

implementation

{$R *.lfm}

{ TDmFbConnect }

procedure TDmFbConnect.DataModuleCreate(Sender: TObject);
begin
  IBConnection1.HostName := 'localhost';
  //IBConnection1.DatabaseName := 'C:\ProgramData\Medoc\Medoc\db\ZVIT.FDB';
  IBConnection1.DatabaseName := '/var/lib/firebird/3.0/data/ZVIT.FDB';
  IBConnection1.UserName := 'SYSDBA';
  IBConnection1.Password := 'masterkey';
  IBConnection1.CharSet := 'UTF8';
  IBConnection1.Transaction := SQLTransaction1;
  IBConnection1.Connected := True;
end;

end.

