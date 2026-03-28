// Created: 2026.03.23
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFrWizard1;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Grids;

type
  { TFrWizard1 }
  TFrWizard1 = class(TFrame)
  private
  public
    procedure LoadScheme(const aName: string);
  end;

implementation
{$R *.lfm}

end.
