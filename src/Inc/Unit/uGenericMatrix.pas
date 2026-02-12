// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

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
    TArrayType = array of T;
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
    procedure Insert(aRowIdx: Integer; const aRow: TArrayType);
    procedure Delete(aRowIdx: Integer);
    function Find(aRowIdxStart, aColIdx: Integer; const aValue: T): Integer;

    // Колонки
    procedure ColAdd(aRowIdx: Integer; const aValue: T);
    procedure ColDel(aRowIdx, aColIdx: Integer);
    function ColExport(aColIdx: Integer): TArrayType;
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


implementation

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

procedure TMatrix.Insert(aRowIdx: Integer; const aRow: TArrayType);
var
  i: Integer;
begin
  if (aRowIdx < 0)
     then aRowIdx := 0;

  if (aRowIdx > Count)
     then aRowIdx := Count;

  SetLength(FData, Count + 1);
  for i := Count - 1 downto aRowIdx + 1 do
    FData[i] := FData[i - 1];

  SetLength(FData[aRowIdx], Length(aRow));
  for i := 0 to High(aRow) do
    FData[aRowIdx][i] := aRow[i];
end;

procedure TMatrix.Delete(aRowIdx: Integer);
var
  i: Integer;
begin
  if (aRowIdx < 0) or (aRowIdx >= Count)
     then Exit;

  for i := aRowIdx to Count - 2 do
    FData[i] := FData[i + 1];

  SetLength(FData, Count - 1);
end;

procedure TMatrix.ColAdd(aRowIdx: Integer; const aValue: T);
var
  NewCol: Integer;
begin
  if (aRowIdx < 0) or (aRowIdx >= Count)
     then Exit;

  NewCol := Length(FData[aRowIdx]);
  SetLength(FData[aRowIdx], NewCol + 1);
  FData[aRowIdx][NewCol] := aValue;
end;

procedure TMatrix.ColDel(aRowIdx, aColIdx: Integer);
var
  i, Len: Integer;
begin
  if (aRowIdx < 0) or (aRowIdx >= Count)
     then Exit;

  Len := Length(FData[aRowIdx]);
  if (aColIdx < 0) or (aColIdx >= Len)
     then Exit;

  for i := aColIdx to Len - 2 do
    FData[aRowIdx][i] := FData[aRowIdx][i + 1];

  SetLength(FData[aRowIdx], Len - 1);
end;

function TMatrix.Find(aRowIdxStart, aColIdx: Integer; const aValue: T): Integer;
var
  i: Integer;
begin
  Result := -1;

  if (aColIdx < 0) or (Length(FData) = 0) then
    Exit;

  for i := aRowIdxStart to High(FData) do
  begin
    if (aColIdx <= High(FData[i])) and (FData[i][aColIdx] = aValue) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TMatrix.ColExport(aColIdx: Integer): TArrayType;
var
  i: integer;
begin
  SetLength(Result, Length(FData));

  for i := 0 to High(FData) do
  begin
    if (aColIdx >= 0) and (aColIdx <= High(FData[i])) then
      Result[i] := FData[i][aColIdx]
    else
      Result[i] := Default(T);
  end;
end;


//---

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

end.

