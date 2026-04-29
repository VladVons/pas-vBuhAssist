// Created: 2026.03.11
// Author: Vladimir Vons <VladVons@gmail.com>

unit uHelper;

{$mode objfpc}{$H+}
{$modeswitch typehelpers}

interface

uses
  Classes, SysUtils, StrUtils, LazUTF8, fpjson;

type
  TStringMapFunc = function(const aStr: string): string;
  TCharSet = set of Char;

  TStringHelperEx = type helper(TStringHelper) for string
    function After(const aStr: string): string;
    function Before(const aStr: string): string;
    function Between(const aStart, aEnd: string): string;
    function DelBOM(): string;
    function DelEmptyLines(): string;
    function EndsWithAny(const aArr: TStringArray): boolean;
    function EscapeRegExp(): string;
    function FileExists(): boolean;
    function FileQuoted(): string;
    function Clone(aCount: integer): string;
    function Filter(aFrom, aTo: char; aInvert: boolean = False): string;
    function Filter(const aAllowed: string; aInvert: boolean = False): string;
    function Filter(const aAllowed: TCharSet; aInvert: boolean = False): string;
    function IsQuoted(): Boolean;
    function IsEmptyTrim(): Boolean;
    function JoinNonEmpty(const aArr : TStringArray): string;
    function Left(aLen: integer; aDoCut: boolean = False): string;
    function Middle(const aStart, aCount: integer): string;
    function PosEx(const aStr: string; aOfst: integer = 1): integer;
    function PosRSpace(aStart, aLen: integer): integer;
    function Replaces(const aOld, aNew: TStringArray): string;
    function Right(aLen: Integer; aDoCut: boolean = False): string;
    function RightFrom(aPos: Integer): string;
    function TrimExt(const aChars: TSysCharSet = [' ']): string;
    function TrimInt(const aChars: TSysCharSet = [' ']): string;
    procedure ToFile(const aFile: string);
  end;

  TStringListHelper = class helper for TStringList
  public
    function AddArray(const aArr : TStringArray): TStringList;
    function AddArray(const aArr : TJSONArray): TStringList;
    function AddExtDelim(const aSL: TStringList; const aDelim: string = '-'): TStringList;
    function AddExtDelim(const aStr: string; const aDelim: string = '-'): TStringList;
    function AddNames(const aSL: TStrings): TStringList;
    function AddWrapped(const aStr: string; aMaxLen: Integer): TStringList;
    function DelArray(const aArr : TStringArray): TStringList;
    function DelEmpty(): TStringList;
    function DelEmpty(aMaxEmpty: Integer): TStringList;
    function Formated(const aFormat: string): TStringList;
    function GetArray(): TStringArray;
    function GetJoin(const aDelim: string): string;
    function GetJoinNonEmpty(const aDelim: string): string;
    function GetJson(): TJSONArray;
    function GetLast(aIdx: integer = 0): string;
    function IndexOfObject(aObj: TObject): Integer;
    function Intersect(const aSL: TStrings): TStringList;
    function Left(aLen: integer): TStringList;
    function Map(aFunc: TStringMapFunc): TStringList;
    function Merge(const aSL: TStrings): TStringList;
    function Quoted(): TStringList;
    function Quoted(const aChar: char): TStringList;
    function Replace(const aFind, aRep: string): TStringList;
    function Split(const aStr, aDelim: string): TStringList;
    function WordWrap(aMaxLen: Integer): TStringList;
    function Uniq(): TStringList;
  end;

  TJSONObjectHelper = type helper for TJSONObject
    //procedure Set1Update(aSrc: TJSONObject);
    procedure Update(aSrc: TJSONObject);
    function GetKeys(): TStringList;
    function GetList(): TStringList;
    function GetNested(const Path: string; aDef: Variant): Variant;
    function GetAsString(const aKey, aDef: string): string;
    procedure SetKey(const aKey: string; aJData: TJSONData);
    procedure SetKey(const aKey: string; aStr: string);
    procedure SetKey(const aKey: string; aInt: integer);
  end;


implementation



// --- TStringHelperEx
function TStringHelperEx.Left(aLen: integer; aDoCut: boolean = False): string;
var
  Len: integer;
begin
  if (aLen <= 0) then
    Exit('');

  Len := System.Length(self);
  if (aLen >= Len) then
      Exit(Self);

  if (aDoCut) then
    Result := System.Copy(self, aLen + 1, Len - aLen)
  else
    Result := System.Copy(self, 1, aLen);
end;

function TStringHelperEx.Middle(const aStart, aCount: integer): string;
begin
  if (aCount = 0) or (aStart > System.Length(self)) then
    Result := ''
  else
    Result := System.Copy(self, aStart, aCount);
end;


function TStringHelperEx.PosEx(const aStr: string; aOfst: integer = 1): integer;
begin
  Result := System.Pos(aStr, self, aOfst);
end;

function TStringHelperEx.PosRSpace(aStart, aLen: integer): integer;
var
  i, Len: Integer;
begin
  Result := 0;

  Len := System.Length(self);
  if (Len = 0) then
    Exit();

  if (aStart > Len) then
    aStart := Len;

  if (aStart - aLen + 1 < 1) then
    aLen := aStart;

  for i := aStart downto aStart - aLen + 1 do
    if (self[i] = ' ') then
       Exit(i);
end;

function TStringHelperEx.After(const aStr: string): string;
var
  Idx: SizeInt;
begin
  Idx := Pos(aStr, self);
  if (Idx > 0) then
    Result := System.Copy(Self, Idx + System.Length(aStr), MaxInt)
  else
    Result := '';
end;

function TStringHelperEx.Before(const aStr: string): string;
begin
  if (Pos(aStr, self) > 0) then
    Result := System.Copy(self, 1, Pos(aStr, self) - 1)
  else
    Result := self;
end;

function TStringHelperEx.Between(const aStart, aEnd: string): string;
var
  Pos1, Pos2: SizeInt;
begin
  Pos1 := Pos(aStart, Self);
  if (Pos1 = 0) then
    Exit('');

  Inc(Pos1, System.Length(aStart));

  Pos2 := System.Pos(aEnd, self, Pos1);
  if (Pos2 = 0) then
    Exit('');

  Result := System.Copy(Self, Pos1, Pos2 - Pos1);
end;

function TStringHelperEx.JoinNonEmpty(const aArr: TStringArray): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to System.Length(aArr) - 1 do
  begin
    if (aArr[i].Trim() = '') then
      continue;

    if (Result <> '') then
      Result := Result + self;

    Result := Result + aArr[i];
  end;
end;

function TStringHelperEx.Right(aLen: Integer; aDoCut: boolean = False): string;
var
  Len: Integer;
begin
  if (aLen <= 0) then
    Exit('');

  Len := System.Length(Self);
  if (aLen >= Len) then
    Exit(Self);

  if (aDoCut) then
    Result := System.Copy(self, 1, Len - aLen)
  else
    Result := System.Copy(Self, Len - aLen + 1, aLen);
end;

function TStringHelperEx.RightFrom(aPos: Integer): string;
var
  Len: Integer;
begin
  Len := System.Length(Self);
  if (Len <= 0) or (aPos >= Len) then
    Exit('');

  Result := System.Copy(self, aPos + 1, Len - aPos);
end;


function TStringHelperEx.TrimExt(const aChars: TSysCharSet = [' ']): string;
var
  Ofs, Len: integer;
begin
  Len := System.Length(self);
  while (Len > 0) and (self[Len] in aChars) do
    Dec(Len);

  Ofs := 1;
  while (Ofs <= Len) and (self[Ofs] in aChars) do
    Inc(Ofs);

  Result := System.Copy(self, Ofs, 1 + Len - Ofs);
end;

function TStringHelperEx.TrimInt(const aChars: TSysCharSet = [' ']): string;
var
  i, Len: Integer;
  PrevSpace: Boolean;
  c: Char;
begin
  SetLength(Result, System.Length(Self));
  Len := 0;
  PrevSpace := False;

  for i := 1 to System.Length(Self) do
  begin
    c := Self[i];
    if (c in aChars) then
    begin
      if (not PrevSpace) then
      begin
        Inc(Len);
        Result[Len] := ' ';
        PrevSpace := True;
      end;
    end else begin
      Inc(Len);
      Result[Len] := c;
      PrevSpace := False;
    end;
  end;

  SetLength(Result, Len);
end;

function TStringHelperEx.DelEmptyLines(): string;
var
  Src, Dest, LineStart: PChar;
  OutLen: Integer;
  HasNonSpace: Boolean;
begin
  if (self = '') then
    Exit(self);

  // Виділяємо буфер для вихідного рядка (не більше, ніж вхідний)
  SetLength(Result, System.Length(self));
  Src := PChar(self);
  Dest := PChar(Result);
  OutLen := 0;

  while (Src^ <> #0) do
  begin
    LineStart := Src;

    HasNonSpace := False;
    while not (Src^ in [#0, #10, #13]) do
    begin
      if not (Src^ in [' ', #9]) then
        HasNonSpace := True;
      Inc(Src);
    end;

    // Копіюємо рядок, якщо він не пустий
    if (HasNonSpace) then
    begin
      Move(LineStart^, Dest^, PtrUInt(Src - LineStart));
      Inc(Dest, Src - LineStart);
      Dest^ := #10; // додаємо LF
      Inc(Dest);
      Inc(OutLen, Src - LineStart + 1);
    end;

    // Пропускаємо CR/LF
    if (Src^ = #13) then
      Inc(Src);
    if (Src^ = #10) then
      Inc(Src);
  end;

  SetLength(Result, OutLen);
end;

function TStringHelperEx.Replaces(const aOld, aNew: TStringArray): string;
var
  i: Integer;
begin
  if (System.Length(aOld) <> System.Length(aNew)) then
    raise Exception.Create('arrays length mismatch');

  Result := self;
  for i := 0 to System.Length(aOld) - 1 do
    Result := StringReplace(Result, aOld[i], aNew[i], [rfReplaceAll]);
end;

//FilterSet(['A'..'Z', 'a'..'z'])
function TStringHelperEx.Filter(const aAllowed: TCharSet; aInvert: boolean = False): string;
var
  i, Len: Integer;
  C: Char;
begin
  SetLength(Result, System.Length(self));
  Len := 0;

  for i := 1 to System.Length(self) do
  begin
    C := self[i];
    if (C in aAllowed) and (aInvert) then
    begin
      Inc(Len);
      Result[Len] := C;
    end;
  end;

  SetLength(Result, Len);
end;

function TStringHelperEx.Filter(aFrom, aTo: char; aInvert: boolean = False): string;
var
  i, Len: Integer;
  C: Char;
begin
  SetLength(Result, System.Length(Self));
  Len := 0;

  for i := 1 to System.Length(Self) do
  begin
    C := self[i];
    if ((C >= aFrom) and (C <= aTo)) xor (aInvert) then
    begin
      Inc(Len);
      Result[Len] := C;
    end;
  end;

  SetLength(Result, Len);
end;

function TStringHelperEx.Filter(const aAllowed: string; aInvert: boolean = False): string;
var
  i, Len: Integer;
  C: Char;
begin
  SetLength(Result, System.Length(Self));
  Len := 0;

  for i := 1 to System.Length(Self) do
  begin
    C := self[i];
    if (Pos(C, aAllowed) > 0) xor (aInvert) then
    begin
      Inc(Len);
      Result[Len] := C;
    end;
  end;

  SetLength(Result, Len);
end;

procedure TStringHelperEx.ToFile(const aFile: string);
var
  FStream: TFileStream;
begin
  FStream := TFileStream.Create(aFile, fmCreate);
  try
    FStream.WriteBuffer(Pointer(self)^, System.Length(self));
  finally
    FStream.Free();
  end;
end;

function TStringHelperEx.Clone(aCount: integer): string;
var
  i, Len, Offset: integer;
begin
  Len := System.Length(self);
  if (aCount <= 0) or (Len = 0) then
     Exit('');

  SetLength(Result, Len * aCount);

  if (Len = 1) then
    FillChar(Result[1], aCount * SizeOf(Char), Ord(self[1]))
  else begin
    Offset := 0;
    for i := 1 to aCount do
    begin
      Move(Self[1], Result[Offset + 1], Len);
      Inc(Offset, Len);
    end;
  end;
end;

function TStringHelperEx.FileExists(): boolean;
begin
  Result := SysUtils.FileExists(self);
end;

function TStringHelperEx.DelBOM(): string;
const
  cUTF8BOM = #$EF#$BB#$BF;
begin
  Result := StringReplace(self, cUTF8BOM, '', []);
end;

function TStringHelperEx.FileQuoted(): string;
begin
 if (Pos(' ', self) > 0) then
    Result := '"' + self + '"'
  else
    Result := self;
end;

function TStringHelperEx.EndsWithAny(const aArr: TStringArray): boolean;
var
  i: integer;
begin
  for i := 0 to System.Length(aArr) - 1 do
    if (EndsWith(aArr[i])) then
      Exit(True);
  Result := False;
end;

function TStringHelperEx.EscapeRegExp(): string;
const
  SpecialChars = '\^$.|?*+()[]{}';
var
  i: Integer;
begin
  Result := '';
  for i := 1 to System.Length(self) do
    if Pos(self[i], SpecialChars) > 0 then
      Result := Result + '\' + self[i]
    else
      Result := Result + self[i];
end;

function TStringHelperEx.IsEmptyTrim(): Boolean;
begin
  Result := (Trim() = '');
end;

function TStringHelperEx.IsQuoted(): Boolean;
var
  Len: integer;
begin
  Len := System.Length(self);
  Result := (Len >= 2) and
    (
     ((self[1] = '''') and (self[Len] = '''')) or
     ((self[1] = '"') and (self[Len] = '"'))
    );
end;


// --- TStringListHelper
function TStringListHelper.AddArray(const aArr: TStringArray): TStringList;
var
  i:  integer;
begin
  for i := 0 to Length(aArr) - 1 do
      Add(aArr[i]);

  Result := self;
end;

function TStringListHelper.AddArray(const aArr: TJSONArray): TStringList;
var
  i:  integer;
begin
  for i := 0 to aArr.Count - 1 do
     Add(aArr[i].AsString);

  Result := self;
end;

function TStringListHelper.AddExtDelim(const aStr: string; const aDelim: string = '-'): TStringList;
var
  Prefix, Num: string;
  i: Integer;
begin
  Prefix := Copy(aStr, 1, Pos(aDelim, aStr) - 1);
  if (Prefix.IsEmpty()) then
    self.Add(aStr)
  else begin
    Num := Copy(aStr, Pos(aDelim, aStr) + 1, Length(aStr));
    for i := 1 to Length(Prefix) do
      self.Add(Prefix[i] + Num);
  end;

  Result := self;
end;

function TStringListHelper.AddNames(const aSL: TStrings): TStringList;
var
  i: Integer;
begin
  for i := 0 to aSL.Count - 1 do
      self.Add(aSL.Names[i]);

  Result := self;
end;

function TStringListHelper.AddWrapped(const aStr: string; aMaxLen: Integer): TStringList;
var
  Start, Cut: Integer;
begin
  Start := 1;

  while (Start <= Length(aStr)) do
  begin
    if (Length(aStr) - Start + 1 <= aMaxLen) then
    begin
      Add(Copy(aStr, Start, aMaxLen));
      Break;
    end;

    Cut := Start + aMaxLen - 1;

    while (Cut > start) and (aStr[cut] <> ' ') do
      Dec(Cut);

    if (Cut = Start) then
      Cut := Start + aMaxLen - 1;

    Add(Trim(Copy(aStr, Start, Cut - Start + 1)));
    Start := Cut + 1;
  end;

  Result := self;
end;

function TStringListHelper.AddExtDelim(const aSL: TStringList; const aDelim: string = '-'): TStringList;
var
  i: Integer;
begin
  for i := 0 to aSL.Count - 1 do
    AddExtDelim(aSL[i], aDelim);

  Result := self;
end;

function TStringListHelper.DelArray(const aArr : TStringArray): TStringList;
var
  Idx: integer;
  Str: string;
begin
  for Str in aArr do
  begin
    Idx := IndexOf(Str);
    if (Idx <> -1) then
      Delete(Idx);
  end;

  Result := self;
end;

function TStringListHelper.DelEmpty(): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (Self[i].IsEmpty) then
      Delete(i);

  Result := Self;
end;

function TStringListHelper.DelEmpty(aMaxEmpty: Integer): TStringList;
var
  i, Cnt: Integer;
begin
  Result := TStringList.Create();
  Result.Capacity := Count;

  Cnt := 0;
  for i := 0 to Count - 1 do
  begin
    if (self[i].IsEmpty()) then
    begin
      if (Cnt < aMaxEmpty) then
      begin
        Result.Add('');
        Inc(Cnt);
      end;
    end else
    begin
      Result.Add(self[i]);
      Cnt := 0;
    end;
  end;
end;

function TStringListHelper.IndexOfObject(aObj: TObject): Integer;
var
  i: Integer;
begin
  for i := 0 to self.Count - 1 do
    if (self.Objects[i] = aObj) then
      Exit(i);

  Result := -1;
end;

function TStringListHelper.GetLast(aIdx: integer): string;
begin
  aIdx := Self.Count - 1 - aIdx;
  if (aIdx >= 0) and (aIdx < Self.Count) then
    Result := Self[aIdx]
  else
    Result := '';
end;

function TStringListHelper.Split(const aStr, aDelim: string): TStringList;
var
  i: integer;
  Parts: TStringArray;
begin
  Clear();
  Parts := aStr.Split(aDelim);
  for i := 0 to Length(Parts) - 1 do
    Add(Parts[i]);

  Result := self;
end;

function TStringListHelper.WordWrap(aMaxLen: Integer): TStringList;
var
  i: Integer;

  function _UTF8PosRightChar(aPL, aPR: PChar; aCh: AnsiChar): PChar;
  begin
    while (aPR > aPL) do
    begin
      if (aPR^ = aCh) then
        Exit(aPR);

      // рух назад до початку попереднього UTF-8 символу
      repeat
        Dec(aPR);
      until (aPR <= aPL) or ((Byte(aPR^) and $C0) <> $80);
    end;

    Result := nil;
  end;

  procedure _ParseStringRecurs(aPL: PChar; aLen: integer);
  var
    Len: integer;
    Str: string;
    PSpace, PLen: PChar;
  begin
    PLen := UTF8CodepointStart(aPL, aLen, aMaxLen);
    if (PLen = nil) then
    begin
      SetString(Str, aPL, aLen);
      Result.Add(Str)
    end else begin
      PSpace := _UTF8PosRightChar(aPL, PLen, ' ');
      if (PSpace <> nil) then
      begin
        Len := PSpace - aPL;
        SetString(Str, aPL, Len);
        Result.Add(Str);

        _ParseStringRecurs(PSpace + 1, aLen - Len - 1);
      end else
        PSpace := PSpace; // Ignore very short wrap aMaxLen = 15
    end;
  end;

begin
  Result := TStringList.Create();
  for i := 0 to Count - 1 do
    _ParseStringRecurs(PChar(self[i]), self[i].Length);
end;

function TStringListHelper.Uniq(): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (IndexOf(self[i]) <> i) then
      Delete(i);

  Result := self;
end;

function TStringListHelper.Quoted(): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := QuotedStr(self[i]);

  Result := self;
end;

function TStringListHelper.Quoted(const aChar: char): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := aChar + self[i] + aChar;

  Result := self;
end;


function TStringListHelper.Formated(const aFormat: string): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := Format(aFormat, [self[i]]);

  Result := self;
end;

function TStringListHelper.Left(aLen: integer): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    if (Self[i].Length > aLen) then
      self[i] := self[i].Left(aLen);

  Result := self;
end;

function TStringListHelper.GetJoin(const aDelim: string): string;
var
  i: integer;
begin
  if (Count = 0) then
    Exit('');

  Result := Self[0];
  for i := 1 to Count - 1 do
    Result := Result + aDelim + Self[i];
end;

function TStringListHelper.GetJoinNonEmpty(const aDelim: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Count - 1 do
  begin
    if (Trim(Self[i]) = '') then
      Continue;

    if (Result <> '') then
      Result := Result + aDelim;

    Result := Result + Self[i];
  end;
end;

function TStringListHelper.GetArray(): TStringArray;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := 0 to Count - 1 do
    Result[i] := Self[i];
end;

function TStringListHelper.Replace(const aFind, aRep: string): TStringList;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    self[i] := StringReplace(self[i], aFind, aRep, [rfReplaceAll]);

  Result := self;
end;

function TStringListHelper.GetJson(): TJSONArray;
var
  i: integer;
begin
  Result := TJSONArray.Create();
  for i := 0 to Count - 1 do
    Result.Add(self[i]);
end;

function TStringListHelper.Intersect(const aSL: TStrings): TStringList;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if (aSL.IndexOf(Self[i]) = -1) then
      Delete(i);

  Result := self;
end;

function TStringListHelper.Merge(const aSL: TStrings): TStringList;
var
  i: Integer;
begin
  for i := 0 to aSL.Count - 1 do
    if (IndexOf(aSL[i]) = -1) then
      Add(aSL[i]);

  Result := self;
end;

// Map(@LowerCase),
function TStringListHelper.Map(aFunc: TStringMapFunc): TStringList;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Self[i] := aFunc(Self[i]);

  Result := Self;
end;


//--- TJSONObjectHelper
procedure TJSONObjectHelper.Update(aSrc: TJSONObject);
var
  i: Integer;
  Key: String;
begin
  for i := 0 to aSrc.Count - 1 do
  begin
    Key := aSrc.Names[i];
    if (self.IndexOfName(Key) <> -1) then
      Delete(Key);

    Add(Key, aSrc.Items[i].Clone());
  end;
end;

function TJSONObjectHelper.GetKeys(): TStringList;
var
  i: Integer;
begin
  Result := TStringList.Create();
  for i := 0 to Count - 1 do
    Result.Add(Names[i]);
end;

function TJSONObjectHelper.GetList(): TStringList;
var
  i: Integer;
begin
  Result := TStringList.Create();
  for i := 0 to Count - 1 do
    Result.Add(Names[i] + '=' + Items[i].AsString);
end;

procedure TJSONObjectHelper.SetKey(const aKey: string; aJData: TJSONData);
begin
  Elements[aKey] := aJData;
end;

procedure TJSONObjectHelper.SetKey(const aKey: string; aStr: string);
begin
  Strings[aKey] := aStr;
end;

procedure TJSONObjectHelper.SetKey(const aKey: string; aInt: integer);
begin
  Integers[aKey] := aInt;
end;

function TJSONObjectHelper.GetNested(const Path: string; aDef: Variant): Variant;
var
  i: integer;
  Parts: TStringArray;
  JObjCur: TJSONObject;
  JData: TJSONData;

  function JsonToVariant(const aJData: TJSONData): Variant;
  begin
    Result := Nil;
    if (aJData <> nil) then
      case aJData.JSONType of
        jtString:
          Result := aJData.AsString;
        jtNumber:
          Result := aJData.AsInteger;
        jtBoolean:
          Result := aJData.AsBoolean;
      end;
  end;

begin
  Result := aDef;

  JObjCur := self;
  Parts := Path.Split(['/']);

  for i := 0 to High(Parts) - 1 do
  begin
    JData := JObjCur.Find(Parts[i]);
    if (JData = nil) or not (JData is TJSONObject) then
      Exit();
    JObjCur := TJSONObject(JData);
  end;

  JData := JObjCur.Find(Parts[High(Parts)]);
  Result := JsonToVariant(JData)
end;

function TJSONObjectHelper.GetAsString(const aKey, aDef: string): string;
var
  JObj: TJSONData;
begin
  JObj := Find(aKey);
  if (JObj = nil) then
    Result := aDef
  else
    Result := JObj.AsString;
end;

end.

