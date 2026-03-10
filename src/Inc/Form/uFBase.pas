// Created: 2026.02.23
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uStateStore;

type

  { TFBase }
  TFBase = class(TForm)
    LabelTitle: TLabel;
    PanelTitle: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  protected
    procedure SetFont(aForm: TForm);
  public

  end;


implementation
{$R *.lfm}

procedure TFBase.SetFont(aForm: TForm);
var
  NewFont: TFont;
begin
  NewFont := TFont.Create();
  try
    NewFont.Name := 'Verdana';
    NewFont.Size := 9;
    //NewFont.Style := [fsBold];
    StateStore.SetCtrlFont(aForm, NewFont);
  finally
    NewFont.Free();
  end;
end;

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

