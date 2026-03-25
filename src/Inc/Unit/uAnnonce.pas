// Created: 2026.02.27
// Author: Vladimir Vons <VladVons@gmail.com>

unit uAnnonce;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, fpjson, DateUtils, LConvEncoding, Dialogs, System.UITypes, Process, Windows,
  uLog, uSettings, uLicence, uFMessage, uSys, uConst;

type
  TAnnonce = class(TSettings)
  private
    fLicence: TLicence;
    procedure OnTimer(aSender: TObject);
    function FindUpdate(aJObj: TJSONObject): TJSONObject;
  public
    constructor Create(const aFile: string; aLicence: TLicence);
    function Check(): TJSONObject;
    procedure CheckForUpdate();
    procedure CheckWithDelay();
  end;


var
  Annonce: TAnnonce;

implementation

constructor TAnnonce.Create(const aFile: string; aLicence: TLicence);
begin
  inherited Create(aFile);
  fLicence := aLicence;
end;

procedure TAnnonce.OnTimer(aSender: TObject);
var
  SkipDays: integer;
  Stdout, Title, Body, Id: string;
  Timer: TTimer;
  JItem: TJSONObject;
begin
  Timer := aSender as TTimer;

  Timer.Enabled := False;
  JItem := TJSONObject(PtrInt(Timer.Tag));
  try
    Title := JItem.Get('title', '');
    Body := JItem.Get('body', '');
    Stdout := JItem.Get('stdout', '');
    if (Stdout = 'console') then
    begin
      Log.Print('i', '= ' + Title + ' =');
      Log.Print('i', Body);
    end else if (Stdout = 'message') then
    begin
      FMessageShow(Title, Body);
    end;

    SkipDays := JItem.Get('skip_days', 0);
    Id := IntToStr(JItem.Get('id', 0));
    SetItem(Id, 'stdout', Stdout);
    SetItem(Id, 'title',  UTF8ToCP1251(Title));
    SetItem(Id, 'done', DateTimeToStr(Now()));
    SetItem(Id, 'next', DateTimeToStr(IncDay(Now(), SkipDays)));
  finally
    JItem.Free();
    Timer.Free();
  end;
end;

function TAnnonce.Check(): TJSONObject;
begin
  Result := fLicence.GetTypeFromHttp('get_annonce');
end;

function TAnnonce.FindUpdate(aJObj: TJSONObject): TJSONObject;
var
  i: integer;
  JItem: TJSONObject;
  Arr: TJSONArray;
begin
  Arr := aJObj.Arrays['list'];
  for i := 0 to Arr.Count - 1 do
  begin
    JItem := Arr.Objects[i];
    if (JItem.Get('type', '') = 'update') then
      Exit(JItem);
  end;
  Result := Nil;
end;

procedure TAnnonce.CheckForUpdate();
const
  cUpdater = 'vAppUpd.exe';
var
  Body, FileLog: string;
  JObj, JItem: TJSONObject;
  Params: TStringList;
  Process: TProcess;
begin
  Log.Print('i', 'Перевірка оновлень');

  JObj := Check();
  if (JObj = nil) then
  begin
    Log.Print('e', 'Помилка перевірки оновлень');
    Exit();
  end;

  Process := Nil;
  Params := Nil;
  try
    JItem := FindUpdate(JObj);
    if (JItem = nil) then
    begin
      Log.Print('i', 'Не знайдено оновлень');
      Exit();
    end;

    Body := JItem.Get('body', '');
    Log.Print('i', Body);
    if (MessageDlg(Body + '. Оновити ?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
      Exit();

    if (not FileExists(cUpdater)) then
    begin
      Log.Print('e', 'Не знайдено програму оновлювач ' + cUpdater);
      Exit();
    end;

    FileLog := ConcatPaths([GetAppConfigDir(False), cUpdater + '.log']);

    Params := TStringList.Create();
    Params.Add('--url=' + JItem.Get('url', ''));
    Params.Add('--dir=' + QuotedFile(GetAppDir()));
    Params.Add('--app=' + QuotedFile(ParamStr(0)));
    //Params.Add('--pid=' + IntToStr(GetCurrentProcessId()));
    Params.Add('--delay=2000');
    Params.Add('--log=' + QuotedFile(FileLog));
    Process := ExecProcess(cUpdater, Params, False);

    Log.Print('i', 'Перезавантаження програми');
    Sleep(1000);
    Halt();
  finally
    JObj.Free();
        FreeAndNil(Params);
    FreeAndNil(Process);
  end;
end;

procedure TAnnonce.CheckWithDelay();
var
  i, Delay: integer;
  Next, Id: string;
  JObj, JItem: TJSONObject;
  Arr: TJSONArray;
  Timer: TTimer;
begin
  JObj := Check();
  if (JObj = nil) then
    Exit();

  try
    Arr := JObj.Arrays['list'];
    for i := 0 to Arr.Count - 1 do
    begin
      JItem := Arr.Objects[i];

      Id := IntToStr(JItem.Get('id', 0));
      Next := GetItem(Id, 'next', '');
      if (not Next.IsEmpty()) and (StrToDateTime(Next) > Now()) then
         continue;

      Delay := JItem.Get('delay', cDelayAnnonce);

      Timer := TTimer.Create(Nil);
      Timer.OnTimer := @OnTimer;
      Timer.Enabled := True;
      Timer.Interval := Delay + random(Delay);
      Timer.Tag := PtrInt(JItem.Clone());
    end;
  finally
    FreeAndNil(JObj);
  end;
end;

end.

