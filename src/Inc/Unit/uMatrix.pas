unit uMatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uGenericMatrix;

implementation

//procedure MatrixToStream(const aMatrix: TStringMatrix; aStream: TStream);
//var
//  i, j, L: Integer;
//  B: TBytes;
//  M: TStringMatrix.TMatrixType;
//begin
//  M := aMatrix.Matrix;
//  aStream.WriteDWord(Length(M));
//
//  for i := 0 to High(M) do
//  begin
//    aStream.WriteDWord(Length(M[i]));
//
//    for j := 0 to High(M[i]) do
//    begin
//      B := TEncoding.UTF8.GetBytes(M[i][j]);
//      L := Length(B);
//      aStream.WriteDWord(L);
//
//      if (L > 0) then
//        aStream.WriteBuffer(B[0], L);
//    end;
//  end;
//end;

//function MatrixFromStream(aStream: TStream): TStringMatrix;
//var
//  i, j, R, C, L: Integer;
//  B: TBytes;
//  Row: array of string;
//begin
//  Result := TStringMatrix.Create();
//
//  R := aStream.ReadDWord();
//
//  for i := 0 to R - 1 do
//  begin
//    C := aStream.ReadDWord();
//    SetLength(Row, C);
//
//    for j := 0 to C - 1 do
//    begin
//      L := aStream.ReadDWord();
//      if (L > 0) then
//      begin
//        SetLength(B, L);
//        aStream.ReadBuffer(B[0], L);
//        Row[j] := TEncoding.UTF8.GetString(B);
//      end
//      else
//        Row[j] := '';
//    end;
//
//    Result.Add(Row);
//  end;
//end;



end.

