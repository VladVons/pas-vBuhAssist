unit uDmFbConnect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, SQLDB, DB;

type

  { TConnect }

  TDmFbConnect = class(TDataModule)
    DataSource1: TDataSource;
    IBConnection1: TIBConnection;
    SQLTransaction1: TSQLTransaction;
  private

  public

  end;

var
  DmFbConnect: TDmFbConnect;

implementation

{$R *.lfm}

end.

