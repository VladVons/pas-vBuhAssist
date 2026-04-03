// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, ValEdit, Buttons, fpjson, TypInfo, Variants, jsonparser, LConvEncoding,
  uFrStringGrid,
  uSys, uSysVcl, uVarUtil, uHelper, uHelperVcl, uFBase, uFBaseScroll, uWinManager, uExGrid, uLog;

type
  TFWizard = class;

  TWizardUser = class(TPersistent)
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
  private
    fParent: TFWizard;
    procedure SaveXml(const aName: string);
  public
    constructor Create(aParent: TFWizard);
  end;

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
    fJScheme, fData: TJSONObject;
    fClassMap: TStringList;
    fWinManager: TWinManager;
    fWizardUser: TWizardUser;
    fFileData: string;
    procedure AddControls(aForm: TScrollingWinControl; aCtrls: TJSONArray; aJConf: TJSONObject);
    procedure ComboBoxWizardsChange();
    procedure LoadForm(aForm: TForm; aJObj: TJSONObject);
    procedure SaveForm(aForm: TForm; aJObj: TJSONObject);
    procedure SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
    procedure SetData(aJObj: TJSONObject);
    procedure SetEventByName(aComponent: TComponent; const aEventName, aHandlerName: string);
  public
    function  GetData(): TJSONObject;
    procedure LoadScheme(const aName: string);
    procedure LoadData(const aFile: string);
    procedure LoadAll(const aName: string; aJObj: TJSONObject);
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
  fClassMap.AddObject('TButton', TObject(TButton));
  fClassMap.AddObject('TValueListEditor', TObject(TValueListEditor));
  fClassMap.AddObject('TFrStringGrid', TObject(TFrStringGrid));
  fClassMap.EndUpdate();

  fWizardUser := TWizardUser.Create(self);
end;

procedure TFWizard.FormDestroy(Sender: TObject);
begin
  if (fWinManager <> nil) then
    fWinManager.CloseAll();
  FreeAndNil(fWinManager);

  FreeAndNil(fClassMap);
  FreeAndNil(fData);
  FreeAndNil(fWizardUser);

  ComboBoxWizards.ClearItems();
  inherited;
end;

procedure TFWizard.SetData(aJObj: TJSONObject);
begin
  FreeAndNil(fData);
  fData := TJSONObject(aJObj.Clone());
end;

function TFWizard.GetData(): TJSONObject;
begin
  if (not Assigned(fData)) then
    Log('i', 'fData is nil');
  Result := fData;
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

procedure TFWizard.SetEventByName(aComponent: TComponent; const aEventName, aHandlerName: string);
var
  PropInfo: PPropInfo;
  Method: TMethod;
begin
  PropInfo := GetPropInfo(aComponent.ClassInfo, aEventName);
  if (PropInfo = nil) then
  begin
    Log('e', Format('_event `%s` не знайдено в `%s`', [aEventName, aComponent.ClassName]));
    Exit();
  end;

  Method.Code := fWizardUser.MethodAddress(aHandlerName);
  if (Method.Code = nil) then
  begin
    Log('e', Format('Обробник  `%s` не знайдено в `%s`', [aHandlerName, fWizardUser.ClassName()]));
    Exit();
  end;

  Method.Data := fWizardUser;
  SetMethodProp(aComponent, PropInfo, Method);
end;

procedure TFWizard.SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
begin
  if (not aCtrl.SetProperty(aName, aVal)) then
    Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
end;

procedure TFWizard.AddControls(aForm: TScrollingWinControl; aCtrls: TJSONArray; aJConf: TJSONObject);
var
  i, j, Idx, PosTop, PosLeft, BottomPad, ConfBottomPad: integer;
  Str, CtrlClass: string;
  JObjCtrl, JObjEvent: TJSONObject;
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
      Log('e', Format('Не відомий _class %s', [CtrlClass]));
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

    JObjEvent := TJSONObject(JObjCtrl.Find('_event'));
    if (JObjEvent <> nil) then
      for j := 0 to JObjEvent.Count - 1 do
        SetEventByName(Ctrl, JObjEvent.Names[j], JObjEvent.Items[j].AsString);

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
  Str: string;
  JArrTab, JArrCtrl: TJSONArray;
  JObjTab, JObjConf, JObjConfDef: TJSONObject;
  Form: TFBaseScroll;
  Macros: TMacros;
begin
  PanelNav.Enabled := true;

  Str := ResourceLoadString(aName, 'json');
  if (fData <> nil) then
  begin
    Macros := TMacros.Create();
    Str := Macros.Exec(Str, fData);
    Macros.Free();
  end;
  fJScheme := TJSONObject(GetJSON(Str.DelBOM()));

  Title := fJScheme.Get('caption', '');
  Log('i', Format('Помічник %s', [Title]));

  JArrTab := TJSONArray(fJScheme.Find('tabs'));
  if (JArrTab = nil) then
  begin
    Log('e', Format('Не знайдено секцію `tabs` в %s', [aName]));
    FreeAndNil(fJScheme);
    Exit();
  end;

  if (fWinManager <> nil) then
    fWinManager.CloseAll();
  FreeAndNil(fWinManager);

  fWinManager := TWinManager.Create(PageControl, Nil);
  fWinManager.Visible(false);

  for i := 0 to JArrTab.Count - 1 do
  begin
    JObjTab := JArrTab.Objects[i];
    if (not JObjTab.Get('_enable', true)) then
      continue;

    Form := TFBaseScroll.Create(Nil);
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

    AddControls(Form.ScrollBox, JArrCtrl, JObjConfDef);
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
  Form: TScrollingWinControl;
begin
  Form := TFBaseScroll(aForm).ScrollBox;

  for i := 0 to Form.ControlCount - 1 do
  begin
    Ctrl := Form.Controls[i];
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
  Form: TScrollingWinControl;
begin
  Form := TFBaseScroll(aForm).ScrollBox;

  for i := 0 to Form.ControlCount - 1 do
  begin
    Ctrl := Form.Controls[i];
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

procedure TFWizard.LoadAll(const aName: string; aJObj: TJSONObject);
var
  i: integer;
  ResName: string;
  JObj, JObjRes, JObjLoad: TJSONObject;
  JArr: TJSONArray;
begin
  SetData(aJObj);

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

  JObjLoad.Free();
end;

//---
constructor TWizardUser.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
end;

procedure TWizardUser.SaveXml(const aName: string);
var
  Str, StrXds, Path: string;
  Macros: TMacros;
  JObj: TJSONObject;
begin
  JObj := fParent.GetData();

  Macros := TMacros.Create();
  try
    StrXds := ResourceLoadString(aName, 'xml');
    Str := Macros.Exec(StrXds, JObj).DelEmptyLines();
    Path := ConcatPaths(['Data', aName + '.xml']);
    Str := UTF8ToCP1251(Str);
    Str.ToFile(Path);
    Log.Print('i', Path);
  finally
    Macros.Free();
  end;
end;

procedure TWizardUser.OnClick_FWizardPdv5_Save(Sender: TObject);
begin
  SaveXml('J1360102');
  SaveXml('J1312603');
end;

end.

