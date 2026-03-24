// Created: 2026.03.20
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Grids, fpjson, TypInfo, Variants,
  uSys, uSysVcl, uVarHelper, uFBase, uWinManager;

type
  { TFWizard }
  TFWizard = class(TFBase)
    PageControl1: TPageControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fJScheme: TJSONObject;
    fClassMap: TStringList;
    procedure AddControls(aForm: TForm; aCtrls: TJSONArray; aJConf: TJSONObject);
    function GetFormName(aJObj: TJSONObject; aIdx: integer): string;
    procedure CtrlSetStringGrid(aCtrl: TStringGrid; aJObj: TJSONObject);
    procedure SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
    procedure SetProperty(aCtrl: TComponent; const aName: string; aJObj: TJSONObject);
    procedure OnStringGridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  public
    procedure LoadScheme(const aName: string);
    procedure LoadData(const aFile: string);
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

function TFWizard.GetFormName(aJObj: TJSONObject; aIdx: integer): string;
begin
  Result := aJObj.Get('name', Format('form_%d', [aIdx]));
end;

//procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
//var
//  Str, P: string;
//  PropInfo: PPropInfo;
//  Ctrl: TObject;
//begin
//  Ctrl := aCtrl;
//  Str := aName;
//
//  // "font.style" := "fsBold"
//  while Pos('.', Str) > 0 do
//  begin
//     P := Str.Before('.');
//     Delete(Str, 1, Length(P) + 1);
//
//     PropInfo := GetPropInfo(Ctrl, P);
//     if (Assigned(PropInfo)) then
//       Ctrl := GetObjectProp(Ctrl, PropInfo)
//     else begin
//       Log('e', Format('Властивість `%s` не знайдена у `%s`', [P, aCtrl.ClassName()]));
//       Exit();
//     end;
//  end;
//
//  PropInfo := GetPropInfo(Ctrl, Str);
//  if (not Assigned(PropInfo)) then
//  begin
//   Log('e', Format('Властивість `%s` не знайдена у `%s`', [aName, aCtrl.ClassName()]));
//   Exit();
//  end;
//
//  case PropInfo^.PropType^.Kind of
//    tkEnumeration:
//      SetOrdProp(Ctrl, PropInfo, GetEnumValue(PropInfo^.PropType, VarToStr(aVal)));
//    tkSet:
//      SetSetProp(Ctrl, PropInfo, VarToStr(aVal));
//  else
//    SetPropValue(Ctrl, Str, aVal);
//  end;
//end;

procedure TFWizard.SetProperty(aCtrl: TComponent; const aName: string; aVal: variant);
var
  i: integer;
  Part: string;
  Parts: TStringArray;
  PropInfo: PPropInfo;
  Ctrl: TObject;
begin
  Ctrl := aCtrl;
  Parts := aName.Split(['.']);
  for i := 0 to High(Parts) do
  begin
     Part := Parts[i];
     PropInfo := GetPropInfo(Ctrl, Part);
     if (not Assigned(PropInfo)) then
     begin
       Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
       Exit();
     end;

     if (i < High(Parts)) then
     begin
       if (PropInfo^.PropType^.Kind <> tkClass) then
       begin
         Log('e', Format('Помилка у %s.%s=%s', [aCtrl.ClassName(), aName, VarToStr(aVal)]));
         Exit();
       end;

       Ctrl := GetObjectProp(Ctrl, PropInfo);
     end;
  end;

  case PropInfo^.PropType^.Kind of
    tkEnumeration:
      SetOrdProp(Ctrl, PropInfo, GetEnumValue(PropInfo^.PropType, VarToStr(aVal)));
    tkSet:
      SetSetProp(Ctrl, PropInfo, VarToStr(aVal));
  else
    SetPropValue(Ctrl, Part, aVal);
  end;
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
    if (not Assigned(Ctrl)) then
    begin
      CClass := TComponentClass(fClassMap.Objects[Idx]);
      Ctrl := TControl(CClass.Create(aForm));
      Ctrl.Name := Str;
    end;

    Ctrl.Parent := aForm;
    Ctrl.Top := PosTop;
    Ctrl.Left := Ctrl.Left + PosLeft;

    for j := 0 to JObjCtrl.Count - 1 do
    begin
      Str := JObjCtrl.Names[j];
      if (Str = 'left') then
        SetProperty(Ctrl, Str, PosLeft + JObjCtrl.Get(Str, 0))
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
        SetProperty(Ctrl, Str, JObjCtrl);
    end;

    if (CtrlClass = 'TStringGrid') then
      CtrlSetStringGrid(TStringGrid(Ctrl), JObjCtrl);

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
  WinManager: TWinManager;
  Form: TFBase;
 begin
  WinManager := TWinManager.Create(PageControl1, Nil);

  fJScheme := ResourceLoadJson(aName);
  JArrTab := TJSONArray(fJScheme.Find('tabs'));
  if (not Assigned(JArrTab)) then
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
    Form.Name := GetFormName(JObjTab, i);
    Form.Caption := JObjTab.Get('caption', Format('caption %d', [i]));

    WinManager.Add(Form);
    Form.Parent.Caption := JObjTab.Get('title', Format('title %d', [i]));

    JArrCtrl := TJSONArray(JObjTab.Find('controls'));
    if (not Assigned(JArrCtrl)) then
    begin
      Log('e', Format('Не знайдено секцію `controls` в закладці %d', [i+1]));
      continue;
    end;

    JObjConfDef := TJSONObject.Create();
    JObjConfDef.Add('_bottompad', 5);
    JObjConfDef.Add('_left', 5);
    JObjConfDef.Add('_top', PanelTitle.Top + PanelTitle.Height + 15);

    JObjConf := TJSONObject(JObjTab.Find('conf'));
    if (Assigned(JObjConf)) then
      JObjConfDef.Update(JObjConf);

    AddControls(Form, JArrCtrl, JObjConfDef);
    JObjConfDef.Free();
  end;

  WinManager.SetActivePage(0);
end;

procedure TFWizard.LoadData(const aFile: string);
var
  i, j: integer;
  Str, FormName: string;
  JArrTab, JArrCtrl: TJSONArray;
  JObjTab, JObjCtrl, JObjData: TJSONObject;
begin
   if (not FileExists(aFile)) then
   begin
     Log('e', Format('Не знайдено файл %s', [aFile]));
     Exit();
   end;
   JObjData := TJSONObject(FileLoadJson(aFile));

  if (not Assigned(fJScheme)) then
  begin
    Log('e', 'Схема не завантажна');
    Exit();
  end;

  JArrTab := TJSONArray(fJScheme.Find('tabs'));
  for i := 0 to JArrTab.Count - 1 do
  begin
    JObjTab := JArrTab.Objects[i];
    FormName := GetFormName(JObjTab, i);

    JArrCtrl := TJSONArray(JObjTab.Find('controls'));
    for j := 0 to JArrCtrl.Count - 1 do
    begin
      JObjCtrl := JArrCtrl.Objects[j];
      if (JObjCtrl.Get('_save', false)) then
        Str := JObjData.Get('_class', '');
    end;
  end;
end;

end.

