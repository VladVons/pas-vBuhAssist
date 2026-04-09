unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, fpjson, LConvEncoding, base64,
  uFWizard, uVarUtil, uMacros, uSysVcl, uHelper, uLog, uSys, uDbList;

type
  TWizardUser = class(TPersistent)
  published
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
    procedure OnShow_FWizardPdv40_1(Sender: TObject);
    function AsGrid(aJObj: TJSONObject; const aFields: TStringArray): TStringList;
  private
    fParent: TFWizard;
    procedure PageControlChange(Sender: TObject);
    procedure D1(aJObjMed, aJObjWiz: TJSONObject);
    procedure D2(aJObjMed, aJObjWiz: TJSONObject);
    procedure SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
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
      Log.Print('i', Format('Не заповнено макроси %d: %s', [SL.Count, SL.CommaText]));
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
end;

function TWizardUser.AsGrid(aJObj: TJSONObject; const aFields: TStringArray): TStringList;
var
  DBL: TDbList;
begin
  DBL := TDbList.Create(aJObj);
  Result := DBL.Print(aFields);
  DBL.Free();
end;

procedure TWizardUser.OnShow_FWizardPdv40_1(Sender: TObject);
const
  cMemoName = 'memo1_s';
var
  i: integer;
  Find, Repl: string;
  JObj, JObjWiz: TJSONObject;
  JArr: TJSONArray;
  Memo: TMemo;
  Macros: TMacros;
  SL, SLPrint: TStringList;
begin
  Memo := TMemo(fParent.FindCtrl(cMemoName));
  if (Memo = nil) then
  begin
    Log.Print('e', Format('Компонент `%s` не знайдено', ['memo1_s']));
    Exit();
  end;

  JObjWiz := fParent.GetDataInt();

  JObj := fParent.FindSchemeItem(cMemoName);
  JArr := JObj.Arrays['lines'];
  Macros := TMacros.Create('{%', '%}');
  Macros.Load(Memo.Text);
  for i := 0 to Macros.Items.Count - 1 do
  begin
    Find := Macros.Items[i];
    SL := TStringList.Create().Split(Find, '|');
    if (SL[0] = 'ctrl') and (SL.Count >= 3) then
      if (SL[1] = 'grid') then
      begin
        SLPrint := AsGrid(JObjWiz.Objects[SL[2]], SL[3].Split(','));
        Memo.Text := Macros.Parse([Find], [SLPrint.Text]);
        SLPrint.Free();
      end;
    SL.Free();
  end;
  Macros.Free();
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


end.

