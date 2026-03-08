// Created: 2026.03.08
// Author: Vladimir Vons <VladVons@gmail.com>

unit uProtectDbg;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Windows,
  uSys;

function IsBreakpoint(aMethod: Pointer): Boolean;
function IsDebugger1(): boolean;
function IsDebugger2(): boolean;
function IsDeveloper(): boolean;

implementation

function IsDebugger1(): boolean;
begin
 Result := IsDebuggerPresent();
end;

function IsDebugger2(): Boolean;
begin
  Result := False;
  try
    asm
      int3;
    end;
  except
    Result := False;
    Exit();
  end;

  Result := True;
end;

//usage: ProtectTimer.IsBreakpoint(TMethod(@ProtectTimer.CompareRnd).Code)
function IsBreakpoint(aMethod: Pointer): Boolean;
begin
  Result := PByte(aMethod)^ = $CC;
end;

//function IsBreakpoint2(aMethod: TAnyMethod): Boolean;
//begin
//  Result := PByte(TMethod(aMethod).Code)^ = $CC;
//end;

function IsDeveloper(): boolean;
var
  Str: string;
begin
  Str := GetAppName() + '.lpr';
  Result := FileExists(Str);
end;

end.

