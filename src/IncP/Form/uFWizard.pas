// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Grids, fpjson, TypInfo,
  uSysVcl, uVarHelper, uFBase, uWinManager;

type
  { TFWizard }
  TFWizard = class(TFBase)
    PageControl1: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fJScheme: TJSONObject;
    fClassMap: TStringList;
    procedure AddControls(aForm: TForm; aCtrls: TJSONArray);
    procedure CtrlSetStringGrid(aCtrl: TStringGrid; aJObj: TJSONObject);
    procedure SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
    procedure SetProperty(aCtrl: TComponent; const aName: string; aJObj: TJSONObject);
    procedure OnStringGridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  public
    procedure LoadScheme(const aName: string);
  end;

implementation
{$R *.lfm}

procedure TFWizard.FormCreate(Sender: TObject);
begin
  inherited;

  fClassMap := TStringList.Create();
  fClassMap.CaseSensitive := False;

  fClassMap.AddObject('TLabel', TObject(TLabel));
  fClassMap.AddObject('TLabeledEdit', TObject(TLabeledEdit));
  fClassMap.AddObject('TEdit', TObject(TEdit));
  fClassMap.AddObject('TComboBox', TObject(TComboBox));
  fClassMap.AddObject('TStringGrid', TObject(TStringGrid));
  fClassMap.AddObject('TMemo', TObject(TMemo));
end;

procedure TFWizard.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fClassMap);
  inherited;
end;

procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
var
  PropInfo: PPropInfo;
begin
  PropInfo := GetPropInfo(aCtrl, aName);
  if (Assigned(PropInfo)) then
    SetPropValue(aCtrl, aName, aVal)
  else
    Log('e', Format('Властивість `%s` не знайдена у `%s`', [aName, aCtrl.ClassName()]));
end;

procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aJObj: TJSONObject);
var
  JData: TJSONData;
begin
  JData := aJObj.Find(aName);
  if (Assigned(JData)) then
    case JData.JSONType of
      jtNumber:
        SetProperty(aCtrl, aName, jData.AsFloat);
      jtString:
        SetProperty(aCtrl, aName, jData.AsString);
      jtBoolean:
        SetProperty(aCtrl, aName, jData.AsBoolean);
    end;
end;

procedure TFWizard.OnStringGridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  OpenDialog: TOpenDialog;
  StringGrid: TStringGrid;
begin
  if (aCol = 1) then // колонка "файл"
  begin
    OpenDialog := TOpenDialog.Create(Nil);
    if (OpenDialog.Execute()) then
    begin
      StringGrid := Sender as TStringGrid;
      StringGrid.Cells[aCol, aRow] := ExtractFileName(OpenDialog.FileName);
    end;
  end;
end;

procedure TFWizard.CtrlSetStringGrid(aCtrl: TStringGrid; aJObj: TJSONObject);
var
  i: integer;
  Fields: TJSONArray;
  JObj: TJSONObject;
begin
  aCtrl.Options := aCtrl.Options + [goEditing];
  //aCtrl.OnSelectCell := @OnStringGridSelectCell;

  Fields := aJObj.Arrays['fields'];
  aCtrl.ColCount := Fields.Count;
  aCtrl.FixedCols := 0;
  for i := 0 to Fields.Count - 1 do
  begin
     JObj := Fields.Objects[i];
     aCtrl.Cells[i, 0] := JObj.Get('caption', '');
     aCtrl.ColWidths[i] := JObj.Get('width', 100);
  end;
end;

procedure TFWizard.AddControls(aForm: TForm; aCtrls: TJSONArray);
var
  i, j, Idx, PosTop, PosLeft: integer;
  Str, CtrlType: string;
  JObjCtrl: TJSONObject;
  Ctrl: TControl;
  CClass: TComponentClass;
  SLSkip: TStringList;
begin
  SLSkip := TStringList.Create().AddArray(['type']);

  PosTop := PanelTitle.Top + PanelTitle.Height + 20;
  PosLeft := 10;

  for i := 0 to aCtrls.Count - 1 do
  begin
    JObjCtrl := aCtrls.Objects[i];
    if (not JObjCtrl.Get('enable', true)) then
      continue;

    CtrlType := JObjCtrl.Get('type', '');
    Idx := fClassMap.IndexOf(CtrlType);
    if (Idx = -1) then
    begin
      Log('e', Format('Не відомий тип %s', [CtrlType]));
      continue;
    end;

    Str := JObjCtrl.Get('name', Format('%s_%d', [CtrlType, i]));
    Ctrl := TControl(FindComponent(Str));
    if (not Assigned(Ctrl)) then
    begin
      CClass := TComponentClass(fClassMap.Objects[Idx]);
      Ctrl := TControl(CClass.Create(aForm));
      Ctrl.Name := Str;
    end;

    Ctrl.Parent := aForm;
    Ctrl.Top := PosTop;
    Ctrl.Left := PosLeft;

    for j := 0 to JObjCtrl.Count - 1 do
    begin
      Str := JObjCtrl.Names[j];
      if (SLSkip.IndexOf(Str) <> -1) then
        continue
      else if (Str = 'align') then
        SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TAlign), JObjCtrl.Get(Str, '')))
      else if (Str = 'borderstyle') then
        SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TBorderStyle), JObjCtrl.Get(Str, '')))
      else if (Str = 'lines') and (CtrlType = 'TMemo') then
        TMemo(Ctrl).Lines := TStringList.Create().AddArray(JObjCtrl.Arrays['lines'])
      else
        SetProperty(Ctrl, Str, JObjCtrl);
    end;

    if (CtrlType = 'TStringGrid') then
      CtrlSetStringGrid(TStringGrid(Ctrl), JObjCtrl);

    Inc(PosTop, Ctrl.Height + 5);
  end;

  SLSkip.Free();
end;

procedure TFWizard.LoadScheme(const aName: string);
var
  i: integer;
  Tabs, Ctrls: TJSONArray;
  TabObj: TJSONObject;
  WinManager: TWinManager;
  Form: TFBase;
begin
  WinManager := TWinManager.Create(PageControl1, Nil);

  fJScheme := ResourceLoadJson(aName);
  Tabs := TJSONArray(fJScheme.Find('tabs'));
  if (not Assigned(Tabs)) then
  begin
    Log('e', Format('Не знайдено секцію `tabs` в %s', [aName]));
    Exit();
  end;

  for i := 0 to Tabs.Count - 1 do
  begin
    TabObj := Tabs.Objects[i];
    if (not TabObj.Get('enable', true)) then
      continue;

    Form := TFBase.Create(Nil);
    Form.Name := Format('form_%d', [i]);
    Form.Caption := TabObj.Get('caption', Format('caption %d', [i]));

    WinManager.Add(Form);
    Form.Parent.Caption := TabObj.Get('title', Format('title %d', [i]));

    Ctrls := TJSONArray(TabObj.Find('controls'));
    if (not Assigned(Ctrls)) then
    begin
      Log('e', Format('Не знайдено секцію `controls` в закладці %d', [i+1]));
      continue;
    end;

    AddControls(Form, Ctrls);
  end;

  WinManager.SetActivePage(0);
end;

end.

