unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, LConvEncoding, base64,
  uFWizard, uVarUtil, uSysVcl, uHelper, uLog, uSys;

type
  TWizardUser = class(TPersistent)
  published
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
  private
    fParent: TFWizard;
    procedure SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
  public
    constructor Create(aParent: TFWizard);
  end;

implementation

constructor TWizardUser.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
end;

procedure TWizardUser.SaveXml(const aName: string; aJObjMed, aJObjWiz: TJSONObject; aIdx: integer);
var
  Str, StrXds, Path, FileName, No, FJ: string;
  Macros: TMacros;
  SL: TStringList;
  JArr1, JArr2: TJSONArray;
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
  aJObjMed.SetKey(Format('FILENAME_%d', [aIdx]), FileName);

  JArr1 := TJSONArray(aJObjWiz.Find('w1s1.grid1_s'));
  if (JArr1 <> nil) and (JArr1.Count > 0) then
  begin
    JArr2 := JArr1.Items[0] as TJSONArray;
    Str := JArr2.Strings[2];
    Str := StrFromFile(Str);
    aJObjMed.SetKey('R01G1B', EncodeStringBase64(Str));
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

  SaveXml('1360102', JObjDb, JObjWiz, 1);
  SaveXml('1312603', JObjDb, JObjWiz, 2);

  JObjDb.Free();
end;


end.

