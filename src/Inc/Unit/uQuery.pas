unit uQuery;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB;

function GetQueryField(aDataSource: TDataSource; aQuery: TSQLQuery; aField: String): TStringList;

implementation

function GetQueryField(aDataSource: TDataSource; aQuery: TSQLQuery; aField: String): TStringList;
var
  Str: String;
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

end.

