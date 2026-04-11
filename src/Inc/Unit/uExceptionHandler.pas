// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>
//
// https://wiki.freepascal.org/Logging_exceptions

unit uExceptionHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Dialogs,
  uUserData, uSys, uHelper, uConst;

 type
  TAppException = class(TUserData)
   private
     fFlagHandler: boolean;
     function GetCallStack(aE: Exception): string;
   public
     procedure Handler(Sender: TObject; E: Exception);
   end;

var
  AppException: TAppException;

implementation

function TAppException.GetCallStack(aE: Exception): string;
var
  I: integer;
  Str: string;
  Frames: PPointer;
begin
  Result := '';
  if (aE <> nil) then
    Result := 'EClass: ' + aE.ClassName() + LineEnding + 'Message: ' + aE.Message + LineEnding;

  Result := Result + BackTraceStrFunc(ExceptAddr());
  Frames := ExceptFrames();
  for I := 0 to ExceptFrameCount() - 1 do
  begin
    Str := BackTraceStrFunc(Frames[I]);
    if (Str.Trim().Length >= 10) then
      Result := Result + LineEnding + Str;
  end;
end;

procedure TAppException.Handler(Sender: TObject; E: Exception);
var
  Msg, Stack: string;
begin
  if (not fFlagHandler) then
  begin
    fFlagHandler := True;

    Msg := LineEnding;
    if (Screen.ActiveForm <> nil) then
       Msg := Msg + 'Form ' + Screen.ActiveForm.Name + LineEnding;

    Msg := Msg + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now()) + LineEnding;
    Stack := GetCallStack(E);
    Msg := Msg + Stack + LineEnding;

    FileAppendText(fFile, Msg);
    if (cCheckDevFile.FileExists()) then
      MessageDlg('Помилка', Msg + LineEnding + fFile, mtError, [mbOK], 0);

    fFlagHandler := False;
  end;
end;


end.

