unit uHttp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson;

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;

implementation

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;
var
  responseData: String;
  client: TFPHTTPClient;
begin
    client := TFPHTTPClient.Create(nil);
    client.AddHeader('Content-Type', 'application/json; charset=UTF-8');
    client.AddHeader('Accept', 'application/json');
    try
      client.RequestBody := TStringStream.Create(aJson.AsJSON);
      responseData := client.Post(aURL);
      if (client.ResponseStatusCode = 200) and (responseData <> '') then
      begin
        Result := TJSONObject(GetJSON(responseData));
      end;
    finally
      FreeAndNil(client);
    end;
end;

end.

