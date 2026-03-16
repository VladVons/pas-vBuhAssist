// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>
//
// GetUrlToString('https://user:passw@download.1x1.com.ua/path/ver.json');

unit uHttp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson, Winsock, Sockets,
  uVarHelper;

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;
function GetUrlToString(const aURL: string; out aData: string): integer;
function GetUrlToFile(const aURL, aDir: string; aFileName: string = ''): string;
function IsPortOpen(const aHost, aPort: string): Boolean;
function HostToIP(const aHost: string): string;


implementation

function PostJSON(const aURL: string; aJSON: TJSONObject): TJSONObject;
var
  Data: string;
  Client: TFPHTTPClient;
  Body: TStringStream;
begin
  Result := Nil;
  Body := TStringStream.Create(aJson.AsJSON);

  Client := TFPHTTPClient.Create(nil);
  Client.AddHeader('Content-Type', 'application/json; charset=UTF-8');
  Client.AddHeader('Accept', 'application/json');
  try
    Client.RequestBody := Body;
    try
      Data := client.Post(aURL);
    except on E: Exception do
      Data := '';
    end;

    if (Client.ResponseStatusCode = 200) and (Data <> '') then
      Result := TJSONObject(GetJSON(Data));
  finally
    Body.Free();
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

// 'https://user:passw@download.1x1.com.ua/public/update/vBuhAssist/vBuhAssist_35.exe.zip'
function GetUrlToFile(const aURL, aDir: string; aFileName: string = ''): string;
var
  Client: TFPHTTPClient;
  FS: TFileStream;
begin
  if (aFileName.IsEmpty()) then
    aFileName := ExtractFileName(aURL);

  Result := aFileName;
  if (not aDir.IsEmpty()) then
    Result := ConcatPaths([aDir, aFileName]);

  FS := TFileStream.Create(Result, fmCreate);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AllowRedirect := True;
    Client.Get(aURL, FS);
  finally
    FreeAndNil(Client);
    FreeAndNil(FS);
  end;
end;

function HostToIP(const aHost: string): string;
var
  H: PHostEnt;
  Addr: LongWord;
begin
  Result := '';
  H := GetHostByName(PChar(aHost));
  if Assigned(H) and (H^.h_addr_list[0] <> nil) then
  begin
    Addr := PLongWord(H^.h_addr_list[0])^;
    Result := Format('%d.%d.%d.%d',
      [Addr and $FF,
       (Addr shr 8) and $FF,
       (Addr shr 16) and $FF,
       (Addr shr 24) and $FF]);
  end;
end;

function IsPortOpen(const aHost, aPort: string): Boolean;
var
  Sock: LongInt;
  Addr: TSockAddr;
  Ip: string;
begin
  Result := False;

  Sock := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Sock < 0 then
    Exit;

  Ip := HostToIP(aHost);
  if (Ip.IsEmpty()) then
    Exit;

  Addr := Default(TSockAddr);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(aPort.ToInteger());
  Addr.sin_addr := StrToNetAddr(Ip);
  if fpConnect(Sock, @Addr, SizeOf(Addr)) = 0 then
    Result := True;

  CloseSocket(Sock);
end;

initialization
  //AddDirDll(cDirAddons + PathDelim + 'ssl');

end.
