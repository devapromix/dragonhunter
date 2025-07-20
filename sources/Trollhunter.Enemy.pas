unit Trollhunter.Enemy;

interface

uses
  Trollhunter.Creature;

type
  TEnemy = class(TCreature)
  private
    procedure AddRandomPoisonEffect;
    procedure AddRandomBlindEffect;
  public
    procedure Move(AX, AY: Integer);
    procedure Process;
    procedure Process2;
    procedure Melee;
    procedure Ranged;
    procedure SetEffects;
    constructor Create(AX, AY: Integer);
    destructor Destroy; override;
  end;

implementation

uses
  Types,
  SysUtils,
  Trollhunter.Creatures,
  Dragonhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Lang,
  Trollhunter.Error,
  Trollhunter.Projectiles,
  Trollhunter.Decorator,
  Dragonhunter.AStar,
  Dragonhunter.Map;

procedure TEnemy.AddRandomPoisonEffect;
var
  V: TArray<string>;
begin
  with Creatures.Character.TempSys do
    if (Rand(1, 3) = 1) then
      if Self.Prop.Poison.Trim <> '' then
      begin
        V := Self.Prop.Poison.Split([',']);
        Add('Poison', V[0].ToInteger, V[1].ToInteger);
        Log.Add(Format(Language.GetLang(75), [Language.GetLang(Prop.Id),
          Power('Poison'), Duration('Poison')]));
      end;
end;

procedure TEnemy.AddRandomBlindEffect;
var
  V: TArray<string>;
begin
  with Creatures.Character.TempSys do
    if (Rand(1, 7) = 1) then
      if Self.Prop.Blind.Trim <> '' then
      begin
        V := Self.Prop.Poison.Split([',']);
        Add('Blind', V[0].ToInteger, V[1].ToInteger);
        Log.Add(Language.GetLang(148));
      end;
end;

procedure TEnemy.SetEffects;
begin
  Self.AddRandomPoisonEffect;
  Self.AddRandomBlindEffect;
end;

procedure TEnemy.Melee;
var
  LDamage: Integer;
begin
  try
    LDamage := Creatures.GetDamage(Self, Creatures.Character.Prop.Protect);
    if (LDamage > 0) and
      (Rand(1, Prop.Dexterity + Creatures.Character.Prop.Dexterity) <=
      Prop.Dexterity) then
    begin
      Creatures.SetDamage(Creatures.Character,
        Language.GetLang(Prop.Id), LDamage);
      Self.SetEffects();
      if Creatures.Character.Life.IsMin then
        Log.Add(Language.GetLang(72));
    end
    else
      Log.Add(Format(Language.GetLang(76), [Language.GetLang(Prop.Id)]));
    // The %s misses you!
  except
    on E: Exception do
      Error.Add('Enemy.Melee', E.Message);
  end;
end;

procedure TEnemy.Ranged;
var
  LDamage: Integer;
  LProjectile: TProjectile;

  procedure AddCr(CrID: string; ManaCost: Byte);
  begin
    if (Mana.Cur >= ManaCost) and (Rand(1, 3) = 1) then
    begin
      Mana.Dec(ManaCost);
      Creatures.Insert(Pos.X, Pos.Y, CrID);
    end;
  end;

begin
  try
    if Prop.AIType = 'NECRO' then
    begin
      AddCr('SKELETON', 10);
      Exit;
    end;
    if Mana.IsMin then
      Exit
    else
      Mana.Dec;
    LProjectile := TProjectile.Create(Self, Pos.X, Pos.Y,
      Creatures.Character.Pos.X, Creatures.Character.Pos.Y);
    try
      LDamage := Creatures.GetDamage(Self, Creatures.Character.Prop.Protect);
      if (LDamage > 0) and
        (Rand(1, Prop.Dexterity + Creatures.Character.Prop.Dexterity) <=
        Prop.Dexterity) then
      begin
        Creatures.SetDamage(Creatures.Character,
          Language.GetLang(Prop.Id), LDamage);
        Self.SetEffects();
        if Creatures.Character.Life.IsMin then
          Log.Add(Language.GetLang(72));
        // The %s misses you!
      end
      else
        Log.Add(Format(Language.GetLang(76), [Language.GetLang(Prop.Id)]));
    finally
      LProjectile.Free;
    end;
  except
    on E: Exception do
      Error.Add('Enemy.Ranged', E.Message);
  end;
end;

procedure TEnemy.Move(AX, AY: Integer);
var
  I: Integer;
begin
  try
    for I := 0 to High(Creatures.Enemy) do
      if not Creatures.Enemy[I].Life.IsMin and
        (Pos.X + AX = Creatures.Enemy[I].Pos.X) and
        (Pos.Y + AY = Creatures.Enemy[I].Pos.Y) then
        Exit;
    if (Pos.X + AX = Creatures.Character.Pos.X) and
      (Pos.Y + AY = Creatures.Character.Pos.Y) then
      Melee
    else
      inherited Move(AX, AY, (Prop.Decor <> 'WEB') or (Prop.Decor <> 'SLIME'));
  except
    on E: Exception do
      Error.Add('Enemy.Move', E.Message);
  end;
end;

constructor TEnemy.Create(AX, AY: Integer);
begin
  inherited Create();
  SetPosition(AX, AY);
end;

destructor TEnemy.Destroy;
begin
  inherited;
end;

function IsFreeCell(AX, AY: Integer): Boolean; stdcall;
begin
  Result := Creatures.Character.FreeCell(AX, AY);
end;

procedure TEnemy.Process2;
begin
  if ParamMove or (GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y,
    Pos.X, Pos.Y) > MaxDistance) then
    Exit;
  try

  except
    on E: Exception do
      Error.Add('Enemy.Process2', E.Message);
  end;
end;

procedure TEnemy.Process;
var
  I, J, JX, JY, NX, NY: Integer;
  LPos: TPoint;
begin
  if ParamMove or (GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y,
    Pos.X, Pos.Y) > MaxDistance) then
    Exit;
  try
    if Prop.AIType = 'SIMPLE' then
    begin
      if Creatures.Character.Pos.X > Pos.X then
        NX := 1
      else if Creatures.Character.Pos.X < Pos.X then
        NX := -1
      else
        NX := 0;
      if Creatures.Character.Pos.Y > Pos.Y then
        NY := 1
      else if Creatures.Character.Pos.Y < Pos.Y then
        NY := -1
      else
        NY := 0;
      if NX <> 0 then
        if (not FreeCell(Pos.X + NX, Pos.Y)) then
          NX := 0;
      if NY <> 0 then
        if (not FreeCell(Pos.X, Pos.Y + NY)) then
          NY := 0;
      if GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y, Pos.X,
        Pos.Y) > Prop.Radius then
        Exit;
      if NX = 0 then
        Move(0, NY)
      else if NY = 0 then
        Move(NX, 0)
      else if (Rand(1, 2) = 1) then
        Move(0, NY)
      else
        Move(NX, 0);
    end
    else
    begin
      if ((Prop.AIType = 'RANGED') or (Prop.AIType = 'NECRO')) and
        (GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y, Pos.X,
        Pos.Y) <= Prop.Distance) and LineDist(Creatures.Character.Pos.X,
        Creatures.Character.Pos.Y, Pos.X, Pos.Y) then
      begin
        // Box(GetDist(Creatures.PC.X, Creatures.PC.Y, X, Y));
        Self.Ranged;
        Exit;
      end;

      LPos := Creatures.Character.Pos;
      if (Prop.AIType <> 'BERSERK') and (AI = aiRun) then
      begin
        if (Mana.Cur < Mana.Max) and (Rand(1, 4) = 1) then
          Mana.Inc;
        if (Life.Cur = Life.Max) then
          AI := aiCombat;
        if ((LPos.X = Look.X) and (LPos.X = Look.Y)) or (Rand(1, 15) = 1) then
        begin
          AI := aiCombat;
          Process;
        end
        else
        begin
          {
            if (Rand(1, 9) = 1) then
            repeat
            WX := Rand(Map.Width + 5, Map.Width - 6);
            WY := Rand(Map.Height + 5, Map.Height - 6);
            until Map.Cell[WY][WX].Tile in FloorSet;
          }
          LPos := Look;
          if not Life.IsMin and (Life.Cur < Life.Max) and (Rand(1, 3) = 1) then
            if not Mana.IsMin then
            begin
              Mana.Dec;
              Life.Inc;
            end
            else if (Mana.Cur < Mana.Max) then
              Mana.Inc;
        end;
      end;
      //
      if not DoAStar(Map.Width, Map.Height, Pos.X, Pos.Y, LPos.X, LPos.Y,
        @IsFreeCell, NX, NY) then
        Exit;
      //
      begin
        if (NX <= 0) or (NY <= 0) then
          Exit;
        if (GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y, Pos.X,
          Pos.Y) > Prop.Radius) then
          Exit;
        for I := 0 to High(Creatures.Enemy) do
          if not Creatures.Enemy[I].Life.IsMin and
            (NX = Creatures.Enemy[I].Pos.X) and (NY = Creatures.Enemy[I].Pos.Y)
          then
          begin
            JX := Rand(NX - 1, NX + 1);
            JY := Rand(NY - 1, NY + 1);
            if Creatures.Character.FreeCell(JX, JY) and
              not((JX = Creatures.Character.Pos.X) and
              (JY = Creatures.Character.Pos.Y)) then
            begin
              for J := 0 to High(Creatures.Enemy) do
                if not Creatures.Enemy[J].Life.IsMin and
                  (JX = Creatures.Enemy[J].Pos.X) and
                  (JY = Creatures.Enemy[J].Pos.Y) then
                  Exit;
              Creatures.Enemy[I].SetPosition(JX, JY);
            end;
            Exit;
          end;
        if (NX = Creatures.Character.Pos.X) and (NY = Creatures.Character.Pos.Y)
        then
          Melee()
        else
          Move(NX - Pos.X, NY - Pos.Y);
      end;
    end;
  except
    on E: Exception do
      Error.Add('Enemy.Process', E.Message);
  end;
end;

end.
