// Created: 2026.02.18
// Author: Vladimir Vons <VladVons@gmail.com>

unit uMed;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, XMLRead, DOM, LConvEncoding, Registry, fpjson,
  uSettings, uVarUtil, uHttp, uVarHelper;

const
  cPerTypeAll  = 500;
  cChooseAll   = '- Всі';
  cBaseCodeLen = 6;

  cDbMonth     = 0;
  cDbQuarter   = 10;
  cDbYearHalf  = 20;
  cDbMonth9    = 25;
  cDbYear      = 30;

type
  TMedIni = class(TSettings)
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
  function GetDocsFilter(aSL: TStrings): TStringList;

var
  MedIni: TMedIni;

implementation

procedure TMedIni.AddFromRegistry(aKey: HKEY);
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

procedure TMedIni.AddFromRegistry();
begin
  AddFromRegistry(HKEY_LOCAL_MACHINE);
  AddFromRegistry(HKEY_CURRENT_USER);
end;

function TMedIni.GetPort(const aDir: string): string;
const
  cPort = '3050';
begin
  Result := '';
  if (DirectoryExists(ConcatPaths([aDir, 'client']))) then
    if (IsPortOpen('localhost', cPort)) then
      Result := cPort;
end;

function TMedIni.DirToFileApp(const aDir: string): string;
begin
  Result := ConcatPaths([aDir, 'ezvit.exe']);
  if (not FileExists(Result)) then
    Result := '';
end;

function TMedIni.DirToFileDb(const aDir: string): string;
begin
  Result := ConcatPaths([aDir, 'db', 'zvit.fdb']);
  if (not FileExists(Result)) then
    Result := '';
end;

function TMedIni.AddPaths(const aDirApp, aDirDb, aPort: string): boolean;
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

function TMedIni.GetPathDbFromXML(const aFile: string): string;
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

function TMedIni.FindDbInDir(aSL: TStringList): string;
var
  i: integer;
begin
  for i := 0 to aSL.Count - 1 do
      if (DirToFileDb(aSL[i]) <> '') then
         Exit(aSL[i]);
  Result := '';
end;

function TMedIni.AddPath(const aDirApp: string): boolean;
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

function TMedIni.ToJson(): TJSONArray;
var
  i: integer;
  App, Section, Port, Db: string;
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
        Db := GetItem(Section, 'db', '');
        Port := GetItem(Section, 'port', '');

        Obj := TJSONObject.Create();
        Obj.Add('path', Section);
        Obj.Add('db', Db);
        Obj.Add('port', Port);
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
    cDbMonth:    Result := 'Місяць';
    cDbQuarter:  Result := 'Квартал';
    cDbYearHalf: Result := 'Півріччя';
    cDbMonth9:   Result := '9 Місяців';
    cDbYear:     Result := 'Рік';
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
    cDbMonth:    Result := 'm';
    cDbQuarter:  Result := 'q';
    cDbYearHalf: Result := 'h';
    cDbYear:     Result := 'y';
  end;
end;

procedure MonthToType(var aPerType, aMonth: integer);
begin
  if (Between(aMonth, 1, 12)) then // month
    aPerType := cDbMonth
  else if (Between(aMonth, 101, 104)) then // quarter
  begin
    aPerType := cDbQuarter;
    aMonth := (aMonth - 100) * 3;
  end
  else if (Between(aMonth, 201, 202)) then // half year
  begin
    aPerType := cDbYearHalf;
    aMonth := (aMonth - 200) * 6;
  end
  else if (aMonth = 301) then // 9 month
  begin
    aPerType := cDbMonth9;
    aMonth := 9;
  end
  else if (aMonth = 401) then // year
  begin
    aPerType := cDbYear;
    aMonth := 12;
  end;
end;

function GetDocsFilter(aSL: TStrings): TStringList;
var
  i, j: integer;
  Str: string;
  SL: TStringList;
begin
  Result := TStringList.Create();

  SL := TStringList.Create();
  try
    for i := 1 to aSL.Count - 1 do
    begin
      SL.Clear();
      SL.AddExtDelim(aSL.Names[i]);
      for j := 0 to SL.Count - 1 do
      begin
        Str := SL[j].Left(cBaseCodeLen);
        Result.Add(Str);
      end;
    end;
  finally
    SL.Free();
  end;
end;


end.
