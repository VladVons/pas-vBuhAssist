unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ExtCtrls,
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
    procedure ActionFAboutExecute(Sender: TObject);
    procedure ActionFMedocCheckDocsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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

procedure TFMain.FormCreate(Sender: TObject);
var
  I: Integer;
  Str: String;
  Json, Row: TJSONObject;
  Licenses: TJSONArray;
begin
  Json := TJSONObject.Create();
  Json.Add('type', 'get_licenses');
  Json.Add('app', 'vBuhAssist');
  Json.Add('firms', TJSONArray.Create(['88888801']));
  Json := PostJSON('https://windows.cloud-server.com.ua/api', Json);

  Licenses := Json.Arrays['licenses'];
  for I := 0 to Licenses.Count - 1 do
  begin
    Row := Licenses.Objects[I];
    Str := Row.Strings['firm'];
    WriteLn(Str);
  end;

  //ShowMessage(Response);
end;

end.

