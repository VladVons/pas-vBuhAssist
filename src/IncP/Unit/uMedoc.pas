// Created: 2026.02.18
// Author: Vladimir Vons <VladVons@gmail.com>

unit uMedoc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, XMLRead, DOM, LConvEncoding, Registry, fpjson,
  uSettings, uVarUtil;

const
  cPerTypeAll = 500;
  cChooseAll  = '- Всі';
  cArrExcl: TStringArray = ('FJ-12%', 'FJ-13%', 'FJ-14%', 'PD%', 'Z0%');

type
  TMedocIni = class(TSettings)
  private
    function AddPaths(const aDirApp, aDirDb, aPort: string): boolean;
    procedure AddFromRegistry(aKey: HKEY);
    function DirToFileDb(const aDir: string): string;
    function GetPathDbFromXML(const aFile: string): string;
    function GetPort(const aDir: string): string;
    function FindDbInDir(aSL: TStringList): string;
  public
    procedure AddFromRegistry();
    function AddPath(const aDirApp: string): boolean;
    function DirToFileApp(const aDir: string): string;
    function ToJson(): TJSONArray;
  end;

  function GetHzXml(const aXML: string): string;
  function GetHzStr(const aStr: string): string;
  function PerTypeToHuman(aType: Integer): string;
  function GetYearPart(aDate: TDate; aDiv: integer): Integer;
  function PerTypeToChar(aPerType: integer): char;
  procedure MonthToType(var aPerType, aMonth: integer);
  procedure SplitCode(var aResSL: TStringList; const aStr: string; const aDelim: string = '-');
  function SplitCodes(aSL: TStringList; const aDelim: string = '-'): TStringList;

var
  MedocIni: TMedocIni;

implementation

procedure TMedocIni.AddFromRegistry(aKey: HKEY);
var
  i: integer;
  Reg: TRegistry;
  Keys: TStringList;
begin
  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create();
  try
    Reg.RootKey := aKey;
    if Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService') then
    begin
      Reg.GetKeyNames(Keys);
      Reg.CloseKey();
      for i := 0 to Keys.Count - 1 do
      begin
        if (Reg.OpenKeyReadOnly('\SOFTWARE\IntellectService\' + Keys[i])) then
          if (Reg.ValueExists('APPDATA')) then
            AddPaths(Reg.ReadString('PATH'), Reg.ReadString('APPDATA'), Reg.ReadString('fbPort'));
        Reg.CloseKey();
      end;
    end;
  finally
    Keys.Free();
    Reg.Free();
  end;
end;

procedure TMedocIni.AddFromRegistry();
begin
  AddFromRegistry(HKEY_LOCAL_MACHINE);
  AddFromRegistry(HKEY_CURRENT_USER);
end;

function TMedocIni.GetPort(const aDir: string): string;
begin
  if (DirectoryExists(ConcatPaths([aDir, 'client']))) then
     Result := '3050'
  else
     Result := ''
end;

function TMedocIni.DirToFileApp(const aDir: string): string;
begin
  Result := ConcatPaths([aDir, 'ezvit.exe']);
  if (not FileExists(Result)) then
    Result := '';
end;

function TMedocIni.DirToFileDb(const aDir: string): string;
begin
  Result := ConcatPaths([aDir, 'db', 'zvit.fdb']);
  if (not FileExists(Result)) then
    Result := '';
end;

function TMedocIni.AddPaths(const aDirApp, aDirDb, aPort: string): boolean;
var
  StrDb: string;
begin
  StrDb := DirToFileDb(aDirDb);
  if (StrDb.IsEmpty()) then
    Exit(False);

  if (DirToFileApp(aDirApp).IsEmpty()) or (GetItem(aDirApp, 'db', '') <> '') then
     Exit(False);

  SetItem(aDirApp, 'db', StrDb);
  SetItem(aDirApp, 'port', aPort);
  Result := True;
end;

function TMedocIni.GetPathDbFromXML(const aFile: string): string;
var
  Doc: TXMLDocument;
  Node: TDOMNode;
begin
  Result := '';

  ReadXMLFile(Doc, aFile);
  try
    Node := Doc.DocumentElement.FindNode('APPDATA');
    if Assigned(Node) then
      Result := UTF8Encode(Node.TextContent);
  finally
    Doc.Free();
  end;
end;

function TMedocIni.FindDbInDir(aSL: TStringList): string;
var
  i: integer;
begin
  for i := 0 to aSL.Count - 1 do
      if (DirToFileDb(aSL[i]) <> '') then
         Exit(aSL[i]);
  Result := '';
end;

function TMedocIni.AddPath(const aDirApp: string): boolean;
const
  cPF = '\Program Files\';
var
  P1: integer;
  Str, StrDb: string;
  SL: TStringList;
begin
  if (not GetItem(aDirApp, 'db', '').IsEmpty()) then
     Exit(False);

  //Str := ConcatPaths([aDirApp, 'config', 'global_client.config']);
  //if (FileExists(Str)) then
  //begin
  //  StrDb := GetPathDbFromXML(Str);
  //  if (StrDb.IsEmpty()) then
  //    Exit(False);
  //end;

  //StrDb := StrDb.Replace('APPDATA', 'PROGRAMDATA');
  //StrDb := ExpandEnvVar(StrDb);
  //if (DirToFileDb(StrDb) = '') then
  //   StrDb := aDirApp;

  try
    SL := TStringList.Create();
    SL.Add(aDirApp);

    P1 := Pos(cPF, aDirApp);
    if (P1 > 0) then
    begin
      Str := Copy(aDirApp, P1 + Length(cPF), Length(aDirApp));
      SL.Add(ConcatPaths([GetEnvironmentVariable('PROGRAMDATA'), Str]));
      SL.Add(ConcatPaths([GetEnvironmentVariable('LOCALAPPDATA'), Str]));
    end;

    StrDb := FindDbInDir(SL);
    Result := AddPaths(aDirApp, StrDb, GetPort(aDirApp));
  finally
    SL.Free();
  end;
end;

function TMedocIni.ToJson(): TJSONArray;
var
  i: integer;
  App, Section: string;
  SL: TStringList;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create();

  SL := GetSections();
  try
    for i := 0 to SL.Count - 1 do
    begin
      Section := SL[i];
      App := ConcatPaths([Section, 'ezvit.exe']);
      if (FileExists(App)) then
      begin
        Obj := TJSONObject.Create();
        Obj.Add('path', Section);
        Obj.Add('db', GetItem(Section, 'db', ''));
        Obj.Add('port', GetItem(Section, 'port', ''));
        Result.Add(Obj);
      end;
    end;
  finally
    SL.Free();
  end;
end;

function GetYearPart(aDate: TDate; aDiv: integer): Integer;
var
  Year, Month, Day: Word;
begin
  DecodeDate(aDate, Year, Month, Day);
  Result := ((Month - 1) div aDiv) + 1;
end;

function PerTypeToHuman(aType: Integer): string;
begin
  case aType of
    0:  Result := 'Місяць';
    10: Result := 'Квартал';
    20: Result := 'Півріччя';
    25: Result := '9 Місяців';
    30: Result := 'Рік';
  else
    Result := 'Не відомий';
  end;
end;


function GetHzValToHuman(const aHZ, aHZN, aHZU: string): string;
begin
  if (aHZ.Trim() = '1') then
     Result := 'Звітний'
  else if (aHZN.Trim() = '1') then
     Result := 'Звітний новий'
  else if (aHZU.Trim() = '1') then
     Result := 'Уточнюючий'
  else
      Result := '';
end;

function GetHzStr(const aStr: string): string;
var
  HZ, HZN, HZU: string;
  Arr: TStringArray;
begin
  Arr := aStr.Split('-');
  HZ := Arr[0];
  HZN := Arr[1];
  HZU := Arr[2];
  Result := GetHzValToHuman(HZ, HZN, HZU);
end;

procedure GetHz(const aXML: string; out aHZ, aHZN, aHZU: string);
var
  Doc: TXMLDocument;
  NodeList: TDOMNodeList;
  RowNode, ValueNode: TDOMNode;
  i: integer;
  NameAttr: string;
begin
  aHZ := '';  aHZN := ''; aHZU := '';

  if (aXML.IsEmpty()) then
    Exit;

  ReadXMLFile(Doc, TStringStream.Create(aXML, TEncoding.UTF8));
  try
    NodeList := Doc.DocumentElement.GetElementsByTagName('ROW');
    for i := 0 to NodeList.Count - 1 do
    begin
      RowNode := NodeList.Item[i];
      if RowNode.Attributes.GetNamedItem('NAME') = nil then
        Continue;

      NameAttr := UTF8Encode(RowNode.Attributes.GetNamedItem('NAME').NodeValue);

      ValueNode := RowNode.FindNode('VALUE');
      if ValueNode = nil then
        Continue;

      if (NameAttr = 'HZ') then
        aHZ := UTF8Encode(ValueNode.TextContent)
      else if (NameAttr = 'HZN') then
        aHZN := UTF8Encode(ValueNode.TextContent)
      else if (NameAttr = 'HZU') then
        aHZU := UTF8Encode(ValueNode.TextContent);
    end;
  finally
    Doc.Free();
  end;
end;

function GetHzXml(const aXML: string): string;
var
   StrXML, HZ, HZN, HZU: string;
begin
  StrXML := CP1251ToUTF8(aXML);
  StrXML := StringReplace(StrXML, 'encoding="windows-1251"', 'encoding="utf-8"', [rfIgnoreCase]);

  GetHz(StrXML, HZ, HZN, HZU);
  Result := GetHzValToHuman(HZ, HZN, HZU);
end;

function PerTypeToChar(aPerType: integer): char;
begin
  case aPerType of
    0:  Result := 'm';
    10: Result := 'q';
    20: Result := 'h';
    30: Result := 'y';
  end;
end;

procedure MonthToType(var aPerType, aMonth: integer);
begin
  if (Between(aMonth, 1, 12)) then // month
    aPerType := 0
  else if (Between(aMonth, 101, 104)) then // quarter
  begin
    aPerType := 10;
    aMonth := (aMonth - 100) * 3;
  end
  else if (Between(aMonth, 201, 202)) then // half year
  begin
    aPerType := 20;
    aMonth := (aMonth - 200) * 6;
  end
  else if (aMonth = 301) then // 9 month
  begin
    aPerType := 25;
    aMonth := 9;
  end
  else if (aMonth = 401) then // year
  begin
    aPerType := 30;
    aMonth := 12;
  end;
end;

procedure SplitCode(var aResSL: TStringList; const aStr: string; const aDelim: string = '-');
var
  Prefix, Num: string;
  i: Integer;
begin
  Prefix := Copy(aStr, 1, Pos(aDelim, aStr) - 1);
  if (Prefix.IsEmpty()) then
    aResSL.Add(aStr)
  else begin
    Num := Copy(aStr, Pos(aDelim, aStr) + 1, Length(aStr));
    for i := 1 to Length(Prefix) do
      aResSL.Add(Prefix[i] + Num);
  end;
end;

function SplitCodes(aSL: TStringList; const aDelim: string = '-'): TStringList;
var
  i: Integer;
begin
  Result := TStringList.Create();
  for i := 0 to aSL.Count - 1 do
    SplitCode(Result, aSL[i], aDelim);
end;

end.
