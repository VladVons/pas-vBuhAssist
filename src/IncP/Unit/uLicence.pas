// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uUserData, uHttp, uCryptAES, uSys, uConst, uLog, uComputerInfo, uHelper;

type
  TLicence = class(TUserData)
  private
    fCryptKey, fUUID, fVerBuild: string;
    fJObjLic: TJSONObject;
    function RefreshFromHttp(aFirmCodes: TStringList): TJSONObject;
    function Request(aParam: TJSONObject): TJSONObject;
  public
    LastErr: string;
    constructor Create(const aFile: string);
    destructor Destroy(); override;
    procedure HttpToFileEncrypt(aFirmCodes: TStringList);
    procedure LoadFromFile();
    function GetTypeFromHttp(const aType: string): TJSONObject;
    function GetFirmCodes(const aModule: string): TStringList;
    function GetLicCount(): integer;
    procedure OrderFromHttp(aFirmCodes: TStringList; const aModule, aDealerName, aDealerPassw: string);
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

function TLicence.GetLicCount(): integer;
begin
  Result := 0;
  if (fJObjLic <> nil) and (fJObjLic.Find('licences') <> nil) then
    Result := fJObjLic.Arrays['licences'].Count;
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
    if (aParam <> nil) then
       for i := 0 to aParam.Count - 1 do
       begin
         Key := aParam.Names[i];
         if (JReq.IndexOfName(Key) = -1) then
            JReq.Add(Key, aParam.Items[i].Clone);
       end;

    Result := PostJSON(cHttpApi, JReq);
    if (Result <> nil) then
      LastErr := Result.Get('error', '')
    else
      LastErr := 'request error';
  finally
    JReq.Free();
  end;
end;

function TLicence.RefreshFromHttp(aFirmCodes: TStringList): TJSONObject;
var
  JReq: TJSONObject;
begin
  try
    JReq := TJSONObject.Create();
    JReq.Add('type', 'get_licence');
    JReq.Add('firms', aFirmCodes.GetJson());
    Result := Request(JReq);
  finally
    JReq.Free();
  end;
end;

procedure TLicence.OrderFromHttp(aFirmCodes: TStringList; const aModule, aDealerName, aDealerPassw: string);
var
  JReq, JRes: TJSONObject;
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
    JReq.Add('firms', aFirmCodes.GetJson());
    JRes := Request(JReq);
  finally
    WMI.Free();
    JRes.Free();
    JReq.Free();
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

procedure TLicence.HttpToFileEncrypt(aFirmCodes: TStringList);
var
  Encrypted, Decrypted: string;
  JObj: TJSONObject;
begin
  JObj := RefreshFromHttp(aFirmCodes);
  if (JObj <> nil) then
  begin
    //// crypt string myself (not secure)
    //Str := JObj.AsJSON;
    //Encrypted := StrEncrypt_AES(Str, fCryptKey);
    //StrToFile(Encrypted, fFile);
    //fJObjLic := JObj;

    // get already encrypted data (more secure)
    Encrypted := JObj.get('licences', '');
    Decrypted := StrDecrypt_AES(Encrypted, fCryptKey);

    fJObjLic := TJSONObject(GetJSON(Decrypted));
    if (GetLicCount() > 0) then
      StrToFile(Encrypted, fFile);
      //StrToFile(Decrypted, fFile);
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
  if (GetLicCount() = 0) then
     Exit();

  Today := FormatDateTime('yyyy-mm-dd', Date);
  JArr := fJObjLic.Arrays['licences'];
  for i := 0 to JArr.Count - 1 do
  begin
    JObjItem := JArr.Objects[i];
    Till := JObjItem.Get('till', '');
    if (JObjItem.Get('module', '') = aModule) and (Today <= Till) then
    begin
      Code := JObjItem.Get('firm', '');
      //Result.Add(Code);
      Result.Values[Code] := Till;
    end;
  end;
end;

end.

