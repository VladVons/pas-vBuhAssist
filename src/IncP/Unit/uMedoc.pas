// Created: 2026.02.18
// Author: Vladimir Vons <VladVons@gmail.com>

unit uMedoc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, XMLRead, DOM, LConvEncoding, Registry, fpjson;

procedure FindMedocFiles(aJArr: TJSONArray);
function GetHzXml(const aXML: string): string;
function GetHzStr(const aStr: string): string;

implementation

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

function RegGetMedocInfo(aKey: HKEY; aJArray: TJSONArray): integer;
var
  i: integer;
  StrDB: string;
  Obj: TJSONObject;
  Reg: TRegistry;
  Keys: TStringList;
begin
  Result := 0;
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
        begin
          if (Reg.ValueExists('APPDATA')) then
          begin
            StrDB := ConcatPaths([Reg.ReadString('APPDATA'), 'db', 'zvit.fdb']);
            if (FileExists(StrDB)) then
            begin
               Obj := TJSONObject.Create();
               Obj.Add('db', StrDB);
               Obj.Add('path', Reg.ReadString('PATH'));
               Obj.Add('port', StrToIntDef(Reg.ReadString('fbPort'), 0));
               aJArray.Add(Obj);
               inc(Result);
            end;
          end;
          Reg.CloseKey();
        end;
      end;
    end;
  finally
    Keys.Free();
    Reg.Free();
  end;
end;

procedure FindMedocFiles(aJArr: TJSONArray);
begin
  RegGetMedocInfo(HKEY_LOCAL_MACHINE, aJArr);
  RegGetMedocInfo(HKEY_CURRENT_USER, aJArr);
end;


end.

