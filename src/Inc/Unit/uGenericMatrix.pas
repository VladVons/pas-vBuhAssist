unit uGenericMatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
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

    // властивість Count (кількість рядків)
    property Count: Integer read GetCount;

    // доступ до елементів, як Cells[Row,Col]
    property Cells[aRow, aCol: Integer]: T read GetCells write SetCells;

    // Рядки
    procedure Add(const aRow: array of T);
    procedure AddMatrix(const aMatrix: TMatrixType);
    procedure Insert(aIndex: Integer; const aRow: array of T);
    procedure Delete(aIndex: Integer);

    // Колонки
    procedure AddColumn(aRowIndex: Integer; const aValue: T);
    procedure DeleteColumn(aRowIndex, aColIndex: Integer);

    // Доступ до всієї матриці
    function GetMatrix(): TMatrixType;
    procedure SetMatrix(const aMatrix: TMatrixType);
  end;

  TStringMatrix = specialize TMatrix<string>;

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

function TMatrix.GetMatrix(): TMatrixType;
begin
  Result := FData;
end;

procedure TMatrix.SetMatrix(const aMatrix: TMatrixType);
begin
  FData := aMatrix;
end;

end.

