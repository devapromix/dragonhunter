unit Dragonhunter.Map.Pattern;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TMapPat = class(TObject)
  private
    FId: string;
    FLevel: Integer;
    FItems: string;
    FCreatures: string;
    FUnderground: Boolean;
    FVillage: Boolean;
    FGenId: Integer;
    FDecorType: string;
    FDecTypSize: Integer;
    FDecTypCount: Integer;
    FIsAutoEnt: Boolean;
    FPrevMap: string;
    FNextMap: string;
    FAltNextMap: string;
    FIsTraps: Boolean;
    FIsVillageEnt: Boolean;
    FFloorTile: string;
    FFloorRes: string;
    FWallRes: string;
    FTreeRes: string;
    FBushRes: string;
  public
    constructor Create;
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Level: Integer read FLevel write FLevel;
    property Items: string read FItems write FItems;
    property Creatures: string read FCreatures write FCreatures;
    property Underground: Boolean read FUnderground write FUnderground;
    property Village: Boolean read FVillage write FVillage;
    property GenId: Integer read FGenId write FGenId;
    property DecorType: string read FDecorType write FDecorType;
    property DecTypSize: Integer read FDecTypSize write FDecTypSize;
    property DecTypCount: Integer read FDecTypCount write FDecTypCount;
    property IsAutoEnt: Boolean read FIsAutoEnt write FIsAutoEnt;
    property PrevMap: string read FPrevMap write FPrevMap;
    property NextMap: string read FNextMap write FNextMap;
    property AltNextMap: string read FAltNextMap write FAltNextMap;
    property IsAltMapEnt: Boolean read FIsAutoEnt write FIsAutoEnt;
    property IsVillageEnt: Boolean read FIsVillageEnt write FIsVillageEnt;
    property IsTraps: Boolean read FIsTraps write FIsTraps;
    property FloorTile: string read FFloorTile write FFloorTile;
    property FloorRes: string read FFloorRes write FFloorRes;
    property WallRes: string read FWallRes write FWallRes;
    property TreeRes: string read FTreeRes write FTreeRes;
    property BushRes: string read FBushRes write FBushRes;
  end;

type
  TMapPats = class(TObject)
  private
    FPatterns: TObjectList<TMapPat>;
    procedure Serialize;
    procedure Deserialize;
  public
    constructor Create;
    destructor Destroy; override;
    property Patterns: TObjectList<TMapPat> read FPatterns write FPatterns;
    function GetPattern(const AIndex: Integer = -1): TMapPat;
  end;

var
  MapPatterns: TMapPats;

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
  Trollhunter.Creatures;

{ TSkill }

constructor TMapPat.Create;
begin

end;

destructor TMapPat.Destroy;
begin

  inherited;
end;

{ TMapPats }

constructor TMapPats.Create;
begin
  FPatterns := TObjectList<TMapPat>.Create;
end;

destructor TMapPats.Destroy;
begin
  FreeAndNil(FPatterns);
  inherited;
end;

function TMapPats.GetPattern(const AIndex: Integer = -1): TMapPat;
begin
  if AIndex > -1 then
    Result := Patterns[AIndex]
  else
    Result := Patterns[Trollhunter.Creatures.Creatures.Character.Dungeon]
end;

procedure TMapPats.Serialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  try
    LJSON := TNeon.ObjectToJSON(MapPatterns);
    try
      LStringList.Text := TNeon.Print(LJSON, True);
      LStringList.SaveToFile(Path + 'maps.json', TEncoding.UTF8);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
  end;
end;

procedure TMapPats.Deserialize;
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
      'maps.json');
    LJSON := TJSONObject.ParseJSONValue(LStringList.Text);
    try
      LConfig := TNeonConfiguration.Default;
      TNeon.JSONToObject(MapPatterns, LJSON, LConfig);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
    LZip.Free;
  end;
end;

initialization

MapPatterns := TMapPats.Create;
MapPatterns.Deserialize;
// MapPatterns.Serialize;

finalization

FreeAndNil(MapPatterns);

end.
