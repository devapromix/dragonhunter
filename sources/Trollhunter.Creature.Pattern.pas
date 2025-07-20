unit Trollhunter.Creature.Pattern;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TCreaturePattern = class(TObject)
  private
    FId: string;
    FAIType: string;
    FDecor: string;
    FProjectile: string;
    FLevel: Integer;
    FMaxDamage: Integer;
    FProtect: Integer;
    FRadius: Integer;
    FDistance: Integer;
    FMinDamage: Integer;
    FStrength: Integer;
    FIntelligence: Integer;
    FPerception: Integer;
    FSpeed: Integer;
    FDexterity: Integer;
    FPoison: string;
    FBlind: string;
  public
    constructor Create;
    destructor Destroy; override;
    property Id: string read FId write FId;
    property AIType: string read FAIType write FAIType;
    property Decor: string read FDecor write FDecor;
    property Projectile: string read FProjectile write FProjectile;
    property Level: Integer read FLevel write FLevel;
    property MinDamage: Integer read FMinDamage write FMinDamage;
    property MaxDamage: Integer read FMaxDamage write FMaxDamage;
    property Protect: Integer read FProtect write FProtect;
    property Radius: Integer read FRadius write FRadius;
    property Distance: Integer read FDistance write FDistance;
    property Strength: Integer read FStrength write FStrength;
    property Dexterity: Integer read FDexterity write FDexterity;
    property Intelligence: Integer read FIntelligence write FIntelligence;
    property Perception: Integer read FPerception write FPerception;
    property Speed: Integer read FSpeed write FSpeed;
    property Poison: string read FPoison write FPoison;
    property Blind: string read FBlind write FBlind;
  end;

type
  TCreaturePatterns = class(TObject)
  private
    FPatterns: TObjectList<TCreaturePattern>;
    procedure Deserialize;
    procedure Serialize;
  public
    constructor Create;
    destructor Destroy; override;
    property Patterns: TObjectList<TCreaturePattern> read FPatterns
      write FPatterns;
    function GetPattern(const AIndex: Integer = -1): TCreaturePattern;
  end;

var
  CreaturePatterns: TCreaturePatterns;

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
  Trollhunter.Zip,
  Dragonhunter.Map,
  Trollhunter.Creatures,
  Trollhunter.Creature;

{ TCreaturePattern }

constructor TCreaturePattern.Create;
begin

end;

destructor TCreaturePattern.Destroy;
begin

  inherited;
end;

{ TCreaturePatterns }

constructor TCreaturePatterns.Create;
begin
  FPatterns := TObjectList<TCreaturePattern>.Create;
end;

destructor TCreaturePatterns.Destroy;
begin
  FreeAndNil(FPatterns);
  inherited;
end;

function TCreaturePatterns.GetPattern(const AIndex: Integer = -1)
  : TCreaturePattern;
begin
  if AIndex > -1 then
    Result := Patterns[AIndex]
  else
    Result := Patterns[Trollhunter.Creatures.Creatures.Character.Dungeon]
end;

procedure TCreaturePatterns.Serialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  try
    LJSON := TNeon.ObjectToJSON(CreaturePatterns);
    try
      LStringList.Text := TNeon.Print(LJSON, True);
      LStringList.SaveToFile(Path + 'creatures.json', TEncoding.UTF8);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
  end;
end;

procedure TCreaturePatterns.Deserialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
  LConfig: INeonConfiguration;
  LZip: TZip;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  LZip := TZip.Create(MainForm);
  try
    LStringList.Text := LZip.ExtractTextFromFile(Path + 'resources.res',
      'creatures.json');
    LJSON := TJSONObject.ParseJSONValue(LStringList.Text);
    try
      LConfig := TNeonConfiguration.Default;
      TNeon.JSONToObject(CreaturePatterns, LJSON, LConfig);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
    LZip.Free;
  end;
end;

initialization

CreaturePatterns := TCreaturePatterns.Create;
CreaturePatterns.Deserialize;
// CreaturePatterns.Serialize;

finalization

FreeAndNil(CreaturePatterns);

end.
