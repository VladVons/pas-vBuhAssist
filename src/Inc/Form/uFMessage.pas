// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMessage;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uFBase;

type

  { TFMessage }
  TFMessage = class(TFBase)
    ButtonOk: TButton;
    CheckBoxConfirm: TCheckBox;
    Memo1: TMemo;
    PanelBottom: TPanel;
    procedure CheckBoxConfirmClick(Sender: TObject);
  private
    fConfirm: boolean;
    function GetText(): String;
    procedure SetText(const aValue: String);
    function GetConfirm(): boolean;
    procedure SetConfirm(aValue: boolean);
  public
    property Text: String read GetText write SetText;
    property Confirm: boolean read GetConfirm write SetConfirm;
  end;

  function FMessageShow(const aTitle: string; aBody: TStrings; aConfirm: boolean = False): TModalResult;
var
  FMessage: TFMessage;

implementation

procedure TFMessage.CheckBoxConfirmClick(Sender: TObject);
begin
  ButtonOk.Enabled := CheckBoxConfirm.Checked;
end;

function TFMessage.GetText(): String;
begin
  Result := Memo1.Text;
end;

procedure TFMessage.SetText(const aValue: String);
begin
  Memo1.Text := aValue;
end;

function TFMessage.GetConfirm(): boolean;
begin
  Result := fConfirm;
end;

procedure TFMessage.SetConfirm(aValue: boolean);
begin
  fConfirm := aValue;

  ButtonOk.Enabled := not aValue;
  CheckBoxConfirm.Visible := aValue;
  CheckBoxConfirm.Checked := not aValue;
end;

function FMessageShow(const aTitle: string; aBody: TStrings; aConfirm: boolean = False): TModalResult;
begin
  FMessage := TFMessage.Create(nil);
  FMessage.Caption := aTitle;
  FMessage.Memo1.Text := aBody.Text;
  FMessage.Confirm := aConfirm;
  Result := FMessage.ShowModal();
  FreeAndNil(FMessage);
end;

{$R *.lfm}

end.

