// Created: 2026.04.01
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFBaseScroll;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uFBase;

type
  { TFBaseScroll }
  TFBaseScroll = class(TFBase)
    ScrollBox: TScrollBox;
  public
  end;

implementation
{$R *.lfm}

end.

