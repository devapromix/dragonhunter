unit Trollhunter.Skill;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TSkill = class(TObject)
  const
    MaxValue = 50;
    MaxExp = 100;
  private
    FLevel: Integer;
    FName: Integer;
    FIdent: string;
    FExp: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Up(const ASkillIdent: string);
    property Ident: string read FIdent write FIdent;
    property Name: Integer read FName write FName;
    property Level: Integer read FLevel write FLevel;
    property Exp: Integer read FExp write FExp;
  end;

type
  TSkills = class(TObject)
  private
    FF: TStringList;
    FSkillList: TObjectList<TSkill>;
    procedure Save;
    procedure Load;
    function GetText: string;
    procedure SetText(const Value: string);
  public
    procedure Clear;
    property Text: string read GetText write SetText;
    procedure Up(const ASkillIdent: string); overload;
    procedure Up(const ASkillIndex: Integer); overload;
    constructor Create;
    destructor Destroy; override;
    property SkillList: TObjectList<TSkill> read FSkillList write FSkillList;
    procedure LoadFromResources;
    procedure AddLevel(const ASkillIdent: string; const ALevel: Integer);
    function GetSkill(const ASkillIdent: string): TSkill;
  end;

var
  Skills: TSkills;

implementation

uses
  System.SysUtils,
  System.JSON,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Trollhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Lang,
  Trollhunter.Error,
  Dragonhunter.MainForm,
  Trollhunter.Zip;

{ TSkill }

constructor TSkill.Create;
begin

end;

destructor TSkill.Destroy;
begin

  inherited;
end;

procedure TSkill.Up(const ASkillIdent: string);
begin

end;

{ TSkills }

constructor TSkills.Create;
begin
  FF := TStringList.Create;
  FSkillList := TObjectList<TSkill>.Create;
  Self.Clear;
end;

destructor TSkills.Destroy;
begin
  FF.Free;
  FreeAndNil(FSkillList);
  inherited;
end;

procedure TSkills.Clear;
var
  I: Integer;
begin
  for I := 0 to FSkillList.Count - 1 do
  begin
    FSkillList[I].Level := 0;
    FSkillList[I].Exp := 0;
  end;
end;

procedure TSkills.AddLevel(const ASkillIdent: string; const ALevel: Integer);
var
  I: Integer;
begin
  for I := 0 to FSkillList.Count - 1 do
    if FSkillList[I].Ident = ASkillIdent then
      FSkillList[I].Level := FSkillList[I].Level + ALevel;
end;

function TSkills.GetSkill(const ASkillIdent: string): TSkill;
var
  I: Integer;
begin
  for I := 0 to FSkillList.Count - 1 do
    if FSkillList[I].Ident = ASkillIdent then
      Result := FSkillList[I];
end;

function TSkills.GetText: string;
begin
  Self.Save;
  Result := FF.Text;
end;

procedure TSkills.Load;
var
  P, I: Integer;
  E: TExplodeResult;
begin
  P := 0;
  E := nil;
  for I := 0 to FF.Count - 1 do
  begin
    E := Explode('/', FF[I]);
    if (Trim(E[0]) <> '') then
    begin
      FSkillList[P].Level := StrToInt(E[0]);
      FSkillList[P].Exp := StrToInt(E[1]);
    end;
    Inc(P);
  end;
end;

procedure TSkills.Save;
var
  I: Byte;
begin
  FF.Clear;
  for I := 0 to Skills.FSkillList.Count - 1 do
    FF.Append(Format('%d/%d', [FSkillList[I].Level, FSkillList[I].Exp]));
end;

procedure TSkills.SetText(const Value: string);
begin
  FF.Text := Value;
  Self.Load;
end;

procedure TSkills.Up(const ASkillIndex: Integer);
begin
  if (FSkillList[ASkillIndex].Level < TSkill.MaxValue) then
  begin
    FSkillList[ASkillIndex].Exp := FSkillList[ASkillIndex].Exp + 5;
    if (FSkillList[ASkillIndex].Exp >= TSkill.MaxExp) then
    begin
      FSkillList[ASkillIndex].Exp := FSkillList[ASkillIndex].Exp -
        TSkill.MaxExp;
      FSkillList[ASkillIndex].Level := FSkillList[ASkillIndex].Level + 1;
      if (FSkillList[ASkillIndex].Level > TSkill.MaxValue) then
      begin
        FSkillList[ASkillIndex].Level := TSkill.MaxValue;
      end;
      Log.Add(Format('%s +1 (%d).', [Language.GetLang(ASkillIndex + 201),
        FSkillList[ASkillIndex].Level]));
    end;
  end;
end;

procedure TSkills.Up(const ASkillIdent: string);
var
  I: Integer;
begin
  for I := 0 to FSkillList.Count - 1 do
    if FSkillList[I].Ident = ASkillIdent then
      Self.Up(I);
end;

procedure TSkills.LoadFromResources;
var
  LStringList: TStringList;
  LZip: TZip;
  LSkill: TSkill;
  LJSONObject: TJSONObject;
  LSkills: TJSONArray;
  I: Integer;
begin
  try
    if not FileExists(Path + 'resources.res') then
      Exit;
    LStringList := TStringList.Create;
    try
      LZip := TZip.Create(MainForm);
      try
        LStringList.Text := LZip.ExtractTextFromFile(Path + 'resources.res',
          'skills.json');
        LSkills := TJSONObject.ParseJSONValue(LStringList.Text) as TJSONArray;
        try
          for I := 0 to LSkills.Count - 1 do
          begin
            LJSONObject := LSkills.Items[I] as TJSONObject;
            LSkill := TSkill.Create;
            LSkill.Ident := LJSONObject.GetValue('ident').Value;
            LSkill.Name := LJSONObject.GetValue('name').Value.ToInteger;
            Skills.SkillList.Add(LSkill);
          end;
        finally
          FreeAndNil(LSkills);
        end;
      finally
        FreeAndNil(LZip);
      end;
    finally
      FreeAndNil(LStringList);
    end;
  except
    on E: Exception do
      Error.Add('Skills.LoadFromResources', E.Message);
  end;
end;

procedure Serialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  try
    LJSON := TNeon.ObjectToJSON(Skills);
    try
      LStringList.Text := TNeon.Print(LJSON, True);
      LStringList.SaveToFile(Path + 'skills.json', TEncoding.UTF8);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
  end;
end;

initialization

Skills := TSkills.Create;
Skills.LoadFromResources;
// Serialize;

finalization

FreeAndNil(Skills);

end.
