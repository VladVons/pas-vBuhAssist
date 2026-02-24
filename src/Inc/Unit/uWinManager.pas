// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWinManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Windows, Controls, ComCtrls, Menus, DateUtils, SysUtils,
  uFBase;

type
  TFormClass = class of TForm;

  TWinManager = class
  protected
    fPageControl: TPageControl;
    fPopupMenu: TPopupMenu;
    procedure PageControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
  public
    constructor Create(aPageControl: TPageControl; aPopupMenu: TPopupMenu);
    procedure Add(aFormClass: TFormClass);
    function FindTabIndex(aFormClass: TFormClass): integer;
    procedure CloseActive();
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SetActivePage(aIdx: integer);
  end;

  TOneInstance = class
  const
    WM_SHOWME = WM_USER + 1971;

  private
    fUniqName: string;
    function FindWindow(): HANDLE;
  public
    constructor Create();
    procedure Check();
    procedure Register(aHandle: HANDLE);
  end;


procedure ShowOrCreateForm(AClass: TFormClass);

var
  WinManager: TWinManager;
  OneInstance: TOneInstance;

implementation

constructor TOneInstance.Create();
begin
  fUniqName := 'qwerty12345';
end;

procedure TOneInstance.Register(aHandle: HANDLE);
begin
  SetProp(aHandle, PChar(fUniqName), PtrUInt(1));
end;

function TOneInstance.FindWindow(): HANDLE;
var
  h: HANDLE;
begin
  Result := 0;
  h := GetTopWindow(0);
  while h <> 0 do
  begin
    if GetProp(h, PChar(fUniqName)) <> 0 then
    begin
      Result := h;
      Exit();
    end;
    h := GetNextWindow(h, GW_HWNDNEXT);
  end;
end;

procedure TOneInstance.Check();
var
  hWnd: HANDLE;
begin
  CreateMutex(nil, True, 'MyUniqMutex_QpTfRRasS_1971');
  if (GetLastError() = ERROR_ALREADY_EXISTS) then
  begin
    //hWnd := FindWindow(nil, PChar(Application.Title));
    hWnd := FindWindow();
    if (hWnd <> 0) then
      PostMessage(hWnd, WM_SHOWME, 0, 0);
    Halt();
  end;
end;

constructor TWinManager.Create(aPageControl: TPageControl; aPopupMenu: TPopupMenu);
begin
  inherited Create();
  fPageControl := aPageControl;
  fPopupMenu := aPopupMenu;

  fPageControl.OnMouseDown := @PageControlMouseDown;
end;

function TWinManager.FindTabIndex(aFormClass: TFormClass): integer;
var
  i: integer;
begin
  Result := -1; // не знайдено
  for i := 0 to fPageControl.PageCount - 1 do
    if (fPageControl.Pages[i].ControlCount > 0) and
      (fPageControl.Pages[i].Controls[0] is aFormClass) then
    begin
      Result := i;
      Exit;
    end;
end;

procedure TWinManager.Add(aFormClass: TFormClass);
var
  Form: TForm;
  TabIndex: integer;
  Tab: TTabSheet;
begin
  TabIndex := FindTabIndex(aFormClass);

  if TabIndex = -1 then
  begin
    // Створюємо нову вкладку та форму
    Tab := TTabSheet.Create(fPageControl);
    Tab.PageControl := fPageControl;

    Form := aFormClass.Create(Application);
    Form.Parent := Tab;
    Form.Align := alClient;
    Form.BorderStyle := bsNone;
    Form.OnClose := @FormClose;
    Form.Show();

    Tab.Caption := Form.Caption;
    fPageControl.ActivePage := Tab;
  end
  else
  begin
    // Вкладка вже існує — робимо її активною
    fPageControl.ActivePage := fPageControl.Pages[TabIndex];
  end;
end;

procedure TWinManager.CloseActive;
var
  Tab: TTabSheet;
  Form: TForm;
begin
  Tab := fPageControl.ActivePage;
  if (Tab = nil) or (Tab.ControlCount = 0) then Exit;

  if Tab.Controls[0] is TForm then
  begin
    Form := TForm(Tab.Controls[0]);
    Form.Close();
  end;
end;

procedure TWinManager.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  Tab: TTabSheet;
begin
  CloseAction := caFree;

  if (Sender is TForm) and (TForm(Sender).Parent is TTabSheet) then
  begin
    Tab := TTabSheet(TForm(Sender).Parent);
    Tab.Free();
  end;
end;

procedure TWinManager.PageControlMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  TabIndex: integer;
begin
  if Button <> mbRight then
    Exit; // тільки правий клік

  TabIndex := fPageControl.IndexOfTabAt(X, Y);
  if TabIndex < 0 then
    Exit; // клік не по вкладці

  // робимо вкладку активною
  fPageControl.ActivePageIndex := TabIndex;

  // відкриваємо попап меню прямо на курсорі
  if Assigned(fPopupMenu) then
    fPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TWinManager.SetActivePage(aIdx: integer);
var
  idx: integer;
begin
  if fPageControl.PageCount = 0 then Exit;
  // немає вкладок, нічого не робимо

  if aIdx >= 0 then
    idx := aIdx
  else
    idx := fPageControl.PageCount + aIdx; // від’ємне: від останньої

  // перевірка, щоб не вийти за межі
  if (idx < 0) then
    idx := 0
  else if (idx >= fPageControl.PageCount) then
    idx := fPageControl.PageCount - 1;

  fPageControl.ActivePageIndex := idx;
end;

procedure ShowOrCreateForm(AClass: TFormClass);
var
  Form: TForm;
  i: integer;
begin
  Form := nil;

  // шукаємо вже створену форму
  for i := 0 to Screen.FormCount - 1 do
    if Screen.Forms[i].ClassType = AClass then
    begin
      Form := Screen.Forms[i];
      Break;
    end;

  // якщо знайдена — показуємо
  if Assigned(Form) then
  begin
    Form.Show();
    Form.BringToFront;
    Exit();
  end;

  // якщо нема — створюємо
  Form := AClass.Create(Application);
  Form.Show();
end;


end.
