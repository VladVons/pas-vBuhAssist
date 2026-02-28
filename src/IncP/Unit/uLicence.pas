// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uUserData, uHttp, uCryptAES, uSys, uConst, uLog, uComputerInfo;

type
  TLicence = class(TUserData)
  private
    fCryptKey, fUUID, fVerBuild: string;
    fJObjLic: TJSONObject;
    function RefreshFromHttp(aFirmCodes: TStrings): TJSONObject;
    function Request(aParam: TJSONObject): TJSONObject;
  public
    LastErr: string;
    constructor Create(const aFile: string);
    destructor Destroy(); override;
    procedure HttpToFileEncrypt(aFirmCodes: TStrings);
    procedure LoadFromFile();
    function GetTypeFromHttp(const aType: string): TJSONObject;
    function GetFirmCodes(const aModule: string): TStringList;
    procedure OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: string);
  end;

var
  Licence: TLicence;

implementation

constructor TLicence.Create(const aFile: string);
var
  WMI: TWMI;
begin
  inherited Create(aFile);

  fCryptKey := 'Vlad1971';
  fJObjLic := Nil;
  fVerBuild := GetAppVer(True);

  WMI := TWMI.Create();
  fUUID := WMI.GetUUID();
  WMI.Free();
end;

destructor TLicence.Destroy();
begin
  FreeAndNil(fJObjLic);
  inherited;
end;

function TLicence.Request(aParam: TJSONObject): TJSONObject;
var
  i: Integer;
  Key: string;
  JReq: TJSONObject;
begin
  JReq := TJSONObject.Create();
  try
    JReq.Add('app', GetAppName());
    JReq.Add('ver', GetAppVer());
    JReq.Add('uuid', fUUID);
    if (Assigned(aParam)) then
       for i := 0 to aParam.Count - 1 do
       begin
         Key := aParam.Names[i];
         if (JReq.IndexOfName(Key) = -1) then
            JReq.Add(Key, aParam.Items[i].Clone);
       end;

    Result := PostJSON(cHttpApi, JReq);
    if (Assigned(Result)) then
      LastErr := Result.Get('error', '')
    else
      LastErr := 'request error';
  finally
    JReq.Free();
  end;
end;

function TLicence.RefreshFromHttp(aFirmCodes: TStrings): TJSONObject;
var
  i: integer;
  JReq: TJSONObject;
  JArrLic: TJSONArray;
begin
  try
    JReq := TJSONObject.Create();
    JReq.Add('type', 'get_licence');

    JArrLic := TJSONArray.Create();
    for i := 0 to aFirmCodes.Count - 1 do
      JArrLic.Add(aFirmCodes[i]);
    JReq.Add('firms', JArrLic);

    Result := Request(JReq);
  finally
    JReq.Free();
  end;
end;

procedure TLicence.OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: string);
var
  i: integer;
  JReq, JRes: TJSONObject;
  JArrLic: TJSONArray;
  WMI: TWMI;
begin
  WMI := TWMI.Create();
  JReq := TJSONObject.Create();
  try
    JReq.Add('type', 'order_licence');
    JReq.Add('module', aModule);
    JReq.Add('user', aDealerName);
    JReq.Add('passw', aDealerPassw);
    JReq.Add('computer', WMI.GetAllAsJson());

    JArrLic := TJSONArray.Create();
    for i := 0 to aFirmCodes.Count - 1 do
      JArrLic.Add(aFirmCodes[i]);
    JReq.Add('firms', JArrLic);

    JRes := Request(JReq);
  finally
    WMI.Free();
    JRes.Free();
    JReq.Free();
    //ArrLic.Free(); already by JsonReq
  end;
end;

function TLicence.GetTypeFromHttp(const aType: string): TJSONObject;
var
  JReq: TJSONObject;
begin
  JReq := TJSONObject.Create();
  try
    JReq.Add('type', aType);
    Result := Request(JReq);
  finally
    JReq.Free();
  end;
end;

procedure TLicence.HttpToFileEncrypt(aFirmCodes: TStrings);
var
  Str, Encrypted: string;
begin
  fJObjLic := RefreshFromHttp(aFirmCodes);
  if (Assigned(fJObjLic)) then
  begin
    Str := fJObjLic.AsJSON;
    Encrypted := StrEncrypt_AES(Str, fCryptKey);
    StrToFile(Encrypted, fFile);
  end;
end;

procedure TLicence.LoadFromFile();
var
  Str, Decrypted: string;
begin
  if (IsFile()) then
  begin
    Str := StrFromFile(fFile);
    Decrypted := StrDecrypt_AES(Str, fCryptKey);

    FreeAndNil(fJObjLic);
    try
      fJObjLic := TJSONObject(GetJSON(Decrypted));
    except on E: Exception do
      Log.Print('x', 'Wrong file type');
    end;
  end;
end;

function TLicence.GetFirmCodes(const aModule: string): TStringList;
var
  i: integer;
  Code, Today, Till: string;
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

