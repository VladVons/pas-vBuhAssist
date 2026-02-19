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
    procedure FormCreate(Sender: TObject);
  private
  public
    procedure Clear();
    procedure OnlyPassw();
  end;

var
  FLogin: TFLogin;

implementation

{$R *.lfm}

{ TFLogin }

procedure TFLogin.Button1Click(Sender: TObject);
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
  Button1.Default := True;
end;

end.

