// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uHttp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson,
  uSys, uConst;

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;

implementation

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;
var
  Data: String;
  Client: TFPHTTPClient;
begin
    Client := TFPHTTPClient.Create(nil);
    Client.AddHeader('Content-Type', 'application/json; charset=UTF-8');
    Client.AddHeader('Accept', 'application/json');
    try
      Client.RequestBody := TStringStream.Create(aJson.AsJSON);
      Data := client.Post(aURL);
      if (Client.ResponseStatusCode = 200) and (Data <> '') then
      begin
        Result := TJSONObject(GetJSON(Data));
      end;
    finally
      Client.Free();
    end;
end;

initialization
  //AddDirDll(cDirAddons + PathDelim + 'ssl');

end.
