unit uLicence;

{$mode objfpc}{$H+}

interface

uses
   Classes, fpjson,
   uHttp, uType, uGenericMatrix;

function GetLicence(aFirms: TStrings): TStringMatrix;

implementation

function GetLicence(aFirms: TStrings): TStringMatrix;
var
  i: Integer;
  Str: String;
  Json, Row: TJSONObject;
  Licenses: TJSONArray;
begin
  Json := TJSONObject.Create();
  Json.Add('type', 'get_licenses');
  Json.Add('app', 'vBuhAssist');

  Licenses := TJSONArray.Create();
  for i := 0 to aFirms.Count - 1 do
    Licenses.Add(aFirms[i]);
  Json.Add('firms', Licenses);

  Json := PostJSON('https://windows.cloud-server.com.ua/api', Json);
  Licenses := Json.Arrays['licenses'];
  for i := 0 to Licenses.Count - 1 do
  begin
    Row := Licenses.Objects[I];
    Str := Row.Strings['firm'];
  end;
end;

end.

