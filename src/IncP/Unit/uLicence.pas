// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uHttp, uCryptAES, uSys, uConst, uLog, uComputerInfo;

type
  TLicence = class
  private
    fFileName: String;
    fCryptKey: String;
    fJObjLic: TJSONObject;
    function GetFromHttp(aFirmCodes: TStrings): TJSONObject;
  public
    LastErr: String;
    constructor Create();
    destructor Destroy(); override;
    procedure HttpToFileEncrypt(aFirmCodes: TStrings);
    procedure LoadFromFile();
    function GetFirmCodes(const aModule: String): TStringList;
    function OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: String): boolean;
    function IsFile(): Boolean;
  end;

var
  Licence: TLicence;

implementation

constructor TLicence.Create();
begin
  fFileName := GetAppFile('app.lic');
  fCryptKey := 'Vlad1971';
  fJObjLic := Nil;
end;

destructor TLicence.Destroy();
begin
  FreeAndNil(fJObjLic);
  inherited;
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
  JReq, JRes: TJSONObject;
  JArrLic: TJSONArray;
  WMI: TWMI;
begin
  WMI := TWMI.Create();
  JReq := TJSONObject.Create();
  try
    JReq.Add('type', 'order_licences');
    JReq.Add('app', 'BuhAssist');
    JReq.Add('module', aModule);
    JReq.Add('user', aDealerName);
    JReq.Add('passw', aDealerPassw);
    JReq.Add('computer', WMI.GetInfoAsJson());

    JArrLic := TJSONArray.Create();
    for i := 0 to aFirmCodes.Count - 1 do
      JArrLic.Add(aFirmCodes[i]);
    JReq.Add('firms', JArrLic);

    JRes := PostJSON(cHttpApi, JReq);
    if (Assigned(JRes)) then
      LastErr := JRes.Get('error', '')
    else
      LastErr := 'request error';
    Result := LastErr.IsEmpty();
  finally
    WMI.Free();
    JRes.Free();
    JReq.Free();
    //ArrLic.Free(); already by JsonReq
  end;
end;

procedure TLicence.HttpToFileEncrypt(aFirmCodes: TStrings);
var
  Str, Encrypted: String;
begin
  fJObjLic := GetFromHttp(aFirmCodes);
  if (Assigned(fJObjLic)) then
  begin
    Str := fJObjLic.AsJSON;
    Encrypted := StrEncrypt_AES(Str, fCryptKey);
    StrToFile(Encrypted, fFileName);
  end;
end;

procedure TLicence.LoadFromFile();
var
  Str, Decrypted: String;
begin
  if (IsFile()) then
  begin
    Str := StrFromFile(fFileName);
    Decrypted := StrDecrypt_AES(Str, fCryptKey);

    FreeAndNil(fJObjLic);
    try
      fJObjLic := TJSONObject(GetJSON(Decrypted));
    except on E: Exception do
      Log.Print('x', 'Wrong file type');
    end;
  end;
end;

function TLicence.IsFile(): Boolean;
begin
  Result := FileExists(fFileName);
end;

function TLicence.GetFirmCodes(const aModule: String): TStringList;
var
  i: Integer;
  Code, Today, Till: String;
  JArr: TJSONArray;
  JObjItem: TJSONObject;
begin
  Result := TStringList.Create();
  if (Assigned(fJObjLic)) and (Assigned(fJObjLic.Find('licences'))) then
  begin
    Today := FormatDateTime('yyyy-mm-dd', Date);
    JArr := fJObjLic.Arrays['licences'];
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

