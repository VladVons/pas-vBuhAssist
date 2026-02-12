// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMessageShow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TFMessageShow }

  TFMessageShow = class(TForm)
    LabelCaption: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
  private

  public

  end;

var
  FMessageShow: TFMessageShow;

implementation

{$R *.lfm}

end.

