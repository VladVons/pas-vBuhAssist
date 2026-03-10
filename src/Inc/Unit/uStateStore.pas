// Created: 2026.02.06
// Author: Vladimir Vons <VladVons@gmail.com>

unit uStateStore;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, IniFiles, StdCtrls, ExtCtrls, Controls, Spin, Graphics, DBGrids,
  uSettings;

type
  TCtrlProc = procedure(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile) of object;

  TStateStore = class(TSettings)
  private
    procedure SaveGrid(const aName: string; aCtrl: TDBGrid; aIni: TIniFile);
    procedure LoadGrid(const aName: string; aCtrl: TDBGrid; aIni: TIniFile);
    procedure SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
    procedure LoadProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
    procedure Walk(aForm: TWinControl; aProc: TCtrlProc);
  public
    procedure ComboBoxSetIndex(const aItems: array of TComboBox; aIndex: integer = 0);
    procedure Load(aForm: TWinControl);
    procedure LoadGrid(const aName: string; aCtrl: TDBGrid);
    procedure Save(aForm: TWinControl);
    procedure SetCtrlColor(aForm: TWinControl; aColor: TColor; const aType: string);
  end;

  TPropGuard = class
  private
    fObjs: array of TObject;
    fProps: array of String;
    fValues: array of Variant;
  public
    constructor Create(const aObjs: array of TObject; const aProp: String; const aValue: Variant);
    destructor Destroy(); override;
  end;

var
  StateStore: TStateStore = Nil;

implementation

procedure TStateStore.ComboBoxSetIndex(const aItems: array of TComboBox; aIndex: integer = 0);
var
  xItem: TComboBox;
begin
  for xItem in aItems do
      if (Assigned(xItem)) and (xItem.Items.Count > aIndex) and (xItem.ItemIndex = -1) then
         xItem.ItemIndex := aIndex;
end;

procedure TStateStore.LoadGrid(const aName: string; aCtrl: TDBGrid);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  LoadGrid(aName, aCtrl, Ini);
  Ini.Free();
end;

procedure TStateStore.LoadGrid(const aName: string; aCtrl: TDBGrid; aIni: TIniFile);
var
  i, Width: integer;
  Col: TColumn;
begin
  for i := 0 to aCtrl.Columns.Count - 1 do
  begin
    Col := aCtrl.Columns[i];
    Width := aIni.ReadInteger(aName, Format('%s_col_%d_width', [aCtrl.Name, i]), 0);
    if (Width > 0) then
      Col.Width := Width;
  end;
end;

procedure TStateStore.SaveGrid(const aName: string; aCtrl: TDBGrid; aIni: TIniFile);
var
  i: integer;
  Col: TColumn;
begin
  for i := 0 to aCtrl.Columns.Count - 1 do
  begin
    Col := aCtrl.Columns[i];
    if (Col.Width > 0) then
      aIni.WriteInteger(aName, Format('%s_col_%d_width', [aCtrl.Name, i]), Col.Width);
  end;
end;

procedure TStateStore.LoadProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
var
  Idx: integer;
begin
  if (aCtrl is TComboBox) then
  begin
     Idx := aIni.ReadInteger(aForm.Name, aCtrl.Name + '_Index', 0);
     if (Idx < TComboBox(aCtrl).Items.Count) then
       TComboBox(aCtrl).ItemIndex := Idx;
  end else if (aCtrl is TEdit) or (aCtrl is TLabeledEdit) then
     TEdit(aCtrl).Text := aIni.ReadString(aForm.Name, aCtrl.Name + '_Text', '')
  else if (aCtrl is TCheckBox) then
     TCheckBox(aCtrl).Checked := boolean(aIni.ReadInteger(aForm.Name, aCtrl.Name + '_Checked', 0))
  else if (aCtrl is TSpinEdit) then
     TSpinEdit(aCtrl).Value := aIni.ReadInteger(aForm.Name, aCtrl.Name + '_Value', 0)
  else if (aCtrl is TDBGrid) then
    LoadGrid(aForm.Name, TDBGrid(aCtrl), aIni);
end;

procedure TStateStore.SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
begin
  if (aCtrl is TComboBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Index', TComboBox(aCtrl).ItemIndex)
  else if (aCtrl is TEdit) or (aCtrl is TLabeledEdit) then
    aIni.WriteString(aForm.Name, aCtrl.Name + '_Text', TEdit(aCtrl).Text)
  else if (aCtrl is TCheckBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Checked', Ord(TCheckBox(aCtrl).Checked))
  else if (aCtrl is TSpinEdit) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Value', TSpinEdit(aCtrl).Value)
  else if (aCtrl is TDBGrid) then
    SaveGrid(aForm.Name, TDBGrid(aCtrl), aIni);
end;

procedure TStateStore.Walk(aForm: TWinControl; aProc: TCtrlProc);
var
  i: integer;
  Ctrl: TComponent;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(fFile);
  try
    for i := 0 to aForm.ComponentCount - 1 do
    begin
      Ctrl := aForm.Components[i];
      aProc(aForm, Ctrl, Ini);
    end;
  finally
    Ini.Free();
  end;
end;

procedure TStateStore.SetCtrlColor(aForm: TWinControl; aColor: TColor; const aType: string);
  procedure AsEdit(aCtrl: TComponent);
  begin
    if (aCtrl is TComboBox) then
      TComboBox(aCtrl).Color := aColor
    else if (aCtrl is TEdit) or (aCtrl is TLabeledEdit) then
      TEdit(aCtrl).Color := aColor
    else if (aCtrl is TCheckBox) then
      TCheckBox(aCtrl).Color := aColor
    else if (aCtrl is TSpinEdit) then
      TSpinEdit(aCtrl).Color := aColor;
  end;

  procedure AsButton(aCtrl: TComponent);
  begin
    if (aCtrl is TButton) then
      TButton(aCtrl).Color := aColor;
  end;

var
  i: integer;
  Ctrl: TComponent;
begin
  for i := 0 to aForm.ComponentCount - 1 do
  begin
    Ctrl := aForm.Components[i];
    if (aType = 'edit') then
       AsEdit(Ctrl)
    else if (aType = 'button') then
      AsButton(Ctrl);
  end;
end;

procedure TStateStore.Save(aForm: TWinControl);
begin
  Walk(aForm, @SaveProc);
end;

procedure TStateStore.Load(aForm: TWinControl);
begin
  if (IsFile()) then
    Walk(aForm, @LoadProc);
end;


//----

constructor TPropGuard.Create(const aObjs: array of TObject; const aProp: String; const aValue: Variant);
var
  i: Integer;
begin
  SetLength(fObjs, Length(aObjs));
  SetLength(fProps, Length(aObjs));
  SetLength(fValues, Length(aObjs));

  for i := 0 to High(aObjs) do
  begin
    fObjs[i] := aObjs[i];
    fProps[i] := aProp;

    fValues[i] := GetPropValue(aObjs[i], aProp);
    SetPropValue(aObjs[i], aProp, aValue);
  end;
end;

destructor TPropGuard.Destroy();
var
  i: Integer;
begin
  for i := 0 to High(fObjs) do
    SetPropValue(fObjs[i], fProps[i], fValues[i]);

  inherited;
end;

end.

