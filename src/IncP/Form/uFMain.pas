// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList, Windows, ExtCtrls,
  ComCtrls, StdCtrls, fpjson,
  uFAbout, uFMedocCheckDocs, uFOptimizePDF, uFSettings, uFLogin, uFMessage, uDmCommon,
  uWinManager, uLicence, uLog, uSettings, uStateStore, uSys, uConst, uProtectTimer;

type
  { TFMain }
  TFMain = class(TForm)
    ActionSettings: TAction;
    ActionExit: TAction;
    ActionOptimizePDF: TAction;
    ActionUserAgreement: TAction;
    ActionFMedocCheckDocs: TAction;
    ActionFAbout: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    ManuItemHelp: TMenuItem;
    MemoInfo1: TMemo;
    Separator2: TMenuItem;
    MenuItemSettings: TMenuItem;
    MenuItemPrint: TMenuItem;
    Separator1: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemCloseTab: TMenuItem;
    MenuItemMedoc: TMenuItem;
    MenuItemLicense: TMenuItem;
    MenuItemOprimizePDF: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemAboutApp: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    Splitter1: TSplitter;
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedocCheckDocsExecute(Sender: TObject);
    procedure ActionUserAgreementExecute(Sender: TObject);
    procedure ActionOptimizePDFExecute(Sender: TObject);
    procedure ActionSettingsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItemCloseTabClick(Sender: TObject);
  private
    function UserAgreement(aConfirm: boolean): boolean;
    procedure WMShowMe(var aMsg: TMessage); message TOneInstance.WM_SHOWME;
  public
  end;

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

procedure TFMain.ActionFMedocCheckDocsExecute(Sender: TObject);
begin
  WinManager.Add(TFMedocCheckDocs);
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
begin
  FMessage := TFMessage.Create(nil);
  FMessage.Caption := 'Ліцензійна угода користувача';
  FMessage.Confirm := aConfirm;
  FMessage.Memo1.Lines.Assign(DmCommon.TextStoreLicence.Lines);
  Log.Print('i', FMessage.Caption);
  Result:= FMessage.ShowModal() = mrOK;
  FreeAndNil(FMessage);
end;


procedure TFMain.FormCreate(Sender: TObject);
var
  i: integer;
  Passw: string;
  Forms: array of TFormClass;
  //SL: TStringList;
begin
  ProtectTimer := TProtectTimer.Create(ParamStr(0));
  ProtectTimer.TimerRunRnd(True, 10000);

  Log := TLog.Create('app.log', MemoInfo1);
  Log.Print('i', 'Початок');

  Settings := TSettings.Create('app.ini');
  if (Settings.GetItem('UserAgreement', 'Accepted', '').IsEmpty()) then
    if (UserAgreement(True)) then
    begin
      Settings.SetItem('UserAgreement', 'Accepted', DateTimeToStr(Now()));
      Log.Print('i', 'Ліцензійна угода прийнята');
    end else begin
      ShowMessage('Для роботи з програмою потрібно підтвердити згоду');
      Halt();
    end;

  StateStore := TStateStore.Create('app_state.ini');

  Licence := TLicence.Create('app.lic');
  Licence.LoadFromFile();

  OneInstance.Register(Handle);
  OneInstance.Free();

  Caption := cAppName + ' ' + GetAppVer();

  WinManager := TWinManager.Create(PageControl1, PopupMenu1);
  Forms := [
    TFMedocCheckDocs,
    //TFOptimizePDF,
    TFSettings
  ];

  for i := 0 to High(Forms) do
    WinManager.Add(Forms[i]);

  WinManager.SetActivePage(0);

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

  WindowState := wsMaximized;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  Log.Print('i', 'Завершення');
end;


end.

