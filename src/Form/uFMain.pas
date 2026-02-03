unit uFMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ExtCtrls, uFAbout, uFMedocCheckDocs,
  fpjson, MyUnit in 'Utit/uHttp.pas';

type

  { TFMain }
  TFMain = class(TForm)
    ActionFMedocCheckDocs: TAction;
    ActionFAbout: TAction;
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    ManuItemHelp: TMenuItem;
    Medoc: TMenuItem;
    MedocCheckDocs: TMenuItem;
    Calculator: TMenuItem;
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

procedure ShowFormDock(aForm: TForm; aHost: TWinControl);
begin
  aForm.Hide();
  aForm.Parent := aHost;
  aForm.Align := alClient;
  aForm.BorderStyle := bsNone;
  aForm.Show();
end;

procedure ShowFormFloat(aForm: TForm);
begin
  aForm.Hide();
  aForm.Parent := nil;
  aForm.Align := alNone;
  aForm.BorderStyle := bsSizeable;
  aForm.Position := poMainFormCenter;
  aForm.Show();
end;

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

