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
    SQLQueryCodes: TSQLQuery;
    SQLQueryTablesMain: TSQLQuery;
    SQLTransaction: TSQLTransaction;
  private
  public
    procedure Connect(const aName: String; aPort: Integer);
    function GetTablesMain(): TStringList;
    function Licence_GetFromHttp(): TStringList;
    procedure Licence_OrderToHttp();
  end;

var
  DmCommon: TDmCommon;

implementation

{$R *.lfm}

procedure TDmCommon.Connect(const aName: String; aPort: Integer);
begin
  IBConnection.Params.Clear();
  IBConnection.UserName := 'SYSDBA';
  IBConnection.Password := 'masterkey';

  if (aPort > 0) then
  begin
    IBConnection.HostName := 'localhost';
    IBConnection.Port := aPort;
  end else begin
    IBConnection.Params.Add('embedded=true');
  end;

  IBConnection.DatabaseName := aName;
  try
    IBConnection.Connected := False;
    IBConnection.Connected := True;
  except
    on E: EDatabaseError do
    begin
      IBConnection.DatabaseName := '';
      if Pos('used by another', LowerCase(E.Message)) > 0 then
        Log.Print('Процес занятий іншим користувачем')
      else
        raise;
    end;
  end;
end;

function TDmCommon.Licence_GetFromHttp(): TStringList;
var
  FirmCodes, FirmCodesLic: TStringList;
begin
  Result := TStringList.Create();
  try
    Log.Print('Завантаження ліцензій ...');
    //QueryOpen();
    FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
    Licence.HttpToFile(FirmCodes);
    if (Licence.LastErr <> '') then
       Log.Print('Помилка ' + Licence.LastErr)
    else begin
      FirmCodesLic := Licence.GetFirmCodes('FMedocCheckDocs');
      FirmCodesLic.Delimiter := ',';
      FirmCodesLic.StrictDelimiter := True;
      Log.Print('Знайдено ліцензії для кодів ' + FirmCodesLic.DelimitedText);
      Result.Assign(FirmCodesLic);
    end;
  finally
    FreeAndNil(FirmCodesLic);
    FirmCodes.Free();
  end;
end;

procedure TDmCommon.Licence_OrderToHttp();
var
  AuthOk: boolean;
  FirmCodes: TStringList;
begin
  FirmCodes := nil;
  try
    FLogin := TFLogin.Create(nil);
    FLogin.Caption := 'Активація програми';
    FLogin.EditUser.EditLabel.Caption := 'Дилер';
    FLogin.EditPassword.EditLabel.Caption := 'Ключ';
    if (FLogin.ShowModal = mrOk) then
    begin
      //QueryOpen();
      FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
      AuthOk := Licence.OrderFromHttp(FirmCodes, Name, FLogin.EditUser.Text, FLogin.EditPassword.Text);
      if (AuthOk) then
        Log.Print('Запит на отримання ліцензій відправлено')
      else
        Log.Print('Помилка авторизації на сервері ліцензій');
    end;
  finally
    FreeAndNil(FirmCodes);
    FreeAndNil(FLogin);
  end;
end;

function TDmCommon.GetTablesMain(): TStringList;
begin
  Result := GetQueryField(DataSource, SQLQueryTablesMain, 'TABLE_NAME');
end;

end.

