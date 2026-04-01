// Created: 2026.02.21
// Author: Vladimir Vons <VladVons@gmail.com>

unit uQuery;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB, RegExpr,
  uVarUtil, uHelper, uType;

function GetQueryField(aDataSource: TDataSource; aQuery: TSQLQuery; aField: string): TStringList;
function ExpandSQL(aQuery: TSQLQuery): string;
function FieldToStrings(aQuery: TSQLQuery; aField: string): TStringList;


implementation


function GetQueryField(aDataSource: TDataSource; aQuery: TSQLQuery; aField: string): TStringList;
var
  Str: string;
begin
  aDataSource.DataSet := aQuery;
  aQuery.Open();

  Result := TStringList.Create();
  aQuery.First();
  while (not aQuery.EOF) do
  begin
    Str := aQuery.FieldByName(aField).AsString;
    Result.Add(Str);
    aQuery.Next();
  end;

  aQuery.Close();
end;

function _SortParamByLen(aParams: TParams): TIntegerArray;
var
  i, j: integer;
begin
  SetLength(Result, aParams.Count);
  for i := 0 to aParams.Count - 1 do
    Result[i] := i;

  // сортування по довжині імені (DESC)
  for i := 0 to aParams.Count - 2 do
    for j := i + 1 to aParams.Count - 1 do
      if (aParams[Result[i]].Name.Length < aParams[Result[j]].Name.Length) then
        Swap(Result[i], Result[j]);
end;

function ExpandSQL(aQuery: TSQLQuery): string;
var
  i: integer;
  sFind, sRepl: string;
  Sorted: TIntegerArray;
begin
  Result := aQuery.SQL.Text;

  Sorted := _SortParamByLen(aQuery.Macros);
  for i := 0 to High(Sorted) do
  begin
    sFind := '%' + aQuery.Macros[Sorted[i]].Name;
    sRepl := aQuery.Macros[Sorted[i]].AsString;
    Result := StringReplace(Result, sFind, sRepl, [rfReplaceAll, rfIgnoreCase]);
  end;

  Sorted := _SortParamByLen(aQuery.Params);
  for i := 0 to High(Sorted) do
  begin
    sFind := ':' + aQuery.Params[Sorted[i]].Name;
    sRepl := aQuery.Params[Sorted[i]].AsString;
    Result := StringReplace(Result, sFind, sRepl, [rfReplaceAll, rfIgnoreCase]);
  end;

  Result := Result.DelEmptyLines();
end;

function FieldToStrings(aQuery: TSQLQuery; aField: string): TStringList;
var
  Str: string;
begin
  Result := TStringList.Create();

  aQuery.First();
  while not aQuery.EOF do
  begin
    Str := aQuery.FieldByName(aField).AsString;
    Result.Add(Str);
    aQuery.Next();
  end;
end;

end.

