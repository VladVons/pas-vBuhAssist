// Created: 2026.02.19
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,DateUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Spin,
  uFBase, uStateStore, uSettings, uSys, uConst;

type

  { TFSettings }

  TFSettings = class(TFBase)
    ButtonDirExportPdv: TButton;
    ButtonOk: TButton;
    CheckBoxUpdates: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    LabeledEditPassword: TLabeledEdit;
    LabeledEditPathExportPdv: TLabeledEdit;
    LabelVer: TLabel;
    PageControlMain: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpinEditBeginYear: TSpinEdit;
    procedure ButtonDirExportPdvClick(Sender: TObject);
    procedure ButtonOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure SelectDir(aEdit: TEdit; const aKey: string);
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

procedure TFSettings.ButtonDirExportPdvClick(Sender: TObject);
begin
  SelectDir(TEdit(LabeledEditPathExportPdv), 'DirExportPdv');
end;

procedure TFSettings.FormCreate(Sender: TObject);
begin
  inherited;

  SetFont(self);
  StateStore.Load(self);

  if (SpinEditBeginYear.Value = 0) then
    SpinEditBeginYear.Value := YearOf(IncYear(Date(), -cYearsBack));

  LabelVer.Caption := cAppName + ' ' + GetAppVer();

  if (LabeledEditPathExportPdv.Text = '') then
    LabeledEditPathExportPdv.Text := ConcatPaths([GetDesktopDir(), 'РозблокуванняПН']);

end;

procedure TFSettings.SelectDir(aEdit: TEdit; const aKey: string);
begin
  if (DirectoryExists(aEdit.Text)) then
     SelectDirectoryDialog1.InitialDir := aEdit.Text;

  if (SelectDirectoryDialog1.Execute()) then
  begin
     Settings.SetItem(Name, aKey, SelectDirectoryDialog1.FileName);
     aEdit.Text := SelectDirectoryDialog1.FileName;
  end;
end;

procedure TFSettings.FormDestroy(Sender: TObject);
begin
  StateStore.Save(self);
end;

end.

