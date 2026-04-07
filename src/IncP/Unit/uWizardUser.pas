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
var
  Str, StrXds, Path, FileName, No, FJ: string;
  Macros: TMacros;
  SL: TStringList;
  JObj: TJSONObject;
  DbL: TDbList;
begin
  FJ := IIF(Length(aJObjMed.Get('TIN', '')) = 8, 'J', 'F');
  No := '1000000009';
  FileName := Format('%s_00_%s_%s_%d%.2d%d_%s%s_%s', [
    aJObjMed.Get('HKSTI', ''),
    aJObjMed.Get('TIN', ''),
    No,
    aJObjMed.Get('DAY', 0),
    aJObjMed.Get('MONTH', 0),
    aJObjMed.Get('YEAR', 0),
    FJ,
    aName,
    aJObjMed.Get('HKSTI', '')
  ]);
  FileName := FileName.Replace('_', '') + '.XML';
  aJObjMed.SetKey('FILENAME', FileName);

  JObj := TJSONObject(aJObjWiz.Find('w1s1.grid1_s'));
  if (JObj  <> nil)then
  begin
    DbL := TDbList.Create(JObj);
    Str := DbL.Rec['doc_name'].AsString;
    Str := StrFromFile(Str);
    aJObjMed.SetKey('R01G1B', EncodeStringBase64(Str));
    DbL.Free();
  end;

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

