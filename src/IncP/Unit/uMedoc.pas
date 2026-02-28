// Created: 2026.02.18
// Author: Vladimir Vons <VladVons@gmail.com>

unit uMedoc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, XMLRead, DOM, LConvEncoding, Registry, IniFiles, fpjson,
  uSettings, uSys;

type
  TMedocIni = class(TSettings)
  private
    function AddPaths(const aDirApp, aDirDb, aPort: string): boolean;
    procedure AddFromRegistry(aKey: HKEY);
    function DirToFileDb(const aDir: string): string;
    function GetPathDbFromXML(const aFile: string): string;
    function GetPort(const aDir: string): string;
  public
    procedure AddFromRegistry();
    function AddPath(const aDirApp: string): boolean;
    function DirToFileApp(const aDir: string): string;
    function ToJson(): TJSONArray;
  end;

function GetHzXml(const aXML: string): string;
function GetHzStr(const aStr: string): string;

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
  //AddFromRegistry(HKEY_LOCAL_MACHINE);
  //AddFromRegistry(HKEY_CURRENT_USER);
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
      Result := Node.TextContent;
  finally
    Doc.Free();
  end;
end;

function TMedocIni.AddPath(const aDirApp: string): boolean;
var
  Str, StrDb: string;
begin
  if (not GetItem(aDirApp, 'db', '').IsEmpty()) then
     Exit(False);

  Str := ConcatPaths([aDirApp, 'config', 'global_client.config']);
  if (not FileExists(Str)) then
    Exit(False);

  StrDb := GetPathDbFromXML(Str);
  if (StrDb.IsEmpty()) then
    Exit(False);

  StrDb := StrDb.Replace('APPDATA', 'PROGRAMDATA');
  StrDb := ExpandEnvVar(StrDb);
  if (DirToFileDb(StrDb) = '') then
     StrDb := aDirApp;

  Result := AddPaths(aDirApp, StrDb, GetPort(aDirApp));
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

      NameAttr := RowNode.Attributes.GetNamedItem('NAME').NodeValue;

      ValueNode := RowNode.FindNode('VALUE');
      if ValueNode = nil then
        Continue;

      if (NameAttr = 'HZ') then
        aHZ := ValueNode.TextContent
      else if (NameAttr = 'HZN') then
        aHZN := ValueNode.TextContent
      else if (NameAttr = 'HZU') then
        aHZU := ValueNode.TextContent;
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

end.
