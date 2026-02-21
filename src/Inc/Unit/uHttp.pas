// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>
//
// GetUrlToString('https://user:passw@download.1x1.com.ua/path/ver.json');

unit uHttp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson;

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;
function GetUrlToString(const aURL: string; out aData: string): integer;
procedure GetUrlToFile(const aURL: string; aSaveAs: string = '');

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
        Result := TJSONObject(GetJSON(Data))
      else
        Result := Nil;
    finally
      Client.Free();
    end;
end;

function GetUrlToString(const aURL: string; out aData: string): integer;
var
  Client: TFPHTTPClient;
begin
  Client := TFPHTTPClient.Create(nil);
  //Client.UserName := aUser;
  //Client.Password := aPassw;
  //https://user:passw@download.1x1.com.ua/path/ver.json - ok
  try
    try
      aData := Client.Get(aURL);
    except
      on E: Exception do
        aData := '';
    end;
    Result := Client.ResponseStatusCode;
  finally
   Client.Free();
  end;
end;

procedure GetUrlToFile(const aURL: string; aSaveAs: string = '');
var
  Client: TFPHTTPClient;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.Get(aURL, aSaveAs);
  finally
    Client.Free();
  end;
end;


initialization
  //AddDirDll(cDirAddons + PathDelim + 'ssl');

end.
