unit uFmWizard1;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls;

type
  { TFmWizard1 }
  TFmWizard1 = class(TFrame)
  private
  public
    procedure LoadScheme(const aName: string);
  end;

implementation
{$R *.lfm}

end.
