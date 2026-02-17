// Created: 2026.02.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uCrypt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, base64, BlowFish, fpjson, jsonparser;

function StrEncrypt(const aStr, aKey: string): Ansistring;
function StrDecrypt(const aStr: Ansistring; aKey: string): string;
function JsonEncrypt(aJObj: TJSONObject; const aKey: string): AnsiString;
function JsonDecrypt(const aStr: AnsiString; const aKey: string): TJSONObject;

implementation

type
  THash256 = array[0..31] of Byte;

function SimpleHash256(const aString: string): THash256;
var
  i, j: Integer;
  h: QWord;
begin
  h := $CBF29CE484222325;
  for i := 1 to Length(aString) do
    h := (h xor Ord(aString[i])) * $100000001B3;

  for j := 0 to High(THash256) do
  begin
    h := h xor (h shr 33);
    h := h * $FF51AFD7ED558CCD;
    h := h xor (h shr 33);
    Result[j] := Byte(h shr ((j mod 8) * 8));
  end;
end;

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

end.

