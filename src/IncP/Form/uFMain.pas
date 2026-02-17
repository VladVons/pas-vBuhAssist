// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList, Windows,
  ExtCtrls, ComCtrls, StdCtrls, fpjson,
  uFAbout, uFMedocCheckDocs, uFLicense, uFOptimizePDF, uWinManager, uLicence, uLog, uSettings, uConst, uFormState, uSys;

type

  { TFMain }
  TFMain = class(TForm)
    ActionOptimizePDF: TAction;
    ActionLicense: TAction;
    ActionFMedocCheckDocs: TAction;
    ActionFAbout: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    ManuItemHelp: TMenuItem;
    MemoInfo1: TMemo;
    MenuItemCloseTab: TMenuItem;
    MenuItemMedoc: TMenuItem;
    MenuItemLicense: TMenuItem;
    MenuItemOprimizePDF: TMenuItem;
    MenuItemModules: TMenuItem;
    MenuItemAboutApp: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    Splitter1: TSplitter;
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedocCheckDocsExecute(Sender: TObject);
    procedure ActionLicenseExecute(Sender: TObject);
    procedure ActionOptimizePDFExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemCloseTabClick(Sender: TObject);
  private
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

procedure TFMain.ActionFMedocCheckDocsExecute(Sender: TObject);
begin
  WinManager.Add(TFMedocCheckDocs);
end;

procedure TFMain.ActionLicenseExecute(Sender: TObject);
begin
  WinManager.Add(TFLicense);
end;

procedure TFMain.ActionOptimizePDFExecute(Sender: TObject);
begin
  WinManager.Add(TFOptimizePDF);
end;

procedure TFMain.MenuItemCloseTabClick(Sender: TObject);
begin
  WinManager.CloseActive();
end;

procedure TFMain.FormCreate(Sender: TObject);
var
  i: integer;
  Forms: array of TFormClass;
begin
  Conf := TConf.Create();
  FormStateRec := TFormStateRec.Create();

  Licence := TLicence.Create();
  Licence.LoadFromFile();

  Caption := Caption + ' ' +  GetAppVer();
  Log := TLog.Create(MemoInfo1);
  Log.Print('Початок');

  CreateMutex(nil, True, 'MyUniqMutex_QpTfRRasS_1971');
  if (GetLastError() = ERROR_ALREADY_EXISTS) then
  begin
    ShowMessage('Програма вже запущена');
    Log.Print('Програма вже запущена');
    Halt();
  end;

  WinManager := TWinManager.Create(PageControl1, PopupMenu1);
  Forms := [
    TFMedocCheckDocs,
    TFOptimizePDF
  ];

  for i := 0 to High(Forms) do
    WinManager.Add(Forms[i]);

  WinManager.SetActivePage(0);
end;


end.

