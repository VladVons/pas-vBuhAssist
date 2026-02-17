// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uHttp, uCrypt, uSys, uConst;

type
  TLicence = class
  private
    FileName: String;
    CryptKey: String;
    JObjLic: TJSONObject;
    function GetFromHttp(aFirmCodes: TStrings): TJSONObject;
  public
    LastErr: String;
    constructor Create();
    procedure HttpToFile(aFirmCodes: TStrings);
    procedure LoadFromFile();
    function GetFirmCodes(const aModule: String): TStringList;
    function OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: String): boolean;
  end;

var
  Licence: TLicence;

implementation

constructor TLicence.Create();
begin
  FileName := GetAppFile('app.lic');
  CryptKey := 'Vlad1971';
end;

function TLicence.GetFromHttp(aFirmCodes: TStrings): TJSONObject;
var
  i: Integer;
  JReq: TJSONObject;
  JArrLic: TJSONArray;
begin
  try
    JReq := TJSONObject.Create();
    JReq.Add('type', 'get_licences');
    JReq.Add('app', GetAppName());

    JArrLic := TJSONArray.Create();
    for i := 0 to aFirmCodes.Count - 1 do
      JArrLic.Add(aFirmCodes[i]);
    JReq.Add('firms', JArrLic);

    Result := PostJSON(cHttpApi, JReq);
    if (Assigned(Result)) then
      LastErr := Result.Get('error', '')
    else
      LastErr := 'request error';
  finally
    JReq.Free();
  end;
end;

function TLicence.OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: String): boolean;
var
  i: Integer;
  JsonReq, JsonRes: TJSONObject;
  ArrLic: TJSONArray;
begin
  try
    JsonReq := TJSONObject.Create();
    JsonReq.Add('type', 'order_licences');
    JsonReq.Add('app', 'BuhAssist');
    JsonReq.Add('module', aModule);
    JsonReq.Add('user', aDealerName);
    JsonReq.Add('passw', aDealerPassw);

    ArrLic := TJSONArray.Create();
    for i := 0 to aFirmCodes.Count - 1 do
      ArrLic.Add(aFirmCodes[i]);
    JsonReq.Add('firms', ArrLic);

    JsonRes := PostJSON(cHttpApi, JsonReq);
    if (Assigned(JsonRes)) then
      LastErr := JsonRes.Get('error', '')
    else
      LastErr := 'request error';
    Result := LastErr.IsEmpty();
  finally
    JsonRes.Free();
    JsonReq.Free();
    //ArrLic.Free(); already by JsonReq
  end;
end;

procedure TLicence.HttpToFile(aFirmCodes: TStrings);
var
  Encrypted: String;
begin
  JObjLic := GetFromHttp(aFirmCodes);
  if (Assigned(JObjLic)) then
  begin
    Encrypted := JsonEncrypt(JObjLic, CryptKey);
    StrToFile(Encrypted, FileName);
  end;
end;

procedure TLicence.LoadFromFile();
var
  Decrypted: String;
begin
  if (FileExists(FileName)) then
  begin
    Decrypted := StrFromFile(FileName);
    JObjLic := JsonDecrypt(Decrypted, CryptKey);
  end;
end;

function TLicence.GetFirmCodes(const aModule: String): TStringList;
var
  i: Integer;
  Code, Today, Till: String;
  JArr: TJSONArray;
  JObjItem: TJSONObject;
begin
  Result := TStringList.Create();
  if (Assigned(JObjLic)) and (Assigned(JObjLic.Find('licences'))) then
  begin
    Today := FormatDateTime('yyyy-mm-dd', Date);
    JArr := JObjLic.Arrays['licences'];
    for i := 0 to JArr.Count - 1 do
    begin
      JObjItem := JArr.Objects[i];
      Till := JObjItem.Get('till', '');
      if (JObjItem.Get('module', '') = aModule) and (Today <= Till) then
      begin
        Code := JObjItem.Get('firm', '');
        Result.Add(Code);
      end;
    end;
  end;
end;

end.

