// Created: 2026.04.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uTpl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  TNodeKind = (nkText, nkIf, nkVar);

  TNode = class
  public
    Kind: TNodeKind;
    Text: string;
    Cond: string;
    VarName: string;
    TruePart: TList;
    FalsePart: TList;

    constructor Create(aKind: TNodeKind);
    destructor Destroy(); override;
  end;

// ================= JSON CONTEXT =================
  TContext = class
  private
    fRoot: TJSONData;
  public
    constructor Create();
    destructor Destroy(); override;

    function GetVar(const aPath: string): TJSONData;
    procedure Load(const aJStr: string);
    procedure Load(const aData: TJSONData);
  end;

// ================= MINI ENGINE =================
  TMiniJinja = class
  private
    fAST: TList;
    function RenderRecurs(aList: TList; aCtx: TContext): string;
    procedure FreeNodeList(aList: TList);

    class function PosEx(const SubStr, S: string; Offset: Integer): Integer; static;
    class function TrimTag(const aStr: string): string; static;
    class function EvalCond(const Cond: string; Ctx: TContext): Boolean; static;
    class function ParseRecurs(const aStr: string; var aI: Integer; aStop1, aStop2: string; out aStopFound: string): TList; static;
    class function Filters(const aValue: string; aParts: TStringArray): string;
  public
    destructor Destroy(); override;
    procedure Parse(const aStr: string);
    function Render(aCtx: TContext): string;
  end;

implementation

// ================= NODE =================
constructor TNode.Create(aKind: TNodeKind);
begin
  Kind := aKind;
  TruePart := TList.Create();
  FalsePart := TList.Create();
end;

destructor TNode.Destroy();
var
  i: Integer;
begin
  for i := 0 to TruePart.Count - 1 do
    TObject(TruePart[i]).Free();

  for i := 0 to FalsePart.Count - 1 do
    TObject(FalsePart[i]).Free();

  TruePart.Free();
  FalsePart.Free();
  inherited;
end;

// ================= CONTEXT =================
constructor TContext.Create;
begin
  fRoot := TJSONObject.Create();
end;

destructor TContext.Destroy();
begin
  FreeAndNil(fRoot);
  inherited;
end;

procedure TContext.Load(const aData: TJSONData);
begin
  FreeAndNil(fRoot);
  fRoot := aData;
end;

procedure TContext.Load(const aJStr: string);
begin
  Load(GetJSON(aJStr));
end;

function TContext.GetVar(const aPath: string): TJSONData;
var
  i: Integer;
  Parts: TStringArray;
begin
  Result := fRoot;

  Parts := aPath.Split(['.']);
  for i := 0 to High(parts) do
  begin
    if (Result = nil) or (Result.JSONType <> jtObject) then
      Exit();

    Result := TJSONObject(Result).Find(Parts[i]);
  end;
end;

// ================= ENGINE =================
destructor TMiniJinja.Destroy();
begin
  FreeNodeList(fAST);
  inherited;
end;

procedure TMiniJinja.FreeNodeList(aList: TList);
var
  i: Integer;
begin
  if (aList = nil) then
    Exit();

  for i := 0 to aList.Count - 1 do
    TObject(aList[i]).Free();

  aList.Free();
end;

function TMiniJinja.Render(aCtx: TContext): string;
begin
  Result := RenderRecurs(fAST, aCtx);
end;

class function TMiniJinja.PosEx(const SubStr, S: string; Offset: Integer): Integer;
begin
  Result := Pos(SubStr, Copy(S, Offset, MaxInt));
  if (Result > 0) then
    Result := Result + Offset - 1;
end;

class function TMiniJinja.TrimTag(const aStr: string): string;
var
  Len: Integer;
begin
  Len := Length(aStr);

  if (Len >= 4) and (aStr[1] = '{') and (aStr[Len] = '}') then
  begin
    if (aStr[2] = '%') and (aStr[Len - 1] = '%') then
      Exit(Trim(Copy(aStr, 3, Len - 4)));

    if (aStr[2] = '{') and (aStr[Len - 1] = '}') then
      Exit(Trim(Copy(aStr, 3, Len - 4)));
  end;

  Result := Trim(aStr);
end;

// ================= CONDITION (JSON AWARE SIMPLE) =================
class function TMiniJinja.EvalCond(const Cond: string; Ctx: TContext): Boolean;

var
  tokens: array of string;
  i: Integer;

  function Peek(): string;
  begin
    if (i <= High(tokens)) then
      Result := tokens[i]
    else
      Result := '';
  end;

  function Next(): string;
  begin
    Result := Peek();
    Inc(i);
  end;

  function ToBool(const v: string): Boolean;
  begin
    Result := StrToIntDef(v, 0) <> 0;
  end;

  function ToNum(const v: string): Double;
  begin
    Result := StrToFloatDef(v, 0);
  end;

  function EvalOr(): Boolean; forward;
  function EvalAnd(): Boolean; forward;
  function EvalAtom(): Boolean; forward;

  function EvalAtom(): Boolean;
  var
    a, b, op: string;
    va, vb: TJSONData;
    na, nb: Double;
  begin
    a := Next();

    if (a = 'not' )then
      Exit(not EvalAtom());

    if (a = '(') then
    begin
      Result := EvalOr;
      if Peek = ')' then
        Next();
      Exit();
    end;

    va := Ctx.GetVar(a);

    if (Peek = '') or (Peek = 'and') or (Peek = 'or') or (Peek = ')') then
    begin
      if (va = nil) then
        Exit(False);
      Exit(ToBool(va.AsString));
    end;

    op := Next();
    b := Next();

    if (va = nil) then
      Exit(False);

    // Literal
    vb := Ctx.GetVar(b);
    if (vb = nil) then
    begin
      if (TryStrToFloat(b, nb)) then
      begin
        na := va.AsFloat;
        case op of
          '>':  Exit(na > nb);
          '<':  Exit(na < nb);
          '=':  Exit(na = nb);
          '>=': Exit(na >= nb);
          '<=': Exit(na <= nb);
          '<>': Exit(na <> nb);
        end;
      end else
        Exit(False);
    end;

    // JSON
    if (va.JSONType = jtNumber) and (vb.JSONType = jtNumber) then
    begin
      na := va.AsFloat;
      nb := vb.AsFloat;

      case op of
        '>':  Result := (na > nb);
        '<':  Result := (na < nb);
        '=':  Result := (na = nb);
        '>=': Result := (na >= nb);
        '<=': Result := (na <= nb);
        '<>': Result := (na <> nb);
      else
        Result := False;
      end;
      Exit();
    end;

    // String
    case op of
      '=':  Result := (va.AsString = vb.AsString);
      '<>': Result := (va.AsString <> vb.AsString);
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
    s, buf: string;
    j: Integer;
    c: Char;
  begin
    s := LowerCase(Trim(Cond));
    SetLength(tokens, 0);
    buf := '';

    j := 1;
    while (j <= Length(s)) do
    begin
      c := s[j];

      if (c in ['(', ')']) then
      begin
        if buf <> '' then
        begin
          SetLength(tokens, Length(tokens)+1);
          tokens[High(tokens)] := buf;
          buf := '';
        end;

        SetLength(tokens, Length(tokens)+1);
        tokens[High(tokens)] := c;

        Inc(j);
        Continue;
      end;

      if (c = ' ') then
      begin
        if (buf <> '') then
        begin
          SetLength(tokens, Length(tokens)+1);
          tokens[High(tokens)] := buf;
          buf := '';
        end;

        Inc(j);
        Continue;
      end;

      buf := buf + c;
      Inc(j);
    end;

    if (buf <> '') then
    begin
      SetLength(tokens, Length(tokens)+1);
      tokens[High(tokens)] := buf;
    end;
  end;

begin
  Tokenize();
  i := 0;
  Result := EvalOr();
end;

// ================= PARSER =================
class function TMiniJinja.ParseRecurs(const aStr: string; var aI: Integer; aStop1, aStop2: string; out aStopFound: string): TList;
var
  List: TList;
  node, ifNode: TNode;
  text, tag: string;
  tagEnd: Integer;

begin
  List := TList.Create();
  aStopFound := '';

  while (aI <= Length(aStr)) do
  begin
    if Copy(aStr, aI, 2) = '{{' then
    begin
      tagEnd := PosEx('}}', aStr, aI);

      node := TNode.Create(nkVar);
      node.VarName := Trim(Copy(aStr, aI + 2, tagEnd - aI - 2));

      List.Add(node);
      aI := tagEnd + 2;
      Continue;
    end;

    if Copy(aStr, aI, 2) = '{%' then
    begin
      tagEnd := PosEx('%}', aStr, aI);
      tag := TrimTag(Copy(aStr, aI, tagEnd - aI + 2));

      if (tag = aStop1) or (tag = aStop2) then
      begin
        aStopFound := tag;
        aI := tagEnd + 2;
        Exit(List);
      end;

      if Pos('if', tag) = 1 then
      begin
        ifNode := TNode.Create(nkIf);
        ifNode.Cond := Trim(Copy(tag, 3, MaxInt));

        aI := tagEnd + 2;

        ifNode.TruePart.Free();
        ifNode.TruePart := ParseRecurs(aStr, aI, 'else', 'endif', aStopFound);

        if (aStopFound = 'else') then
        begin
          ifNode.FalsePart.Free();
          ifNode.FalsePart := ParseRecurs(aStr, aI, '', 'endif', aStopFound);
        end;

        List.Add(ifNode);
        Continue;
      end;

      aI := tagEnd + 2;
      Continue;
    end;

    // TEXT
    tagEnd := PosEx('{', aSTr, aI);
    if tagEnd = 0 then
      tagEnd := Length(aStr) + 1;

    text := Copy(aStr, aI, tagEnd - aI);
    if text <> '' then
    begin
      node := TNode.Create(nkText);
      node.Text := text;
      List.Add(node);
    end;

    aI := tagEnd;
  end;

  Result := List;
end;

procedure TMiniJinja.Parse(const aStr: string);
var
  iDummy: Integer;
  sDummy: string;
begin
  FreeAndNil(fAST);

  iDummy := 1;
  fAST := ParseRecurs(aStr, iDummy, '', 'endif', sDummy);
end;

// ================= RENDER =================
class function TMiniJinja.Filters(const aValue: string; aParts: TStringArray): string;
var
  i: Integer;
begin
  Result := aValue;

  // parts[0] = ім'я змінної
  for i := 1 to High(aParts) do
  begin
    case Trim(LowerCase(aParts[i])) of
      'upper':
        Result := UpperCase(Result);

      'trim':
        Result := Trim(Result);
    end;
  end;
end;

function TMiniJinja.RenderRecurs(aList: TList; aCtx: TContext): string;
var
  i: Integer;
  VarName: string;
  Parts: TStringArray;
  Node: TNode;
  JData: TJSONData;
begin
  Result := '';

  for i := 0 to aList.Count - 1 do
  begin
    Node := TNode(aList[i]);
    case Node.Kind of
      nkText:
        Result := Result + Node.Text;

      nkVar:
      begin
        Parts := Node.VarName.Split(['|']);
        VarName := Trim(parts[0]);
        JData := aCtx.GetVar(VarName);
        if (JData = nil) then
          Result := Result + '{{' + Node.VarName + '}}'
        else
          Result := Result + Filters(JData.AsString, Parts);
      end;

      nkIf:
        if EvalCond(Node.Cond, aCtx) then
          Result := Result + RenderRecurs(Node.TruePart, aCtx)
        else
          Result := Result + RenderRecurs(Node.FalsePart, aCtx);
    end;
  end;
end;

end.
