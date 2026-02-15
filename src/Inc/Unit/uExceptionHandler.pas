// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>
//
// https://wiki.freepascal.org/Logging_exceptions

unit uExceptionHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms,
  uSys;

 type
  TAppException = class
   private
     FileLog: String;
     FlagHandler: Boolean;
     function GetCallStack(aE: Exception): String;
   public
     constructor Create();
     procedure Handler(Sender: TObject; E: Exception);
   end;

var
  AppException: TAppException;

implementation

constructor TAppException.Create();
begin
  FlagHandler := False;
  FileLog := GetAppFile('app.err');
end;

function TAppException.GetCallStack(aE: Exception): String;
var
  I: Integer;
  Str: String;
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
  Msg, Stack: String;
begin
  if (not FlagHandler) then
  begin
    FlagHandler := True;

    Msg := LineEnding;
    if Assigned(Screen.ActiveForm) then
       Msg := Msg + 'Form ' + Screen.ActiveForm.Name + LineEnding;

    Msg := Msg + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now()) + LineEnding;
    Stack := GetCallStack(E);
    Msg := Msg + Stack + LineEnding;
    FileAppendText(FileLog, Msg);

    FlagHandler := False;
  end;
end;


end.

