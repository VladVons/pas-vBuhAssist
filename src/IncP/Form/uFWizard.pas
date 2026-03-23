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
    procedure PanelTitleClick(Sender: TObject);
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

procedure TFWizard.PanelTitleClick(Sender: TObject);
begin

end;

procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
var
  Str, P: string;
  PropInfo: PPropInfo;
  Ctrl: TObject;
begin
  Ctrl := aCtrl;
  Str := aName;
  while Pos('.', Str) > 0 do
  begin
     P := Str.Before('.');
     Delete(Str, 1, Length(P) + 1);

     PropInfo := GetPropInfo(Ctrl, P);
     if (Assigned(PropInfo)) then
       Ctrl := GetObjectProp(Ctrl, PropInfo)
     else
       Ctrl := Nil;
  end;

  if (Assigned(Ctrl)) and (Assigned(GetPropInfo(Ctrl, Str))) then
    SetPropValue(Ctrl, Str, aVal)
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
  Str, CtrlClass: string;
  JObjCtrl: TJSONObject;
  Ctrl: TControl;
  CClass: TComponentClass;
begin
  PosTop := PanelTitle.Top + PanelTitle.Height + 20;
  PosLeft := 10;

  for i := 0 to aCtrls.Count - 1 do
  begin
    JObjCtrl := aCtrls.Objects[i];
    if (not JObjCtrl.Get('_enable', true)) then
      continue;

    CtrlClass := JObjCtrl.Get('_class', '');
    Idx := fClassMap.IndexOf(CtrlClass);
    if (Idx = -1) then
    begin
      Log('e', Format('Не відомий тип %s', [CtrlClass]));
      continue;
    end;

    Str := JObjCtrl.Get('name', Format('%s_%d', [CtrlClass, i]));
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
      if (Str.StartsWith('_')) then
        continue
      else if (Str = 'align') then
        SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TAlign), JObjCtrl.Get(Str, '')))
      else if (Str = 'borderstyle') then
        SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TBorderStyle), JObjCtrl.Get(Str, '')))
      else if (Str = 'lines') and (CtrlClass = 'TMemo') then
          TMemo(Ctrl).Lines := TStringList.Create().AddArray(JObjCtrl.Arrays[Str])
      else if (Str = 'items') and (CtrlClass = 'TComboBox') then
      begin
          TComboBox(Ctrl).Items := TStringList.Create().AddArray(JObjCtrl.Arrays[Str]);
          TComboBox(Ctrl).ItemIndex := 0;
      end
      else
        SetProperty(Ctrl, Str, JObjCtrl);
    end;

    if (CtrlClass = 'TStringGrid') then
      CtrlSetStringGrid(TStringGrid(Ctrl), JObjCtrl);

    Inc(PosTop, Ctrl.Height + 5);
  end;
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
    if (not TabObj.Get('_enable', true)) then
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

