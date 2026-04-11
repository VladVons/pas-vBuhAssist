// Created: 2026.04.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, fpjson, LConvEncoding, base64, fppdf,
  uFWizard, uVarUtil, uMacros, uSysVcl, uHelper, uLog, uSys, uDbList;

type
  TWizardUser = class(TPersistent)
  published
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
    procedure OnShow_w30s10(Sender: TObject);
    procedure OnShow_w40s20(Sender: TObject);
  private
    fParent: TFWizard;
    procedure PageControlChange(Sender: TObject);
    procedure D1(aJObjMed, aJObjWiz: TJSONObject);
    procedure D2(aJObjMed, aJObjWiz: TJSONObject);
    procedure SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
    function AsGrid(aJObj: TJSONObject; const aParam: TStringList): TStringList;
    procedure StringListToPDF(aLines: TStringList; const aFileName: string);
    procedure ParseMemo(const aName: string);
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
  SL: TStringList;
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
      Log.Print('i', Format('Не заповнено макроси %d: %s', [Macros.Items.Count, SL.CommaText]));
    SL.Free();
  finally
    Macros.Free();
  end;

  Path := ConcatPaths(['Data', FileName]);
  StrXds.ToFile(Path);
  Log.Print('i', Path);
end;

procedure TWizardUser.D2(aJObjMed, aJObjWiz: TJSONObject);
var
  i: integer;
  Str, Key: string;
  JObj: TJSONObject;
  DBL: TDbList;
  Rec: TDbRec;
begin
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
        Str := StrFromFile(Str);
        aJObjMed.SetKey('R01G1B', EncodeStringBase64(Str));

        SaveXml('1360102', aJObjMed, JObj, i);
      end;
      DBL.Free();
    end;
  end;
end;

procedure TWizardUser.D1(aJObjMed, aJObjWiz: TJSONObject);
const
  cMemo4 = 'w4s1.memo1_s';
var
  JArr: TJSONArray;
  SL: TStringList;
begin
  JArr := TJSONArray(aJObjWiz.Find(cMemo4));
  if (JArr <> nil) then
  begin
    SL := TStringList.Create();
    aJObjMed.SetKey('R01G1S_1', SL.AddArray(JArr).Text);
    SL.Free();
  end;

  SaveXml('1312603', aJObjMed, aJObjWiz, 1);
  //StringListToPDF(TStringList(Memo.Lines), 'aFileName.pdf');
end;

procedure TWizardUser.OnClick_FWizardPdv5_Save(Sender: TObject);
var
  JObjMed, JObjWiz: TJSONObject;
begin
  JObjMed := TJSONObject(fParent.GetDataExt().Clone());
  JObjWiz := fParent.GetDataInt();

  D1(JObjMed, JObjWiz);
  D2(JObjMed, JObjWiz);

  JObjMed.Free();
end;

procedure TWizardUser.StringListToPDF(aLines: TStringList; const aFileName: string);
begin
end;

function TWizardUser.AsGrid(aJObj: TJSONObject; const aParam: TStringList): TStringList;
var
  DBL: TDbList;
  JObj: TJSONObject;
begin
  JObj := aJObj.Objects[aParam[2]];
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
  Find: string;
  JObj, JObjWiz, JObjRepl: TJSONObject;
  Memo: TMemo;
  Macros: TMacros;
  SL, SLScheme, SLPrint: TStringList;
begin
  Memo := TMemo(fParent.FindCtrl(aName));
  if (Memo = nil) then
  begin
    Log.Print('e', Format('Компонент `%s` не знайдено', [aName]));
    Exit();
  end;

  JObjWiz := fParent.GetDataInt();

  JObj := fParent.FindSchemeItem(aName);
  SLScheme := TStringList.Create().AddArray(JObj.Arrays['lines']);

  JObjRepl := TJSONObject.Create();

  Macros := TMacros.Create('{%', '%}');
  Macros.Load(SLScheme.Text);
  for i := 0 to Macros.Items.Count - 1 do
  begin
    Find := Macros.Items[i];
    SL := TStringList.Create().Split(Find, '|');
    if (SL[0] = 'ctrl') and (SL.Count >= 3) then
      if (SL[1] = 'grid') then
      begin
        SLPrint := AsGrid(JObjWiz, SL);
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

procedure TWizardUser.OnShow_w30s10(Sender: TObject);
begin
  ParseMemo('memo1');
end;

procedure TWizardUser.OnShow_w40s20(Sender: TObject);
begin
  ParseMemo('memo2');
end;

end.

