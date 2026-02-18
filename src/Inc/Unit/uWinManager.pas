// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWinManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Windows, Controls, ComCtrls, Menus, DateUtils, SysUtils;

type
  TFormClass = class of TForm;

  TWinManager = class
  protected
    PageControl: TPageControl;
    PopupMenu: TPopupMenu;
    procedure PageControlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    constructor Create(aPageControl: TPageControl; aPopupMenu: TPopupMenu);
    procedure Add(aFormClass: TFormClass);
    function FindTabIndex(aFormClass: TFormClass): Integer;
    procedure CloseActive();
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SetActivePage(aIdx: integer);
  end;

  TOneInstance = class
  const
    WM_SHOWME = WM_USER + 1971;
  private
    fUniqName: String;
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
  PageControl := aPageControl;
  PopupMenu := aPopupMenu;

  PageControl.OnMouseDown := @PageControlMouseDown;
end;

function TWinManager.FindTabIndex(aFormClass: TFormClass): Integer;
var
  i: Integer;
begin
  Result := -1; // не знайдено
  for i := 0 to PageControl.PageCount - 1 do
    if (PageControl.Pages[i].ControlCount > 0) and (PageControl.Pages[i].Controls[0] is aFormClass) then
    begin
      Result := i;
      Exit;
    end;
end;

procedure TWinManager.Add(aFormClass: TFormClass);
var
  Form: TForm;
  TabIndex: Integer;
  Tab: TTabSheet;
begin
  TabIndex := FindTabIndex(aFormClass);

  if TabIndex = -1 then
  begin
    // Створюємо нову вкладку та форму
    Tab := TTabSheet.Create(PageControl);
    Tab.PageControl := PageControl;

    Form := aFormClass.Create(Application);
    Form.Parent := Tab;
    Form.Align := alClient;
    Form.BorderStyle := bsNone;
    Form.OnClose := @FormClose;
    Form.Show();

    Tab.Caption := Form.Caption;
    PageControl.ActivePage := Tab;
  end
  else
  begin
    // Вкладка вже існує — робимо її активною
    PageControl.ActivePage := PageControl.Pages[TabIndex];
  end;
end;

procedure TWinManager.CloseActive;
var
  Tab: TTabSheet;
  Form: TForm;
begin
  Tab := PageControl.ActivePage;
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

procedure TWinManager.PageControlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  TabIndex: Integer;
begin
  if Button <> mbRight then
     Exit; // тільки правий клік

  TabIndex := PageControl.IndexOfTabAt(X, Y);
  if TabIndex < 0 then
     Exit; // клік не по вкладці

  // робимо вкладку активною
  PageControl.ActivePageIndex := TabIndex;

  // відкриваємо попап меню прямо на курсорі
  if Assigned(PopupMenu) then
    PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TWinManager.SetActivePage(aIdx: Integer);
var
  idx: Integer;
begin
  if PageControl.PageCount = 0
     then Exit; // немає вкладок, нічого не робимо

  if aIdx >= 0 then
    idx := aIdx
  else
    idx := PageControl.PageCount + aIdx; // від’ємне: від останньої

  // перевірка, щоб не вийти за межі
  if (idx < 0) then
    idx := 0
  else if (idx >= PageControl.PageCount) then
    idx := PageControl.PageCount - 1;

  PageControl.ActivePageIndex := idx;
end;

procedure ShowOrCreateForm(AClass: TFormClass);
var
  Form: TForm;
  i: Integer;
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
