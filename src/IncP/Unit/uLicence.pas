// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uHttp, uGenericMatrix, uSys, uConst;

  function GetLicenceFromHttp(aFirms: TStrings; const aModule: String): TJSONObject;
  function OrderLicenceFromHttp(aFirms: TStrings; const aModule, aDealerName, aDealerPassw: String): boolean;
  procedure GetLicenceFromHttpToFile(const aModule: string; aFirms: TStringList);
  procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TStringMatrix);
  function MatrixCryptFromFile(const aFileName, aPassword: string): TStringMatrix;

implementation

type
THash256 = array[0..31] of Byte;

function GetLicenceFromHttp(aFirms: TStrings; const aModule: String): TJSONObject;
var
  i: Integer;
  JReq, JResp: TJSONObject;
  JArrLic: TJSONArray;
begin
  try
    JResp := TJSONObject.Create();

    JReq := TJSONObject.Create();
    JReq.Add('type', 'get_licenses');
    JReq.Add('app', GetAppName());
    JReq.Add('module', aModule);

    JArrLic := TJSONArray.Create();
    for i := 0 to aFirms.Count - 1 do
      JArrLic.Add(aFirms[i]);
    JReq.Add('firms', JArrLic);

    JResp := PostJSON('https://windows.cloud-server.com.ua/api', JReq);
    if (JResp.Find('error') = nil) then
       Result := JResp;
  finally
    JReq.Free();
    JResp.Free();
    //ArrLic.Free();
  end;
end;

function OrderLicenceFromHttp(aFirms: TStrings; const aModule, aDealerName, aDealerPassw: String): boolean;
var
  i: Integer;
  Err: string;
  JsonReq, JsonRes: TJSONObject;
  ArrLic: TJSONArray;
begin
  try
    JsonReq := TJSONObject.Create();
    JsonReq.Add('type', 'order_licenses');
    JsonReq.Add('app', 'BuhAssist');
    JsonReq.Add('module', aModule);
    JsonReq.Add('user', aDealerName);
    JsonReq.Add('passw', aDealerPassw);

    ArrLic := TJSONArray.Create();
    for i := 0 to aFirms.Count - 1 do
      ArrLic.Add(aFirms[i]);
    JsonReq.Add('firms', ArrLic);

    JsonRes := PostJSON('https://windows.cloud-server.com.ua/api', JsonReq);
    if Assigned(JsonRes) then
      Err := JsonRes.Get('error', '')
    else
      Err := 'Request error';
    Result := Err.IsEmpty();
  finally
    JsonRes.Free();
    JsonReq.Free();
    //ArrLic.Free(); already by JsonReq
  end;
end;


procedure GetLicenceFromHttpToFile(const aModule: string; aFirms: TStringList);
var
  JObj: TJSONObject;
begin
  try
    JObj := GetLicenceFromHttp(aFirms, aModule);
    //MatrixCryptToFile(cFileLic, cFileLicPassw, Matrix);
  finally
    JObj.Free();
  end;
end;


function SimpleHash256(const aString: string): THash256;
var
  i, j: Integer;
  h: QWord;
begin
  h := $CBF29CE484222325;
  for i := 1 to Length(aString) do
    h := (h xor Ord(aString[i])) * $100000001B3;

  for j := 0 to 31 do
  begin
    h := h xor (h shr 33);
    h := h * $FF51AFD7ED558CCD;
    h := h xor (h shr 33);
    Result[j] := Byte(h shr ((j mod 8) * 8));
  end;
end;

procedure CryptStream(aStreamIn, aStreamOut: TStream; const aPassword: string);
var
  Key: THash256;
  Buf: array[0..4095] of Byte;
  R, i, p: Integer;
begin
  Key := SimpleHash256(aPassword);
  p := 0;

  while True do
  begin
    R := aStreamIn.Read(Buf, SizeOf(Buf));
    if R = 0 then Break;

    for i := 0 to R - 1 do
    begin
      Buf[i] := Buf[i] xor Key[p];
      Inc(p);
      if p > High(Key) then p := 0;
    end;

    aStreamOut.WriteBuffer(Buf, R);
  end;
end;

procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TStringMatrix);
var
  Plain, Crypt: TMemoryStream;
begin
  Plain := TMemoryStream.Create();
  Crypt := TMemoryStream.Create();
  try
    specialize MatrixToStream<string>(aMatrix, Plain, @WriteStringItem);
    Plain.Position := 0;
    CryptStream(Plain, Crypt, aPassword);
    Crypt.SaveToFile(aFileName);
  finally
    Plain.Free();
    Crypt.Free();
  end;
end;

function MatrixCryptFromFile(const aFileName, aPassword: string): TStringMatrix;
var
  Plain, Crypt: TMemoryStream;
begin
  Crypt := TMemoryStream.Create();
  Plain := TMemoryStream.Create();
  try
    Crypt.LoadFromFile(aFileName);
    Crypt.Position := 0;

    CryptStream(Crypt, Plain, aPassword);
    Plain.Position := 0;

    Result := specialize MatrixFromStream<string>(Plain, @ReadStringItem);
  finally
    Plain.Free();
    Crypt.Free();
  end;
end;

end.

