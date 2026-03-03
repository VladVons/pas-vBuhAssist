// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uDmCommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, SQLDB, DB, Controls, uTextStore,
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
    SQLTransaction: TSQLTransaction;
    TextStoreLicence: TTextStore;
  private
  public
    procedure Connect(const aName: string; aPort: integer);
    function GetTablesMain(): TStringList;
    function Licence_GetFromHttp(): TStringList;
    procedure Licence_OrderToHttp(const aModule: string);
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

  if (aPort > 0) then
  begin
    IBConnection.HostName := 'localhost';
    IBConnection.Port := aPort;
  end else begin
    IBConnection.HostName := '';
    IBConnection.Port := 0;
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
        Log.Print('e', 'Процес занятий іншим користувачем')
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
    //QueryOpen();
    FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
    //Log.Print('i', 'Запит на коди ' + FirmCodes.CommaText)
    Licence.HttpToFileEncrypt(FirmCodes);
    if (Licence.LastErr <> '') then
       Log.Print('e', 'Помилка ' + Licence.LastErr)
    else begin
      FirmCodesLic := Licence.GetFirmCodes('FMedocCheckDocs');
      FirmCodesLic.Delimiter := ',';
      FirmCodesLic.StrictDelimiter := True;
      Result.Assign(FirmCodesLic);
    end;
  finally
    FreeAndNil(FirmCodesLic);
    FirmCodes.Free();
  end;
end;

procedure TDmCommon.Licence_OrderToHttp(const aModule: string);
var
  FirmCodes: TStringList;
begin
  FirmCodes := nil;
  try
    FLogin := TFLogin.Create(nil);
    FLogin.Caption := 'Активація програми';
    FLogin.EditUser.EditLabel.Caption := 'Користувач';
    FLogin.EditPassword.EditLabel.Caption := 'Ключ';
    if (FLogin.ShowModal() = mrOk) then
    begin
      //QueryOpen();
      FirmCodes := GetQueryField(DataSource, SQLQueryCodes, 'EDRPOU');
      //Log.Print('i', 'Запит ліцензій на коди ' + FirmCodes.CommaText);
      Licence.OrderFromHttp(FirmCodes, aModule, FLogin.EditUser.Text, FLogin.EditPassword.Text);
      if (Licence.LastErr.IsEmpty()) then
        Log.Print('i', 'Запит на отримання ліцензій відправлено')
      else
        Log.Print('w', 'Помилка авторизації');
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

