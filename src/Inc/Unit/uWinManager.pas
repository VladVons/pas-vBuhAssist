// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWinManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Windows, Controls, ComCtrls, Menus, DateUtils, SysUtils, fpjson;

type
  TFormClass = class of TForm;
  TFormArray = array of TForm;

  TWinManager = class
  protected
    fPageControl: TPageControl;
    fPopupMenu: TPopupMenu;
    procedure PageControlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
  public
    constructor Create(aPageControl: TPageControl; aPopupMenu: TPopupMenu);
    procedure Add(aForm: TForm);
    function Add(aFormClass: TFormClass): TForm;
    procedure Adds(aForms: array of TFormClass);
    function GetForms(): TFormArray;
    function FindTabIndex(aFormClass: TFormClass): integer;
    procedure SendMsg(aForm: TForm; const aData: TJSONObject);
    function CloseActive(): integer;
    procedure CloseAll();
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SetActivePage(aIdx: integer);
    procedure Next(aStep: integer);
    procedure Visible(aShow: boolean);
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

uses
  uFBase;

//--- Misc

procedure ShowOrCreateForm(AClass: TFormClass);
var
  Form: TForm;
  i: integer;
begin
  Form := nil;

  // шукаємо вже створену форму
  for i := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[i].ClassType = AClass) then
    begin
      Form := Screen.Forms[i];
      Break;
    end;

  // якщо знайдена — показуємо
  if (Form <> nil) then
  begin
    Form.Show();
    Form.BringToFront;
    Exit();
  end;

  // якщо нема — створюємо
  Form := AClass.Create(Application);
  Form.Show();
end;

//--- TWinManager

constructor TWinManager.Create(aPageControl: TPageControl; aPopupMenu: TPopupMenu);
begin
  inherited Create();
  fPageControl := aPageControl;
  fPopupMenu := aPopupMenu;

  if (aPopupMenu <> nil) then
    fPageControl.OnMouseDown := @PageControlMouseDown;
end;

procedure TWinManager.Next(aStep: integer);
var
  Idx: Integer;
begin
  if (fPageControl.PageCount = 0) then
    Exit();

  Idx := fPageControl.ActivePageIndex;
  Inc(Idx, aStep);

  if (Idx < 0) then
    Idx := 0
  else if (Idx >= fPageControl.PageCount) then
    Idx := fPageControl.PageCount - 1;

  fPageControl.ActivePageIndex := Idx;
end;

procedure TWinManager.Visible(aShow: boolean);
begin
  fPageControl.Visible := aShow;
end;

function TWinManager.GetForms(): TFormArray;
var
  i: integer;
  Form: TForm;
begin
  SetLength(Result, fPageControl.PageCount);

  for i := 0 to fPageControl.PageCount - 1 do
  begin
    Form := TForm(fPageControl.Pages[i].Tag);
    Result[i] := Form;
  end;
end;

function TWinManager.FindTabIndex(aFormClass: TFormClass): integer;
var
  i: integer;
begin
  for i := 0 to fPageControl.PageCount - 1 do
    if (fPageControl.Pages[i].ControlCount > 0) and (fPageControl.Pages[i].Controls[0] is aFormClass) then
    begin
      Result := i;
      Exit();
    end;

  Result := -1;
end;

procedure TWinManager.SendMsg(aForm: TForm; const aData: TJSONObject);
var
  i, j: Integer;
  Tab: TTabSheet;
  Form: TFBase;
begin
  for i := 0 to fPageControl.PageCount - 1 do
  begin
    Tab := fPageControl.Pages[i];

    for j := 0 to Tab.ControlCount - 1 do
      if (Tab.Controls[j] is TForm) then
      begin
        Form := TFBase(Tab.Controls[j]);
        if (Form <> aForm) then
          if (Form.OnSendMsg(aForm, aData)) then
             Exit();
      end;
  end;
end;

procedure TWinManager.Add(aForm: TForm);
var
  Tab: TTabSheet;
begin
  Tab := TTabSheet.Create(fPageControl);
  Tab.PageControl := fPageControl;

  aForm.Tag := integer(self);
  aForm.Parent := Tab;
  aForm.Align := alClient;
  aForm.BorderStyle := bsNone;
  aForm.OnClose := @FormClose;
  aForm.Show();

  Tab.Caption := aForm.Caption;
  Tab.Tag := integer(aForm);
  fPageControl.ActivePage := Tab;
end;

function TWinManager.Add(aFormClass: TFormClass): TForm;
var
  TabIndex: integer;
begin
  TabIndex := FindTabIndex(aFormClass);
  if (TabIndex = -1) then
  begin
    Result := aFormClass.Create(Application);
    Add(Result);
  end else begin
    // Вкладка вже існує — робимо її активною
    fPageControl.ActivePage := fPageControl.Pages[TabIndex];
    Result := TForm(fPageControl.ActivePage.Tag);
  end;
end;

procedure TWinManager.Adds(aForms: array of TFormClass);
var
  i: integer;
begin
  for i := 0 to High(aForms) do
    Add(aForms[i]);
end;

procedure TWinManager.CloseAll();
var
  i: integer;
  Tab: TTabSheet;
  Form: TForm;
begin
  for i := fPageControl.PageCount - 1 downto 0 do
  begin
    Tab := fPageControl.Pages[i];
    if (Tab.ControlCount > 0) and (Tab.Controls[0] is TForm) then
    begin
      Form := TForm(Tab.Controls[0]);
      Form.Close();
    end;
  end;
end;

function TWinManager.CloseActive(): integer;
var
  Tab: TTabSheet;
  Form: TForm;
begin
  Tab := fPageControl.ActivePage;
  if (Tab = nil) or (Tab.ControlCount = 0) then 
    Exit();

  if (Tab.Controls[0] is TForm) then
  begin
    Form := TForm(Tab.Controls[0]);
    Form.Close();
  end;

  Result := fPageControl.PageCount;
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

procedure TWinManager.PageControlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  TabIndex: integer;
begin
  Shift := Shift;
  if (Button <> mbRight) then
    Exit(); // тільки правий клік

  TabIndex := fPageControl.IndexOfTabAt(X, Y);
  if (TabIndex < 0) then
    Exit(); // клік не по вкладці

  // робимо вкладку активною
  fPageControl.ActivePageIndex := TabIndex;

  // відкриваємо попап меню прямо на курсорі
  if (fPopupMenu <> nil) then
    fPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TWinManager.SetActivePage(aIdx: integer);
var
  idx: integer;
begin
  if (fPageControl.PageCount = 0) then 
    Exit();

  if (aIdx >= 0) then
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

//--- TOneInstance

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
    if (GetProp(h, PChar(fUniqName)) <> 0) then
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

end.
