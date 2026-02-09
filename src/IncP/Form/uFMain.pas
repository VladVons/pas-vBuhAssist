unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ExtCtrls, ComCtrls, StdCtrls, fpjson,
  uFAbout, uFMedocCheckDocs, uFLicense, uFOptimizePDF, uForms, uHttp;

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
    MenuItemMedoc: TMenuItem;
    MenuItemLicense: TMenuItem;
    MenuItemOprimizePDF: TMenuItem;
    MenuItemModules: TMenuItem;
    MenuItemAboutApp: TMenuItem;
    Panel1: TPanel;
    PanelClient: TPanel;
    Splitter1: TSplitter;
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedocCheckDocsExecute(Sender: TObject);
    procedure ActionLicenseExecute(Sender: TObject);
    procedure ActionOptimizePDFExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PanelClientClick(Sender: TObject);
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
    FAbout.Show();
end;

procedure TFMain.ActionFMedocCheckDocsExecute(Sender: TObject);
begin
    ShowFormDock(FMedocCheckDocs, PanelClient);
end;

procedure TFMain.ActionLicenseExecute(Sender: TObject);
begin
    ShowFormDock(FLicense, PanelClient);
end;

procedure TFMain.ActionOptimizePDFExecute(Sender: TObject);
begin
  ShowFormDock(FOptimizePDF, PanelClient);
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  MemoInfo := MemoInfo1;
end;

procedure TFMain.PanelClientClick(Sender: TObject);
begin

end;

end.

