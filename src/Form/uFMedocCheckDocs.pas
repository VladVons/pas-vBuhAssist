unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
    Button1: TButton;
    DBGrid1: TDBGrid;
  private

  public

  end;

var
  FMedocCheckDocs: TFMedocCheckDocs;

implementation

{$R *.lfm}

end.

