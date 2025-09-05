unit Dragonhunter.Map;

interface

uses
  Graphics,
  Classes,
  Trollhunter.CustomMap,
  Dragonhunter.MiniMap,
  Dragonhunter.Item,
  Dragonhunter.Script,
  Trollhunter.Map.Tiles,
  Trollhunter.Decorator,
  Trollhunter.Map.Generator;

const
  MAX_LOCATION_LEVEL = 15;

const
  FloorSet = [tlFloor, tlGrass];

type
  TMapRec = record
    ID: string;
    Level: Integer;
    Items: string;
    Creatures: string;
    Underground: Boolean;
    Village: Boolean;
    GenID: Integer;
    DecorType: string;
    DecTypSize: Integer;
    DecTypCount: Integer;
    IsAutoEnt: Boolean;
    PrevMap: string;
    NextMap: string;
    AltNextMap: string;
    IsAltMapEnt: Boolean;
    IsVillageEnt: Boolean;
    IsTraps: Boolean;
    FloorTile: string;
    FloorRes: string;
    WallRes: string;
  end;

type
  TCell = record
    Tile: Tiles;
    Decor: ShortInt;
    Light: ShortInt;
    Viz: Boolean;
    FOV: Boolean;
  end;

  PDType = (pdItem, pdDecorator, pdCreature);

  TCells = array of array of TCell;

  TMap = class(TCustomMap)
  private
    FLevel: Word;
    FItems: string;
    FCreatures: string;
    FMiniMap: TMiniMap;
    procedure SetLevel(const Value: Word);
    procedure SetItems(const Value: string);
    procedure SetCreatures(const Value: string);
    procedure SetMiniMap(const Value: TMiniMap);
  public
    FM, FV, FS, FD, FL: TStringList;
    Cell: array of array of TCell;
    property Level: Word read FLevel write SetLevel;
    property Items: string read FItems write SetItems;
    property Creatures: string read FCreatures write SetCreatures;
    property MiniMap: TMiniMap read FMiniMap write SetMiniMap;
    procedure AddCreatures(const DungeonLevel: Word);
    procedure AddItems(const DungeonLevel: Word);
    procedure Clear; override;
    procedure Render; override;
    procedure ClearViz;
    function GetMapIndex(AMapIdent: string): Integer;
    function GetRandItemID: string;
    procedure Save(const ID: Integer);
    procedure Load(const ID: Integer);
    procedure Gen(const ID: Integer);
    procedure VizCell(X, Y: Integer; F: Boolean = True);
    procedure LineFOV2(AX, AY, X, Y: Integer; F: Boolean = True);
    procedure SpotDraw(AP: PDType; AX, AY: Integer; Decor: string; Size: Byte);
    constructor Create;
    destructor Destroy; override;
  end;

var
  Map: TMap;

implementation

uses
  Math, dialogs,
  SysUtils,
  Dragonhunter.AStar,
  Trollhunter.Creatures,
  Dragonhunter.Utils,
  Trollhunter.Error,
  Trollhunter.Graph,
  Dragonhunter.Color,
  Trollhunter.Light,
  Dragonhunter.Resources,
  Dragonhunter.Map.Pattern,
  Trollhunter.Item.Pattern,
  Dragonhunter.Item.Default,
  Dragonhunter.Item.Underground,
  Dragonhunter.Wander,
  Dragonhunter.Item.Level;

{ TMap }

constructor TMap.Create;
begin
  inherited;
  FM := TStringList.Create;
  FV := TStringList.Create;
  FS := TStringList.Create;
  FD := TStringList.Create;
  FL := TStringList.Create;
  Level := 0;
  Items := '';
  Creatures := '';
  MiniMap := TMiniMap.Create;
end;

destructor TMap.Destroy;
begin
  MiniMap.Free;
  FM.Free;
  FV.Free;
  FS.Free;
  FD.Free;
  FL.Free;
  inherited;
end;

procedure TMap.LineFOV2(AX, AY, X, Y: Integer; F: Boolean = True);
var
  I, L, DX, DY: Integer;
  LR: Real;
begin
  I := 1;
  if not isValidCell(X, Y) then
    Exit;
  with Trollhunter.Creatures.Creatures do
  begin
    L := Math.Max(Abs(AX - X), Abs(AY - Y)) + 1;
    if (AX = X) and (AY < Y) then
      L := L * I;
    for I := 1 to L do
    begin
      LR := I / L;
      DX := AX + Trunc((X - AX) * LR);
      DY := AY + Trunc((Y - AY) * LR);
      VizCell(DX, DY, F);
      if not Character.FreeCell(DX, DY) and (I > 1) then
        Break;
    end;
  end;
end;

procedure TMap.SpotDraw(AP: PDType; AX, AY: Integer; Decor: string; Size: Byte);
var
  N, S, E, W, X, Y, I: Integer;

  procedure Insert;
  begin
    if (Cell[Y][X].Tile in FloorSet) then
      case AP of
        pdCreature:
          if (Trollhunter.Creatures.Creatures.EmptyCell(X, Y)) then
            Trollhunter.Creatures.Creatures.Add(X, Y, Decor);
        pdDecorator:
          Decorators.Insert(Decor, X, Y);
        pdItem:
          Dragonhunter.Item.Items.Add(X, Y, Decor);
      end;
  end;

begin
  X := AX;
  Y := AY;
  for I := 1 to Size do
  begin
    N := Random(6);
    E := Random(6);
    S := Random(6);
    W := Random(6);
    if N = 1 then
    begin
      X := X - 1;
      if (X < 0) then
        X := 0;
      Insert;
    end;
    if W = 1 then
    begin
      Y := Y - 1;
      if (Y < 0) then
        Y := 0;
      Insert;
    end;
    if S = 1 then
    begin
      X := X + 1;
      if (X > Width - 1) then
        X := Width - 1;
      Insert;
    end;
    if E = 1 then
    begin
      Y := Y + 1;
      if (Y > Height - 1) then
        Y := Height - 1;
      Insert;
    end;
  end;
end;

procedure TMap.Gen(const ID: Integer);
var
  T: Tiles;
  DR: TBeaRLibMap;
  VilGateX, X, Y, I, L, V, C, VX, VY: Integer;

  procedure GenNewFloorPos();
  begin
    repeat
      X := Rand(10, Width - 11);
      Y := Rand(10, Height - 11);
    until (Cell[Y][X].Tile in FloorSet);
  end;

  procedure GenChestPos();
  const
    ChestSet = [tlClosedWoodChest, tlLockedWoodChest, tlLockedBestChest,
      tlClosedBarrel];
  begin
    repeat
      GenNewFloorPos();
    until ((Map.Cell[Y][X - 1].Tile = tlWall) and
      (Map.Cell[Y - 1][X].Tile = tlWall) and (Map.Cell[Y][X + 1].Tile
      in FloorSet) and (Map.Cell[Y + 1][X].Tile in FloorSet) and
      (Map.Cell[Y + 1][X + 1].Tile in FloorSet)) or
      ((Map.Cell[Y][X - 1].Tile in FloorSet) and
      (Map.Cell[Y - 1][X].Tile = tlWall) and (Map.Cell[Y][X + 1].Tile = tlWall)
      and (Map.Cell[Y + 1][X].Tile in FloorSet) and (Map.Cell[Y + 1][X - 1].Tile
      in FloorSet)) or ((Map.Cell[Y][X - 1].Tile in FloorSet) and
      (Map.Cell[Y - 1][X].Tile in FloorSet) and
      (Map.Cell[Y][X + 1].Tile = tlWall) and (Map.Cell[Y + 1][X].Tile = tlWall)
      and (Map.Cell[Y - 1][X - 1].Tile in FloorSet)) or
      ((Map.Cell[Y][X - 1].Tile = tlWall) and (Map.Cell[Y - 1][X].Tile
      in FloorSet) and (Map.Cell[Y][X + 1].Tile in FloorSet) and
      (Map.Cell[Y + 1][X].Tile = tlWall) and (Map.Cell[Y - 1][X + 1].Tile
      in FloorSet)

      ) or ((Rand(1, 10) = 1) and (

      (((Map.Cell[Y][X - 1].Tile in ChestSet) and (Map.Cell[Y][X + 1].Tile
      in FloorSet) and (Map.Cell[Y + 1][X].Tile = tlWall))

      or ((Map.Cell[Y][X - 1].Tile in ChestSet) and (Map.Cell[Y][X + 1].Tile
      in FloorSet) and (Map.Cell[Y - 1][X].Tile = tlWall))

      or ((Map.Cell[Y][X + 1].Tile in ChestSet) and (Map.Cell[Y][X - 1].Tile
      in FloorSet) and (Map.Cell[Y + 1][X].Tile = tlWall))

      or ((Map.Cell[Y][X + 1].Tile in ChestSet) and (Map.Cell[Y][X - 1].Tile
      in FloorSet) and (Map.Cell[Y - 1][X].Tile = tlWall))

      or ((Map.Cell[Y - 1][X].Tile in ChestSet) and (Map.Cell[Y + 1][X].Tile
      in FloorSet) and (Map.Cell[Y][X + 1].Tile = tlWall))

      or ((Map.Cell[Y - 1][X].Tile in ChestSet) and (Map.Cell[Y + 1][X].Tile
      in FloorSet) and (Map.Cell[Y][X - 1].Tile = tlWall))

      or ((Map.Cell[Y + 1][X].Tile in ChestSet) and (Map.Cell[Y - 1][X].Tile
      in FloorSet) and (Map.Cell[Y][X + 1].Tile = tlWall))

      or ((Map.Cell[Y + 1][X].Tile in ChestSet) and (Map.Cell[Y - 1][X].Tile
      in FloorSet) and (Map.Cell[Y][X - 1].Tile = tlWall)))));
  end;

begin
  Randomize;
  try
    Self.Clear;
    SetLength(DR, Self.Width * Self.Height);
    CreateMap(Self.Width, Self.Height, MapPatterns.GetPattern.GenID, DR,
      Self.Width * Self.Height); // супер 1, 7, 17, 18, 19, 21
    SetLength(Cell, Self.Height + 1);

    for Y := 0 to Self.Height - 1 do
    begin
      SetLength(Cell[Y], Self.Width + 1);
      for X := 0 to Width do
      begin
        Map.Cell[Y][X].Decor := -1;
        for T := Succ(Low(Tiles)) to Pred(High(Tiles)) do
        begin
          if (Tile[T].Tile = DR[X * Self.Height + Y]) then
          begin
            // Doors
            if (T = tlClosedDoor) then
              case Rand(0, 19) of
                16:
                  begin
                    Cell[Y][X].Tile := tlClosedDoorWithFireTrap;
                    Break;
                  end;
                17:
                  begin
                    Cell[Y][X].Tile := tlClosedDoorWithLightningTrap;
                    Break;
                  end;
                18:
                  begin
                    Cell[Y][X].Tile := tlLockedDoor;
                    Break;
                  end;
                19:
                  begin
                    Cell[Y][X].Tile := tlHiddenDoor;
                    Break;
                  end;
              end;
            Cell[Y][X].Tile := T;
            Break;
          end;
        end;
      end;
    end;
    ClearViz;
    // Hero pos
    if (Trollhunter.Creatures.Creatures.Character.Dungeon = 0) then
    begin
      GenNewFloorPos();
      Trollhunter.Creatures.Creatures.Character.SetPosition(X, Y);
    end;
    // Add gate
    if MapPatterns.GetPattern.IsVillageEnt then
    begin
      VilGateX := Rand(15, Width - 16);
      for Y := 0 to 7 do
        for X := 0 to 8 do
          Map.Cell[Y][VilGateX - 4 + X].Tile := tlFloor;
      L := Math.RandomRange(5, 10) * 2;
      for I := 0 to L do
        Map.Cell[0][VilGateX - (L div 2) + I].Tile := tlWall;
      V := 0;
      L := Math.RandomRange(1, 5);
      C := 4;
      if MapPatterns.GetPattern.Village then
        C := Math.RandomRange(65, 75);
      for I := 3 to L + C do
      begin
        V := V + (Math.RandomRange(1, 4) - 2);
        VX := VilGateX + V;
        VY := I;
        Map.Cell[VY][VX].Tile := tlStone;
      end;
      for I := -1 to 1 do
        Map.Cell[1][VilGateX + I].Tile := tlStone;
      Map.Cell[2][VilGateX].Tile := tlStone;
      Map.Cell[0][VilGateX].Tile := tlVillageGate;
    end;
    // Add forge
    if MapPatterns.GetPattern.Village then
    begin
      for X := VX - 5 to VX + 5 do
        for Y := VY to VY + 10 do
          Map.Cell[Y][X].Tile := tlStone;
    end;
    // Map.Cell[VY][VX].Tile := tlClosedDoor;
    // Add stairs
    if not MapPatterns.GetPattern.IsAutoEnt and
      (MapPatterns.GetPattern.PrevMap <> '') then
    begin
      GenNewFloorPos();
      Map.Cell[Y][X].Tile := tlPrevDungeon;
    end;
    if not MapPatterns.GetPattern.IsAutoEnt and
      (MapPatterns.GetPattern.NextMap <> '') then
    begin
      GenNewFloorPos();
      Map.Cell[Y][X].Tile := tlNextDungeon;
    end;
    if (MapPatterns.GetPattern.AltNextMap <> '') then
    begin
      GenNewFloorPos();
      Map.Cell[Y][X].Tile := tlAltNextDungeon;
    end;
    // Add shrine
    if not MapPatterns.GetPattern.Village then
      for I := 1 to 3 do
      begin
        GenNewFloorPos();
        case Rand(1, 3) of
          1:
            Map.Cell[Y][X].Tile := tlLifeShrine;
          2:
            Map.Cell[Y][X].Tile := tlManaShrine;
          3:
            Map.Cell[Y][X].Tile := tlMegaShrine;
        end;
      end;
    // Add chest
    if MapPatterns.GetPattern.Underground then
      for I := 1 to 19 do
      begin
        GenChestPos();
        case Rand(1, 7) of
          1 .. 3:
            Map.Cell[Y][X].Tile := tlClosedBarrel;
          4 .. 5:
            Map.Cell[Y][X].Tile := tlClosedWoodChest;
          6:
            Map.Cell[Y][X].Tile := tlLockedWoodChest;
          7:
            Map.Cell[Y][X].Tile := tlLockedBestChest;
        end;
      end;
    // Add decorators
    if not MapPatterns.GetPattern.Village then
    begin
      Light.Clear;
      for I := 0 to 1999 do
      begin
        X := Rand(2, Map.Width - 3);
        Y := Rand(2, Map.Height - 3);
        if not(Map.Cell[Y][X].Tile in FloorSet + [tlWall]) then
          Continue;
        Decorators.Add(X, Y, Rand(1, 19));
      end;
    end;
    if (MapPatterns.GetPattern.DecorType <> '') then
      for I := 1 to MapPatterns.GetPattern.DecTypCount do
      begin
        X := Rand(2, Map.Width - 3);
        Y := Rand(2, Map.Height - 3);
        SpotDraw(pdDecorator, X, Y, MapPatterns.GetPattern.DecorType,
          MapPatterns.GetPattern.DecTypSize);
      end;
    // Script
    // Map Level
    Level := MapPatterns.GetPattern.Level;
    // Map Creatures
    Creatures := MapPatterns.GetPattern.Creatures;
    // Map Items
    Items := AppendToString('', MapPatterns.GetPattern.Items);
    Items := AppendToString(Items, DefaultItems.Items);
    if MapPatterns.GetPattern.Underground then
      Items := AppendToString(Items, UndergroundItems.Items);
    Items := AppendToString(Items, RandomScrolls);
    Items := AppendToString(Items, RandomPotions);
    Items := AppendToString(Items, LevelItems.GetItems(Level));
    if not MapPatterns.GetPattern.Village then
    begin
      // Add monsters
      AddCreatures(ID);
      // Add items
      AddItems(ID);
    end;
  except
    on E: Exception do
      Error.Add('Map.Gen', E.Message);
  end;
end;

procedure TMap.AddCreatures(const DungeonLevel: Word);
var
  I, X, Y: Integer;
  V: TExplodeResult;
begin
  V := nil;
  try
    if (Trim(Creatures) = '') then
      Exit;
    Creatures := RemoveBack(',', Creatures);
    V := Explode(',', Creatures);
    for I := 0 to Clamp(MapPatterns.GetPattern.Level + 15, 15, 49) do
    begin
      repeat
        X := Rand(5, Map.Width - 6);
        Y := Rand(5, Map.Height - 6);
      until (Cell[Y][X].Tile in FloorSet);
      SpotDraw(pdCreature, X, Y, V[Rand(0, High(V))],
        Clamp(MapPatterns.GetPattern.Level + 5, 5, 15))
    end;
  except
    on E: Exception do
      Error.Add('Map.AddCreatures', E.Message);
  end;
end;

procedure TMap.AddItems(const DungeonLevel: Word);
var
  I, X, Y: Integer;
  S: string;
begin
  try
    for I := 0 to Clamp(MapPatterns.GetPattern.Level, 9, 24) do
    begin
      repeat
        X := Rand(2, Map.Width - 3);
        Y := Rand(2, Map.Height - 3);
      until (Map.Cell[Y][X].Tile in FloorSet);
      S := GetRandItemID;
      if (ItemPatterns.Patterns[Dragonhunter.Item.Items.ItemIndex(S)
        ].Category = 'GOLD') then
        SpotDraw(pdItem, X, Y, S, Clamp(MapPatterns.GetPattern.Level, 2, 5))
      else
        Dragonhunter.Item.Items.Add(X, Y, GetRandItemID);
    end;
  except
    on E: Exception do
      Error.Add('Map.AddItems', E.Message);
  end;
end;

function TMap.GetRandItemID: string;
var
  V: TExplodeResult;
begin
  V := nil;
  Result := '';
  try
    if (Trim(Map.Items) = '') then
      Exit;
    Map.Items := RemoveBack(',', Map.Items);
    V := Explode(',', Map.Items);
    Result := V[Rand(0, High(V))];
    if (ItemPatterns.Patterns[Dragonhunter.Item.Items.ItemIndex(Result)
      ].Rarity = 'MAGIC') then
      if (Rand(0, 5) > 0) then
        Result := GetRandItemID;
    if (ItemPatterns.Patterns[Dragonhunter.Item.Items.ItemIndex(Result)
      ].Rarity = 'RARE') then
      if (Rand(0, 15) > 0) then
        Result := GetRandItemID;
    if (ItemPatterns.Patterns[Dragonhunter.Item.Items.ItemIndex(Result)
      ].Rarity = 'UNIQUE') then
      if (Rand(0, 45) > 0) then
        Result := GetRandItemID;
  except
    on E: Exception do
      Error.Add('Map.GetRandItemID', E.Message);
  end;
end;

procedure TMap.Load(const ID: Integer);
var
  T: Tiles;
  C: Char;
  X, Y: Integer;
  Script: TScript;
begin
  try
    // Map
    Self.Clear;
    if (FM.Count > 0) then
    begin
      SetLength(Cell, Height + 1);
      for Y := 0 to Height - 1 do
      begin
        SetLength(Cell[Y], Width + 1);
        for X := 0 to Width do
          for T := Succ(Low(Tiles)) to Pred(High(Tiles)) do
            if (Tile[T].Tile = FM[Y][X + 1]) then
            begin
              Cell[Y][X].Tile := T;
              Break;
            end;
      end;
    end;
    // Viz map
    if (FV.Count > 0) then
    begin
      for Y := 0 to Height - 1 do
        for X := 0 to Width do
          Cell[Y][X].Viz := FV[Y][X + 1] = #32;
    end;
    // Decor map
    if (FD.Count > 0) then
    begin
      for Y := 0 to Height - 1 do
        for X := 0 to Width do
        begin
          C := FD[Y][X + 1];
          Cell[Y][X].Decor := Ord(C) - 33;
        end;
    end;
    // Light map
    if (FL.Count > 0) then
    begin
      for Y := 0 to Height - 1 do
        for X := 0 to Width do
        begin
          C := FL[Y][X + 1];
          Cell[Y][X].Light := Ord(C) - 33;
        end;
    end;
    // Minimap
    MiniMap.Make;
    // Script
    Script := TScript.Create(FS.Text);
    try
      Script.Run;
    finally
      Script.Free;
    end;
  except
    on E: Exception do
      Error.Add('Map.Load', E.Message);
  end;
end;

procedure TMap.Save(const ID: Integer);
var
  S: string;
  I, X, Y: Integer;
begin
  try
    // Map
    FM.Clear;
    for Y := 0 to Height - 1 do
    begin
      S := '';
      for X := 1 to Width do
        S := S + Tile[Cell[Y][X - 1].Tile].Tile;
      FM.Append(S);
    end;
    // Viz map
    FV.Clear;
    for Y := 0 to Height - 1 do
    begin
      S := '';
      for X := 1 to Width do
        if (Cell[Y][X - 1].Viz) then
          S := S + #32
        else
          S := S + '#';
      FV.Append(S);
    end;
    // Decor map
    FD.Clear;
    for Y := 0 to Height - 1 do
    begin
      S := '';
      for X := 1 to Width do
        S := S + Chr(Cell[Y][X - 1].Decor + 33);
      FD.Append(S);
    end;
    // Light map
    FL.Clear;
    for Y := 0 to Height - 1 do
    begin
      S := '';
      for X := 1 to Width do
        S := S + Chr(Cell[Y][X - 1].Light + 33);
      FL.Append(S);
    end;
    // Script
    FS.Clear;
    FS.Append('MapItems ' + Map.Items);
    FS.Append('MapCreatures ' + Map.Creatures);
    FS.Append('MapLevel ' + IntToStr(Map.Level));
    // Creatures
    with Trollhunter.Creatures.Creatures do
      if (Length(Enemy) > 0) then
        for I := 0 to High(Enemy) do
          FS.Append('AddCreature ' + IntToStr(Enemy[I].Pos.X) + ' ' +
            IntToStr(Enemy[I].Pos.Y) + ' ' + Enemy[I].Name + ' ' +
            IntToStr(Enemy[I].Life.Cur) + ' ' + IntToStr(Enemy[I].Mana.Cur));
    // Items
    with Dragonhunter.Item.Items do
      if (Length(Item) > 0) then
        for I := 0 to High(Item) do
          FS.Append('AddItem ' + IntToStr(Item[I].Pos.X) + ' ' +
            IntToStr(Item[I].Pos.Y) + ' ' + Item[I].Name + ' ' +
            IntToStr(Item[I].Prop.Tough) + ' ' + IntToStr(Item[I].Count));
  except
    on E: Exception do
      Error.Add('Map.Save', E.Message);
  end;
end;

procedure TMap.SetLevel(const Value: Word);
begin
  FLevel := Value;
end;

procedure TMap.VizCell(X, Y: Integer; F: Boolean = True);
begin
  if not isValidCell(X, Y) then
    Exit;
  Cell[Y][X].FOV := True;
  if F then
    Cell[Y][X].Viz := True;
end;

procedure TMap.Clear;
begin
  MiniMap.Clear;
  Trollhunter.Creatures.Creatures.Clear;
  Dragonhunter.Item.Items.Clear;
end;

procedure TMap.ClearViz;
var
  X, Y: Integer;
begin
  for X := 0 to Width - 1 do
    for Y := 0 to Height - 1 do
      Cell[Y][X].Viz := False;
end;

procedure TMap.SetItems(const Value: string);
begin
  FItems := Value;
end;

procedure TMap.SetCreatures(const Value: string);
begin
  FCreatures := Value;
end;

function TMap.GetMapIndex(AMapIdent: string): Integer;
var
  LMapIndex: Integer;
begin
  Result := 0;
  for LMapIndex := 0 to MapPatterns.Patterns.Count - 1 do
    if (MapPatterns.GetPattern(LMapIndex).ID = UpperCase(AMapIdent)) then
    begin
      Result := LMapIndex;
      Exit;
    end;
end;

procedure TMap.SetMiniMap(const Value: TMiniMap);
begin
  FMiniMap := Value;
end;

procedure TMap.Render;
var
  B: Boolean;
  X, Y, DX, DY: Integer;
begin
  for X := Trollhunter.Creatures.Creatures.Character.Pos.X - (Graph.RW + 1)
    to Trollhunter.Creatures.Creatures.Character.Pos.X + (Graph.RW + 1) do
    for Y := Trollhunter.Creatures.Creatures.Character.Pos.Y - (Graph.RH + 1)
      to Trollhunter.Creatures.Creatures.Character.Pos.Y + (Graph.RH + 1) do
    begin
      if (X < 0) or (Y < 0) or (X > MapSide - 1) or (Y > MapSide - 1) then
        Continue;
      Map.Cell[Y][X].FOV := False;
    end;
  ///
  for X := Trollhunter.Creatures.Creatures.Character.Pos.X -
    Graph.RW to Trollhunter.Creatures.Creatures.Character.Pos.X + Graph.RW do
    for Y := Trollhunter.Creatures.Creatures.Character.Pos.Y -
      Graph.RH to Trollhunter.Creatures.Creatures.Character.Pos.Y + Graph.RH do
    begin
      if (X < 0) or (Y < 0) or (X > MapSide - 1) or (Y > MapSide - 1) then
        Continue;
      if (GetDist(Trollhunter.Creatures.Creatures.Character.Pos.X,
        Trollhunter.Creatures.Creatures.Character.Pos.Y, X, Y) >
        Trollhunter.Creatures.Creatures.Character.GetRadius) then
        Continue;
      Map.LineFOV2(Trollhunter.Creatures.Creatures.Character.Pos.X,
        Trollhunter.Creatures.Creatures.Character.Pos.Y, X, Y);
    end;
  with Graph.Surface.Canvas do
  begin
    for X := Trollhunter.Creatures.Creatures.Character.Pos.X -
      Graph.RW to Trollhunter.Creatures.Creatures.Character.Pos.X + Graph.RW do
      for Y := Trollhunter.Creatures.Creatures.Character.Pos.Y -
        Graph.RH to Trollhunter.Creatures.Creatures.Character.Pos.Y +
        Graph.RH do
      begin
        if (X < 0) or (Y < 0) or (X > MapSide - 1) or (Y > MapSide - 1) then
          Continue;
        B := False;
        if not Map.Cell[Y][X].FOV then
        begin
          if not Map.Cell[Y][X].Viz then
            Continue;
          B := True;
        end;
        DX := (X - (Trollhunter.Creatures.Creatures.Character.Pos.X - Graph.RW))
          * TileSize;
        DY := (Y - (Trollhunter.Creatures.Creatures.Character.Pos.Y - Graph.RH))
          * TileSize + Graph.CharHeight;
        if not Map.Cell[Y, X].Viz then
          Map.VizCell(X, Y);
        case Map.Cell[Y][X].Tile of
          tlWall, tlHiddenDoor:
            if B then
              Draw(DX, DY, GameResources.FOGWALL)
            else
              Draw(DX, DY, GameResources.WALL);
          tlVillageGate:
            if B then
              Draw(DX, DY, GameResources.FOGGATE)
            else
              Draw(DX, DY, GameResources.GATE);
          tlOpenDoor:
            if B then
              Draw(DX, DY, GameResources.FOGODOOR)
            else
              Draw(DX, DY, GameResources.ODOOR);
          tlClosedDoor .. tlLockedDoor:
            if B then
              Draw(DX, DY, GameResources.FOGCDOOR)
            else
              Draw(DX, DY, GameResources.CDOOR);
          tlEmptyShrine .. tlMegaShrine:
            begin
              if B then
                Draw(DX, DY, GameResources.SHRINE[Map.Cell[Y][X].Tile].FOG)
              else
                Draw(DX, DY, GameResources.SHRINE[Map.Cell[Y][X].Tile].IMG);
            end;
          tlOpenWoodChest .. tlClosedBarrel:
            begin
              if B then
                Draw(DX, DY, GameResources.CHEST[Map.Cell[Y][X].Tile].FOG)
              else
                Draw(DX, DY, GameResources.CHEST[Map.Cell[Y][X].Tile].IMG);
            end;
          tlStone:
            if B then
              Draw(DX, DY, GameResources.FOGSTONE)
            else
              Draw(DX, DY, GameResources.STONE);
          tlGrass:
            if B then
              Draw(DX, DY, GameResources.FOGGRASS)
            else
              Draw(DX, DY, GameResources.GRASS);
          tlTree:
            if B then
              Draw(DX, DY, GameResources.FOGTREE)
            else
              Draw(DX, DY, GameResources.TREE);
          tlBush:
            if B then
              Draw(DX, DY, GameResources.FOGBUSH)
            else
              Draw(DX, DY, GameResources.BUSH);
          tlPrevDungeon:
            if B then
              Draw(DX, DY, GameResources.FOGUP)
            else
              Draw(DX, DY, GameResources.UP);
          tlNextDungeon, tlAltNextDungeon:
            if B then
              Draw(DX, DY, GameResources.FOGDOWN)
            else
              Draw(DX, DY, GameResources.DOWN);
        else
          if MapPatterns.GetPattern.FloorTile = 'GRASS' then
            if B then
              Draw(DX, DY, GameResources.FOGGRASS)
            else
              Draw(DX, DY, GameResources.GRASS);
          if MapPatterns.GetPattern.FloorTile = 'FLOOR' then
            if B then
              Draw(DX, DY, GameResources.FOGFLOOR)
            else
              Draw(DX, DY, GameResources.FLOOR);
        end;
        if B then
          Continue;
        case Map.Cell[Y][X].Tile of
          tlLockedDoor, tlLockedWoodChest, tlLockedBestChest:
            Draw(DX, DY, GameResources.LOCK); { ? }
          tlOpenWoodChest, tlOpenBestChest:
            if (Dragonhunter.Item.Items.CellItemsCount(X, Y) > 0) then
              Draw(DX, DY, GameResources.TREASURE);
        end;
        Decorators.Render(X, Y, DX, DY);
        Trollhunter.Creatures.Creatures.Render(X, Y, DX, DY, True);
        Dragonhunter.Item.Items.Render(X, Y, DX, DY);
        Trollhunter.Creatures.Creatures.Render(X, Y, DX, DY, False);
        if not ParamLight then
          Light.Render(X, Y, DX, DY);

        // Look
        if (CursorMode <> cmNone) then
          if ((Trollhunter.Creatures.Creatures.Character.Look.X = X) and
            (Trollhunter.Creatures.Creatures.Character.Look.Y = Y)) then
          begin
            Brush.Style := bsClear;
            case CursorMode of
              cmLook:
                Pen.Color := cLtYellow;
              cmShoot:
                Pen.Color := cLtRed;
            end;
            Rectangle(DX, DY, DX + TileSize, DY + TileSize);
          end;
      end;
    Trollhunter.Creatures.Creatures.Character.Render;
  end;
end;

initialization

Map := TMap.Create;

finalization

Map.Free;

end.
