// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, ValEdit, Buttons, fpjson, TypInfo, Variants, jsonparser,
  uFrStringGrid,
  uSys, uSysVcl, uMacros, uHelper, uHelperVcl, uFBase, uFBaseScroll, uWinManager, uExGrid;

const
  cMarkSaveLoad = '_s';
  cMarkSave = '_S';

type
  { TFWizard }
  TFWizard = class(TFBase)
    BitBtnClose: TBitBtn;
    BitBtnNext: TBitBtn;
    BitBtnPrev: TBitBtn;
    ComboBoxWizards: TComboBox;
    PageControl: TPageControl;
    PanelNav: TPanel;
    procedure BitBtnCloseClick(Sender: TObject);
    procedure BitBtnNextClick(Sender: TObject);
    procedure BitBtnPrevClick(Sender: TObject);
    procedure ComboBoxWizardsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fJScheme, fDataExt: TJSONObject;
    fClassMap: TStringList;
    fWinManager: TWinManager;
    fHelper: TPersistent;
    fFileData, fDirData: string;

    procedure AddControls(aForm: TScrollingWinControl; aCtrls: TJSONArray; aJConf: TJSONObject);
    procedure ComboBoxWizardsChange();
    procedure GetVal(const aFile: string; aJObj: TJSONObject);
    function GetFormData(aJObj: TJSONObject; aForm: TForm): boolean;
    procedure GetFormsData(aJObj: TJSONObject);
    procedure LoadForm(aForm: TForm; aJObj: TJSONObject);
    procedure SaveData();
    procedure SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
    procedure SetData(aJObj: TJSONObject);
    procedure SetEventByName(aComponent: TComponent; const aEventName, aHandlerName: string);
    procedure SetEvent(aCtrl: TControl; aJObj: TJSONObject);
  public
    function  GetDataExt(): TJSONObject;
    function  GetDataInt(): TJSONObject;
    function  GetDir(): string;
    function  GetVal(const aFile: string): TJSONObject;
    function  FindCtrl(const aName: string): TComponent;
    function  FindSchemeItem(const aName: string): TJSONObject;
    procedure Load(const aDir: string; aJObjWiz, aJObjMed: TJSONObject);
    procedure LoadFormData(const aFile: string);
    procedure LoadFormScheme(const aName: string);
    procedure SetHelper(aHelper: TPersistent);
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
  fClassMap.AddObject('TImage', TObject(TImage));
  fClassMap.EndUpdate();
end;

procedure TFWizard.FormDestroy(Sender: TObject);
begin
  if (fWinManager <> nil) then
    fWinManager.CloseAll();
  FreeAndNil(fWinManager);

  FreeAndNil(fClassMap);
  FreeAndNil(fDataExt);
  FreeAndNil(fHelper);

  ComboBoxWizards.ClearItems();

  inherited;
end;

function TFWizard.GetDir(): string;
begin
  Result := fDirData;
end;

procedure TFWizard.SetHelper(aHelper: TPersistent);
begin
  FreeAndNil(fHelper);
  fHelper := aHelper;
end;

procedure TFWizard.SetData(aJObj: TJSONObject);
begin
  FreeAndNil(fDataExt);
  fDataExt := TJSONObject(aJObj.Clone());
end;

function TFWizard.GetDataExt(): TJSONObject;
begin
  Result := fDataExt;
end;

function TFWizard.FindSchemeItem(const aName: string): TJSONObject;
var
  i, j: integer;
  JArr, JArrTab: TJSONArray;
  JObj, JObjTab: TJSONObject;
begin
  JArrTab := fJScheme.Arrays['tabs'];
  for i := 0 to JArrTab.Count - 1 do
  begin
    JObjTab := JArrTab.Objects[i];
    if (JObjTab.Get('_enable', true)) then
    begin
      JArr := JObjTab.Arrays['_controls'];
      for j := 0 to JArr.Count - 1 do
      begin
        JObj := JArr.Objects[j];
        if (JObj.Get('_enable', true)) and (JObj.Get('name', '') = aName) then
          Exit(JObj);
      end;
    end;
  end;

  Result := nil;
end;

function TFWizard.FindCtrl(const aName: string): TComponent;
var
  Form: TForm;
begin
  Form := fWinManager.GetActiveForm();
  Result := TFBaseScroll(Form).ScrollBox.FindComponent(aName);
end;

function TFWizard.GetDataInt(): TJSONObject;
var
  i: integer;
  SL: TStringList;
begin
  Result := TJSONObject.Create();
  SL := GetDirFiles(fDirData, '*.json');
  for i := 0 to SL.Count - 1 do
    GetVal(SL[i], Result);
  SL.Free();
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
  LoadFormScheme(Str);
  Path := ConcatPaths([fDirData, Str + '.json']);
  LoadFormData(Path);
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
  if (fHelper = nil) then
  begin
    Log('i', 'Не ініціалізовано Helper');
    Exit();
  end;

  PropInfo := GetPropInfo(aComponent.ClassInfo, aEventName);
  if (PropInfo = nil) then
  begin
    Log('e', Format('_event `%s` не знайдено в `%s`', [aEventName, aComponent.ClassName]));
    Exit();
  end;

  Method.Code := fHelper.MethodAddress(aHandlerName);
  if (Method.Code = nil) then
  begin
    Log('e', Format('Обробник  `%s` не знайдено в `%s`', [aHandlerName, fHelper.ClassName()]));
    Exit();
  end;

  Method.Data := fHelper;
  SetMethodProp(aComponent, PropInfo, Method);
end;

procedure TFWizard.SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
begin
  if (not aCtrl.SetProperty(aName, aVal)) then
    Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
end;

procedure TFWizard.SetEvent(aCtrl: TControl; aJObj: TJSONObject);
var
  i, Idx: integer;
  Str: string;
  JObj: TJSONObject;
begin
  JObj := TJSONObject(aJObj.Find('_event'));
  if (JObj = nil) then
    Exit();

  for i := 0 to JObj.Count - 1 do
    begin
      Str := JObj.Items[i].AsString;
      Idx := Str.PosEx(':');
      if (Idx > 0) then
      begin
        aCtrl.Hint := Str.RightFrom(Idx);
        Str := Str.Left(Idx - 1);
      end;
      SetEventByName(aCtrl, JObj.Names[i], Str);
    end;
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

    SetEvent(Ctrl, JObjCtrl);

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
      TStringGridEx(Ctrl).LoadHeadFromJson(JObjCtrl)
    else if (CtrlClass = 'TFrStringGrid') then
      TFrStringGrid(Ctrl).LoadHeadFromJson(JObjCtrl, self)
    else if (CtrlClass = 'TImage') then
    begin
      Str := JObjCtrl.Get('_file', '');
      TImage(Ctrl).Picture.LoadFromFile(Str);
    end;

    BottomPad := JObjCtrl.Get('_bottompad', ConfBottomPad);
    if (Ctrl.Visible) and (BottomPad > 0) then
      Inc(PosTop, Ctrl.Height + BottomPad);
  end;
end;

procedure TFWizard.LoadFormScheme(const aName: string);
var
  i, j: integer;
  Str: string;
  JArrTab, JArrCtrl: TJSONArray;
  JObjTab, JObjConf, JObjConfDef: TJSONObject;
  Form: TFBaseScroll;
  Macros: TMacros;
  TabSheet: TTabSheet;
begin
  PanelNav.Enabled := true;

  Str := ResourceLoadString(aName, 'json');
  if (fDataExt <> nil) then
  begin
    Macros := TMacros.Create();
    Macros.Load(Str);
    Str := Macros.Parse(fDataExt);
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

    for j := 0 to JObjTab.Count - 1 do
    begin
      Str := JObjTab.Names[j];
      if (not Str.StartsWith('_')) then
        Form.SetJProperty(JObjTab, Str);
    end;

    Form.Parent.Caption := JObjTab.Get('_title', Format('title %d', [i]));
    Form.Name := Form.GetJName(JObjTab, i);
    Form.Title := Form.Caption;

    SetEvent(Form.Parent, JObjTab);

    JArrCtrl := TJSONArray(JObjTab.Find('_controls'));
    if (JArrCtrl = nil) then
    begin
      Log('e', Format('Не знайдено секцію `_controls` в закладці %d', [i+1]));
      continue;
    end;

    JObjConfDef := TJSONObject.Create();
    JObjConfDef.Add('_toppad', 0);
    JObjConfDef.Add('_bottompad', 5);
    JObjConfDef.Add('_left', 5);
    //JObjConfDef.Add('_top', PanelTitle.Top + PanelTitle.Height + 15);
    JObjConfDef.Add('_top', 5);

    JObjConf := TJSONObject(JObjTab.Find('_conf'));
    if (JObjConf <> nil) then
      JObjConfDef.Update(JObjConf);

    AddControls(Form.ScrollBox, JArrCtrl, JObjConfDef);
    JObjConfDef.Free();
  end;

  fWinManager.Visible(true);
  fWinManager.SetActivePage(0);

  // Force OnShow event for one page only
  if (fWinManager.GetPageCount() = 1) then
  begin
    TabSheet := fWinManager.GetPage(0);
    TabSheet.Hide();
    TabSheet.Show();
  end;
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
    if (not CtrlName.EndsWith(cMarkSaveLoad)) then
      continue;

    CtrlClass := Ctrl.ClassName();
    JObj := TJSONObject(aJObj.Find(CtrlName));
    if (JObj = nil) then
      continue;

    if (CtrlClass = 'TFrStringGrid') then
      TFrStringGrid(Ctrl).Import(JObj.Objects['val'])
    else if (CtrlClass = 'TValueListEditor') then
      ValueList_FromJson(TValueListEditor(Ctrl), JObj.Arrays['val'])
    else
      Ctrl.SetJProperty(JObj, JObj.Get('prop', ''), 'val');
  end;
end;

procedure TFWizard.GetVal(const aFile: string; aJObj: TJSONObject);
var
  i: integer;
  Key: string;
  JObj: TJSONObject;
  JData: TJSONData;
begin
  JObj := TJSONObject(FileLoadJson(aFile));
  try
    for i := 0 to JObj.Count - 1 do
    begin
      Key := JObj.Names[i];
      JData := JObj.Objects[Key].Find('val');
      if (JData <> nil) then
        aJObj.SetKey(Key, JData.Clone());
    end;
  finally
    JObj.Free();
  end;
end;

function TFWizard.GetVal(const aFile: string): TJSONObject;
begin
  Result := TJSONObject.Create();
  GetVal(aFile, Result);
end;

procedure TFWizard.LoadFormData(const aFile: string);
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

function TFWizard.GetFormData(aJObj: TJSONObject; aForm: TForm): boolean;
var
  i: integer;
  CtrlName, CtrlClass, Prop: string;
  Ctrl: TControl;
  JObj, JItem: TJSONObject;
  JArr: TJSONArray;
  Form: TScrollingWinControl;
begin
  Form := TFBaseScroll(aForm).ScrollBox;

  for i := 0 to Form.ControlCount - 1 do
  begin
    Ctrl := Form.Controls[i];
    CtrlName := Format('%s.%s', [aForm.Name, Ctrl.Name]);
    if (not CtrlName.EndsWithAny([cMarkSaveLoad, cMarkSave])) then
      continue;

    JItem := TJSONObject.Create();
    CtrlClass := Ctrl.ClassName();
    if (CtrlClass = 'TFrStringGrid') then
    begin
      Result := TFrStringGrid(Ctrl).TableCheck();
      if (not Result) then
        Exit();

      JObj := TFrStringGrid(Ctrl).Export();
      JItem.Add('val', JObj);
    end else if (CtrlClass = 'TValueListEditor') then
    begin
      JArr := ValueList_ToJson(TValueListEditor(Ctrl));
      JItem.Add('val', JArr);
    end else if (CtrlClass = 'TMemo') then
    begin
      JArr := TStringList(TMemo(Ctrl).Lines).GetJson();
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

  Result := True;
end;

procedure TFWizard.GetFormsData(aJObj: TJSONObject);
var
  i: integer;
  Forms: TFormArray;
begin
  Forms := fWinManager.GetForms();
  for i := 0 to Length(Forms) - 1 do
    GetFormData(aJObj, Forms[i]);
end;

procedure TFWizard.SaveData();
var
  Str: string;
  JObj: TJSONObject;
begin
  if (fFileData.IsEmpty()) then
    Exit();

  if (fFileData.FileExists()) then
    JObj := TJSONObject(FileLoadJson(fFileData))
  else
    JObj := TJSONObject.Create();

  try
    GetFormsData(JObj);
    Str := JObj.FormatJSON();
    Str.ToFile(fFileData);
  finally
    JObj.Free();
  end;
end;

procedure TFWizard.Load(const aDir: string; aJObjWiz, aJObjMed: TJSONObject);
var
  i: integer;
  ResName: string;
  JObj, JObjRes: TJSONObject;
  JArr: TJSONArray;
begin
  Working(True);
  SetData(aJObjMed);

  if (not DirectoryExists(aDir)) then
    ForceDirectories(aDir);
  fDirData := aDir;

  JArr := TJSONArray(aJObjWiz.Find('items'));
  for i := 0 to JArr.Count - 1 do
  begin
    ResName := JArr[i].AsString;
    JObjRes := TJSONObject(ResourceLoadJson(ResName));

    JObj := TJSONObject.Create();
    JObj.Add('text', JObjRes.Get('caption', ''));
    JObj.Add('res', ResName);
    ComboBoxWizards.Add(JObj);

    JObjRes.Free();
  end;

  ComboBoxWizards.ItemIndex := 0;
  ComboBoxWizards.Visible := True;
  ComboBoxWizardsChange();

  Working(False);
end;

end.

