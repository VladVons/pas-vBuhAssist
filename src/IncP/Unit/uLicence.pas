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
    fCryptKey: string;
    fJObjLic: TJSONObject;
    function GetFromHttp(aFirmCodes: TStrings): TJSONObject;
  public
    LastErr: string;
    constructor Create(const aFile: string);
    destructor Destroy(); override;
    procedure HttpToFileEncrypt(aFirmCodes: TStrings);
    procedure LoadFromFile();
    function GetFirmCodes(const aModule: string): TStringList;
    function OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: string): boolean;
    function IsFile(): boolean;
  end;

var
  Licence: TLicence;

implementation

constructor TLicence.Create(const aFile: string);
begin
  inherited Create(aFile);

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
  i: integer;
  JReq: TJSONObject;
  JArrLic: TJSONArray;
begin
  try
    JReq := TJSONObject.Create();
    JReq.Add('type', 'get_licences');
    JReq.Add('app', GetAppName());
    JReq.Add('ver', GetAppVer());

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

function TLicence.OrderFromHttp(aFirmCodes: TStrings; const aModule, aDealerName, aDealerPassw: string): boolean;
var
  i: integer;
  JReq, JRes: TJSONObject;
  JArrLic: TJSONArray;
  WMI: TWMI;
begin
  WMI := TWMI.Create();
  JReq := TJSONObject.Create();
  try
    JReq.Add('type', 'order_licences');
    JReq.Add('app', GetAppName());
    JReq.Add('ver', GetAppVer());
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
  Str, Encrypted: string;
begin
  fJObjLic := GetFromHttp(aFirmCodes);
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

function TLicence.IsFile(): boolean;
begin
  Result := FileExists(fFile);
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

