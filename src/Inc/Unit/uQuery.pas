// Created: 2026.02.21
// Author: Vladimir Vons <VladVons@gmail.com>

unit uQuery;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB, RegExpr;

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

function ExpandSQL(aQuery: TSQLQuery): string;
var
  i: integer;
  SQL, sFind, sRepl: string;
  Re: TRegExpr;
begin
  // спочатку беремо SQL з макросами
  SQL := aQuery.SQL.Text;

  Re := TRegExpr.Create();

  // підставляємо макроси
  for i := 0 to aQuery.Macros.Count - 1 do
  begin
    sFind := '%' + aQuery.Macros[i].Name;
    sRepl := aQuery.Macros[i].AsString;
    //Re.Expression := sFind + '(?![A-Za-z0-9_])';
    //SQL := Re.Replace(SQL, sRepl, True);
    SQL := StringReplace(SQL, sFind, sRepl, [rfReplaceAll, rfIgnoreCase]);
  end;

  // тепер підставляємо параметри
  for i := 0 to aQuery.Params.Count - 1 do
  begin
    sFind := ':' + aQuery.Params[i].Name;
    sRepl := aQuery.Params[i].AsString;
    SQL := StringReplace(SQL, sFind, sRepl, [rfReplaceAll, rfIgnoreCase]);
  end;

  Re.Free();
  Result := SQL;
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

