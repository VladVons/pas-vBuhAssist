// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Grids, ValEdit, fpjson, TypInfo, Variants, jsonparser, uSys,
  uSysVcl, uHelper, uHelperVcl, uFBase, uWinManager, uGrid;

type
  { TFWizard }
  TFWizard = class(TFBase)
    PageControl1: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fJScheme: TJSONObject;
    fClassMap: TStringList;
    fWinManager: TWinManager;
    fFileData: string;
    procedure AddControls(aForm: TForm; aCtrls: TJSONArray; aJConf: TJSONObject);
    procedure SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
    procedure OnStringGridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  public
    procedure LoadScheme(const aName: string);
    procedure LoadData(const aFile: string);
    procedure SaveData();
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
  fClassMap.AddObject('TCheckBox', TObject(TCheckBox));
  fClassMap.AddObject('TMemo', TObject(TMemo));
  fClassMap.AddObject('TStringGrid', TObject(TStringGrid));
  fClassMap.AddObject('TValueListEditor', TObject(TValueListEditor));
end;

procedure TFWizard.FormDestroy(Sender: TObject);
begin
  SaveData();
  FreeAndNil(fClassMap);
  inherited;
end;

procedure TFWizard.SetCtrlProperty(aCtrl: TControl; const aName: string; aVal: variant);
begin
  if (not aCtrl.SetProperty(aName, aVal)) then
    Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
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
      StringGridHeadFromJson(TStringGrid(Ctrl), JObjCtrl);

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
  FreeAndNil(fWinManager);
  fWinManager := TWinManager.Create(PageControl1, Nil);

  fJScheme := ResourceLoadJson(aName);
  JArrTab := TJSONArray(fJScheme.Find('tabs'));
  if (JArrTab = nil) then
  begin
    Log('e', Format('Не знайдено секцію `tabs` в %s', [aName]));
    FreeAndNil(fJScheme);
    Exit();
  end;

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

  fWinManager.SetActivePage(0);
end;

procedure TFWizard.LoadData(const aFile: string);
var
  i, j: integer;
  CtrlName, CtrlClass: string;
  JObj, JObjData: TJSONObject;
  Forms: TFormArray;
  Ctrl: TControl;
begin
  fFileData := aFile;
  if (FileExists(aFile)) then
    JObjData := TJSONObject(FileLoadJson(aFile))
  else
    JObjData := TJSONObject.Create();

  Forms := fWinManager.GetForms();
  for i := 0 to Length(Forms) - 1 do
    for j := 0 to Forms[i].ControlCount - 1 do
    begin
      Ctrl := Forms[i].Controls[j];
      CtrlName := Format('%s.%s', [Forms[i].Name, Ctrl.Name]);
      CtrlClass := Ctrl.ClassName();
      JObj := TJSONObject(JObjData.Find(CtrlName));
      if (JObj <> nil) then
        if (CtrlClass = 'TStringGrid') then
          StringGridDataFromJson(TStringGrid(Ctrl), JObj.Arrays['val'])
        else if (CtrlClass = 'TValueListEditor') then
          ValueListFromJson(TValueListEditor(Ctrl), JObj.Arrays['val'])
        else
          Ctrl.SetJProperty(JObj, JObj.Get('prop', ''), 'val');
    end;

  JObjData.Free();
end;

procedure TFWizard.SaveData();
var
  i, j: integer;
  Str, Prop, CtrlName, CtrlClass: string;
  JObjData, JItem: TJSONObject;
  JArr: TJSONArray;
  Forms: TFormArray;
  Ctrl: TControl;
begin
  JObjData := TJSONObject.Create();
  try
    Forms := fWinManager.GetForms();
    for i := 0 to Length(Forms) - 1 do
      for j := 0 to Forms[i].ControlCount - 1 do
      begin
        Ctrl := Forms[i].Controls[j];
        CtrlName := Format('%s.%s', [Forms[i].Name, Ctrl.Name]);
        if (CtrlName.EndsWith('_s')) then
        begin
          JItem := TJSONObject.Create();

          CtrlClass := Ctrl.ClassName();
          if (CtrlClass = 'TStringGrid') then
          begin
            JArr := StringGridDataToJson(TStringGrid(Ctrl));
            JItem.Add('val', JArr);
          end else if (CtrlClass = 'TValueListEditor') then
          begin
            JArr := ValueListToJson(TValueListEditor(Ctrl));
            JItem.Add('val', JArr);
          end else begin
            Prop := Ctrl.GetInputName();
            if (not Prop.IsEmpty()) then
            begin
              JItem.Add('prop', Prop);
              Ctrl.GetJProperty(JItem, Prop, 'val');
            end;
          end;
          JObjData.Add(CtrlName, JItem);
        end;
      end;

    Str := JObjData.FormatJSON();
    Str.ToFile(fFileData);
  finally
    JObjData.Free();
  end;
end;

end.

