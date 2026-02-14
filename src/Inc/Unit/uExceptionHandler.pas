// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>
//
// https://wiki.freepascal.org/Logging_exceptions

unit uExceptionHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  uSys;

 type
  TAppException = class
   private
     DirApp: String;
     FlagHandler: Boolean;
     function GetCallStack(aE: Exception): String;
   public
     constructor Create();
     procedure Handler(Sender: TObject; E: Exception);
   end;


implementation

constructor TAppException.Create();
begin
  FlagHandler := False;
  DirApp := GetAppProgramData();
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
  Msg, Date: String;
begin
  if (not FlagHandler) then
  begin
    FlagHandler := True;

    Date := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now());
    Msg := GetCallStack(E);
    FileAppendText(DirApp + PathDelim + 'error.log', LineEnding + Date + LineEnding + Msg);

    FlagHandler := False;
  end;
end;


end.

