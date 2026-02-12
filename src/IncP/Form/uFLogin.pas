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
    User: TLabeledEdit;
    Password: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  FLogin: TFLogin;

implementation

{$R *.lfm}

{ TFLogin }

procedure TFLogin.Button1Click(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.

