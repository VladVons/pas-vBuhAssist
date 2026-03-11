// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFLogin;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls;

type
  { TFLogin }
  TFLogin = class(TForm)
    ButtonOk: TButton;
    EditUser: TLabeledEdit;
    EditPassword: TLabeledEdit;
    procedure ButtonOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
  public
    procedure Clear();
    procedure OnlyPassw();

    class function Execute(out aLogin, aPassw: string;
        const aCaption, aUserLabel, aPasswLabel: string ): Boolean;
  end;

var
  FLogin: TFLogin;

implementation

{$R *.lfm}

{ TFLogin }

procedure TFLogin.ButtonOkClick(Sender: TObject);
begin
  if (EditUser.Enabled) and (Trim(EditUser.Text) = '') then
    EditUser.SetFocus()
  else begin
    ModalResult := mrOk;
  end;
end;

procedure TFLogin.Clear();
begin
  EditUser.Text := '';
  EditPassword.Text := '';
  EditUser.Enabled := True;
end;

procedure TFLogin.OnlyPassw();
begin
  EditUser.Enabled := False;
end;

procedure TFLogin.FormCreate(Sender: TObject);
begin
  ButtonOk.Default := True;
end;

class function TFLogin.Execute(out aLogin, aPassw: string;
  const aCaption, aUserLabel, aPasswLabel: string ): Boolean;
var
  F: TFLogin;
begin
  F := TFLogin.Create(nil);

  if (not aCaption.IsEmpty()) then
     F.Caption := aCaption;

  if (not aUserLabel.IsEmpty()) then
     F.EditUser.EditLabel.Caption := aUserLabel;

  if (not aPasswLabel.IsEmpty()) then
    F.EditPassword.EditLabel.Caption := aPasswLabel;

  try
    Result := (F.ShowModal = mrOk);
    if (Result) then
    begin
      aLogin := F.EditUser.Text;
      aPassw := F.EditPassword.Text;
    end;
  finally
    F.Free();
  end;
end;

end.

