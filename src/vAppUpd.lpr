program vAppUpd;

{$mode objfpc}{$H+}
{$apptype console}

uses
  Classes, SysUtils, CustApp, opensslsockets, URIParser, fpjson, jsonparser,
  uSys, uHttp, uArchive, uVarUtil;
type

  TAppUpd = class(TCustomApplication)
  protected
    procedure DoRun(); override;
    procedure Quit(aErr: Integer = 0; const aMsg: String = '');
    function GetVerRemote(const aUrl: String): String;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy(); override;
    procedure ShowHelp(); virtual;
    procedure Update(const aUrl: String);
  end;

{ TMyApplication }
procedure TAppUpd.Quit(aErr: Integer = 0; const aMsg: String = '');
begin
  if (not aMsg.IsEmpty()) then
    WriteLn(aMsg);

  if (HasOption('p', 'pause')) then
  begin
    WriteLn('press enter to quit');
    ReadLn();
  end;

  Terminate();
  Halt(aErr);
end;

function TAppUpd.GetVerRemote(const aUrl: String): String;
var
  Str: String;
  Err: Integer;
  Uri: TURI;
begin
  Err := GetUrlToString(aUrl, Result);
  if (Err <> 200) then
  begin
    Uri := ParseURI(aUrl);
    if (not Uri.Password.IsEmpty()) then
    begin
      Uri.Password := 'xxx';
      EncodeURI(Uri);
      Str := EncodeURI(Uri);
    end else
      Str := aUrl;
    Quit(1, format('Error %d downloading %s', [Err, Str]));
  end
end;

procedure TAppUpd.Update(const aUrl: String);
var
  StrJson, Ver: String;
  JObj: TJSONObject;
begin
  StrJson := GetVerRemote(aUrl);
  JObj := TJSONObject(GetJSON(StrJson));
  Ver := GetJsonNested(JObj, 'ver/release', '');
end;

procedure TAppUpd.DoRun();
var
  Str: String;
begin
  if (ParamCount = 0) then
  begin
    ShowHelp();
    Quit();
  end;

  Update('https://collector:col2024@download.1x1.com.ua/private/update/Test/ver.json');

  //WriteLn(Str);
  //Str := GetOptionValue('s', 'sleep');

  //UnZipToDir('c:\temp\pdf_small.zip', 'c:\temp\12\34');
  Quit();
end;

constructor TAppUpd.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  StopOnException:=True;
end;

destructor TAppUpd.Destroy();
begin
  inherited Destroy();
end;

procedure TAppUpd.ShowHelp();
begin
  WriteLn(GetAppName(), ' ', GetAppVer(), ' ', {$I %DATE%});
  WriteLn('options:');
  WriteLn('  -u, --url');
  WriteLn('  -s, --sleep');
  WriteLn('  -p, --pause');
  WriteLn('  -d, --dir');
end;

var
  AppUpd: TAppUpd;
  {$R *.res}
begin
  AppUpd:=TAppUpd.Create(nil);
  AppUpd.Title:='App Updater';
  AppUpd.Run();
  AppUpd.Free();
end.

