// Created: 2026.02.19
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,DateUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Spin,
  uFormState, uLog;

type

  { TFSettings }

  TFSettings = class(TForm)
    ButtonOk: TButton;
    Label1: TLabel;
    LabeledEditPassword: TLabeledEdit;
    PageControlMain: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    SpinEditBeginYear: TSpinEdit;
    procedure ButtonOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FSettings: TFSettings;

implementation

{$R *.lfm}

{ TFSettings }

procedure TFSettings.ButtonOkClick(Sender: TObject);
begin
  FormStateRec.Save(self);
  Log.Print('Збережено');
end;

procedure TFSettings.FormCreate(Sender: TObject);
begin
  FormStateRec.Load(self);

  if (SpinEditBeginYear.Value = 0) then
    SpinEditBeginYear.Value := YearOf(IncYear(Date(), -2));
end;

end.

