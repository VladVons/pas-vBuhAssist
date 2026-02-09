unit uForms;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, StdCtrls, DateUtils, SysUtils;

procedure ShowFormDock(aForm: TForm; aControl: TWinControl);
procedure ShowFormFloat(aForm: TForm);
procedure Log(const aText: String);

var
  MemoInfo: TMemo;

implementation

procedure Log(const aText: String);
var
  Str: String;
begin
  Str := FormatDateTime('hh:nn:ss', Now()) + ' '+ aText;
  MemoInfo.Lines.Add(Str);
end;

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
