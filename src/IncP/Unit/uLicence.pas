unit uLicence;

{$mode objfpc}{$H+}

interface

uses
   Classes, fpjson,
   uHttp, uType, uGenericMatrix;

function GetLicence(aFirms: TStrings; const aModule: String): TStringMatrix;

implementation

function GetLicence(aFirms: TStrings; const aModule: String): TStringMatrix;
var
  i: Integer;
  Str: String;
  Json, Row: TJSONObject;
  ArrLic, Licenses: TJSONArray;
begin
  try
    Result := TStringMatrix.Create();

    Json := TJSONObject.Create();
    Json.Add('type', 'get_licenses');
    Json.Add('app', 'BuhAssist');
    Json.Add('module', aModule);

    ArrLic := TJSONArray.Create();
    for i := 0 to aFirms.Count - 1 do
      ArrLic.Add(aFirms[i]);
    Json.Add('firms', ArrLic);

    Json := PostJSON('https://windows.cloud-server.com.ua/api', Json);
    Licenses := Json.Arrays['licenses'];
    for i := 0 to Licenses.Count - 1 do
    begin
      Row := Licenses.Objects[I];
      Result.Add([Row.Strings['firm'], Row.Strings['module'], Row.Strings['till']]);
    end;
  finally
    Json.Free();
    ArrLic.Free();
  end;
end;

end.

