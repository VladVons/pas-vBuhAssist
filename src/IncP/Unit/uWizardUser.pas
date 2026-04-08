unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, LConvEncoding, base64,
  uFWizard, uVarUtil, uSysVcl, uHelper, uLog, uSys, uDbList;

type
  TWizardUser = class(TPersistent)
  published
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
  private
    fParent: TFWizard;
    procedure SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject);
  public
    constructor Create(aParent: TFWizard);
  end;

implementation

constructor TWizardUser.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
end;

procedure TWizardUser.SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject);
const
  cGrid1 = 'w1s1.grid1_s';
  cMemo4 = 'w4s1.memo1_s';
var
  Str, StrXds, Path, FileName, No, FJ: string;
  Macros: TMacros;
  SL: TStringList;
  JObj: TJSONObject;
  JArr: TJSONArray;
  DbL: TDbList;
begin
  JObj := TJSONObject(aJObjWiz.Find(cGrid1));
  if (JObj = nil) then
  begin
    Log.Print('i', 'Не визначено ' + cGrid1);
    Exit();
  end;

  DbL := TDbList.Create(JObj);
  if (DbL.GetSize() = 0) then
  begin
    DbL.Free();
    Log.Print('e', 'Не заповнена таблиця ' + cGrid1);
    Exit();
  end;

  if (aName = '1360102') then
  begin
    Str := string('_').JoinNonEmpty([
      DbL.Rec['doc_type'].AsString,
      DbL.Rec['firm'].AsString,
      DbL.Rec['doc_number'].AsString,
      string(DbL.Rec['doc_date'].AsString).Replace('.', '')
    ]);
    aJObjMed.SetKey('R01G1S_2', Str + '.xml');

    Str := DbL.Rec['doc_name'].AsString;
    Str := StrFromFile(Str);
    aJObjMed.SetKey('R01G1B', EncodeStringBase64(Str));
  end else if (aName = '1312603') then
  begin
    JArr := TJSONArray(aJObjWiz.Find(cMemo4));
    if (JArr <> nil) then
    begin
      SL := TStringList.Create();
      aJObjMed.SetKey('R01G1S_1', SL.AddArray(JArr).Text);
      SL.Free();
    end;
  end;
  DbL.Free();

  FJ := IIF(Length(aJObjMed.Get('TIN', '')) = 8, 'J', 'F');
  No := '1000000009';
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
    StrXds := Macros.Exec(StrXds, aJObjMed).DelEmptyLines();
    StrXds := UTF8ToCP1251(StrXds);

    SL := Macros.GetList(StrXds);
    if (SL.Count > 0) then
      Log.Print('i', Format('Не заповнено макроси %d: %s', [SL.Count, SL.CommaText]));
    SL.Free();
  finally
    Macros.Free();
  end;

  Path := ConcatPaths(['Data', FileName]);
  StrXds.ToFile(Path);
  Log.Print('i', Path);
end;

procedure TWizardUser.OnClick_FWizardPdv5_Save(Sender: TObject);
var
  JObjDb, JObjWiz: TJSONObject;
begin
  JObjDb := TJSONObject(fParent.GetDataExt().Clone());
  JObjWiz := fParent.GetDataInt();

  SaveXml('1360102', JObjDb, JObjWiz);
  SaveXml('1312603', JObjDb, JObjWiz);

  JObjDb.Free();
end;


end.

