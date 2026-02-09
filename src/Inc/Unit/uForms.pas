unit uForms;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, StdCtrls, DateUtils, SysUtils;

procedure ShowFormDock(aForm: TForm; aControl: TWinControl);
procedure ShowFormFloat(aForm: TForm);

implementation

procedure ShowFormDock(aForm: TForm; aControl: TWinControl);
begin
  aForm.Hide();
  aForm.Parent := aControl;
  aForm.Align := alClient;
  aForm.BorderStyle := bsNone;
  aForm.Show();
end;

procedure ShowFormFloat(aForm: TForm);
begin
  aForm.Hide();
  aForm.Parent := nil;
  aForm.Align := alNone;
  aForm.BorderStyle := bsSizeable;
  aForm.Position := poMainFormCenter;
  aForm.Show();
end;

end.
