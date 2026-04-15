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
    destructor Destroy; override;
  end;

// ================= JSON CONTEXT =================
  TContext = class
  private
    FRoot: TJSONData;
    function GetByPath(const aPath: string): TJSONData;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load(const aJStr: string);
    procedure Load(const aData: TJSONData);

    function GetVar(const aPath: string): TJSONData;
  end;

// ================= MINI ENGINE =================
  TMiniJinja = class
  private
    class function PosEx(const SubStr, S: string; Offset: Integer): Integer; static;
    class function TrimTag(const aStr: string): string; static;
    class function EvalCond(const Cond: string; Ctx: TContext): Boolean; static;
    class function ParseBlock(const S: string; var i: Integer; Stop1, Stop2: string; out StopFound: string): TList; static;
    class function RenderList(L: TList; Ctx: TContext): string; static;
    class function Filters(const aValue: string; aParts: TStringArray): string;
  public
    class function Parse(const aStr: string): TList; static;
    class function Render(AST: TList; Ctx: TContext): string; static;
  end;

implementation

// ================= NODE =================
constructor TNode.Create(aKind: TNodeKind);
begin
  Kind := aKind;
  TruePart := TList.Create;
  FalsePart := TList.Create;
end;

destructor TNode.Destroy;
var
  i: Integer;
begin
  for i := 0 to TruePart.Count - 1 do
    TObject(TruePart[i]).Free;

  for i := 0 to FalsePart.Count - 1 do
    TObject(FalsePart[i]).Free;

  TruePart.Free;
  FalsePart.Free;
  inherited;
end;

// ================= CONTEXT =================
constructor TContext.Create;
begin
  FRoot := TJSONObject.Create;
end;

destructor TContext.Destroy;
begin
  FreeAndNil(FRoot);
  inherited;
end;

procedure TContext.Load(const aData: TJSONData);
begin
  FreeAndNil(FRoot);
  FRoot := aData;
end;

procedure TContext.Load(const aJStr: string);
begin
  Load(GetJSON(aJStr));
end;

function TContext.GetByPath(const aPath: string): TJSONData;
var
  parts: TStringArray;
  i: Integer;
  cur: TJSONData;
begin
  Result := nil;
  if (FRoot = nil) then
    Exit();

  parts := aPath.Split(['.']);
  cur := FRoot;

  for i := 0 to High(parts) do
  begin
    if (cur = nil) or (cur.JSONType <> jtObject) then Exit;
    cur := TJSONObject(cur).Find(parts[i]);
  end;

  Result := cur;
end;

function TContext.GetVar(const aPath: string): TJSONData;
begin
  Result := GetByPath(aPath);
end;

// ================= ENGINE =================
class function TMiniJinja.PosEx(const SubStr, S: string; Offset: Integer): Integer;
begin
  Result := Pos(SubStr, Copy(S, Offset, MaxInt));
  if Result > 0 then
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

  function Peek: string;
  begin
    if i <= High(tokens) then Result := tokens[i]
    else Result := '';
  end;

  function Next: string;
  begin
    Result := Peek;
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

  function EvalOr: Boolean; forward;
  function EvalAnd: Boolean; forward;
  function EvalAtom: Boolean; forward;

  function EvalAtom: Boolean;
  var
    a, b, op: string;
    va, vb: TJSONData;
    na, nb: Double;
  begin
    a := Next;

    if a = 'not' then
      Exit(not EvalAtom());

    if a = '(' then
    begin
      Result := EvalOr;
      if Peek = ')' then Next;
      Exit;
    end;

    va := Ctx.GetVar(a);

    if (Peek = '') or (Peek = 'and') or (Peek = 'or') or (Peek = ')') then
    begin
      if (va = nil) then
        Exit(False);
      Exit(ToBool(va.AsString));
    end;

    op := Next;
    b := Next;

    vb := Ctx.GetVar(b);

    // ================= FIX CRITICAL NIL =================
    if va = nil then
      Exit(False);

    // якщо vb не JSON → це literal
    if vb = nil then
    begin
      if TryStrToFloat(b, nb) then
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
      end
      else
        Exit(False);
    end;

    // ================= JSON vs JSON =================
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
      Exit;
    end;

    // string fallback
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
    while j <= Length(s) do
    begin
      c := s[j];

      if c in ['(', ')'] then
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

      if c = ' ' then
      begin
        if buf <> '' then
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

    if buf <> '' then
    begin
      SetLength(tokens, Length(tokens)+1);
      tokens[High(tokens)] := buf;
    end;
  end;

begin
  Tokenize;
  i := 0;
  Result := EvalOr;
end;

// ================= PARSER =================
class function TMiniJinja.ParseBlock(const S: string; var i: Integer; Stop1, Stop2: string; out StopFound: string): TList;
var
  List: TList;
  node, ifNode: TNode;
  text, tag: string;
  tagEnd: Integer;

begin
  List := TList.Create();
  StopFound := '';

  while i <= Length(S) do
  begin
    if Copy(S, i, 2) = '{{' then
    begin
      tagEnd := PosEx('}}', S, i);

      node := TNode.Create(nkVar);
      node.VarName := Trim(Copy(S, i + 2, tagEnd - i - 2));

      List.Add(node);
      i := tagEnd + 2;
      Continue;
    end;

    if Copy(S, i, 2) = '{%' then
    begin
      tagEnd := PosEx('%}', S, i);
      tag := TrimTag(Copy(S, i, tagEnd - i + 2));

      if (tag = Stop1) or (tag = Stop2) then
      begin
        StopFound := tag;
        i := tagEnd + 2;
        Exit(List);
      end;

      if Pos('if', tag) = 1 then
      begin
        ifNode := TNode.Create(nkIf);
        ifNode.Cond := Trim(Copy(tag, 3, MaxInt));

        i := tagEnd + 2;

        ifNode.TruePart := ParseBlock(S, i, 'else', 'endif', StopFound);

        if StopFound = 'else' then
          ifNode.FalsePart := ParseBlock(S, i, '', 'endif', StopFound);

        List.Add(ifNode);
        Continue;
      end;

      i := tagEnd + 2;
      Continue;
    end;

    // TEXT
    tagEnd := PosEx('{', S, i);
    if tagEnd = 0 then tagEnd := Length(S) + 1;

    text := Copy(S, i, tagEnd - i);
    if text <> '' then
    begin
      node := TNode.Create(nkText);
      node.Text := text;
      List.Add(node);
    end;

    i := tagEnd;
  end;

  Result := List;
end;

class function TMiniJinja.Parse(const aStr: string): TList;
var
  i: Integer;
  dummy: string;
begin
  i := 1;
  Result := ParseBlock(aStr, i, '', 'endif', dummy);
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

class function TMiniJinja.RenderList(L: TList; Ctx: TContext): string;
var
  i: Integer;
  VarName: string;
  Parts: TStringArray;
  n: TNode;
  v: TJSONData;
begin
  Result := '';

  for i := 0 to L.Count - 1 do
  begin
    n := TNode(L[i]);
    case n.Kind of
      nkText:
        Result := Result + n.Text;

      nkVar:
      begin
        Parts := n.VarName.Split(['|']);
        VarName := Trim(parts[0]);

        v := Ctx.GetVar(VarName);
        if (v = nil) then
          Result := Result + '{{' + n.VarName + '}}'
        else
          Result := Result + Filters(v.AsString, Parts);
      end;

      nkIf:
        if EvalCond(n.Cond, Ctx) then
          Result := Result + RenderList(n.TruePart, Ctx)
        else
          Result := Result + RenderList(n.FalsePart, Ctx);
    end;
  end;
end;

class function TMiniJinja.Render(AST: TList; Ctx: TContext): string;
begin
  Result := RenderList(AST, Ctx);
end;

end.
