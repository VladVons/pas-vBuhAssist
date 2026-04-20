// Created: 2026.04.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, fpjson, LConvEncoding, base64, fppdf,
  uFWizard, uVarUtil, uMacros, uTpl, uSysVcl, uHelper, uLog, uSys, uDbList, uStrArr;

type
  TUserData = class
    Ctx: TContext;
    JWiz, JMed: TJSONObject;
  end;

  TWizardUser = class(TPersistent)
  published
    procedure OnClick_g01w50s20_save(Sender: TObject);
    procedure OnClick_g00w10_save(Sender: TObject);
    procedure OnShow_TMemo(aSender: TMemo);
    procedure OnShow_TMemoIf(aSender: TMemo);
    function OnSetVal(aData: TUserData; const aStr: string): string;
    function OnVar(aData: TUserData; const aStr: string): string;
  private
    fParent: TFWizard;
    procedure PageControlChange(Sender: TObject);
    procedure D1(aJObjMed, aJObjWiz: TJSONObject);
    function D2(aJObjMed, aJObjWiz: TJSONObject): integer;
    procedure SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
    function AsGridPrint(aJObj: TJSONObject; const aParam: TStringList): TStringList;
    procedure StringListToPDF(aLines: TStringList; const aFileName: string);
    procedure ParseMemo(const aName: string);
    procedure ParseMemoIf(const aName: string);
  public
    constructor Create(aParent: TFWizard);
  end;

implementation

constructor TWizardUser.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
  //fParent.PageControl.OnChange := @PageControlChange;
end;

procedure TWizardUser.PageControlChange(Sender: TObject);
begin
end;

procedure TWizardUser.SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
var
  StrXds, Path, FileName, No, FJ: string;
  Macros: TMacros;
begin
  FJ := IIF(Length(aJObjMed.Get('TIN', '')) = 8, 'J', 'F');
  No := Format('100000000%d', [aIdx]);
  FileName := Format('%s_00_%s_%s%s_%s_%d%.2d%d_%s', [
    aJObjMed.Get('HKSTI', ''),
    aJObjMed.Get('TIN', ''),
    FJ,
    aName,
    No,
    aJObjMed.Get('_DAY', 0),
    aJObjMed.Get('_MONTH', 0),
    aJObjMed.Get('_YEAR', 0),
    aJObjMed.Get('HKSTI', '')
  ]);
  FileName := FileName.Replace('_', '') + '.XML';
  aJObjMed.SetKey('FILENAME', FileName);

  Macros := TMacros.Create();
  try
    StrXds := ResourceLoadString(aName, 'xml');
    Macros.Load(StrXds);
    StrXds := Macros.Parse(aJObjMed).DelEmptyLines();
    StrXds := UTF8ToCP1251(StrXds);
    if (Macros.Items.Count > 0) then
      Log.Print('i', Format('Не заповнено макроси %d: %s', [Macros.Items.Count, Macros.Items.CommaText]));
  finally
    Macros.Free();
  end;

  Path := ConcatPaths(['Data', FileName]);
  StrXds.ToFile(Path);
  Log.Print('i', Path);
end;

function TWizardUser.D2(aJObjMed, aJObjWiz: TJSONObject): integer;
const
  cDoc = '1360102';
var
  i: integer;
  Str, Key: string;
  JObj: TJSONObject;
  DBL: TDbList;
  Rec: TDbRec;
  SLFiles: TStringList;
begin
  SLFiles := TStringList.Create();
  SLFiles.CaseSensitive := False;

  for i := 0 to aJObjWiz.Count - 1 do
  begin
    Key := aJObjWiz.Names[i];
    if (Key.PosEx('_d2_') > 0) then
    begin
      JObj := TJSONObject(aJObjWiz.Items[i]);
      DBL := TDbList.Create(JObj);
      for Rec in DBL do
      begin
        Str := string(' ').JoinNonEmpty([
          DbL.Rec['doc_type'].AsString,
          DbL.Rec['firm'].AsString,
          DbL.Rec['doc_number'].AsString,
          string(DbL.Rec['doc_date'].AsString).Replace('.', '')
        ]);
        aJObjMed.SetKey('R01G1S_2', Str + '.pdf');

        Str := DbL.Rec['doc_name'].AsString;
        if (Str.IsEmpty()) then
          Log.Print('e', Format('Не визначено `doc_name` для `%s`', [cDoc]))
        else if (Str.FileExists()) then
        begin
          if (SLFiles.IndexOf(Str) <> -1) then
            Log.Print('e', Format('Файл вже існує `%s`', [Str]))
          else
            SLFiles.Add(Str);
          aJObjMed.SetKey('HNUM_2', SLFiles.Count);

          Str := StrFromFile(Str);
          aJObjMed.SetKey('R01G1B', EncodeStringBase64(Str));
        end else
          Log.Print('e', Format('Не знайдено файл `%s`', [Str]));

        SaveXml(cDoc, aJObjMed, JObj, i);
      end;
      DBL.Free();
    end;
  end;

  Result := SLFiles.Count;
end;

procedure TWizardUser.D1(aJObjMed, aJObjWiz: TJSONObject);
const
  cDoc = '1312603';
  cMemo = 'g01w40s10.memo1_S';
var
  JArr: TJSONArray;
  SL: TStringList;
begin
  JArr := TJSONArray(aJObjWiz.Find(cMemo));
  if (JArr <> nil) then
  begin
    SL := TStringList.Create();
    aJObjMed.SetKey('R01G1S_1', SL.AddArray(JArr).Text);
    SL.Free();
  end;

  SaveXml(cDoc, aJObjMed, aJObjWiz, 1);
  //StringListToPDF(TStringList(Memo.Lines), 'aFileName.pdf');
end;

function TWizardUser.OnVar(aData: TUserData; const aStr: string): string;
var
  SL, SLPrint: TStringList;
begin
  Result := aStr;
  if (not aStr.IsQuoted()) then
    Exit();

  SL := TStringList.Create().Split(aStr, '|');
  SLPrint := AsGridPrint(aData.JWiz, SL);
  Result := SLPrint.Text;
  aData.Ctx.SetVar(aStr, TJSONString.Create(Result));
  SL.Free();
end;

function TWizardUser.OnSetVal(aData: TUserData; const aStr: string): string;
var
  CtrlName: string;
  JObj: TJSONObject;
  Parts: TStringArray;
  DBL: TDbList;
begin
  Result := aStr;
  if (not aStr.StartsWith('ctrl|grid')) then
    Exit();

  Parts := aStr.Split('|');
  CtrlName := Parts[2];
  JObj := TJSONObject(aData.JWiz.Find(CtrlName));
  if (JObj = nil) then
    Exit();

  DBL := TDbList.Create(JObj);
  Result := IntToStr(DBL.Count);
  DBL.Free();
end;

procedure TWizardUser.OnClick_g01w50s20_save(Sender: TObject);
var
  Cnt: integer;
  JObjMed, JObjWiz: TJSONObject;
begin
  JObjMed := TJSONObject(fParent.GetDataExt().Clone());
  JObjWiz := fParent.GetDataInt();

  Cnt := D2(JObjMed, JObjWiz);

  JObjMed.SetKey('R001G10', Cnt);
  D1(JObjMed, JObjWiz);

  JObjMed.Free();
end;

procedure TWizardUser.StringListToPDF(aLines: TStringList; const aFileName: string);
begin
end;

function TWizardUser.AsGridPrint(aJObj: TJSONObject; const aParam: TStringList): TStringList;
var
  DBL: TDbList;
  JObj: TJSONObject;
begin
  JObj := TJSONObject(aJObj.Find(aParam[2]));
  if (JObj = nil) then
    Exit(TStringList.Create().AddArray(['---']));

  DBL := TDbList.Create(JObj);
  if (DBL.Count = 0) then
    Result := TStringList.Create().AddArray(['---'])
  else
    Result := DBL.Print(aParam[3].Split(','), aParam[4].Split(','));
  DBL.Free();
end;

procedure TWizardUser.ParseMemo(const aName: string);
var
  i: integer;
  Str, Find: string;
  JObj, JObjWiz, JObjRepl: TJSONObject;
  Memo: TMemo;
  Macros: TMacros;
  SL, SLScheme, SLPrint: TStringList;
begin
  Memo := TMemo(fParent.FindCtrl(aName));
  if (Memo = nil) then
  begin
    Log.Print('e', Format('Не знайдено компонент `%s`', [aName]));
    Exit();
  end;

  JObjWiz := fParent.GetDataInt();

  JObj := fParent.FindSchemeItem(aName);
  SLScheme := TStringList.Create().AddArray(JObj.Arrays['lines']);

  JObjRepl := TJSONObject.Create();

  Str := SLScheme.Text;
  Macros := TMacros.Create('{%', '%}');
  Macros.Load(Str);
  for i := 0 to Macros.Items.Count - 1 do
  begin
    Find := Macros.Items[i];
    SL := TStringList.Create().Split(Find, '|').Map(@Trim);
    if (SL[0] = 'ctrl') and (SL.Count >= 3) then
      if (SL[1] = 'grid') then
      begin
        SLPrint := AsGridPrint(JObjWiz, SL);
        JObjRepl.SetKey(Find, SLPrint.Text);
        SLPrint.Free();
      end;
    SL.Free();
  end;
  Memo.Text := Macros.Parse(JObjRepl);

  JObjRepl.Free();
  SLScheme.Free();
  Macros.Free();
end;

procedure TWizardUser.ParseMemoIf(const aName: string);
var
  Memo: TMemo;
  Ctx: TContext;
  UserData: TUserData;
  Tpl: TTpl;
  JObjMed, JObjWiz: TJSONObject;
begin
  Memo := TMemo(fParent.FindCtrl(aName));
  if (Memo = nil) then
  begin
    Log.Print('e', Format('Не знайдено компонент `%s`', [aName]));
    Exit();
  end;

  JObjWiz := fParent.GetDataInt();

  JObjMed := TJSONObject(fParent.GetDataExt().Clone());
  JObjMed.Add('band', 'pink floyd');

  Ctx := TContext.Create();
  Ctx.Load(JObjMed);

  UserData := TUserData.Create();
  UserData.JMed := JObjMed;
  UserData.JWiz := JObjWiz;
  UserData.Ctx := Ctx;

  Tpl := TTpl.Create();
  Tpl.OnSetVal := TTplFunc(@OnSetVal);
  Tpl.OnVar := TTplFunc(@OnVar);
  Tpl.UserData := UserData;
  Tpl.Parse(Memo.Text);
  Memo.Text := Tpl.Render(Ctx);
  Memo.Lines.Assign(TStringList(Memo.Lines).DelEmpty(1));

  Ctx.Free();
  JObjMed.Free();
  JObjWiz.Free();
  UserData.Free();
end;

procedure TWizardUser.OnShow_TMemo(aSender: TMemo);
begin
  ParseMemo(aSender.Hint);
end;

procedure TWizardUser.OnShow_TMemoIf(aSender: TMemo);
begin
  ParseMemoIf(aSender.Hint);
end;

procedure TWizardUser.OnClick_g00w10_save(Sender: TObject);
begin
  ParseMemoIf('memo1');
end;

end.

