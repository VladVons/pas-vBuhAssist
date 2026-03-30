// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, ValEdit, Buttons, fpjson, TypInfo, Variants, jsonparser,
  uFrStringGrid,
  uSys, uSysVcl, uHelper, uHelperVcl, uFBase, uWinManager, uExGrid;

type
  { TFWizard }
  TFWizard = class(TFBase)
    BitBtnNext: TBitBtn;
    BitBtnClose: TBitBtn;
    BitBtnPrev: TBitBtn;
    ComboBoxWizards: TComboBox;
    PageControl: TPageControl;
    PanelNav: TPanel;
    procedure BitBtnCloseClick(Sender: TObject);
    procedure BitBtnPrevClick(Sender: TObject);
    procedure BitBtnNextClick(Sender: TObject);
    procedure ComboBoxWizardsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fJScheme: TJSONObject;
    fClassMap: TStringList;
    fWinManager: TWinManager;
    fFileData: string;
    procedure ComboBoxWizardsChange();
    procedure AddControls(aForm: TForm; aCtrls: TJSONArray; aJConf: TJSONObject);
    procedure SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
    procedure LoadForm(aForm: TForm; aJObj: TJSONObject);
    procedure SaveForm(aForm: TForm; aJObj: TJSONObject);
  public
    procedure LoadScheme(const aName: string);
    procedure LoadData(const aFile: string);
    procedure Load(const aName: string);
    procedure SaveData();
  end;

implementation
{$R *.lfm}

procedure TFWizard.FormCreate(Sender: TObject);
begin
  inherited;

  fClassMap := TStringList.Create();
  fClassMap.CaseSensitive := False;

  fClassMap.BeginUpdate();
  fClassMap.AddObject('TLabel', TObject(TLabel));
  fClassMap.AddObject('TLabeledEdit', TObject(TLabeledEdit));
  fClassMap.AddObject('TEdit', TObject(TEdit));
  fClassMap.AddObject('TComboBox', TObject(TComboBox));
  fClassMap.AddObject('TCheckBox', TObject(TCheckBox));
  fClassMap.AddObject('TMemo', TObject(TMemo));
  fClassMap.AddObject('TValueListEditor', TObject(TValueListEditor));
  fClassMap.AddObject('TFrStringGrid', TObject(TFrStringGrid));
  fClassMap.EndUpdate();
end;

procedure TFWizard.ComboBoxWizardsChange();
var
  Str, Path: string;
  JObj: TJSONObject;
begin
  JObj := ComboBoxWizards.GetJObj();
  if (JObj = nil) then
    Exit();

  Str := JObj.Get('res', '');
  LoadScheme(Str);
  Path := ConcatPaths(['Data\12345', Str + '_dat.json']);
  LoadData(Path);
end;

procedure TFWizard.ComboBoxWizardsChange(Sender: TObject);
begin
  ComboBoxWizardsChange();
end;

procedure TFWizard.BitBtnPrevClick(Sender: TObject);
begin
  fWinManager.Next(-1);
end;

procedure TFWizard.BitBtnNextClick(Sender: TObject);
begin
  fWinManager.Next(1);
end;

procedure TFWizard.BitBtnCloseClick(Sender: TObject);
var
  Cnt: integer;
begin
  SaveData();
  Cnt := fWinManager.CloseActive();
  if (Cnt = 0) then
    if (not ComboBoxWizards.HasNext()) then
      Close()
    else begin
      ComboBoxWizards.Next(1);
      ComboBoxWizardsChange();
    end;
end;

procedure TFWizard.FormDestroy(Sender: TObject);
begin
  if (fWinManager <> nil) then
    fWinManager.CloseAll();
  FreeAndNil(fWinManager);

  FreeAndNil(fClassMap);

  ComboBoxWizards.ClearItems();
  inherited;
end;

procedure TFWizard.SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
begin
  if (not aCtrl.SetProperty(aName, aVal)) then
    Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
end;

procedure TFWizard.AddControls(aForm: TForm; aCtrls: TJSONArray; aJConf: TJSONObject);
var
  i, j, Idx, PosTop, PosLeft, BottomPad, ConfBottomPad: integer;
  Str, CtrlClass: string;
  JObjCtrl: TJSONObject;
  Ctrl: TControl;
  CClass: TComponentClass;
begin
  PosTop := aJConf.Get('_top', 0);
  PosLeft := aJConf.Get('_left', 0);
  ConfBottomPad := aJConf.Get('_bottompad', 0);

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
    if (Ctrl = nil) then
    begin
      CClass := TComponentClass(fClassMap.Objects[Idx]);
      Ctrl := TControl(CClass.Create(aForm));
      Ctrl.Name := Str;
    end;

    Inc(PosTop, JObjCtrl.Get('_toppad', 0));
    Ctrl.Top := PosTop;
    Ctrl.Left := Ctrl.Left + PosLeft;
    Ctrl.Parent := aForm;

    for j := 0 to JObjCtrl.Count - 1 do
    begin
      Str := JObjCtrl.Names[j];
      if (Str = 'left') then
        SetCtrlProperty(Ctrl, Str, PosLeft + JObjCtrl.Get(Str, 0))
      //else if (Str = 'align') then
      //  SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TAlign), JObjCtrl.Get(Str, '')))
      //else if (Str = 'borderstyle') then
      //  SetProperty(Ctrl, Str, GetEnumValue(TypeInfo(TBorderStyle), JObjCtrl.Get(Str, '')))
      else if (Str = 'lines') and (CtrlClass = 'TMemo') then
          TMemo(Ctrl).Lines := TStringList.Create().AddArray(JObjCtrl.Arrays[Str])
      else if (Str = 'items') and (CtrlClass = 'TComboBox') then
      begin
          TComboBox(Ctrl).Items := TStringList.Create().AddArray(JObjCtrl.Arrays[Str]);
          TComboBox(Ctrl).ItemIndex := 0;
      end
      else if (not Str.StartsWith('_')) then
        Ctrl.SetJProperty(JObjCtrl, Str);
    end;

    if (CtrlClass = 'TStringGrid') then
      TStringGridEx(Ctrl).HeadFromJson(JObjCtrl)
    else if (CtrlClass = 'TFrStringGrid') then
      TFrStringGrid(Ctrl).LoadHeadFromJson(JObjCtrl);

    BottomPad := JObjCtrl.Get('_bottompad', ConfBottomPad);
    if (Ctrl.Visible) and (BottomPad > 0) then
      Inc(PosTop, Ctrl.Height + BottomPad);
  end;
end;

procedure TFWizard.LoadScheme(const aName: string);
var
  i: integer;
  JArrTab, JArrCtrl: TJSONArray;
  JObjTab, JObjConf, JObjConfDef: TJSONObject;
  Form: TFBase;
begin
  if (fWinManager <> nil) then
    fWinManager.CloseAll();
  FreeAndNil(fWinManager);

  fWinManager := TWinManager.Create(PageControl, Nil);

  fJScheme := ResourceLoadJson(aName);
  JArrTab := TJSONArray(fJScheme.Find('tabs'));
  if (JArrTab = nil) then
  begin
    Log('e', Format('Не знайдено секцію `tabs` в %s', [aName]));
    FreeAndNil(fJScheme);
    Exit();
  end;

  Title := fJScheme.Get('caption', '');

  fWinManager.Visible(false);
  for i := 0 to JArrTab.Count - 1 do
  begin
    JObjTab := JArrTab.Objects[i];
    if (not JObjTab.Get('_enable', true)) then
      continue;

    Form := TFBase.Create(Nil);
    fWinManager.Add(Form);
    Form.Parent.Caption := JObjTab.Get('title', Format('title %d', [i]));
    Form.Name := Form.GetJName(JObjTab, i);
    Form.Caption := JObjTab.Get('caption', Format('caption %d', [i]));
    Form.Title := Form.Caption;

    JArrCtrl := TJSONArray(JObjTab.Find('controls'));
    if (JArrCtrl = nil) then
    begin
      Log('e', Format('Не знайдено секцію `controls` в закладці %d', [i+1]));
      continue;
    end;

    JObjConfDef := TJSONObject.Create();
    JObjConfDef.Add('_toppad', 0);
    JObjConfDef.Add('_bottompad', 5);
    JObjConfDef.Add('_left', 5);
    JObjConfDef.Add('_top', PanelTitle.Top + PanelTitle.Height + 15);

    JObjConf := TJSONObject(JObjTab.Find('conf'));
    if (JObjConf <> nil) then
      JObjConfDef.Update(JObjConf);

    AddControls(Form, JArrCtrl, JObjConfDef);
    JObjConfDef.Free();
  end;

  fWinManager.Visible(true);
  fWinManager.SetActivePage(0);
end;

procedure TFWizard.LoadForm(aForm: TForm; aJObj: TJSONObject);
var
  i: integer;
  CtrlName, CtrlClass: string;
  Ctrl: TControl;
  JObj: TJSONObject;
begin
  for i := 0 to aForm.ControlCount - 1 do
  begin
    Ctrl := aForm.Controls[i];
    CtrlName := Format('%s.%s', [aForm.Name, Ctrl.Name]);
    CtrlClass := Ctrl.ClassName();
    JObj := TJSONObject(aJObj.Find(CtrlName));
    if (JObj = nil) then
      continue;

    if (CtrlClass = 'TFrStringGrid') then
      TFrStringGrid(Ctrl).LoadDataFromJson(JObj.Arrays['val'])
    else if (CtrlClass = 'TValueListEditor') then
      ValueList_FromJson(TValueListEditor(Ctrl), JObj.Arrays['val'])
    else
      Ctrl.SetJProperty(JObj, JObj.Get('prop', ''), 'val');
  end;
end;

procedure TFWizard.LoadData(const aFile: string);
var
  i: integer;
  JObj: TJSONObject;
  Forms: TFormArray;
begin
  fFileData := aFile;

  if (aFile.FileExists()) then
    JObj := TJSONObject(FileLoadJson(aFile))
  else
    JObj := TJSONObject.Create();

  Forms := fWinManager.GetForms();
  for i := 0 to Length(Forms) - 1 do
    LoadForm(Forms[i], JObj);

  JObj.Free();
end;

procedure TFWizard.SaveForm(aForm: TForm; aJObj: TJSONObject);
var
  i: integer;
  CtrlName, CtrlClass, Prop: string;
  Ctrl: TControl;
  JItem: TJSONObject;
  JArr: TJSONArray;
begin
  for i := 0 to aForm.ControlCount - 1 do
  begin
    Ctrl := aForm.Controls[i];
    CtrlName := Format('%s.%s', [aForm.Name, Ctrl.Name]);
    if (not CtrlName.EndsWith('_s')) then
      continue;

    JItem := TJSONObject.Create();
    CtrlClass := Ctrl.ClassName();
    if (CtrlClass = 'TFrStringGrid') then
    begin
      JArr := TFrStringGrid(Ctrl).LoadDataToJson();
      JItem.Add('val', JArr);
    end else if (CtrlClass = 'TValueListEditor') then
    begin
      JArr := ValueList_ToJson(TValueListEditor(Ctrl));
      JItem.Add('val', JArr);
    end else begin
      Prop := Ctrl.GetInputName();
      if (not Prop.IsEmpty()) then
      begin
        JItem.Add('prop', Prop);
        Ctrl.GetJProperty(JItem, Prop, 'val');
      end;
    end;

    aJObj.Elements[CtrlName] := JItem;
  end;
end;

procedure TFWizard.SaveData();
var
  i: integer;
  Str: string;
  JObj: TJSONObject;
  Forms: TFormArray;
begin
  if (fFileData.IsEmpty()) then
    Exit();

  if (fFileData.FileExists()) then
    JObj := TJSONObject(FileLoadJson(fFileData))
  else
    JObj := TJSONObject.Create();

  try
    Forms := fWinManager.GetForms();
    for i := 0 to Length(Forms) - 1 do
      SaveForm(Forms[i], JObj);

    Str := JObj.FormatJSON();
    Str.ToFile(fFileData);
  finally
    JObj.Free();
  end;
end;

procedure TFWizard.Load(const aName: string);
var
  i: integer;
  ResName: string;
  JObj, JObjRes, JObjLoad: TJSONObject;
  JArr: TJSONArray;
begin
  JObjLoad := ResourceLoadJson(aName);
  JArr := TJSONArray(JObjLoad.Find('items'));
  for i := 0 to JArr.Count - 1 do
  begin
    ResName := JArr[i].AsString;
    JObjRes := ResourceLoadJson(ResName);
    JObj := TJSONObject.Create();
    JObj.Add('text', JObjRes.Get('caption', ''));
    JObj.Add('res', ResName);
    ComboBoxWizards.Add(JObj);

    JObjRes.Free();
  end;

  ComboBoxWizards.ItemIndex := 0;
  ComboBoxWizards.Visible := True;
  ComboBoxWizardsChange();
end;


end.

