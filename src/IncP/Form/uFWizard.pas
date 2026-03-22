unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Grids, fpjson, TypInfo,
  uSysVcl, uFBase, uWinManager, uLog;

type
  { TFWizard }
  TFWizard = class(TFBase)
    PageControl1: TPageControl;
  private
    fJScheme: TJSONObject;
    procedure AddControls(aForm: TForm; aCtrls: TJSONArray);
    procedure CtrlSetLabeledEdit(aCtrl: TLabeledEdit; aJObj: TJSONObject);
    procedure CtrlSetLabel(aCtrl: TLabel; aJObj: TJSONObject);
    procedure CtrlSetMemo(aCtrl: TMemo; aJObj: TJSONObject);
    procedure CtrlSetStringGrid(aCtrl: TStringGrid; aJObj: TJSONObject);
    procedure SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
  public
    procedure LoadScheme(const aName: string);
  end;

implementation
{$R *.lfm}

procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
var
  PropInfo: PPropInfo;
begin
  PropInfo := GetPropInfo(aCtrl, aName);
  if (Assigned(PropInfo)) then
    SetPropValue(aCtrl, aName, aVal);
end;

procedure TFWizard.CtrlSetLabeledEdit(aCtrl: TLabeledEdit; aJObj: TJSONObject);
var
  Str: string;
begin
  aCtrl.LabelPosition := lpAbove;
  Str := aJObj.Get('caption', 'default');
  aCtrl.EditLabel.Caption := Str;
end;

procedure TFWizard.CtrlSetLabel(aCtrl: TLabel; aJObj: TJSONObject);
var
  Str: string;
begin
  Str := aJObj.Get('caption', 'default');
  aCtrl.Caption := Str;
end;

procedure TFWizard.CtrlSetMemo(aCtrl: TMemo; aJObj: TJSONObject);
var
  Str: string;
begin
  Str := aJObj.Get('text', 'default');
  aCtrl.Text := Str;

  if (not aJObj.Get('border', true)) then
    aCtrl.BorderStyle := bsNone;
end;

procedure TFWizard.CtrlSetStringGrid(aCtrl: TStringGrid; aJObj: TJSONObject);
var
  i: integer;
  Fields: TJSONArray;
  JObj: TJSONObject;
begin
  Fields := aJObj.Arrays['fields'];
  aCtrl.ColCount := Fields.Count;
  aCtrl.FixedCols := 0;
  for i := 0 to Fields.Count - 1 do
  begin
     JObj := Fields.Objects[i];
     aCtrl.Cells[i, 0] := JObj.Get('caption', '');
     aCtrl.ColWidths[i] := JObj.Get('width', 80);
  end;
end;


procedure TFWizard.AddControls(aForm: TForm; aCtrls: TJSONArray);
var
  bool: boolean;
  i, Int, PosTop, PosLeft: integer;
  Typ: string;
  JObjCtrl: TJSONObject;
  Ctrl: TControl;
begin
  PosTop := PanelTitle.Top + PanelTitle.Height + 20;
  PosLeft := 10;

  for i := 0 to aCtrls.Count - 1 do
  begin
    JObjCtrl := aCtrls.Objects[i];
    if (not JObjCtrl.Get('enable', true)) then
      continue;

    Typ := JObjCtrl.Get('type', '');
    if (Typ = 'TLabeledEdit') then
    begin
      Ctrl := TLabeledEdit.Create(Nil);
      CtrlSetLabeledEdit(TLabeledEdit(Ctrl), JObjCtrl);
    end else if (Typ = 'TLabel') then
    begin
      Ctrl := TLabel.Create(Nil);
      CtrlSetLabel(TLabel(Ctrl), JObjCtrl);
    end else if (Typ = 'TMemo') then
    begin
      Ctrl := TMemo.Create(Nil);
      CtrlSetMemo(TMemo(Ctrl), JObjCtrl);
    end else if (Typ = 'TStringGrid') then
    begin
      Ctrl := TStringGrid.Create(Nil);
      CtrlSetStringGrid(TStringGrid(Ctrl), JObjCtrl);
    end else begin
      Log.Print('e', Format('Не відомий тип %s', [Typ]));
      continue;
    end;

    Ctrl.Parent := aForm;
    Ctrl.Top := PosTop;
    Ctrl.Left := PosLeft;

    Int := JObjCtrl.Get('width', 0);
    if (Int <> 0) then
      SetProperty(Ctrl, 'width', Int);

    Int := JObjCtrl.Get('height', 0);
    if (Int <> 0) then
      SetProperty(Ctrl, 'height', Int);

    bool := JObjCtrl.Get('readonly', false);
    SetProperty(Ctrl, 'readonly', bool);

    Ctrl.Name := JObjCtrl.Get('name', Format('%s_%d', [Ctrl.ClassName, i]));
    Inc(PosTop, Ctrl.Height + 5);
  end;
end;

procedure TFWizard.LoadScheme(const aName: string);
var
  i: integer;
  Str: string;
  Tabs, Ctrls: TJSONArray;
  TabObj: TJSONObject;
  WinManager: TWinManager;
  Form: TFBase;
begin
  WinManager := TWinManager.Create(PageControl1, Nil);

  fJScheme := ResourceLoadJson(aName);
  Tabs := fJScheme.Arrays['tabs'];
  for i := 0 to Tabs.Count - 1 do
  begin
    TabObj := Tabs.Objects[i];
    if (not TabObj.Get('enable', true)) then
      continue;

    Form := TFBase.Create(Nil);
    Form.Name := Format('form_%d', [i]);
    Str := TabObj.Get('caption', Format('caption %d', [i]));
    Form.Caption := Str;

    WinManager.Add(Form);
    Form.Parent.Caption := Str;

    Ctrls := TJSONArray(TabObj.Find('controls'));
    if (Assigned(Ctrls)) then
      AddControls(Form, Ctrls);
  end;

  WinManager.SetActivePage(0);
end;

end.

