unit uMedoc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, XMLRead, DOM, LConvEncoding;

function GetHzXml(const aXML: String): String;
function GetHzStr(const aStr: String): String;

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

function GetHzStr(const aStr: String): String;
var
  HZ, HZN, HZU: String;
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
  i: Integer;
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

function GetHzXml(const aXML: String): String;
var
   StrXML, HZ, HZN, HZU: String;
begin
  StrXML := CP1251ToUTF8(aXML);
  StrXML := StringReplace(StrXML, 'encoding="windows-1251"', 'encoding="utf-8"', [rfIgnoreCase]);

  GetHz(StrXML, HZ, HZN, HZU);
  Result := GetHzValToHuman(HZ, HZN, HZU);
end;

end.

