// Created: 2026.02.19
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,DateUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Spin,
  uFBase, uStateStore, uSys, uConst;

type
  { TFSettings }
  TFSettings = class(TFBase)
    ButtonOk: TButton;
    CheckBoxUpdates: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    LabeledEditPassword: TLabeledEdit;
    LabelVer: TLabel;
    PageControlMain: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    SpinEditBeginYear: TSpinEdit;
    procedure ButtonOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
  StateStore.Save(self);
  Log('i', 'Збережено');
end;

procedure TFSettings.FormCreate(Sender: TObject);
begin
  inherited;

  SetFont(self);
  StateStore.Load(self);

  if (SpinEditBeginYear.Value = 0) then
    SpinEditBeginYear.Value := YearOf(IncYear(Date(), -cYearsBack));

  LabelVer.Caption := cAppName + ' ' + GetAppVer();
end;

procedure TFSettings.FormDestroy(Sender: TObject);
begin
  StateStore.Save(self);
end;

end.

