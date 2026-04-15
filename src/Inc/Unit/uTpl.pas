unit uTpl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type

  TMiniJinja = class
  private
    //class function PosEx(const SubStr, S: string; Offset: Integer): Integer; static;
    //class function TrimTag(const aStr: string): string; static;
    //
    //class function EvalExpr(E: PExpr; Ctx: TContext): Variant; static;
    //class function ParseExpr(const S: string): PExpr; static;
    //class procedure FreeExpr(E: PExpr); static;
    //
    //class function EvalCond(const Cond: string; Ctx: TContext): Boolean; static;
    //
    class function ParseBlock(const S: string; var i: Integer; Stop1, Stop2: string; out StopFound: string): TList; static;
    class function RenderList(L: TList; Ctx: TContext): string; static;
  public
    class function Parse(const aStr: string): TList; static;
    class function Render(AST: TList; Ctx: TContext): string; static;
  end;


implementation
                                             qwe
// ================= NODE =================  3
constructor TNode.Create(aKind: TNodeKind);
begin
  Kind := aKind;
  TruePart := TList.Create;
  FalsePart := TList.Create;
end;

destructor TNode.Destroy;
var i: Integer;
begin
  for i := 0 to TruePart.Count - 1 do TObject(TruePart[i]).Free;
  for i := 0 to FalsePart.Count - 1 do TObject(FalsePart[i]).Free;
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
  FreeObject(FRoot);
  inherited;
end;

procedure TContext.Load(const aData: TJSONData);
begin
  FreeObject(FRoot);
  FRoot := aData;
end;

procedure TContext.LoadJSON(const aJSON: string);
begin
  Load(GetJSON(aJSON));
end;

function TContext.GetByPath(const aPath: string): TJSONData;
var parts: TStringArray; i: Integer; cur: TJSONData;
begin                                   231212312
  Result := nil;
  if FRoot = nil then Exit;                      23
                                                   2
  parts := aPath.Split(['.']);                      51
  cur := FRoot;                                       25
                                                        12
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

// =====================================================
// =============== EXPRESSION AST ENGINE ===============
// =====================================================

class function TMiniJinja.ParseExpr(const S: string): PExpr;
var
  tokens: TStringList;
  i: Integer;

  function NewNode(k: TExprKind; const v: string = ''): PExpr;
  begin
    New(Result);
    Result^.Kind := k;
    Result^.Value := v;
    Result^.Left := nil;
    Result^.Right := nil;
  end;

  function Peek: string;
  begin
    if i <= tokens.Count-1 then Result := tokens[i] else Result := '';
  end;

  function Next: string;
  begin
    Result := Peek;
    Inc(i);
  end;

  function ParseAtom: PExpr; forward;
  function ParseNot: PExpr; forward;
  function ParseCmp: PExpr; forward;
  function ParseAnd: PExpr; forward;
  function ParseOr: PExpr; forward;

  function ParseAtom: PExpr;
  var v: string;
  begin
    v := Next;

    if v = '(' then
    begin
      Result := ParseOr;
      if Peek = ')' then Next;
      Exit;
    end;

    if TryStrToFloat(v, Result) then Exit(NewNode(exNumber, v));
    if (v = 'true') or (v = 'false') then Exit(NewNode(exBool, v));

    Result := NewNode(exVar, v);
  end;

  function ParseNot: PExpr;
  begin
    if Peek = 'not' then
    begin
      Next;
      Result := NewNode(exNot);
      Result^.Left := ParseNot;
      Exit;
    end;
    Result := ParseAtom;
  end;

  function ParseCmp: PExpr;
  var n: PExpr; op: string;
  begin
    n := ParseNot;

    op := Peek;
    if (op = '=') or (op = '!=') or (op = '>') or (op = '<') or (op = '>=') or (op = '<=') then
    begin
      Next;
      Result := NewNode(
        TExprKind(Ord(exEq) + Ord(op='!=') + Ord(op='>')*2 + Ord(op='<')*3 + Ord(op='>=')*4 + Ord(op='<=')*5)
      );
      Result^.Left := n;
      Result^.Right := ParseNot;
      Exit;
    end;

    Result := n;
  end;

  function ParseAnd: PExpr;
  var n: PExpr;
  begin
    n := ParseCmp;
    while Peek = 'and' do
    begin
      Next;
      with NewNode(exAnd) do
      begin
        Left := n;
        Right := ParseCmp;
        n := Result;
      end;
    end;
    Result := n;
  end;

  function ParseOr: PExpr;
  var n: PExpr;
  begin
    n := ParseAnd;
    while Peek = 'or' do
    begin
      Next;
      with NewNode(exOr) do
      begin
        Left := n;
        Right := ParseAnd;
        n := Result;
      end;
    end;
    Result := n;
  end;

  procedure Tokenize;
  var s, buf: string; c: Char; j: Integer;
  begin
    tokens := TStringList.Create;
    s := LowerCase(S);
    buf := '';

    for j := 1 to Length(s) do
    begin
      c := s[j];

      if c in ['(', ')'] then
      begin
        if buf <> '' then begin tokens.Add(buf); buf := ''; end;
        tokens.Add(c);
      end
      else if c = ' ' then
      begin
        if buf <> '' then begin tokens.Add(buf); buf := ''; end;
      end
      else buf := buf + c;
    end;

    if buf <> '' then tokens.Add(buf);
  end;

begin
  Tokenize;
  i := 0;
  Result := ParseOr;
  tokens.Free;
end;

// ================= EVAL AST =================
class function TMiniJinja.EvalExpr(E: PExpr; Ctx: TContext): Variant;
var
  L, R: Variant;
  v: TJSONData;

begin
  if E = nil then Exit(False);

  case E^.Kind of

    exNumber: Exit(StrToFloatDef(E^.Value, 0));

    exBool: Exit(E^.Value = 'true');

    exVar:
      begin
        v := Ctx.GetVar(E^.Value);
        if v = nil then Exit(Null);
        Exit(v.AsString);
      end;

    exNot:
      Exit(not Boolean(EvalExpr(E^.Left, Ctx)));

    exAnd:
      Exit(Boolean(EvalExpr(E^.Left, Ctx)) and Boolean(EvalExpr(E^.Right, Ctx)));

    exOr:
      Exit(Boolean(EvalExpr(E^.Left, Ctx)) or Boolean(EvalExpr(E^.Right, Ctx)));

    exEq: Exit(EvalExpr(E^.Left, Ctx) = EvalExpr(E^.Right, Ctx));
    exNe: Exit(EvalExpr(E^.Left, Ctx) <> EvalExpr(E^.Right, Ctx));
    exGt: Exit(EvalExpr(E^.Left, Ctx) > EvalExpr(E^.Right, Ctx));
    exLt: Exit(EvalExpr(E^.Left, Ctx) < EvalExpr(E^.Right, Ctx));
    exGe: Exit(EvalExpr(E^.Left, Ctx) >= EvalExpr(E^.Right, Ctx));
    exLe: Exit(EvalExpr(E^.Left, Ctx) <= EvalExpr(E^.Right, Ctx));

  end;

  Result := False;
end;

class function TMiniJinja.EvalCond(const Cond: string; Ctx: TContext): Boolean;
var e: PExpr;
begin
  e := ParseExpr(Cond);
  Result := Boolean(EvalExpr(e, Ctx));
  FreeExpr(e);
end;

class procedure TMiniJinja.FreeExpr(E: PExpr);
begin
  if E = nil then Exit;
  FreeExpr(E^.Left);
  FreeExpr(E^.Right);
  Dispose(E);
end;

// ================= TEMPLATE ENGINE (без змін логіки) =================
class function TMiniJinja.PosEx(const SubStr, S: string; Offset: Integer): Integer;
begin
  Result := Pos(SubStr, Copy(S, Offset, MaxInt));
  if Result > 0 then Result := Result + Offset - 1;
end;

class function TMiniJinja.TrimTag(const aStr: string): string;
var L: Integer;
begin
  L := Length(aStr);
  if (L >= 4) and (aStr[1] = '{') then
  begin
    if (aStr[2] = '%') then
      Exit(Trim(Copy(aStr, 3, L-4)));
  end;
  Result := Trim(aStr);
end;

// ===== PARSER / RENDER (залишив як у тебе концепт) =====
// (не дублюю щоб не роздувати — логіка та сама)

class function TMiniJinja.Parse(const aStr: string): TList;
var i: Integer; dummy: string;
begin
  i := 1;
  Result := ParseBlock(aStr, i, '', 'endif', dummy);
end;

class function TMiniJinja.Render(AST: TList; Ctx: TContext): string;
begin
  Result := RenderList(AST, Ctx);
end;

class function TMiniJinja.ParseBlock(const S: string; var i: Integer; Stop1, Stop2: string; out StopFound: string): TList;
begin
  Result := TList.Create;
  // (твоя логіка без змін)
  StopFound := '';
end;

class function TMiniJinja.RenderList(L: TList; Ctx: TContext): string;
begin
  Result := '';
  // (твоя логіка без змін)
end;

end.
