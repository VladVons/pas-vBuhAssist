// Created: 2026.04.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uTpl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser,
  uHelper;

type
  TNodeKind = (nkText, nkIf, nkVar, nkSet);
  TTplFunc = function(aObject: TObject; const aStr: string): string of object;

  TNode = class
  public
    Kind: TNodeKind;
    Text, Cond, VarName, Set_Val: string;
    PartTrue, PartFalse: TList;

    constructor Create(aKind: TNodeKind);
    destructor Destroy(); override;
  end;

// ================= JSON CONTEXT =================
  TContext = class
  private
    fRoot: TJSONObject;
  public
    constructor Create();
    destructor Destroy(); override;

    function GetVar(const aPath: string): TJSONData;
    procedure SetVar(const aName: string; aVal: TJSONData);
    procedure Load(const aJStr: string);
    procedure Load(aJObj: TJSONObject);
  end;

// ================= MINI ENGINE =================
  TTpl = class
  private
    fAST: TList;
    function RenderRecurs(aList: TList; aCtx: TContext): string;
    procedure FreeNodeList(aList: TList);
    function ParseRecurs(const aStr: string; var aI: Integer; aStop1, aStop2: string; out aStopFound: string): TList;

    class function PosEx(const aSubStr, aStr: string; aOffset: Integer): Integer; static;
    class function TrimTag(const aStr: string): string; static;
    class function EvalCond(const aCond: string; aCtx: TContext): Boolean; static;
    class function Filters(const aValue: string; aParts: TStringArray): string;
    class function ParseVal(const aStr: string): TJSONData; static;
  public
    UserData: TObject;
    OnSetVal, OnVar: TTplFunc;

    destructor Destroy(); override;
    procedure Parse(const aStr: string);
    function Render(aCtx: TContext): string;
  end;

implementation

// ================= NODE =================
constructor TNode.Create(aKind: TNodeKind);
begin
  Kind := aKind;
  PartTrue := TList.Create();
  PartFalse := TList.Create();
end;

destructor TNode.Destroy();
var
  i: Integer;
begin
  for i := 0 to PartTrue.Count - 1 do
    TObject(PartTrue[i]).Free();

  for i := 0 to PartFalse.Count - 1 do
    TObject(PartFalse[i]).Free();

  PartTrue.Free();
  PartFalse.Free();

  inherited;
end;

// ================= CONTEXT =================
constructor TContext.Create();
begin
  fRoot := TJSONObject.Create();
end;

destructor TContext.Destroy();
begin
  FreeAndNil(fRoot);
  inherited;
end;

procedure TContext.Load(aJObj: TJSONObject);
begin
  FreeAndNil(fRoot);
  fRoot := TJSONObject(aJObj.Clone());
end;

procedure TContext.Load(const aJStr: string);
var
  JObj: TJSONObject;
begin
  JObj := TJSONObject(GetJSON(aJStr));
  Load(JObj);
end;

function TContext.GetVar(const aPath: string): TJSONData;
var
  i: Integer;
  Parts: TStringArray;
begin
  if (aPath.IsQuoted()) then
    Exit(TJSONObject(fRoot).Find(aPath));

  Result := fRoot;
  Parts := aPath.Split(['.']);
  for i := 0 to High(parts) do
  begin
    if (Result = nil) or (Result.JSONType <> jtObject) then
      Exit();

    Result := TJSONObject(Result).Find(Parts[i]);
  end;
end;

procedure TContext.SetVar(const aName: string; aVal: TJSONData);
begin
  if (fRoot.JSONType <> jtObject) then
    Exit();

  fRoot.SetKey(aName, aVal);
end;

// ================= ENGINE =================
destructor TTpl.Destroy();
begin
  FreeNodeList(fAST);
  inherited;
end;

procedure TTpl.FreeNodeList(aList: TList);
var
  i: Integer;
begin
  if (aList = nil) then
    Exit();

  for i := 0 to aList.Count - 1 do
    TObject(aList[i]).Free();

  aList.Free();
end;

function TTpl.Render(aCtx: TContext): string;
begin
  Result := RenderRecurs(fAST, aCtx);
end;

class function TTpl.PosEx(const aSubStr, aStr: string; aOffset: Integer): Integer;
begin
  Result := Pos(aSubStr, Copy(aStr, aOffset, MaxInt));
  if (Result > 0) then
    Result := Result + aOffset - 1;
end;

class function TTpl.TrimTag(const aStr: string): string;
var
  Len: Integer;
begin
  Len := Length(aStr);
  if (Len >= 4) and (aStr[1] = '{') and (aStr[Len] = '}') then
    if ((aStr[2] = '%') and (aStr[Len - 1] = '%')) or
       ((aStr[2] = '{') and (aStr[Len - 1] = '}')) then
      Exit(Trim(Copy(aStr, 3, Len - 4)));

  Result := Trim(aStr);
end;

// ================= CONDITION (JSON AWARE SIMPLE) =================
class function TTpl.EvalCond(const aCond: string; aCtx: TContext): Boolean;
var
  Tokens: array of string;
  i: Integer;

  function Peek(): string;
  begin
    if (i <= High(Tokens)) then
      Result := Tokens[i]
    else
      Result := '';
  end;

  function Next(): string;
  begin
    Result := Peek();
    Inc(i);
  end;

  function ToBool(const aStr: string): boolean;
  begin
    Result := StrToIntDef(aStr, 0) <> 0;
  end;

  function ToNum(const aStr: string): Double;
  begin
    Result := StrToFloatDef(aStr, 0);
  end;

  function EvalOr(): Boolean; forward;
  function EvalAnd(): Boolean; forward;
  function EvalAtom(): Boolean; forward;

  function EvalAtom(): Boolean;
  var
    StrA, StrB, StrOp: string;
    Ja, Jb: TJSONData;
    Da, Db: Double;
  begin
    StrA := Next();

    if (StrA = 'not' )then
      Exit(not EvalAtom());

    if (StrA = '(') then
    begin
      Result := EvalOr;
      if Peek = ')' then
        Next();
      Exit();
    end;

    Ja := aCtx.GetVar(StrA);
    if (Peek = '') or (Peek = 'and') or (Peek = 'or') or (Peek = ')') then
    begin
      if (Ja = nil) then
        Exit(False);
      Exit(ToBool(Ja.AsString));
    end;

    StrOp := Next();
    StrB := Next();

    if (Ja = nil) then
      Exit(False);

    // Literal
    Jb := aCtx.GetVar(StrB);
    if (Jb = nil) then
    begin
      if (TryStrToFloat(StrB, Db)) then
      begin
        Da := Ja.AsFloat;
        case StrOp of
          '>':  Exit(Da > Db);
          '<':  Exit(Da < Db);
          '=':  Exit(Da = Db);
          '>=': Exit(Da >= Db);
          '<=': Exit(Da <= Db);
          '<>': Exit(Da <> Db);
        end;
      end else
        Exit(False);
    end;

    // JSON
    if (Ja.JSONType = jtNumber) and (Jb.JSONType = jtNumber) then
    begin
      Da := Ja.AsFloat;
      Db := Jb.AsFloat;

      case StrOp of
        '>':  Result := (Da > Db);
        '<':  Result := (Da < Db);
        '=':  Result := (Da = Db);
        '>=': Result := (Da >= Db);
        '<=': Result := (Da <= Db);
        '<>': Result := (Da <> Db);
      else
        Result := False;
      end;
      Exit();
    end;

    // String
    case StrOp of
      '=':  Result := (Ja.AsString = Jb.AsString);
      '<>': Result := (Ja.AsString <> Jb.AsString);
    else
      Result := False;
    end;
  end;

  function EvalAnd(): Boolean;
  begin
    Result := EvalAtom();
    while (Peek = 'and') do
    begin
      Next();
      Result := (Result and EvalAtom());
    end;
  end;

  function EvalOr(): Boolean;
  begin
    Result := EvalAnd();
    while (Peek = 'or') do
    begin
      Next();
      Result := (Result or EvalAnd());
    end;
  end;

  procedure Tokenize();
  var
    Str, buf: string;
    j: Integer;
    c: Char;
  begin
    Str := Trim(aCond);
    SetLength(Tokens, 0);
    Buf := '';

    j := 1;
    while (j <= Length(Str)) do
    begin
      c := Str[j];

      if (c in ['(', ')']) then
      begin
        if (Buf <> '') then
        begin
          SetLength(Tokens, Length(Tokens)+1);
          Tokens[High(Tokens)] := Buf;
          Buf := '';
        end;

        SetLength(Tokens, Length(Tokens)+1);
        Tokens[High(Tokens)] := c;

        Inc(j);
        Continue;
      end;

      if (c = ' ') then
      begin
        if (buf <> '') then
        begin
          SetLength(Tokens, Length(Tokens)+1);
          Tokens[High(Tokens)] := buf;
          Buf := '';
        end;

        Inc(j);
        Continue;
      end;

      buf := buf + c;
      Inc(j);
    end;

    if (buf <> '') then
    begin
      SetLength(Tokens, Length(Tokens)+1);
      Tokens[High(Tokens)] := Buf;
    end;
  end;

begin
  Tokenize();
  i := 0;
  Result := EvalOr();
end;

// ================= PARSER =================
function TTpl.ParseRecurs(const aStr: string; var aI: Integer; aStop1, aStop2: string; out aStopFound: string): TList;
var
  TagEnd, Pos1, Len: Integer;
  Str, text, Tag: string;
  List, TmpList: TList;
  node, ifNode: TNode;
begin
  List := TList.Create();
  aStopFound := '';

  Len := aStr.Length;
  while (aI <= Len) do
  begin
    if (Copy(aStr, aI, 2) = '{{') then
    begin
      TagEnd := PosEx('}}', aStr, aI);

      node := TNode.Create(nkVar);
      node.VarName := Trim(Copy(aStr, aI + 2, TagEnd - aI - 2));
      if (Assigned(OnVar)) then
        OnVar(UserData, node.VarName);

      List.Add(node);
      aI := TagEnd + 2;

      Continue;
    end;

    //aStr.ToFile('memo.txt');
    if (Copy(aStr, aI, 2) = '{%') then
    begin
      TagEnd := PosEx('%}', aStr, aI);
      Tag := TrimTag(Copy(aStr, aI, TagEnd - aI + 2));

      if (Tag = aStop1) or (Tag = aStop2) then
      begin
        aStopFound := Tag;
        aI := TagEnd + 2;
        Exit(List);
      end;

      if (Pos('set ', Tag) = 1) then
      begin
        node := TNode.Create(nkSet);

        Str := Trim(Copy(Tag, 5, MaxInt));
        Pos1 := Pos('=', Str);

        if (Pos1 > 0) then
        begin
          node.VarName := Trim(Copy(Str, 1, Pos1 - 1));
          node.Set_Val := Trim(Copy(Str, Pos1 + 1, MaxInt));
          if (Assigned(OnSetVal)) then
            node.Set_Val := OnSetVal(UserData, node.Set_Val);
        end;

        List.Add(node);
        aI := TagEnd + 2;
        Continue;
      end;

      if (Pos('if', Tag) = 1) then
      begin
        ifNode := TNode.Create(nkIf);
        ifNode.Cond := Trim(Copy(Tag, 3, MaxInt));

        aI := TagEnd + 2;

        TmpList := ParseRecurs(aStr, aI, 'else', 'endif', aStopFound);
        ifNode.PartTrue.Free();
        ifNode.PartTrue := TmpList;

        if (aStopFound = 'else') then
        begin
          TmpList := ParseRecurs(aStr, aI, '', 'endif', aStopFound);
          ifNode.PartFalse.Free();
          ifNode.PartFalse := TmpList;
        end;

        List.Add(ifNode);
        Continue;
      end;

      aI := TagEnd + 2;
      Continue;
    end;

    // TEXT
    TagEnd := PosEx('{', aStr, aI);
    if (TagEnd = 0) then
      TagEnd := Len + 1;

    if (TagEnd <= aI) then
      Inc(TagEnd);

    text := Copy(aStr, aI, TagEnd - aI);
    if (text <> '') then
    begin
      node := TNode.Create(nkText);
      node.Text := text;
      List.Add(node);
    end;

    aI := TagEnd;
  end;

  Result := List;
end;

procedure TTpl.Parse(const aStr: string);
var
  iDummy: Integer;
  sDummy: string;
begin
  FreeAndNil(fAST);

  iDummy := 1;
  fAST := ParseRecurs(aStr, iDummy, '', 'endif', sDummy);
end;

// ================= RENDER =================
class function TTpl.Filters(const aValue: string; aParts: TStringArray): string;
var
  i: Integer;
begin
  Result := aValue;

  // parts[0] = ім'я змінної
  for i := 1 to High(aParts) do
    case aParts[i].Trim() of
      'upper':
        Result := UpperCase(Result);

      'trim':
        Result := Result.Trim();
    end;
end;

class function TTpl.ParseVal(const aStr: string): TJSONData;
var
  i: integer;
  d: Double;
  b: boolean;
begin
  // string
  if (aStr.IsQuoted()) then
    Exit(TJSONString.Create(Copy(aStr, 2, Length(aStr) - 2)));

  if (TryStrToInt(aStr, i)) then
      Exit(TJSONIntegerNumber.Create(i));

  if (TryStrToFloat(aStr, d)) then
      Exit(TJSONFloatNumber.Create(d));

  if (TryStrToBool(aStr, b)) then
    Exit(TJSONBoolean.Create(b));

  Result := nil;
end;

function TTpl.RenderRecurs(aList: TList; aCtx: TContext): string;
var
  i: Integer;
  VarName: string;
  Parts: TStringArray;
  Node: TNode;
  JData: TJSONData;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create();

  for i := 0 to aList.Count - 1 do
  begin
    Node := TNode(aList[i]);
    case Node.Kind of
      nkText:
        SB.Append(Node.Text);

      nkVar:
      begin
        if (Node.VarName.IsQuoted()) then
          VarName := Node.VarName
        else
        begin
          Parts := Node.VarName.Split(['|']);
          VarName := parts[0].Trim();
        end;

        JData := aCtx.GetVar(VarName);
        if (JData = nil) then
          SB.Append('{{' + Node.VarName + '}}')
        else
          SB.Append(Filters(JData.AsString, Parts));
      end;

      nkIf:
      begin
        if (EvalCond(Node.Cond, aCtx)) then
          SB.Append(RenderRecurs(Node.PartTrue, aCtx).Trim())
        else
          SB.Append(RenderRecurs(Node.PartFalse, aCtx).Trim());
      end;

      nkSet:
      begin
        JData := ParseVal(Node.Set_Val);
        if (JData = nil) then
          JData := aCtx.GetVar(Node.Set_Val);

        if (JData <> nil) then
          aCtx.SetVar(Node.VarName, JData.Clone);
      end;
    end;
  end;

  Result := SB.ToString();
  SB.Free();
end;

end.
