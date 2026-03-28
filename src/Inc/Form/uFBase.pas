// Created: 2026.02.23
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, fpjson,
  uStateStore, uWinManager, uLog;

type
  { TFBase }
  TFBase = class(TForm)
    LabelTitle: TLabel;
    PanelTitle: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure SetTitle(const aStr: string);
    function  GetTitle(): string;
  protected
    procedure SetFont(aForm: TForm);
    procedure SendMsg(const aData: TJSONObject);
    procedure Log(aType: char; const aMsg: string);
  public
    property Title: string read GetTitle write SetTitle;
    function OnSendMsg(aForm: TForm; const aJObj: TJSONObject): boolean; virtual;
  end;


implementation
{$R *.lfm}

procedure TFBase.SetTitle(const aStr: string);
begin
  LabelTitle.Caption := aStr;
end;

function TFBase.GetTitle(): string;
begin
  Result := LabelTitle.Caption;
end;

procedure TFBase.Log(aType: char; const aMsg: string);
begin
  uLog.Log.Print(aType, Format('%s %s', [Caption, aMsg]));
end;

procedure TFBase.SetFont(aForm: TForm);
var
  NewFont: TFont;
begin
  NewFont := TFont.Create();
  try
    NewFont.Name := 'Verdana';
    NewFont.Size := 9;
    //NewFont.Style := [fsBold];
    StateStore.SetCtrlFont(aForm, NewFont);
  finally
    NewFont.Free();
  end;
end;

procedure TFBase.FormShow(Sender: TObject);
begin
  PanelTitle.Align := alNone;
  PanelTitle.Align := alTop;
  //LabelTitle.Caption := Caption;
end;

function TFBase.OnSendMsg(aForm: TForm; const aJObj: TJSONObject): boolean;
begin
  Result := False;
end;

procedure TFBase.SendMsg(const aData: TJSONObject);
var
  WinManager: TWinManager;
begin
  WinManager := TWinManager(Tag);

  if (WinManager <> nil) and (WinManager is TWinManager) then
    WinManager.SendMsg(Self, aData);
end;

procedure TFBase.FormCreate(Sender: TObject);
begin
  Color := clWhite;
  Title := Caption;
end;

initialization
  RegisterClass(TFBase);

end.

