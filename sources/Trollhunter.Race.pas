unit Trollhunter.Race;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TRace = class(TObject)
  private
    FIdent: string;
    FNameID: Integer;
    FEndDescr: Integer;
    FBeginDescr: Integer;
    FStrength: Integer;
    FIntelligence: Integer;
    FPerception: Integer;
    FSpeed: Integer;
    FDexterity: Integer;
    FEquipment: TStringList;
    FSkills: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    property Ident: string read FIdent write FIdent;
    property Name: Integer read FNameID write FNameID;
    property BeginDescr: Integer read FBeginDescr write FBeginDescr;
    property EndDescr: Integer read FEndDescr write FEndDescr;
    property Strength: Integer read FStrength write FStrength;
    property Dexterity: Integer read FDexterity write FDexterity;
    property Intelligence: Integer read FIntelligence write FIntelligence;
    property Perception: Integer read FPerception write FPerception;
    property Speed: Integer read FSpeed write FSpeed;
    property Equipment: TStringList read FEquipment write FEquipment;
    property Skills: TStringList read FSkills write FSkills;
  end;

  TRaces = class(TObject)
  private
    FRaceList: TObjectList<TRace>;
  public
    constructor Create;
    destructor Destroy; override;
    property RaceList: TObjectList<TRace> read FRaceList write FRaceList;
    procedure LoadFromResources;
  end;

var
  Races: TRaces;

implementation

uses
  Vcl.Dialogs,
  System.SysUtils,
  System.JSON,
  Dragonhunter.MainForm,
  Trollhunter.Error,
  Trollhunter.Zip,
  Trollhunter.Utils;

{ TRace }

constructor TRace.Create;
begin
  FEquipment := TStringList.Create;
  FSkills := TStringList.Create;
end;

destructor TRace.Destroy;
begin
  FreeAndNil(FSkills);
  FreeAndNil(FEquipment);
  inherited;
end;

{ TRaces }

constructor TRaces.Create;
begin
  FRaceList := TObjectList<TRace>.Create;
end;

destructor TRaces.Destroy;
begin
  FreeAndNil(FRaceList);
  inherited;
end;

procedure TRaces.LoadFromResources;
var
  I, J, K: Integer;
  LZip: TZip;
  LStringList: TStringList;
  LJSONObject: TJSONObject;
  LRaces, LEquipment, LSkills: TJSONArray;
  LRace: TRace;
begin
  try
    if not FileExists(Path + 'resources.res') then
      Exit;
    LStringList := TStringList.Create;
    try
      LZip := TZip.Create(MainForm);
      try
        LStringList.Text := LZip.ExtractTextFromFile(Path + 'resources.res',
          'races.json');
        LRaces := TJSONObject.ParseJSONValue(LStringList.Text) as TJSONArray;
        try
          for I := 0 to LRaces.Count - 1 do
          begin
            LJSONObject := LRaces.Items[I] as TJSONObject;
            LRace := TRace.Create;
            LRace.Ident := LJSONObject.GetValue('ident').Value;
            LRace.Name := LJSONObject.GetValue('name').Value.ToInteger;
            LRace.BeginDescr := LJSONObject.GetValue('begin_descr')
              .Value.ToInteger;
            LRace.EndDescr := LJSONObject.GetValue('end_descr').Value.ToInteger;
            LRace.Strength := LJSONObject.GetValue('strength').Value.ToInteger;
            LRace.Dexterity := LJSONObject.GetValue('dexterity')
              .Value.ToInteger;
            LRace.Intelligence := LJSONObject.GetValue('intelligence')
              .Value.ToInteger;
            LRace.Perception := LJSONObject.GetValue('perception')
              .Value.ToInteger;
            LRace.Speed := LJSONObject.GetValue('speed').Value.ToInteger;
            // Equipment
            LEquipment := LJSONObject.GetValue<TJSONArray>('equipment');
            for J := 0 to LEquipment.Count - 1 do
            begin
              LRace.Equipment.Append(LEquipment.Items[J].Value);
            end;
            // Skills
            LSkills := LJSONObject.GetValue<TJSONArray>('skills');
            for K := 0 to LSkills.Count - 1 do
            begin
              LRace.Skills.Append(LSkills.Items[K].Value);
            end;

            Races.RaceList.Add(LRace);
          end;
        finally
          FreeAndNil(LRaces);
        end;
      finally
        FreeAndNil(LZip);
      end;

    finally
      FreeAndNil(LStringList);
    end;
  except
    on E: Exception do
      Error.Add('Race.LoadFromResources', E.Message);
  end;
end;

initialization

Races := TRaces.Create;
Races.LoadFromResources;

finalization

FreeAndNil(Races);

end.
