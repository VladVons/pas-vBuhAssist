unit uAnnonce;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, fpjson, DateUtils, LConvEncoding,
  uLog, uSettings, uLicence, uFMessage;

type
  TAnnonce = class(TSettings)
  private
    fLicence: TLicence;
    procedure OnTimer(aSender: TObject);
  public
    constructor Create(const aFile: string; aLicence: TLicence);
    procedure Check();
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
  Stdout, Title, Id: string;
  Timer: TTimer;
  JItem: TJSONObject;
  SL: TStringList;
begin
  Timer := aSender as TTimer;

  Timer.Enabled := False;
  JItem := TJSONObject(PtrInt(Timer.Tag));
  SL := TStringList.Create();
  try
    Title := JItem.Get('title', '');
    SL.Text := StringReplace(JItem.Get('body', ''), '\n', LineEnding, [rfReplaceAll]);
    Stdout := JItem.Get('stdout', '');
    if (Stdout = 'console') then
    begin
      Log.Print('i', '= ' + Title + ' =');
      Log.Print('i', SL);
    end else if (Stdout = 'message') then
    begin
      FMessageShow(Title, SL);
    end;

    SkipDays := JItem.Get('skip_days', 0);
    Id := IntToStr(JItem.Get('id', 0));
    SetItem(Id, 'stdout', Stdout);
    SetItem(Id, 'title',  UTF8ToCP1251(Title));
    SetItem(Id, 'done', DateTimeToStr(Now()));
    SetItem(Id, 'next', DateTimeToStr(IncDay(Now(), SkipDays)));
  finally
    SL.Free();
    JItem.Free();
    Timer.Free();
  end;
end;

procedure TAnnonce.Check();
var
  i, Delay: integer;
  Next, Id: string;
  JObj, JItem: TJSONObject;
  Arr: TJSONArray;
  Timer: TTimer;
begin
  JObj := fLicence.GetTypeFromHttp('get_annonce');
  try
    if (Assigned(JObj))then
    begin
      Arr := JObj.Arrays['list'];
      for i := 0 to Arr.Count - 1 do
      begin
        JItem := Arr.Objects[i];

        Id := IntToStr(JItem.Get('id', 0));
        Next := GetItem(Id, 'next', '');
        if (not Next.IsEmpty()) and (StrToDateTime(Next) > Now()) then
           continue;

        Delay := JItem.Get('delay', 10000);

        Timer := TTimer.Create(Nil);
        Timer.OnTimer := @OnTimer;
        Timer.Enabled := True;
        Timer.Interval := Delay + random(Delay);
        Timer.Tag := PtrInt(JItem.Clone());
      end;
    end;
  finally
    FreeAndNil(JObj);
  end;
end;

end.

