unit uCrypt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, base64, BlowFish, fpjson, jsonparser,
  uSys;

function StrEncrypt(const aStr, aKey: string): Ansistring;
function StrDecrypt(const aStr: Ansistring; aKey: string): string;
function JsonEncrypt(aJObj: TJSONObject; const aKey: string): AnsiString;
function JsonDecrypt(const aStr: AnsiString; const aKey: string): TJSONObject;

implementation

function StrXor(const aStr, aKey: string): string;
var
  i: Integer;
begin
  SetLength(Result, aStr.Length);
  for i := 1 to aStr.Length do
    Result[i] := Chr(Ord(aStr[i]) xor Ord(aKey[(i-1) mod aKey.Length + 1]));
end;

function StrEncrypt(const aStr, aKey: string): Ansistring;
var
  Stream: TStringStream;
  StreamBF: TBlowFishEncryptStream;
  Str: string;
begin
  Stream := TStringStream.Create('');
  StreamBF := TBlowFishEncryptStream.Create(aKey, Stream);
  StreamBF.WriteAnsiString(aStr);
  StreamBF.Free();

  Str := Stream.DataString;
  Str := EncodeStringBase64(Str);
  Result := StrXor(Str, aKey);
  Stream.Free();
end;

function StrDecrypt(const aStr: Ansistring; aKey: string): string;
var
  Stream: TStringStream;
  StreamBF: TBlowFishDecryptStream;
  Str: string;
begin
  Str := StrXor(aStr, aKey);
  Str := DecodeStringBase64(Str);
  Stream := TStringStream.Create(Str);
  StreamBF := TBlowFishDecryptStream.Create(aKey, Stream);
  Result := StreamBF.ReadAnsiString();
  StreamBF.Free();
  Stream.Free();
end;

function JsonEncrypt(aJObj: TJSONObject; const aKey: string): AnsiString;
var
  Str: string;
begin
  Str := aJObj.AsJSON;
  Result := StrEncrypt(Str, aKey);
end;

function JsonDecrypt(const aStr: AnsiString; const aKey: string): TJSONObject;
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
//  JOriginal.Add('name', 'Volodymyr Volodymyr Volodymyr Volodymyr Volodymyr Volodymyr ');
//  JOriginal.Add('age', 34);
//  JOriginal.Add('city', 'Kyiv Kyiv Kyiv Kyiv Kyiv Kyiv Kyiv Kyiv Kyiv ');
//  Encrypted := JsonEncrypt(JOriginal, 'MyKey1234567');
//
//  StrToFile(Encrypted, 'Encrypted.dat');
//  Decrypted := StrFromFile('Encrypted.dat');
//
//  JDecrypted := JsonDecrypt(Decrypted, 'MyKey1234567');
//  Str := JDecrypted.Get('name', '')
end.

