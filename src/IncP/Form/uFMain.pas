unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ExtCtrls, ComCtrls,
  uFAbout, uFMedocCheckDocs, fpjson, uForms, uHttp;

type

  { TFMain }
  TFMain = class(TForm)
    ActionFMedocCheckDocs: TAction;
    ActionFAbout: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    ManuItemHelp: TMenuItem;
    Medoc: TMenuItem;
    MenuItemOprimizePDF: TMenuItem;
    MenuItemModules: TMenuItem;
    MenuItemAboutApp: TMenuItem;
    PanelClient: TPanel;
    Splitter1: TSplitter;
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedocCheckDocsExecute(Sender: TObject);
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

end.

