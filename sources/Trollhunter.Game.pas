unit Trollhunter.Game;

interface

uses
  Trollhunter.Race,
  Trollhunter.Scores,
  Dragonhunter.Resources;

type
  TPCInfo = record
    Level: Byte;
    Rating: Cardinal;
    Dungeon: Byte;
  end;

  TGame = class(TObject)
  private
    FScores: TScores;
    procedure SetScores(const Value: TScores);
  public
    procedure New;
    procedure Save;
    procedure Load(I: Integer = -1);
    function GetPCInfo(AFileName: string): TPCInfo;
    constructor Create;
    destructor Destroy; override;
    property Scores: TScores read FScores write SetScores;
  end;

var
  Game: TGame;

implementation

uses
  System.SysUtils,
  Dragonhunter.MainForm,
  Dragonhunter.Map,
  Trollhunter.Utils,
  Trollhunter.Creatures,
  Trollhunter.Log,
  Trollhunter.Zip,
  Trollhunter.Graph,
  Trollhunter.Error,
  Trollhunter.TempSys,
  Dragonhunter.Item,
  Trollhunter.Settings,
  Trollhunter.Skill;

{ TGame }

constructor TGame.Create;
begin
  FScores := TScores.Create(26);
  if FileExists(Path + 'save\Scores.rec') then
    FScores.Load;
end;

destructor TGame.Destroy;
begin
  FreeAndNil(FScores);
  inherited;
end;

procedure TGame.New;
begin
  try
    Creatures.Character.Create;
    Game.Load;
    Log.Clear;
  except
    on E: Exception do
      Error.Add('Game.New', E.Message);
  end;
end;

procedure TGame.Load(I: Integer = -1);
var
  LFileName: string;
  LZip: TZip;
begin
  IsGame := True;
  with Creatures do
    try
      LFileName := Character.Name;
      if not FileExists(Path + 'save\' + LFileName + '.sav') then
      begin
        Character.World.Gen;
        Map.Gen(Character.Dungeon);
        Character.Redraw;
        GameResources.Free;
        GameResources := TResources.Create;
        Exit;
      end;
      // Open save
      LZip := TZip.Create(MainForm);
      try
        LZip.Password := PWD;
        LZip.FileName := Path + 'save\' + LFileName + '.sav';
        LZip.OpenArchive;
        // PC
        Character.Text := LZip.ExtractToText('pc.txt');
        // Scrolls Properties
        Character.Scrolls.Text := LZip.ExtractToText('scrolls.txt');
        // Potions Properties
        Character.Potions.Text := LZip.ExtractToText('potions.txt');
        // Inventory
        Character.Inv.Text := LZip.ExtractToText('inv.txt');
        if (I > -1) then
          Character.Dungeon := I;
        // Skills
        Skills.Text := LZip.ExtractToText('skill.txt');
        // Map
        if not LZip.FileExists(IntToStr(Character.Dungeon) + '.m') then
        begin
          Map.Gen(Character.Dungeon);
        end
        else
        begin
          Map.FM.Text := LZip.ExtractToText(IntToStr(Character.Dungeon) + '.m');
          Map.FV.Text := LZip.ExtractToText(IntToStr(Character.Dungeon) + '.v');
          Map.FS.Text := LZip.ExtractToText(IntToStr(Character.Dungeon) + '.s');
          Map.FD.Text := LZip.ExtractToText(IntToStr(Character.Dungeon) + '.d');
          Map.FL.Text := LZip.ExtractToText(IntToStr(Character.Dungeon) + '.l');
          Map.Load(Character.Dungeon);
        end;
        // Counters
        Character.TempSys.Text := LZip.ExtractToText('effects.txt');
        // Statistics
        Character.Statistics.Text := LZip.ExtractToText('statistics.txt');
        // Log
        Log.Text := LZip.ExtractToText('log.txt');
        // World
        Character.World.Text := LZip.ExtractToText('world.p');
        //
        LZip.CloseArchive;
      finally
        LZip.Free;
      end;
      Character.Redraw;
      GameResources.Free;
      GameResources := TResources.Create;
    except
      on E: Exception do
        Error.Add('Game.Load', E.Message);
    end;
end;

function TGame.GetPCInfo(AFileName: string): TPCInfo;
var
  LZip: TZip;
begin
  LZip := TZip.Create(MainForm);
  try
    LZip.Password := PWD;
    LZip.FileName := AFileName;
    LZip.OpenArchive;
    // PC
    Creatures.Character.Text := LZip.ExtractToText('pc.txt');
    Result.Level := Creatures.Character.Prop.Level;
    Result.Rating := Creatures.Character.Rating;
    Result.Dungeon := Creatures.Character.Dungeon;
    LZip.CloseArchive;
  finally
    LZip.Free;
  end;
end;

procedure TGame.Save;
var
  LFileName: string;
  LSettings: TSettings;
  LZip: TZip;
begin
  if not IsGame then
    Exit;
  with Creatures do
    try
      if not Character.Life.IsMin and (Character.Name <> '') then
      begin
        LFileName := Character.Name;
        LZip := TZip.Create(MainForm);
        try
          LZip.Password := PWD;
          LZip.FileName := Path + 'save\' + LFileName + '.sav';
          LZip.OpenArchive;
          // PC
          LZip.AddFromString('pc.txt', Character.Text);
          // Scrolls Properties
          LZip.AddFromString('scrolls.txt', Character.Scrolls.Text);
          // Potions Properties
          LZip.AddFromString('potions.txt', Character.Potions.Text);
          // PC.Inv
          LZip.AddFromString('inv.txt', Character.Inv.Text);
          // PC.Skill
          LZip.AddFromString('skill.txt', Skills.Text);
          // Map
          Map.Save(Character.Dungeon);
          LZip.AddFromString(IntToStr(Character.Dungeon) + '.m', Map.FM.Text);
          LZip.AddFromString(IntToStr(Character.Dungeon) + '.v', Map.FV.Text);
          LZip.AddFromString(IntToStr(Character.Dungeon) + '.s', Map.FS.Text);
          LZip.AddFromString(IntToStr(Character.Dungeon) + '.d', Map.FD.Text);
          LZip.AddFromString(IntToStr(Character.Dungeon) + '.l', Map.FL.Text);
          // Counters
          LZip.AddFromString('effects.txt', Character.TempSys.Text);
          // Statistics
          LZip.AddFromString('statistics.txt', Character.Statistics.Text);
          // Log
          LZip.AddFromString('log.txt', Log.Text);
          // World
          LZip.AddFromString('world.p', Character.World.Text);
          //
          LZip.CloseArchive;
        finally
          LZip.Free;
        end;
        LSettings := TSettings.Create;
        try
          LSettings.Write('Settings', 'LastName', Character.Name);
        finally
          LSettings.Free;
        end;
      end;
    except
      on E: Exception do
        Error.Add('Game.Save', E.Message);
    end;
end;

procedure TGame.SetScores(const Value: TScores);
begin
  FScores := Value;
end;

initialization

Game := TGame.Create;

finalization

Game.Free;

end.
