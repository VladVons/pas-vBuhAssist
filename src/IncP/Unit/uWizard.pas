// Created: 2026.04.22
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWizard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uFWizard, Forms;

type
  TWizard = class(TPersistent)
  private
  protected
    fParent: TFWizard;
  public
    function DoSaveTab(aForm: TScrollBox): string; virtual;
    constructor Create(aParent: TFWizard);
  end;

implementation

constructor TWizard.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
end;

function TWizard.DoSaveTab(aForm: TScrollBox): string;
begin
  Result := '';
end;

end.

