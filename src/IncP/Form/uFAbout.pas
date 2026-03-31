// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFAbout;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  LCLVersion,
  uSys, uSysVcl, uVarUtil, uConst;

type
  { TFAbout }
  TFAbout = class(TForm)
    Image1: TImage;
    LabeledEditMail: TLabeledEdit;
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

procedure TFAbout.FormCreate(Sender: TObject);
var
  Str: string;
  Macros: TMacros;
begin
  LabeledEditVer.Text  := GetAppVer();
  LabeledEditDate.Text := {$I %DATE%};
  LabeledEdittIde.Text := Format('Lazarus %s', [LCLVersion]);
  LabeledEditFpc.Text  := Format('FPC %s', [{$I %FPCVERSION%}]);
  LabeledEditMail.Text := cMail;

  Str := ResourceLoadString('About', 'txt');
  Macros := TMacros.Create();
  Memo1.Text := Macros.Exec(Str, ['Mail'], [cMail]);
  Macros.Free();
end;

end.

