// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList, Windows, ExtCtrls,
  ComCtrls, StdCtrls, fpjson,
  uFAbout, uFMedFindZvit, uFMedFindAkz, uFMedFindPdv, uFOptimizePDF, uFSettings, uFLogin, uFMessage,
  uWinManager, uLicence, uLog, uSettings, uStateStore, uSys, uSysVcl, uConst, uProtectTimer, uAnnonce, uMed, uVarHelper;

type
  { TFMain }
  TFMain = class(TForm)
    ActionFMedFindPdv: TAction;
    ActionFMedFindAkz: TAction;
    ActionHelp: TAction;
    ActionName: TAction;
    ActionCheckForUpdate: TAction;
    ActionSettings: TAction;
    ActionExit: TAction;
    ActionOptimizePDF: TAction;
    ActionUserAgreement: TAction;
    ActionFMedFindZvit: TAction;
    ActionFAbout: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    ManuItemHelp: TMenuItem;
    MemoInfo1: TMemo;
    MenuItemFMedFindPdv: TMenuItem;
    MenuItemCloseTab: TMenuItem;
    MenuItemFMedFindAkz: TMenuItem;
    MenuItemHep: TMenuItem;
    MenuItemCheckForUpdates: TMenuItem;
    PopupMenuPageControl: TPopupMenu;
    Separator2: TMenuItem;
    MenuItemSettings: TMenuItem;
    MenuItemPrint: TMenuItem;
    Separator1: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemFMedFindZvit: TMenuItem;
    MenuItemLicense: TMenuItem;
    MenuItemOprimizePDF: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemAboutApp: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Splitter1: TSplitter;
    TimerAnnonce: TTimer;
    procedure ActionCheckForUpdateExecute(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedFindAkzExecute(Sender: TObject);
    procedure ActionFMedFindPdvExecute(Sender: TObject);
    procedure ActionFMedFindZvitExecute(Sender: TObject);
    procedure ActionHelpExecute(Sender: TObject);
    procedure ActionUserAgreementExecute(Sender: TObject);
    procedure ActionOptimizePDFExecute(Sender: TObject);
    procedure ActionSettingsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItemCloseTabClick(Sender: TObject);
    procedure TimerAnnonceTimer(Sender: TObject);
  private
    procedure CheckPassw();
    procedure CheckUserAgreement();
    procedure CheckAnnonce();
    procedure FormsLoad();
    function UserAgreement(aConfirm: boolean): boolean;
    procedure WMShowMe(var aMsg: TMessage); message TOneInstance.WM_SHOWME;
  public
  end;

  function HtmlHelp(hwndCaller: HWND; pszFile: PChar; uCommand: UINT; dwData: PtrUInt): HWND; stdcall;
    external 'hhctrl.ocx' name 'HtmlHelpA';

var
  FMain: TFMain;

implementation

{$R *.lfm}
{ TFMain }

procedure TFMain.ActionFAboutExecute(Sender: TObject);
begin
  ShowOrCreateForm(TFAbout);
end;

procedure TFMain.ActionExitExecute(Sender: TObject);
begin
  Halt();
end;

procedure TFMain.ActionCheckForUpdateExecute(Sender: TObject);
begin
  Annonce.CheckForUpdate();
end;

procedure TFMain.ActionFMedFindZvitExecute(Sender: TObject);
begin
  WinManager.Add(TFMedFindZvit);
end;

procedure TFMain.ActionFMedFindAkzExecute(Sender: TObject);
begin
  WinManager.Add(TFMedFindAkz);
end;

procedure TFMain.ActionFMedFindPdvExecute(Sender: TObject);
begin
  WinManager.Add(TFMedFindPdv);
end;

procedure TFMain.ActionHelpExecute(Sender: TObject);
begin
  HtmlHelp(0, PChar(GetAppName() + '.chm'), $0000, 0);
end;

procedure TFMain.ActionUserAgreementExecute(Sender: TObject);
begin
  UserAgreement(False);
end;

procedure TFMain.ActionOptimizePDFExecute(Sender: TObject);
begin
  WinManager.Add(TFOptimizePDF);
end;

procedure TFMain.ActionSettingsExecute(Sender: TObject);
begin
  WinManager.Add(TFSettings);
end;

procedure TFMain.MenuItemCloseTabClick(Sender: TObject);
begin
  WinManager.CloseActive();
end;

procedure TFMain.TimerAnnonceTimer(Sender: TObject);
begin
  Annonce.CheckWithDelay();
  TimerAnnonce.Enabled := False;
end;

procedure TFMain.WMShowMe(var aMsg: TMessage);
begin
  Log.Print('w', 'Програма вже запущена');
  if IsIconic(Handle) then
    ShowWindow(Handle, SW_RESTORE);

  Application.Restore();
  BringToFront();
  SetForegroundWindow(Handle);
end;

function TFMain.UserAgreement(aConfirm: boolean): boolean;
var
  Title, Body: string;
begin
  Title := 'Ліцензійна угода користувача';
  Body := ResourceLoadString('Text_UserAgreement');
  Log.Print('i', Title);
  Result := (FMessageShow(Title, Body, aConfirm) = mrOK);
end;

procedure TFMain.CheckPassw();
var
  Passw: string;
begin
  Passw := StateStore.GetItem('FSettings', 'LabeledEditPassword_Text', '');
  if (not Passw.IsEmpty()) then
  begin
    FLogin := TFLogin.Create(nil);
    FLogin.Caption := 'Авторизація';
    FLogin.OnlyPassw();
    if (FLogin.ShowModal() = mrOk) and (FLogin.EditPassword.Text = Passw) then
      Log.Print('i', 'Вхід по паролю')
    else
      Halt();
    FreeAndNil(FLogin);
  end;
end;

procedure TFMain.CheckUserAgreement();
begin
  if (Settings.GetItem('UserAgreement', 'Accepted', '').IsEmpty()) then
    if (UserAgreement(True)) then
    begin
      Settings.SetItem('UserAgreement', 'Accepted', DateTimeToStr(Now()));
      Log.Print('i', 'Ліцензійна угода прийнята');
    end else begin
      ShowMessage('Для роботи з програмою потрібно підтвердити згоду');
      Halt();
    end;
end;

procedure TFMain.CheckAnnonce();
var
 CheckUpdates: integer;
begin
  CheckUpdates := StateStore.GetItem('FSettings', 'CheckBoxUpdates_Checked', 0);
  if (CheckUpdates <> 0) then
  begin
    if (cDelayAnnonce = 0) then
      Annonce.CheckWithDelay()
    else begin
      TimerAnnonce.Interval := cDelayAnnonce + random(cDelayAnnonce);
      TimerAnnonce.Enabled := True;
    end;
  end;
end;

procedure TFMain.FormsLoad();
const
  cSect = 'Forms';
  cAutoForm: TStringArray = ('TFMedFindZvit', 'TFMedFindAkz', 'TFMedFindPdv', 'TFSettings');
var
  i: integer;
  SL: TStringList;
  Cls: TClass;
begin
  RegisterClasses([TFMedFindZvit, TFMedFindAkz, TFMedFindPdv, TFOptimizePDF, TFSettings]);
  WinManager := TWinManager.Create(PageControl1, PopupMenuPageControl);

  SL := Settings.GetSection(cSect);
  try
    if (SL.Count = 0) then
      for i := 0 to Length(cAutoForm) - 1 do
      begin
        SL.Add(cAutoForm[i]);
        Settings.SetItem(cSect, SL.GetLast(), 1);
      end;

    for i := 0 to SL.Count - 1 do
      if (Settings.GetItem(cSect, SL[i], 0) = 1) then
      begin
        Cls := GetClass(SL[i]);
        if (Assigned(Cls)) then
          WinManager.Add(TFormClass(Cls));
      end;
    WinManager.SetActivePage(0);
  finally
    SL.Free();
  end;
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  ProtectTimer := TProtectTimer.Create(ParamStr(0));
  ProtectTimer.TimerRunRnd(True, cDelayAnnonce);

  Log := TLog.Create('app.log', MemoInfo1);
  Log.Print('i', 'Початок роботи');

  StateStore := TStateStore.Create('app_state.ini');

  Licence := TLicence.Create('app.lic');
  Licence.LoadFromFile();

  Annonce := TAnnonce.Create('app_annonce.ini', Licence);

  Settings := TSettings.Create('app.ini');
  CheckUserAgreement();

  MedIni := TMedIni.Create('app_med.ini');

  OneInstance.Register(Handle);
  OneInstance.Free();

  FormsLoad();

  CheckPassw();
  CheckAnnonce();

  Caption := cAppName + ' ' + GetAppVer();
  //WindowState := wsMaximized;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  Log.Print('i', 'Завершення роботи');
end;

end.

