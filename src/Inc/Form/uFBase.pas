// Created: 2026.02.23
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TFBase }
  TFBase = class(TForm)
    LabelTitle: TLabel;
    PanelTitle: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  protected
  public

  end;


implementation
{$R *.lfm}

procedure TFBase.FormShow(Sender: TObject);
begin
  PanelTitle.Align := alNone;
  PanelTitle.Align := alTop;
  LabelTitle.Caption := Caption;
end;

procedure TFBase.FormCreate(Sender: TObject);
begin
  Color := clWhite;
end;

initialization
  RegisterClass(TFBase);

end.

