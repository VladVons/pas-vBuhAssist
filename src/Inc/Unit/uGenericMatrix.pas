unit uGenericMatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  generic TWriteItemProc<T> = procedure(const aValue: T; aStream: TStream);

  generic TMatrix<T> = class
  public
    type
    TMatrixType = array of array of T;
  private
    FData: TMatrixType;
    function GetCount(): Integer;
    function GetCells(aRow, aCol: Integer): T;
    procedure SetCells(aRow, aCol: Integer; const Value: T);
  public
    constructor Create();
    destructor Destroy(); override;

    property Matrix: TMatrixType read FData write FData;
    property Count: Integer read GetCount;
    property Cells[aRow, aCol: Integer]: T read GetCells write SetCells;

    // Рядки
    procedure Add(const aRow: array of T);
    procedure AddMatrix(const aMatrix: TMatrixType);
    procedure Insert(aIndex: Integer; const aRow: array of T);
    procedure Delete(aIndex: Integer);

    // Колонки
    procedure AddColumn(aRowIndex: Integer; const aValue: T);
    procedure DeleteColumn(aRowIndex, aColIndex: Integer);
  end;

  TStringMatrix = specialize TMatrix<string>;

  generic TReadItemProc<T> = procedure(aStream: TStream; out aValue: T);
  procedure ReadStringItem(aStream: TStream; out aValue: string);
  procedure WriteStringItem(const aValue: string; aStream: TStream);

  generic procedure MatrixToStream<T>(
    const aMatrix: specialize TMatrix<T>;
    aStream: TStream;
    const aWriteItem: specialize TWriteItemProc<T>
  );

  generic function MatrixFromStream<T>(
    aStream: TStream;
    const aReadItem: specialize TReadItemProc<T>
  ): specialize TMatrix<T>;

  procedure MatrixCryptToFile(const aFileName, aPassword: string; const aMatrix: TStringMatrix);
  function MatrixCryptFromFile(const aFileName, aPassword: string): TStringMatrix;


implementation

type
THash256 = array[0..31] of Byte;

{ TMatrix<T> }
constructor TMatrix.Create();
begin
  inherited;
  SetLength(FData, 0);
end;

destructor TMatrix.Destroy();
begin
  SetLength(FData, 0);
  inherited;
end;

function TMatrix.GetCount: Integer;
begin
  Result := Length(FData);
end;

function TMatrix.GetCells(aRow, aCol: Integer): T;
begin
  if (aRow < 0) or (aRow >= Count) then
     Exit(Default(T));

  if (aCol < 0) or (aCol >= Length(FData[aRow])) then
     Exit(Default(T));

  Result := FData[aRow][aCol];
end;

procedure TMatrix.SetCells(aRow, aCol: Integer; const Value: T);
begin
  if (aRow < 0) or (aRow >= Count)
     then Exit;

  if (aCol < 0) or (aCol >= Length(FData[aRow]))
     then Exit;

  FData[aRow][aCol] := Value;
end;

procedure TMatrix.Add(const aRow: array of T);
var
  NewIndex, i: Integer;
begin
  NewIndex := Length(FData);
  SetLength(FData, NewIndex + 1);
  SetLength(FData[NewIndex], Length(aRow));
  for i := 0 to High(aRow) do
    FData[NewIndex][i] := aRow[i];
end;

procedure TMatrix.AddMatrix(const aMatrix: TMatrixType);
var
  i: Integer;
begin
  for i := 0 to High(aMatrix) do
    Add(aMatrix[i]);
end;

procedure TMatrix.Insert(aIndex: Integer; const aRow: array of T);
var
  i: Integer;
begin
  if aIndex < 0
     then aIndex := 0;

  if aIndex > Count
     then aIndex := Count;

  SetLength(FData, Count + 1);
  for i := Count - 1 downto aIndex + 1 do
    FData[i] := FData[i - 1];

  SetLength(FData[aIndex], Length(aRow));
  for i := 0 to High(aRow) do
    FData[aIndex][i] := aRow[i];
end;

procedure TMatrix.Delete(aIndex: Integer);
var
  i: Integer;
begin
  if (aIndex < 0) or (aIndex >= Count)
     then Exit;

  for i := aIndex to Count - 2 do
    FData[i] := FData[i + 1];

  SetLength(FData, Count - 1);
end;

procedure TMatrix.AddColumn(aRowIndex: Integer; const aValue: T);
var
  NewCol: Integer;
begin
  if (aRowIndex < 0) or (aRowIndex >= Count)
     then Exit;

  NewCol := Length(FData[aRowIndex]);
  SetLength(FData[aRowIndex], NewCol + 1);
  FData[aRowIndex][NewCol] := aValue;
end;

procedure TMatrix.DeleteColumn(aRowIndex, aColIndex: Integer);
var
  i, Len: Integer;
begin
  if (aRowIndex < 0) or (aRowIndex >= Count)
     then Exit;

  Len := Length(FData[aRowIndex]);
  if (aColIndex < 0) or (aColIndex >= Len)
     then Exit;

  for i := aColIndex to Len - 2 do
    FData[aRowIndex][i] := FData[aRowIndex][i + 1];

  SetLength(FData[aRowIndex], Len - 1);
end;

//---
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


procedure ReadStringItem(aStream: TStream; out aValue: string);
var
  L: Integer;
  B: TBytes;
begin
  L := aStream.ReadDWord();
  if L > 0 then
  begin
    SetLength(B, L);
    aStream.ReadBuffer(B[0], L);
    aValue := TEncoding.UTF8.GetString(B);
  end
  else
    aValue := '';
end;

procedure WriteStringItem(const aValue: string; aStream: TStream);
var
  B: TBytes;
  L: Integer;
begin
  B := TEncoding.UTF8.GetBytes(aValue);
  L := Length(B);
  aStream.WriteDWord(L);
  if L > 0 then
    aStream.WriteBuffer(B[0], L);
end;

generic procedure MatrixToStream<T>(
  const aMatrix: specialize TMatrix<T>;
  aStream: TStream;
  const aWriteItem: specialize TWriteItemProc<T>
);
var
  i, j: Integer;
  M: specialize TMatrix<T>.TMatrixType;
begin
  M := aMatrix.Matrix;

  aStream.WriteDWord(Length(M));

  for i := 0 to High(M) do
  begin
    aStream.WriteDWord(Length(M[i]));
    for j := 0 to High(M[i]) do
      aWriteItem(M[i][j], aStream);
  end;
end;

generic function MatrixFromStream<T>(
  aStream: TStream;
  const aReadItem: specialize TReadItemProc<T>
): specialize TMatrix<T>;
var
  i, j, R, C: Integer;
  M: specialize TMatrix<T>;
  Row: array of T;
begin
  M := specialize TMatrix<T>.Create();

  R := aStream.ReadDWord();

  for i := 0 to R - 1 do
  begin
    C := aStream.ReadDWord();
    SetLength(Row, C);

    for j := 0 to C - 1 do
      aReadItem(aStream, Row[j]);

    M.Add(Row);
  end;

  Result := M;
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

