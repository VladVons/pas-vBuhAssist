// Created: 2026.02.06
// Author: Vladimir Vons <VladVons@gmail.com>

unit uStateStore;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, StdCtrls, ExtCtrls, Controls, Spin, Graphics,
  uSettings, uSys;

type
  TCtrlProc = procedure(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile) of object;

  TStateStore = class(TSettings)
  private
    procedure Walk(aForm: TWinControl; aProc: TCtrlProc);
    procedure SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
    procedure LoadProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
  public
    procedure SetCtrlColor(aForm: TWinControl; aColor: TColor; const aType: string);
    procedure Load(aForm: TWinControl);
    procedure Save(aForm: TWinControl);
  end;

var
  StateStore: TStateStore = Nil;

implementation

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
     TCheckBox(aCtrl).State := TCheckBoxState(aIni.ReadInteger(aForm.Name, aCtrl.Name + '_State', 0))
  else if (aCtrl is TSpinEdit) then
     TSpinEdit(aCtrl).Value := aIni.ReadInteger(aForm.Name, aCtrl.Name + '_Value', 0);
end;

procedure TStateStore.SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
begin
  if (aCtrl is TComboBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Index', TComboBox(aCtrl).ItemIndex)
  else if (aCtrl is TEdit) or (aCtrl is TLabeledEdit) then
    aIni.WriteString(aForm.Name, aCtrl.Name + '_Text', TEdit(aCtrl).Text)
  else if (aCtrl is TCheckBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_State', Ord(TCheckBox(aCtrl).State))
  else if (aCtrl is TSpinEdit) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Value', TSpinEdit(aCtrl).Value);
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
  Walk(aForm, @LoadProc);
end;

end.

