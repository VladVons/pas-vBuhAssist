// Created: 2026.02.06
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFormState;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, StdCtrls, ExtCtrls, Controls,
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
     TCheckBox(aCtrl).State := TCheckBoxState(aIni.ReadInteger(aForm.Name, aCtrl.Name + '_State', 0));
end;

procedure TFormStateRec.SaveProc(aForm: TWinControl; aCtrl: TComponent; aIni: TIniFile);
begin
  if (aCtrl is TComboBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_Index', TComboBox(aCtrl).ItemIndex)
  else if (aCtrl is TEdit) or (aCtrl is TLabeledEdit) then
    aIni.WriteString(aForm.Name, aCtrl.Name + '_Text', TEdit(aCtrl).Text)
  else if (aCtrl is TCheckBox) then
    aIni.WriteInteger(aForm.Name, aCtrl.Name + '_State', Ord(TCheckBox(aCtrl).State));
end;

procedure TFormStateRec.Walk(aForm: TWinControl; aProc: TCtrlProc);
var
  Ini: TIniFile;
  i: Integer;
  Ctrl: TComponent;
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

procedure TFormStateRec.Save(aForm: TWinControl);
begin
  Walk(aForm, @SaveProc);
end;

procedure TFormStateRec.Load(aForm: TWinControl);
begin
  Walk(aForm, @LoadProc);
end;

end.

