// Created: 2026.02.22
// Author: Vladimir Vons <VladVons@gmail.com>

unit uCryptAES;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  DCPcrypt2, DCPblockciphers, DCPsha256, DCPrijndael, Base64,
  uProtectDbg;


function StrEncrypt_AES(const aText, aKey: string): AnsiString;
function StrDecrypt_AES(const aBase64, aKey: string): string;

implementation

function StrEncrypt_AES(const aText, aKey: string): AnsiString;
var
  Cipher: TDCP_rijndael;
  InStream, OutStream: TMemoryStream;
  IV: array[0..15] of byte;
begin
  Result := '';
  try
    Cipher := TDCP_rijndael.Create(nil);
    InStream := TMemoryStream.Create();
    OutStream := TMemoryStream.Create();

    // записуємо текст у потік
    InStream.WriteBuffer(Pointer(aText)^, aText.Length);
    InStream.Position := 0;

    // генеруємо IV
    Randomize();
    FillChar(IV, SizeOf(IV), 0);
    Move(Random(MaxInt), IV, SizeOf(IV));

    // запис IV на початок вихідного потоку
    OutStream.WriteBuffer(IV, SizeOf(IV));

    // ініціалізація AES-256
    Cipher.InitStr(aKey, TDCP_sha256);
    Cipher.SetIV(IV);

    Cipher.EncryptStream(InStream, OutStream, InStream.Size);
    Cipher.Burn();

    // повертаємо Base64
    OutStream.Position := 0;
    SetLength(Result, OutStream.Size);
    OutStream.ReadBuffer(Pointer(Result)^, OutStream.Size);
    Result := EncodeStringBase64(Result);
  finally
    InStream.Free();
    OutStream.Free();
    Cipher.Free();
  end;
end;

function StrDecrypt_AES(const aBase64, aKey: string): string;
var
  Cipher: TDCP_rijndael;
  InStream, OutStream: TMemoryStream;
  IV: array[0..15] of byte;
  EncBytes: string;
  DataSize: Int64;
begin
  Result := '';
  if (aBase64.Length = 0) then
    Exit();

  EncBytes := DecodeStringBase64(aBase64);

  // 🔴 КРИТИЧНА перевірка
  if (EncBytes.Length < SizeOf(IV)) then
    Exit(); // або raise

  Cipher := TDCP_rijndael.Create(nil);
  InStream := TMemoryStream.Create();
  OutStream := TMemoryStream.Create();
  try
    InStream.WriteBuffer(EncBytes[1], Length(EncBytes));
    InStream.Position := 0;

    InStream.ReadBuffer(IV, SizeOf(IV));

    Cipher.InitStr(aKey, TDCP_sha256);
    Cipher.SetIV(IV);

    DataSize := InStream.Size - SizeOf(IV);
    if (DataSize <= 0) then
      Exit();

    if (not IsDebugger2()) or (IsDeveloper()) then
    begin
      Cipher.DecryptStream(InStream, OutStream, DataSize);
      Cipher.Burn();
    end;

    // результат
    if (OutStream.Size > 0) then
    begin
      SetLength(Result, OutStream.Size);
      OutStream.Position := 0;

      if (not IsDebugger1()) or (IsDeveloper()) then
        OutStream.ReadBuffer(Result[1], OutStream.Size);
    end;
  finally
    InStream.Free();
    OutStream.Free();
    Cipher.Free();
  end;
end;

end.

