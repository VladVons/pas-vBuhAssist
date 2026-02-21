// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFAbout;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  LCLVersion,
  uSys;

type

  { TFAbout }

  TFAbout = class(TForm)
    Image1: TImage;
    LabeledEdit1: TLabeledEdit;
    LabeledEditDate: TLabeledEdit;
    LabeledEditFpc: TLabeledEdit;
    LabeledEdittIde: TLabeledEdit;
    LabeledEditVer: TLabeledEdit;
    Memo1: TMemo;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FAbout: TFAbout;

implementation

{$R *.lfm}

{ TFAbout }

procedure TFAbout.FormCreate(Sender: TObject);
begin
  LabeledEditVer.Text  := GetAppVer();
  LabeledEditDate.Text := {$I %DATE%};
  LabeledEdittIde.Text := Format('Lazarus %s', [LCLVersion]);
  LabeledEditFpc.Text  := Format('FPC %s', [{$I %FPCVERSION%}]);
end;

end.

