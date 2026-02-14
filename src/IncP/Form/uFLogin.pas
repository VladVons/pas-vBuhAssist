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
    Button1: TButton;
    EditUser: TLabeledEdit;
    EditPassword: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
  private

  public
    procedure Clear();
  end;

var
  FLogin: TFLogin;

implementation

{$R *.lfm}

{ TFLogin }

procedure TFLogin.Button1Click(Sender: TObject);
begin
  if (Trim(EditUser.Text) = '') then
  begin
    EditUser.SetFocus();
    Exit;
  end;

  ModalResult := mrOk;
end;

procedure TFLogin.Clear();
begin
  EditUser.Text := '';
  EditPassword.Text := '';
end;

end.

