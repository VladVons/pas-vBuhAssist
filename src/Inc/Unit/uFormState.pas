// Created: 2026.02.06
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFormState;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, StdCtrls, ExtCtrls, Controls, Spin, Graphics,
  uSys;

type
  TCtrlProc = procedure(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile) of object;

  TFormStateRec = class
  private
    FileName: string;
    procedure Walk(aForm: TWinControl; aProc: TCtrlProc);
    procedure SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
    procedure LoadProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
  public
    constructor Create();
    function GetItem(const aSect, aItem: String; aDef: String = ''): String;
    function GetItem(const aSect, aItem: String; aDef: Integer = 0): Integer;
    procedure SetCtrlColor(aForm: TWinControl; aColor: TColor; const aType: String);
    procedure Load(aForm: TWinControl);
    procedure Save(aForm: TWinControl);
  end;

var
  FormStateRec: TFormStateRec;

implementation

constructor TFormStateRec.Create();
begin
  FileName := GetAppFile('app_state.ini');
end;

procedure TFormStateRec.LoadProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
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

procedure TFormStateRec.SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
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

function TFormStateRec.GetItem(const aSect, aItem: String; aDef: String = ''): String;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(FileName);
    Result := Ini.ReadString(aSect, aItem, aDef);
  finally
    Ini.Free();
  end;
end;

function TFormStateRec.GetItem(const aSect, aItem: String; aDef: Integer = 0): Integer;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(FileName);
    Result := Ini.ReadInteger(aSect, aItem, aDef);
  finally
    Ini.Free();
  end;
end;

procedure TFormStateRec.Walk(aForm: TWinControl; aProc: TCtrlProc);
var
  i: Integer;
  Ctrl: TComponent;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
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

procedure TFormStateRec.SetCtrlColor(aForm: TWinControl; aColor: TColor; const aType: String);
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
  i: Integer;
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

procedure TFormStateRec.Save(aForm: TWinControl);
begin
  Walk(aForm, @SaveProc);
end;

procedure TFormStateRec.Load(aForm: TWinControl);
begin
  Walk(aForm, @LoadProc);
end;

end.

