// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLicence;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpjson,
  uHttp, uGenericMatrix, uConst;

  function GetLicenceFromHttp(aFirms: TStrings; const aModule, aDealer: String): TStringMatrix;
  procedure GetLicenceFromHttpToFile(const aModule: string; aFirms: TStringList);
  procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TStringMatrix);
  function MatrixCryptFromFile(const aFileName, aPassword: string): TStringMatrix;

implementation

type
THash256 = array[0..31] of Byte;

function GetLicenceFromHttp(aFirms: TStrings; const aModule, aDealer: String): TStringMatrix;
var
  i: Integer;
  Json, Row: TJSONObject;
  ArrLic, Licenses: TJSONArray;
begin
  try
    Result := TStringMatrix.Create();

    Json := TJSONObject.Create();
    Json.Add('type', 'get_licenses');
    Json.Add('app', 'BuhAssist');
    Json.Add('module', aModule);
    Json.Add('dealer', aDealer);

    ArrLic := TJSONArray.Create();
    for i := 0 to aFirms.Count - 1 do
      ArrLic.Add(aFirms[i]);
    Json.Add('firms', ArrLic);

    Json := PostJSON('https://windows.cloud-server.com.ua/api', Json);
    Licenses := Json.Arrays['licenses'];
    for i := 0 to Licenses.Count - 1 do
    begin
      Row := Licenses.Objects[I];
      Result.Add([Row.Strings['firm'], Row.Strings['module'], Row.Strings['till']]);
    end;
  finally
    Json.Free();
    ArrLic.Free();
  end;
end;

procedure GetLicenceFromHttpToFile(const aModule: string; aFirms: TStringList);
var
  Matrix: TStringMatrix;
begin
  try
    Matrix := GetLicenceFromHttp(aFirms, aModule, '');
    MatrixCryptToFile(cFileLic, cFileLicPassw, Matrix);
  finally
    Matrix.Free();
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

