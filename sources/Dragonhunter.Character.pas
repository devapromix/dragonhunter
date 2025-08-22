unit Dragonhunter.Character;

interface

uses
  Classes,
  Dragonhunter.Effect,
  Trollhunter.Creature,
  Trollhunter.Inv,
  Trollhunter.Skill,
  Trollhunter.TempSys,
  Dragonhunter.Item.Random,
  Trollhunter.GlobalMap,
  Trollhunter.Statistics;

type
  TCharacter = class(TCreature)
  private
    FInv: TAdvInv;
    FTempSys: TTempSys;
    FRace: Integer;
    FDungeon: Integer;
    FLastTurns: Integer;
    FTurns: Integer;
    FRating: Integer;
    FKills: Integer;
    FF: TStringList;
    FDay: Integer;
    FMonth: Integer;
    FWeek: Integer;
    FYear: Integer;
    FEffects: TEffects;
    FScrolls: TRandItems;
    FPotions: TRandItems;
    FWorld: TGlobalMap;
    FStatistics: TStatistics;
    FAtrPoint: Integer;
    function GetText: string;
    procedure SetInv(const Value: TAdvInv);
    procedure SetTempSys(const Value: TTempSys);
    procedure SetRace(const Value: Integer);
    procedure SetDungeon(const Value: Integer);
    procedure SetLastTurns(const Value: Integer);
    procedure SetKills(const Value: Integer);
    procedure SetRating(const Value: Integer);
    procedure SetTurns(const Value: Integer);
    procedure SetDay(const Value: Integer);
    procedure SetMonth(const Value: Integer);
    procedure SetWeek(const Value: Integer);
    procedure SetYear(const Value: Integer);
    procedure SetText(const Value: string);
    procedure SetEffects(const Value: TEffects);
    procedure SetScrolls(const Value: TRandItems);
    procedure SetPotions(const Value: TRandItems);
    procedure SetAtrPoint(const Value: Integer);
  public
    procedure Calc;
    procedure Save;
    procedure Load;
    procedure Defeat;
    procedure Render;
    procedure Redraw;
    procedure DoTime();
    procedure AddStrength;
    procedure AddDexterity;
    procedure AddIntelligence;
    procedure AddPerception;
    procedure AddSpeed;
    procedure DetectTraps;
    procedure DoDetectTraps;
    procedure Melee(I: Integer);
    procedure Ranged(I: Integer);
    function MaxExp(ALevel: Integer = 0): Integer;
    function AddExp(Value: Word): Boolean;
    procedure Move(AX, AY: Integer);
    procedure Wait;
    procedure TrainSkill;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    property Statistics: TStatistics read FStatistics write FStatistics;
    property Inv: TAdvInv read FInv write SetInv;
    property Scrolls: TRandItems read FScrolls write SetScrolls;
    property Potions: TRandItems read FPotions write SetPotions;
    property World: TGlobalMap read FWorld write FWorld;
    property TempSys: TTempSys read FTempSys write SetTempSys;
    property AtrPoint: Integer read FAtrPoint write SetAtrPoint;
    property Race: Integer read FRace write SetRace;
    property Dungeon: Integer read FDungeon write SetDungeon;
    property LastTurns: Integer read FLastTurns write SetLastTurns;
    property Rating: Integer read FRating write SetRating;
    property Turns: Integer read FTurns write SetTurns;
    property Kills: Integer read FKills write SetKills;
    property Day: Integer read FDay write SetDay;
    property Week: Integer read FWeek write SetWeek;
    property Month: Integer read FMonth write SetMonth;
    property Year: Integer read FYear write SetYear;
    property Text: string read GetText write SetText;
    property Effects: TEffects read FEffects write SetEffects;
    function GetRadius: Integer;
    procedure Portal;
    function GetSpeed: Integer;
    procedure NewLevel;
    function PossibleImproveAttribute: Boolean;
    function UseAtrPoint: Boolean;
  end;

implementation

uses
  Math,
  Windows,
  SysUtils,
  Graphics,
  Trollhunter.Error,
  Trollhunter.Graph,
  Trollhunter.Log,
  Trollhunter.Decorator,
  Trollhunter.Lang,
  Dragonhunter.Item,
  Trollhunter.Scenes,
  Dragonhunter.Scene.LevelUp,
  Trollhunter.Creatures,
  Trollhunter.Projectiles,
  Dragonhunter.Utils,
  Dragonhunter.Map,
  Dragonhunter.Scene.Item,
  Trollhunter.Scene.Game,
  Trollhunter.Time,
  Trollhunter.Settings,
  Trollhunter.Screenshot,
  Trollhunter.Game,
  Trollhunter.Scene.Records,
  Trollhunter.Formulas,
  Trollhunter.Item.Pattern;

{ TPC }

procedure TCharacter.Clear;
begin
  Prop.Decor := 'BLOOD';
  Prop.MinDamage := 1;
  Prop.MaxDamage := 2;
  Prop.Protect := 0;
  Prop.Radius := 7;
  Prop.Distance := 7;
  Prop.Strength := 15;
  Prop.Dexterity := 5;
  Prop.Intelligence := 8;
  Prop.Perception := 5;
  Prop.Speed := 10;
  Dungeon := 0;
  Race := 0;
  Rating := 0;
  Turns := 0;
  LastTurns := 0;
  Kills := 0;
  Day := 1;
  Week := 1;
  Month := 1;
  Year := 1;
  Inv.Clear;
  Skills.Clear;
  Statistics.Clear;
  Calc();
  Fill();
end;

constructor TCharacter.Create;
begin
  inherited Create;
  FF := TStringList.Create;
  TempSys := TTempSys.Create;
  World := TGlobalMap.Create;
  Inv := TAdvInv.Create;
  Statistics := TStatistics.Create;
  Effects := TEffects.Create;
  Scrolls := TRandItems.Create(RandomScrollsCount);
  Potions := TRandItems.Create(RandomPotionsCount);
  Clear;
end;

destructor TCharacter.Destroy;
begin
  World.Free;
  Potions.Free;
  Scrolls.Free;
  Effects.Free;
  TempSys.Free;
  Statistics.Free;
  Inv.Free;
  FF.Free;
  inherited;
end;

procedure TCharacter.Redraw;
var
  I, L: Integer;
  B, D: Graphics.TBitmap;
  LCategories: TArray<string>;
begin
  try
    with Graph.Surface.Canvas do
    begin
      B := Graphics.TBitmap.Create;
      B.Handle := Windows.LoadBitmap(hInstance, 'PC');
      Graph.BitmapFromTileset(Image, B, Race);
      B.Free;
      LCategories := ExplodeString(EquipmentCategories);
      for L := 0 to Length(LCategories) - 1 do
        for I := 1 to Inv.Count do
          if Inv.GetDoll(I) and
            Items.IsCategory(ItemPatterns.Patterns[Items.ItemIndex(I)].Category,
            EquipmentCategories) and
            (UpperCase(Trim(ItemPatterns.Patterns[Items.ItemIndex(I)].Category))
            = UpperCase(Trim(LCategories[L]))) then
          begin
            D := Graphics.TBitmap.Create;
            B := Graphics.TBitmap.Create;
            B.Handle := Windows.LoadBitmap(hInstance, PChar(Inv.GetIdent(I)));
            Graph.BitmapFromTileset(D, B, 1);
            D.Transparent := True;
            Image.Canvas.Draw(0, 0, D);
            B.Free;
            D.Free;
          end;
      Image.Transparent := True;
    end;
  except
    on E: Exception do
      Error.Add('PC.Render', E.Message);
  end;
end;

procedure TCharacter.Load;
var
  ID, X, Y: Word;

  function GetName: string;
  begin
    Result := FF[ID];
    Inc(ID);
  end;

  function Get: Integer;
  begin
    Result := StrToInt(FF[ID]);
    Inc(ID);
  end;

begin
  try
    ID := 0;
    Name := GetName;
    X := Get;
    Y := Get;
    SetPosition(X, Y);
    Life.SetCur(Get);
    Mana.SetCur(Get);
    Dungeon := Get;
    Race := Get;
    Prop.Strength := Get;
    Prop.Dexterity := Get;
    Prop.Intelligence := Get;
    Prop.Perception := Get;
    Prop.Speed := Get;
    Prop.Level := Get;
    Exp := Get;
    Prop.MinDamage := Get;
    Prop.MaxDamage := Get;
    Prop.Protect := Get;
    AtrPoint := Get;
    Rating := Get;
    Turns := Get;
    LastTurns := Get;
    Kills := Get;
    Day := Get;
    Week := Get;
    Month := Get;
    Year := Get;
    Calc;
  except
    on E: Exception do
      Error.Add('PC.Load', E.Message);
  end;
end;

procedure TCharacter.Save;

  procedure Add(V: Integer); overload;
  begin
    FF.Append(IntToStr(V));
  end;

  procedure Add(V: string); overload;
  begin
    FF.Append(V)
  end;

begin
  try
    FF.Clear;
    //
    Add(Name);
    Add(Pos.X);
    Add(Pos.Y);
    Add(Life.Cur);
    Add(Mana.Cur);
    Add(Dungeon);
    Add(Race);
    //
    Add(Prop.Strength);
    Add(Prop.Dexterity);
    Add(Prop.Intelligence);
    Add(Prop.Perception);
    Add(Prop.Speed);
    //
    Add(Prop.Level);
    Add(Exp);
    Add(Prop.MinDamage);
    Add(Prop.MaxDamage);
    Add(Prop.Protect);
    //
    Add(AtrPoint);
    //
    Add(Rating);
    Add(Turns);
    Add(LastTurns);
    Add(Kills);
    //
    Add(Day);
    Add(Week);
    Add(Month);
    Add(Year);
  except
    on E: Exception do
      Error.Add('PC.Save', E.Message);
  end;
end;

function TCharacter.MaxExp(ALevel: Integer): Integer;
var
  L: Integer;
begin
  if (ALevel = 0) then
    L := Prop.Level
  else
    L := ALevel;
  Result := L * ((L * 3) + 30);
end;

procedure TCharacter.NewLevel;
begin
  with Prop do
  begin
    Level := Level + 1;
    AtrPoint := AtrPoint + 1;
    Rating := Rating + (Level * 10);
    Log.Add(Language.GetLang(60));
    Log.Add(Format(Language.GetLang(61), [Level]));
  end;
  Scenes.Scene := SceneLevelUp;
end;

function TCharacter.AddExp(Value: Word): Boolean;
begin
  Result := False;
  try
    Exp := Exp + Value;
    Log.Add(Format(Language.GetLang(64), [Value]));
    Self.Statistics.Inc(stKills);
    with Prop do
      while (Exp >= MaxExp) do
      begin
        Result := True;
        Self.NewLevel();
      end;
  except
    on E: Exception do
      Error.Add('PC.AddExp', E.Message);
  end;
end;

procedure TCharacter.Move(AX, AY: Integer);
var
  I, V: Integer;
begin
  with Creatures do
    try
      // Move
      for I := 0 to High(Enemy) do
        if not Enemy[I].Life.IsMin and (Pos.X + AX = Enemy[I].Pos.X) and
          (Pos.Y + AY = Enemy[I].Pos.Y) then
        begin
          if not Items.IsRangedWeapon then
            Melee(I);
          Exit;
        end;
      inherited Move(AX, AY);
      if ((AX <> 0) or (AY <> 0)) then
        Look := Pos;
      if TempSys.IsVar('POISON') then
      begin
        V := TempSys.Power('POISON');
        with TAnimNumber.Create(-V) do
          Free;
        Life.Dec(V);
        Log.Add(Format(Language.GetLang(70), [V, TempSys.Duration('POISON')]));
        if (TempSys.Duration('POISON') <= 1) then
          Log.Add(Language.GetLang(71));
      end;
      if TempSys.IsVar('VIALOFLIFE') and not Life.IsMax then
      begin
        V := TempSys.Power('VIALOFLIFE');
        with TAnimNumber.Create(V) do
          Free;
        Life.Inc(V);
      end;
      if TempSys.IsVar('VIALOFMANA') and not Mana.IsMax then
      begin
        V := TempSys.Power('VIALOFMANA');
        with TAnimNumber.Create(V) do
          Free;
        Mana.Inc(V);
      end;
      Self.DetectTraps;
      Self.DoTime();
      Self.TempSys.Move;
      if Self.Life.IsMin then
        Log.Add(Language.GetLang(72)); // You die.
    except
      on E: Exception do
        Error.Add('PC.Move', E.Message);
    end;
end;

procedure TCharacter.Melee(I: Integer);
var
  D, J, LExp: Integer;
  N: string;
begin
  with Creatures do
    try
      D := GetDamage(Character, Enemy[I].Prop.Protect);
      if (D > 0) and (Rand(1, Prop.Dexterity + Enemy[I].Prop.Dexterity) <=
        Prop.Dexterity) then
      begin
        N := Language.GetLang(Enemy[I].Prop.ID);
        SetDamage(Enemy[I], N, D);
        Enemy[I].AI := aiCombat;
        TrainSkill();
        if Enemy[I].Life.IsMin then
        begin
          LExp := Enemy[I].Life.Max;
          if Enemy[I].Prop.AIType = 'BIGSLIME' then
          begin
            for J := 1 to 3 do
              Insert(Enemy[I].Pos.X, Enemy[I].Pos.Y, 'SLIME');
          end;
          if Enemy[I].Prop.AIType = 'SLIME' then
          begin
            for J := 1 to 3 do
              Insert(Enemy[I].Pos.X, Enemy[I].Pos.Y, 'SMALLSLIME');
          end;
          if (Rand(0, 9) = 0) then
            Items.Add(Enemy[I].Pos.X, Enemy[I].Pos.Y, Map.GetRandItemID);
          Log.Add(Format(Language.GetLang(73), [N])); // The %s dies.
          if Character.AddExp(LExp) then
            Log.Add(Format(Language.GetLang(65), [Character.Prop.Level]));
          with Character do
            Rating := Rating + LExp;
        end;
        if (Enemy[I].Prop.AIType = 'GOBLIN') then
        begin
          for D := 0 to High(Enemy) do
            if (Rand(1, 3) <= 2) then
              Enemy[D].AI := aiRun;
          Exit;
        end;
      end
      else
      begin
        Log.Add(Format(Language.GetLang(74),
          [Language.GetLang(Enemy[I].Prop.ID)]));
        // You miss the %s.
        if Enemy[I].Prop.AIType = 'SLUG' then
        begin
          Insert(Enemy[I].Pos.X, Enemy[I].Pos.Y, Enemy[I].Name, 5);
        end;
      end;
      if ((Enemy[I].Prop.AIType = 'GOBLIN') or (Enemy[I].Prop.AIType = 'MELEE')
        or (Enemy[I].Prop.AIType = 'RANGED')) then
        if (Enemy[I].AI <> aiRun) and (Rand(1, 2) = 1) and
          (Enemy[I].Life.Cur < (Enemy[I].Life.Max div 2)) and
          ((Enemy[I].Pos.X <> Enemy[I].Look.X) and
          (Enemy[I].Pos.X <> Enemy[I].Look.Y)) then
          Enemy[I].AI := aiRun;
    except
      on E: Exception do
        Error.Add('PC.Melee', E.Message);
    end;
end;

procedure TCharacter.Ranged(I: Integer);
var
  C, EX, EY: Integer;
  ProjID: string;
  P: TProjectile;

  procedure Rang(ProjID: string);
  var
    J: Integer;
  begin
    with Creatures.Character do
      for J := 1 to Inv.Count do
        if Inv.GetDoll(J) and (Inv.GetIdent(J) = ProjID) then
        begin
          if (Inv.GetCount(J) = 1) then
          begin
            SceneItem.UnEquip(J, False);
            CursorMode := cmNone;
            Calc();
            Redraw;
          end;
          Exit;
        end;
  end;

begin
  try
    with Items do
      with Creatures do
        if IsRangedWeapon then
        begin
          ProjID := GetDollItemID(ArmorCategories);
          C := Character.Inv.GetCount(ProjID);
          if IsBow() then
            Character.Prop.Projectile := 'ARROW';
          if IsCrossBow() then
            Character.Prop.Projectile := 'BOLT';
          if (C > 0) then
          begin
            EX := Enemy[I].Pos.X;
            EY := Enemy[I].Pos.Y;
            P := TProjectile.Create(Self, Pos.X, Pos.Y, EX, EY);
            try
              // if (Rand(1, Prop.Dexterity + Enemy[I].Prop.Dexterity)
              // <= Prop.Dexterity) then
              // точность зависит от расстояния
              Melee(I);
              if (C = 1) then
                Rang(ProjID);
              Character.Inv.Del(ProjID);
              Wait();
              Exit;
            finally
              P.Free;
            end;
          end;
        end;
  except
    on E: Exception do
      Error.Add('PC.Ranged', E.Message);
  end;
end;

procedure TCharacter.SetText(const Value: string);
begin
  FF.Text := Value;
  Self.Load;
end;

procedure TCharacter.SetEffects(const Value: TEffects);
begin
  FEffects := Value;
end;

procedure TCharacter.SetScrolls(const Value: TRandItems);
begin
  FScrolls := Value;
end;

procedure TCharacter.SetPotions(const Value: TRandItems);
begin
  FPotions := Value;
end;

procedure TCharacter.Portal;
begin
  SceneGame.GoToPrevMap;
end;

function TCharacter.PossibleImproveAttribute: Boolean;
begin
  Result := AtrPoint > 0;
end;

procedure TCharacter.SetTurns(const Value: Integer);
begin
  FTurns := Value;
end;

procedure TCharacter.SetAtrPoint(const Value: Integer);
begin
  FAtrPoint := Value;
end;

procedure TCharacter.SetDay(const Value: Integer);
begin
  FDay := Value;
end;

procedure TCharacter.SetMonth(const Value: Integer);
begin
  FMonth := Value;
end;

procedure TCharacter.SetWeek(const Value: Integer);
begin
  FWeek := Value;
end;

procedure TCharacter.SetYear(const Value: Integer);
begin
  FYear := Value;
end;

function TCharacter.GetText: string;
begin
  Self.Save;
  Result := FF.Text;
end;

procedure TCharacter.SetTempSys(const Value: TTempSys);
begin
  FTempSys := Value;
end;

procedure TCharacter.SetRace(const Value: Integer);
begin
  FRace := Value;
end;

procedure TCharacter.SetDungeon(const Value: Integer);
begin
  FDungeon := Value;
end;

procedure TCharacter.SetLastTurns(const Value: Integer);
begin
  FLastTurns := Value;
end;

procedure TCharacter.SetKills(const Value: Integer);
begin
  FKills := Value;
end;

procedure TCharacter.SetRating(const Value: Integer);
begin
  FRating := Value;
end;

procedure TCharacter.DoDetectTraps;
var
  AX, AY: Integer;
begin
  for AX := Pos.X - 1 to Pos.X + 1 do
    for AY := Pos.Y - 1 to Pos.Y + 1 do
      if (Map.Cell[AY][AX].Decor = dTrap) then
      begin
        Map.Cell[AY][AX].Decor := dTrapDet;
        Log.Add(Language.GetLang(109));
        Skills.Up('TRAPS');
      end;
end;

procedure TCharacter.DetectTraps;
begin
  if (Rand(0, 100) < Skills.GetSkill('TRAPS').Level) then
    DoDetectTraps;
end;

procedure TCharacter.SetInv(const Value: TAdvInv);
begin
  FInv := Value;
end;

procedure TCharacter.Wait;
begin
  Move(0, 0);
  Creatures.Move;
  Log.Apply;
  Scenes.Render;
end;

procedure TCharacter.DoTime;
begin
  Turns := Turns + 1;
  Trollhunter.Time.DoTime();
end;

procedure TCharacter.TrainSkill;
var
  LItemIdent, LSkill: string;
begin
  LItemIdent := Trim(Items.GetDollItemID(WeaponCategories));
  if (LItemIdent <> '') then
  begin
    LSkill := ItemPatterns.Patterns[Items.ItemIndex(LItemIdent)].Script;
    if (LSkill <> '') then
      Skills.Up(LSkill);
  end;

  {
    'Dodge':1,
    'Two weapon fighting':2,
    'Whips':3,
    'Unarmed fighting':3,
    'Throwing':2,
  }
end;

function TCharacter.UseAtrPoint: Boolean;
begin
  Result := False;
  if PossibleImproveAttribute then
  begin
    AtrPoint := AtrPoint - 1;
    Result := True;
  end;
end;

procedure TCharacter.AddDexterity;
begin
  Prop.Dexterity := Prop.Dexterity + 1;
  Log.Add(Format('%s +1 (%d).', [Language.GetLang(16), Prop.Dexterity]));
  Calc;
end;

procedure TCharacter.AddSpeed;
begin
  Prop.Speed := Prop.Speed + 1;
  Log.Add(Format('%s +1 (%d).', [Language.GetLang(19), Prop.Speed]));
  Calc;
end;

procedure TCharacter.AddStrength;
begin
  Prop.Strength := Prop.Strength + 1;
  Log.Add(Format('%s +1 (%d).', [Language.GetLang(15), Prop.Strength]));
  Calc;
end;

procedure TCharacter.AddIntelligence;
begin
  Prop.Intelligence := Prop.Intelligence + 1;
  Log.Add(Format('%s +1 (%d).', [Language.GetLang(17), Prop.Intelligence]));
  Calc;
end;

procedure TCharacter.AddPerception;
begin
  Prop.Perception := Prop.Perception + 1;
  Log.Add(Format('%s +1 (%d).', [Language.GetLang(18), Prop.Perception]));
  Calc;
end;

procedure TCharacter.Calc;
begin
  inherited Calc;
  AP.SetMax(GetMaxAP(GetSpeed));
  Inv.MaxCount := GetMaxCount(Prop.Strength);
  Inv.MaxWeight := GetMaxWeight(Prop.Strength);
  Mana.SetMax(GetMaxMana(Prop.Intelligence) +
    GetAdvMana(Skills.GetSkill('MAGIC').Level));
end;

procedure TCharacter.Render;
var
  TX, TY: Integer;
begin
  try
    with Graph do
    begin
      TX := TileSize * RW;
      TY := TileSize * RH + CharHeight;
      Surface.Canvas.Draw(TX, TY, Image);
      // Surface.Canvas.Draw(TX, TY, Effects.Image[0]);
    end;
  except
    on E: Exception do
      Error.Add('PC.Render', E.Message);
  end;
end;

function TCharacter.GetRadius: Integer;
begin
  Prop.Radius := Clamp(Prop.Radius, 0, 9);
  Result := Prop.Radius;
  if TempSys.IsVar('Blind') then
    Result := 1;
end;

function TCharacter.GetSpeed: Integer;
begin
  Result := Prop.Speed;
  if TempSys.IsVar('Webbed') then
    Result := Math.EnsureRange(Prop.Speed - TempSys.Power('Webbed'), 3,
      Prop.Speed);
end;

procedure TCharacter.Defeat;
var
  S: TSettings;
begin
  try
    Life.SetToMin;
    Mana.SetToMin;
    TakeScreenShot(False);
    Rating := Rating + (Creatures.Character.Turns div 100);
    if (Rating > 0) then
      Game.Scores.Add(Rating, Name, DateTimeToStr(Now), Prop.Level,
        Dungeon, Turns);
    DelFile(Name);
    Self.Clear;
    // Create;  {!!!!!!!!!!!!!!!!!!}
    Scenes.Scene := SceneRecords;
    S := TSettings.Create;
    try
      S.Write('Settings', 'LastName', '');
    finally
      S.Free;
    end;
  except
    on E: Exception do
      Error.Add('PC.Defeat', E.Message);
  end;
end;

end.
