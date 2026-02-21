// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList, Windows, ExtCtrls,
  ComCtrls, StdCtrls, fpjson,
  uFAbout, uFMedocCheckDocs, uFOptimizePDF, uFSettings, uFLogin,
  uWinManager, uLicence, uLog, uSettings, uFormState, uSys;

type
  { TFMain }
  TFMain = class(TForm)
    ActionSettings: TAction;
    ActionExit: TAction;
    ActionOptimizePDF: TAction;
    ActionLicense: TAction;
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
    procedure ActionLicenseExecute(Sender: TObject);
    procedure ActionOptimizePDFExecute(Sender: TObject);
    procedure ActionSettingsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItemCloseTabClick(Sender: TObject);
  private
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

procedure TFMain.ActionLicenseExecute(Sender: TObject);
begin
  //WinManager.Add(TFLicense);
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
  Log.Print('Програма вже запущена');
  if IsIconic(Handle) then
    ShowWindow(Handle, SW_RESTORE);

  Application.Restore();
  BringToFront();
  SetForegroundWindow(Handle);
end;

procedure TFMain.FormCreate(Sender: TObject);
var
  i: integer;
  Passw: String;
  Forms: array of TFormClass;
begin
  Conf := TConf.Create();
  FormStateRec := TFormStateRec.Create();

  Licence := TLicence.Create();
  Licence.LoadFromFile();

  OneInstance.Register(Handle);
  OneInstance.Free();

  Caption := Caption + ' ' + GetAppVer();

  Log := TLog.Create(MemoInfo1);
  Log.Print('Початок');

  WinManager := TWinManager.Create(PageControl1, PopupMenu1);
  Forms := [
    TFMedocCheckDocs,
    TFSettings
    //TFOptimizePDF
  ];

  for i := 0 to High(Forms) do
    WinManager.Add(Forms[i]);

  WinManager.SetActivePage(0);

  Passw := FormStateRec.GetItem('FSettings', 'LabeledEditPassword_Text', '');
  if (not Passw.IsEmpty()) then
  begin
    FLogin := TFLogin.Create(nil);
    FLogin.Caption := 'Авторизація';
    FLogin.OnlyPassw();
    if (FLogin.ShowModal() = mrOk) and (FLogin.EditPassword.Text = Passw) then
      Log.Print('Вхід по паролю')
    else
      Halt();
    FreeAndNil(FLogin);
  end;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  Log.Print('Завершення');
end;


end.

