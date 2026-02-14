unit uCrypt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, base64, BlowFish, fpjson, jsonparser;

function StrEncrypt(const aStr, aKey: string): string;
function StrDecrypt(const aStr, aKey: string): string;
function JsonEncrypt(aJObj: TJSONObject; const aKey: string): string;
function JsonDecrypt(const aStr, aKey: string): TJSONObject;

implementation

function StrXor(const aStr, aKey: string): string;
var
  i: Integer;
begin
  SetLength(Result, aStr.Length);
  for i := 1 to aStr.Length do
    Result[i] := Chr(Ord(aStr[i]) xor Ord(aKey[(i-1) mod aKey.Length + 1]));
end;

function StrEncrypt(const aStr, aKey: string): string;
var
  s1: TStringStream;
  en: TBlowFishEncryptStream;
  temp: string;
begin
  s1 := TStringStream.Create('');
  en := TBlowFishEncryptStream.Create(aKey, s1);
  en.WriteAnsiString(aStr);
  en.Free();

  temp := s1.DataString;
  temp := EncodeStringBase64(temp);
  Result := StrXor(temp, aKey);
  s1.Free();
end;

function StrDecrypt(const aStr, aKey: string): string;
var
  s2: TStringStream;
  de: TBlowFishDecryptStream;
  temp: string;
begin
  temp := StrXor(aStr, aKey);
  temp := DecodeStringBase64(temp);
  s2 := TStringStream.Create(temp);
  de := TBlowFishDecryptStream.Create(aKey, s2);
  Result := de.ReadAnsiString();
  de.Free();
  s2.Free();
end;

function JsonEncrypt(aJObj: TJSONObject; const aKey: string): string;
var
  Str: string;
begin
  Str := aJObj.AsJSON;
  Result := StrEncrypt(Str, aKey);
end;

function JsonDecrypt(const aStr, aKey: string): TJSONObject;
var
  Str: string;
begin
  Str := StrDecrypt(aStr, aKey);
  Result := TJSONObject(GetJSON(Str));
end;


//var
//  Original, Encrypted, Decrypted, Str: string;
//  JOriginal, JDecrypted: TJSONObject;
//begin
//  Original := 'Привіт, Lazarus! 123';
//  Encrypted := StrEncrypt(Original, 'MyKey1234567');
//  Decrypted := StrDecrypt(Encrypted, 'MyKey1234567');
//
//  JOriginal := TJSONObject.Create();
//  JOriginal.Add('name', 'Volodymyr');
//  JOriginal.Add('age', 34);
//  JOriginal.Add('city', 'Kyiv');
//  Encrypted := JsonEncrypt(JOriginal, 'MyKey1234567');
//  StrToFile(Encrypted, 'Encrypted.dat');
//  JDecrypted := JsonDecrypt(Encrypted, 'MyKey1234567');
//  Str := JDecrypted.Get('name', '')
end.

