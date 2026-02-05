unit uMatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uType;

procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TMatrixString);
function MatrixCryptFromFile(const aFileName, aPassword: string): TMatrixString;

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

  for j := 0 to 31 do
  begin
    h := h xor (h shr 33);
    h := h * $FF51AFD7ED558CCD;
    h := h xor (h shr 33);
    Result[j] := Byte(h shr ((j mod 8) * 8));
  end;
end;

procedure MatrixToStream(const aMatrix: TMatrixString; aStream: TStream);
var
  i, j, L: Integer;
  B: TBytes;
begin
  aStream.WriteDWord(Length(aMatrix));

  for i := 0 to High(aMatrix) do
  begin
    aStream.WriteDWord(Length(aMatrix[i]));
    for j := 0 to High(aMatrix[i]) do
    begin
      B := TEncoding.UTF8.GetBytes(aMatrix[i][j]);
      L := Length(B);
      aStream.WriteDWord(L);
      if (L > 0) then
        aStream.WriteBuffer(B[0], L);
    end;
  end;
end;

function MatrixFromStream(aStream: TStream): TMatrixString;
var
  i, j, R, C, L: Integer;
  B: TBytes;
begin
  R := aStream.ReadDWord();
  SetLength(Result, R);

  for i := 0 to R - 1 do
  begin
    C := aStream.ReadDWord();
    SetLength(Result[i], C);
    for j := 0 to C - 1 do
    begin
      L := aStream.ReadDWord();
      if L > 0 then
      begin
        SetLength(B, L);
        aStream.ReadBuffer(B[0], L);
        Result[i][j] := TEncoding.UTF8.GetString(B);
      end
      else
        Result[i][j] := '';
    end;
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

procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TMatrixString);
var
  Plain, Crypt: TMemoryStream;
begin
  Plain := TMemoryStream.Create();
  Crypt := TMemoryStream.Create();
  try
    MatrixToStream(aMatrix, Plain);
    Plain.Position := 0;

    CryptStream(Plain, Crypt, aPassword);
    Crypt.SaveToFile(aFileName);
  finally
    Plain.Free();
    Crypt.Free();
  end;
end;

function MatrixCryptFromFile(const aFileName, aPassword: string): TMatrixString;
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

    Result := MatrixFromStream(Plain);
  finally
    Plain.Free();
    Crypt.Free();
  end;
end;


end.

