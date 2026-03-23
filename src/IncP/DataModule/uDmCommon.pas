// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uDmCommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, SQLDB, DB, Controls,
  uLicence, uLog, uQuery,
  uFLogin;

type
  { TDmCommon }
  TDmCommon = class(TDataModule)
    DataSource: TDataSource;
    IBConnection: TIBConnection;
    ImageList1: TImageList;
    SQLQueryCodes: TSQLQuery;
    SQLQueryTablesMain: TSQLQuery;
    SQLTransactionDm: TSQLTransaction;
    procedure DataModuleDestroy(Sender: TObject);
  private
  public
    procedure Connect(const aName: string; aPort: integer);
    procedure Close();
    function GetTablesMain(): TStringList;
    function Licence_GetFromHttp(const aModule: string): TStringList;
    procedure Licence_OrderToHttp(const aModule: string; aMaxFree: integer = -1);
  end;

var
  DmCommon: TDmCommon;

implementation

{$R *.lfm}

procedure TDmCommon.Connect(const aName: string; aPort: integer);
begin
  IBConnection.Params.Clear();
  IBConnection.UserName := 'SYSDBA';
  IBConnection.Password := 'masterkey';

  if (aPort = 0) then
  begin
    IBConnection.HostName := '';
    IBConnection.Port := 0;
  end else begin
    IBConnection.HostName := 'localhost';
    IBConnection.Port := aPort;
  end;

  IBConnection.DatabaseName := aName;
  IBConnection.Connected := False;
  try
    IBConnection.Connected := True;
  except
    on E: EDatabaseError do
    begin
      IBConnection.DatabaseName := '';
      if (Pos('used by another', LowerCase(E.Message)) > 0) then
        Log.Print('e', 'Процес занятий іншим користувачем')
      else
        raise;
    end;
  end;
end;

function TDmCommon.Licence_GetFromHttp(const aModule: string): TStringList;
var
  FirmCodes: TStringList;
begin
  Result := TStringList.Create();
  FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
  try
    //Log.Print('i', 'Запит на коди ' + FirmCodes.CommaText)
    Licence.HttpToFileEncrypt(FirmCodes);
    if (Licence.LastErr <> '') then
       Log.Print('e', 'Помилка ' + Licence.LastErr)
    else begin
      Result := Licence.GetFirmCodes(aModule);
      Result.Delimiter := ',';
      Result.StrictDelimiter := True;
    end;
  finally
    FreeAndNil(FirmCodes);
  end;
end;

procedure TDmCommon.Licence_OrderToHttp(const aModule: string; aMaxFree: integer);
var
  FirmCodes: TStringList;
  User, Passw: string;
begin
  FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
  if (aMaxFree <> -1) and (aMaxFree < FirmCodes.Count) then
  begin
    Log.Print('i', Format('В базі більше ніж %d фірма', [aMaxFree]) );
    Exit();
  end;

  Log.Print('i', 'Запит ліцензій для кодів ' + FirmCodes.CommaText);
  if (TFLogin.Execute(User, Passw, 'Активація програми', 'Користувач', 'Ключ')) then
  begin
    Licence.OrderFromHttp(FirmCodes, aModule, User, Passw);
    if (Licence.LastErr.IsEmpty()) then
      Log.Print('i', 'Запит на отримання ліцензій відправлено')
    else
      Log.Print('w', 'Помилка активації: ' + Licence.LastErr);
    FreeAndNil(FirmCodes);
  end;
end;

function TDmCommon.GetTablesMain(): TStringList;
begin
  Result := GetQueryField(DataSource, SQLQueryTablesMain, 'TABLE_NAME');
end;

procedure TDmCommon.Close();
begin
  if (IBConnection.Connected) then
    IBConnection.Connected := False;
end;

procedure TDmCommon.DataModuleDestroy(Sender: TObject);
begin
  Close();
end;

end.

