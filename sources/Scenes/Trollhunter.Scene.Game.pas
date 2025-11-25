unit Trollhunter.Scene.Game;

interface

uses
  Classes,
  Graphics,
  Trollhunter.Scene,
  Dragonhunter.Map,
  Trollhunter.Map.Tiles;

var
  TT, MaxTT: Cardinal;

type
  TSceneGame = class(TScene)
  private
    procedure Go(T: Tiles);
  public
    procedure GoToVillage;
    procedure GoToPrevMap;
    procedure GoToNextMap;
    procedure GoToAltNextMap;
    procedure GoToGlobalMap;
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure Info();
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneGame: TSceneGame;

implementation

uses
  Windows, Dialogs,
  Types,
  SysUtils,
  Trollhunter.Graph,
  Trollhunter.Creatures,
  Trollhunter.Scenes,
  Dragonhunter.Utils,
  Trollhunter.Trap,
  Trollhunter.Log,
  Trollhunter.Game,
  Dragonhunter.Item,
  Dragonhunter.Color,
  Trollhunter.Error,
  Dragonhunter.Scene.Menu,
  Dragonhunter.Scene.Inv,
  Trollhunter.Projectiles,
  Dragonhunter.Scene.Item,
  Trollhunter.Decorator,
  Trollhunter.Scene.Char,
  Trollhunter.Lang,
  Trollhunter.Light,
  Trollhunter.Look,
  Trollhunter.Scene.Help,
  Dragonhunter.Scene.LevelUp,
  Trollhunter.Skill,
  Trollhunter.Scene.Statistics,
  Trollhunter.Statistics,
  Trollhunter.GlobalMap,
  Dragonhunter.Map.Pattern,
  Dragonhunter.Wander;

{ TGame }

constructor TSceneGame.Create;
begin

end;

destructor TSceneGame.Destroy;
begin
  inherited;
end;

procedure TSceneGame.Go(T: Tiles);
var
  X, Y: Word;
begin
  for X := 0 to Map.Width - 1 do
    for Y := 0 to Map.Height - 1 do
      if (T = Map.Cell[Y][X].Tile) then
      begin
        Creatures.Character.SetPosition(X, Y);
        Exit;
      end;
end;

procedure TSceneGame.GoToVillage;
begin
  if MapPatterns.GetPattern.IsVillageEnt then
  begin
    Graph.Messagebar.Clear;
    if not MapPatterns.GetPattern.Village then
      Log.Add(Language.GetLang(290) + ' ' + Language.GetLang('VILLAGE') + '.')
    else
      Log.Add(Language.GetLang(290) + ' ' +
        Language.GetLang('SPIDERFOREST') + '.');
    Log.Apply;
    Game.Save;
    if MapPatterns.GetPattern.Village then
      Game.Load(1)
    else
      Game.Load(0);
    Go(tlVillageGate);
    Scenes.Render;
  end;
end;

procedure TSceneGame.GoToPrevMap;
var
  I: Integer;
  B: Boolean;
begin
  if (MapPatterns.GetPattern.PrevMap <> '') then
  begin
    Graph.Messagebar.Clear;
    Log.Add(Language.GetLang(290) + ' ' + Language.GetLang
      (MapPatterns.GetPattern.PrevMap) + '.');
    Log.Apply;
    Game.Save;
    B := MapPatterns.GetPattern.IsAltMapEnt;
    I := Map.GetMapIndex(MapPatterns.GetPattern.PrevMap);
    if (I < 0) then
      I := 0;
    Game.Load(I);
    if B then
      Go(tlAltNextDungeon)
    else
      Go(tlNextDungeon);
    Scenes.Render;
  end;
end;

procedure TSceneGame.GoToNextMap;
begin
  if (MapPatterns.GetPattern.NextMap <> '') then
  begin
    Graph.Messagebar.Clear;
    Log.Add(Language.GetLang(290) + ' ' + Language.GetLang
      (MapPatterns.GetPattern.NextMap) + '.');
    Log.Apply;
    Game.Save;
    Game.Load(Map.GetMapIndex(MapPatterns.GetPattern.NextMap));
    Go(tlPrevDungeon);
    Scenes.Render;
  end;
end;

procedure TSceneGame.GoToAltNextMap;
begin
  if (MapPatterns.GetPattern.AltNextMap <> '') then
  begin
    Graph.Messagebar.Clear;
    Log.Add(Language.GetLang(290) + ' ' + Language.GetLang
      (MapPatterns.GetPattern.AltNextMap) + '.');
    Log.Apply;
    Game.Save;
    Game.Load(Map.GetMapIndex(MapPatterns.GetPattern.AltNextMap));
    Go(tlPrevDungeon);
    Scenes.Render;
  end;
end;

procedure TSceneGame.GoToGlobalMap;
begin
  IsGlobalMap := not IsGlobalMap;
  Scenes.Render;
end;

procedure TSceneGame.Info();
var
  LTile: Tiles;
  F: Boolean;
  I: Integer;

  procedure ItemInfo(const I: Integer);
  var
    J, K: Integer;
    S: string;
  begin
    Graph.Messagebar.Clear;
    S := Language.GetItemLang(Items.Item[I].Prop.Id);
    if (Items.Item[I].Prop.IsStack) and (Items.Item[I].Count > 1) then
      S := S + Format('$ (#r%dx$)', [Items.Item[I].Count]);
    if (Items.CellItemsCount(Items.Item[I].Pos.X, Items.Item[I].Pos.Y) > 1) then
      J := 0
    else
      J := 1;
    case LTile of
      tlOpenWoodChest, tlOpenBestChest:
        begin
          K := 51;
          F := True;
        end;
      tlOpenBarrel:
        begin
          K := 101;
          F := True;
        end;
    else
      begin
        K := 53;
        F := True;
      end;
    end;
    Graph.Messagebar.Add(Format(Language.GetLang(K + J), [S]));
  end;

begin
  F := False;
  LTile := tlMin;
  case CursorMode of
    cmNone:
      LTile := Map.Cell[Creatures.Character.Pos.Y]
        [Creatures.Character.Pos.X].Tile;
    cmLook, cmShoot:
      begin
        LTile := Map.Cell[Creatures.Character.Look.Y]
          [Creatures.Character.Look.X].Tile;
        if (Length(Creatures.Enemy) > 0) then
          for I := 0 to High(Creatures.Enemy) do
            if (Creatures.Character.Look.X = Creatures.Enemy[I].Pos.X) and
              (Creatures.Character.Look.Y = Creatures.Enemy[I].Pos.Y) then
            begin
              Graph.Messagebar.Add
                ('#r' + Language.GetLang(Creatures.Enemy[I].Name) +
                Format(' (%d/%d).$', [Creatures.Enemy[I].Life.Cur,
                Creatures.Enemy[I].Life.Max]));
              Exit;
            end;
        if (Length(Items.Item) > 0) then
          for I := 0 to High(Items.Item) do
            if (Creatures.Character.Look.X = Items.Item[I].Pos.X) and
              (Creatures.Character.Look.Y = Items.Item[I].Pos.Y) then
            begin
              ItemInfo(I);
              Exit;
            end;
      end;
  end;
  case LTile of
    tlLockedDoor:
      Graph.Messagebar.Add(Language.GetLang(58));
    tlClosedDoor:
      Graph.Messagebar.Add(Language.GetLang(59));
    tlPrevDungeon:
      Graph.Messagebar.Add(Format(Language.GetLang(83),
        [Language.GetLang(MapPatterns.GetPattern.PrevMap)]));
    tlNextDungeon:
      Graph.Messagebar.Add(Format(Language.GetLang(84),
        [Language.GetLang(MapPatterns.GetPattern.NextMap)]));
    tlAltNextDungeon:
      Graph.Messagebar.Add(Format(Language.GetLang(84),
        [Language.GetLang(MapPatterns.GetPattern.AltNextMap)]));
    tlEmptyShrine:
      Graph.Messagebar.Add(Language.GetLang(85));
    tlLifeShrine:
      Graph.Messagebar.Add(Language.GetLang(86));
    tlManaShrine:
      Graph.Messagebar.Add(Language.GetLang(86));
    tlMegaShrine:
      Graph.Messagebar.Add(Language.GetLang(86));
    tlClosedBarrel:
      Graph.Messagebar.Add(Language.GetLang(57));
    tlClosedWoodChest:
      Graph.Messagebar.Add(Language.GetLang(87));
    tlLockedWoodChest:
      Graph.Messagebar.Add(Language.GetLang(88));
    tlLockedBestChest:
      Graph.Messagebar.Add(Language.GetLang(88));
  end;
  // Item
  if (Length(Items.Item) > 0) then
    for I := 0 to High(Items.Item) do
      if (Creatures.Character.Pos.X = Items.Item[I].Pos.X) and
        (Creatures.Character.Pos.Y = Items.Item[I].Pos.Y) then
      begin
        ItemInfo(I);
        Break;
      end;
  if F then
    Exit;
  case LTile of
    tlOpenBarrel:
      Graph.Messagebar.Add(Language.GetLang(56));
    tlOpenWoodChest, tlOpenBestChest:
      Graph.Messagebar.Add(Language.GetLang(47));
  end;
end;

procedure TSceneGame.KeyDown(var Key: Word; Shift: TShiftState);
var
  I, X, Y: Integer;
  T: Tiles;

  procedure OpenDoor(AX, AY: Integer);
  begin
    Map.Cell[Creatures.Character.Pos.Y + AY][Creatures.Character.Pos.X + AX]
      .Tile := tlOpenDoor;
    Log.Add(Language.GetLang(46));
  end;

  procedure DoMove();
  var
    Trap: TTrap;
    TX, TY: Integer;
  begin
    Graph.Messagebar.Clear;
    // Look
    if (CursorMode <> cmNone) then
    begin
      if (GetDist(Creatures.Character.Pos.X, Creatures.Character.Pos.Y,
        Creatures.Character.Look.X + X, Creatures.Character.Look.Y + Y) >
        Creatures.Character.Prop.Distance) then
        Exit;
      if Map.Cell[Creatures.Character.Look.Y + Y, Creatures.Character.Look.X +
        X].FOV then
        Creatures.Character.IncLook(X, Y);
      Scenes.Render;
      Exit;
    end
    else
      // Move
      if Creatures.Character.FreeCell(Creatures.Character.Pos.X + X,
        Creatures.Character.Pos.Y + Y) then
      begin
        TX := Creatures.Character.Pos.X + X;
        TY := Creatures.Character.Pos.X + Y;
        Creatures.Character.Move(X, Y);
        if (TX <> Creatures.Character.Pos.X + X) or
          (TY <> Creatures.Character.Pos.X + Y) then
          Creatures.Character.Statistics.Inc(stTilesMoved);
      end
      else
        case Map.Cell[Creatures.Character.Pos.Y + Y]
          [Creatures.Character.Pos.X + X].Tile of
          // Open door
          tlClosedDoor:
            OpenDoor(X, Y);
          // Trap in door
          tlClosedDoorWithFireTrap:
            begin
              OpenDoor(X, Y);
              Trap := TTrap.Create;
              Trap.Fire;
              Trap.Free;
            end;
          tlClosedDoorWithLightningTrap:
            begin
              OpenDoor(X, Y);
              Trap := TTrap.Create;
              Trap.Lightning;
              Trap.Free;
            end;
          // Locked door
          tlLockedDoor:
            begin
              if (Creatures.Character.Inv.GetCount('KEY') > 0) then
              begin
                Log.Add(Language.GetLang(44));
                Creatures.Character.Inv.Del('KEY');
                OpenDoor(X, Y);
              end
              else
                Log.Add(Language.GetLang(10));
            end;
          // Hidden door
          tlHiddenDoor:
            begin
              case Rand(1, 9) of
                1 .. 4:
                  T := tlClosedDoor;
                5 .. 6:
                  T := tlClosedDoorWithFireTrap;
                7 .. 8:
                  T := tlClosedDoorWithLightningTrap;
                9:
                  T := tlLockedDoor;
              end;
              Map.Cell[Creatures.Character.Pos.Y + Y]
                [Creatures.Character.Pos.X + X].Tile := T;
              Log.Add(Language.GetLang(43));
            end;
        end;
    Creatures.Move;
    Log.Apply;
    Scenes.Render;
  end;

  procedure Move(AX, AY: Integer);
  begin
    X := AX;
    Y := AY;
    with Creatures.Character do
      if IsValidCell(Pos.X + AX, Pos.Y + AY) then
        DoMove();
  end;

  procedure Run(AX, AY: Integer);
  begin

  end;

begin
  inherited;
  try
    TransKeys(Key);
    if Creatures.Character.Life.IsMin then
    begin
      Creatures.Character.Defeat;
      Exit;
    end;
    T := tlMin;
    X := 0;
    Y := 0;

    // Move //
    if ssAlt in Shift then
    begin
      if ((GetKeyState(VK_LEFT) and 128) = 128) and
        ((GetKeyState(VK_DOWN) and 128) = 128) then
        Move(-1, 1)
      else if ((GetKeyState(VK_RIGHT) and 128) = 128) and
        ((GetKeyState(VK_DOWN) and 128) = 128) then
        Move(1, 1)
      else if ((GetKeyState(VK_LEFT) and 128) = 128) and
        ((GetKeyState(VK_UP) and 128) = 128) then
        Move(-1, -1)
      else if ((GetKeyState(VK_RIGHT) and 128) = 128) and
        ((GetKeyState(VK_UP) and 128) = 128) then
        Move(1, -1);
      Exit;
    end
    else
      case Key of
        // Shoot //
        13:
          case CursorMode of
            cmShoot:
              begin
                if (Length(Creatures.Enemy) > 0) then
                  with Creatures.Character do
                    for I := 0 to High(Creatures.Enemy) do
                      if not Creatures.Enemy[I].Life.IsMin and
                        (Look.X = Creatures.Enemy[I].Pos.X) and
                        (Look.Y = Creatures.Enemy[I].Pos.Y) then
                      begin
                        Ranged(I);
                        Graph.Messagebar.Clear;
                        Exit;
                      end;
              end;
          end;
        // Look //
        ord('L'):
          begin
            if CursorMode <> cmNone then
              CursorMode := cmNone
            else
            begin
              Creatures.Character.Look := Creatures.Character.Pos;
              CursorMode := cmLook;
            end;
            Scenes.Render;
          end;
        // Shoot //
        ord('S'):
          begin
            if CursorMode <> cmNone then
              CursorMode := cmNone
            else if Items.IsRangedWeapon then
            begin
              Creatures.Character.Look := Creatures.Character.Pos;
              CursorMode := cmShoot;
            end;
            Scenes.Render;
          end;
        // Detect traps //
        ord('D'):
          begin
            Creatures.Character.Wait;
            Creatures.Character.DoDetectTraps;
            Scenes.Render;
          end;
        ord('A'):
          if ParamDebug then
          begin
            if not Wander.WanderMode then
              Wander.Start
            else
              Wander.Finish(True);
          end;
        ord('M'):
          if ParamDebug then
          begin
            Creatures.Character.Prop.Radius :=
              Creatures.Character.Prop.Radius + 1;
            Scenes.Render;
          end;
        ord('N'):
          if ParamDebug then
          begin
            Creatures.Character.Prop.Radius :=
              Creatures.Character.Prop.Radius - 1;
            Scenes.Render;
          end;
        27, 123:
          begin
            Game.Save;
            Scenes.Scene := SceneMenu;
            CursorMode := cmNone;
          end;
        ord('I'):
          begin
            SceneInv.RedrawPCIcon;
            SceneInv.ItemUseID := '';
            Scenes.Scene := SceneInv;
          end;
        ord('C'):
          begin
            SceneInv.RedrawPCIcon;
            Scenes.Scene := SceneChar;
          end;
        ord('Y'):
          begin
            Scenes.Scene := SceneStatistics;
          end;
        // Rest //
        ord('R'):
          begin

          end;
        // New Level //
        ord('F'):
          if ParamDebug then
            Creatures.Character.NewLevel
          else
            Scenes.Scene := SceneLevelUp;
        // Move //
        ord('W'), 12, 101, 53:
          Creatures.Character.Wait;
        35, 97, 49:
          if ssShift in Shift then
            Run(-1, 1)
          else
            Move(-1, 1);
        40, 98, 50:
          if ssShift in Shift then
            Run(0, 1)
          else
            Move(0, 1);
        34, 99, 51:
          if ssShift in Shift then
            Run(1, 1)
          else
            Move(1, 1);
        37, 100, 52:
          if ssShift in Shift then
            Run(-1, 0)
          else
            Move(-1, 0);
        39, 102, 54:
          if ssShift in Shift then
            Run(1, 0)
          else
            Move(1, 0);
        36, 103, 55:
          if ssShift in Shift then
            Run(-1, -1)
          else
            Move(-1, -1);
        38, 104, 56:
          if ssShift in Shift then
            Run(0, -1)
          else
            Move(0, -1);
        33, 105, 57:
          if ssShift in Shift then
            Run(1, -1)
          else
            Move(1, -1);
        // Use object //
        32, ord('U'):
          begin
            case Map.Cell[Creatures.Character.Pos.Y]
              [Creatures.Character.Pos.X].Tile of
              tlLifeShrine:
                begin
                  Graph.Messagebar.Clear;
                  with TAnimNumber.Create(Creatures.Character.Life.Max -
                    Creatures.Character.Life.Cur) do
                    Free;
                  Creatures.Character.Life.SetToMax;
                  Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X]
                    .Tile := tlEmptyShrine;
                  Creatures.Character.Rating := Creatures.Character.Rating + 25;
                  // Log.Add('.');
                  Scenes.Render;
                end;
              tlManaShrine:
                begin
                  Graph.Messagebar.Clear;
                  with TAnimNumber.Create(Creatures.Character.Mana.Max -
                    Creatures.Character.Mana.Cur) do
                    Free;
                  Creatures.Character.Mana.SetToMax;
                  Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X]
                    .Tile := tlEmptyShrine;
                  Creatures.Character.Rating := Creatures.Character.Rating + 25;
                  // Log.Add('.');
                  Scenes.Render;
                end;
              tlMegaShrine:
                begin
                  Graph.Messagebar.Clear;
                  with TAnimNumber.Create(Creatures.Character.Life.Max -
                    Creatures.Character.Life.Cur) do
                    Free;
                  with TAnimNumber.Create(Creatures.Character.Mana.Max -
                    Creatures.Character.Mana.Cur) do
                    Free;
                  Creatures.Character.Fill;
                  Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X]
                    .Tile := tlEmptyShrine;
                  Creatures.Character.Rating := Creatures.Character.Rating + 50;
                  // Log.Add('.');
                  Scenes.Render;
                end;
              tlVillageGate:
                GoToVillage;
              tlPrevDungeon:
                GoToPrevMap;
              tlNextDungeon:
                GoToNextMap;
              tlAltNextDungeon:
                GoToAltNextMap;
              tlClosedBarrel:
                begin
                  Graph.Messagebar.Clear;
                  OpenChest(False);
                  Log.Apply;
                  Scenes.Render;
                end;
              tlClosedWoodChest:
                begin
                  Graph.Messagebar.Clear;
                  OpenChest(False);
                  Log.Apply;
                  Scenes.Render;
                end;
              tlLockedWoodChest, tlLockedBestChest:
                begin
                  Graph.Messagebar.Clear;
                  if (Map.Cell[Creatures.Character.Pos.Y]
                    [Creatures.Character.Pos.X].Tile in [tlLockedWoodChest,
                    tlLockedBestChest]) then
                  begin
                    if (Creatures.Character.Inv.GetCount('KEY') > 0) then
                    begin
                      Creatures.Character.Inv.Del('KEY');
                      OpenChest(True);
                    end
                    else
                      Log.Add(Language.GetLang(10));
                    Log.Apply;
                    Scenes.Render;
                  end;
                  Scenes.Render;
                end;
            end;
          end;
        // Pick up
        ord('G'):
          Items.Pickup;
        112: // Help
          Scenes.Scene := SceneHelp;
        ord('V'):
          if ParamDebug then
            GoToVillage;
        // ord('X'):
        // if ParamDebug then
        // GoToGlobalMap;
        ord('H'):
          if ParamDebug then
            GoToPrevMap;
        ord('J'):
          if ParamDebug then
            GoToNextMap;
        ord('K'):
          if ParamDebug then
            GoToAltNextMap;
      end;
  except
    on E: Exception do
      Error.Add('SceneGame.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneGame.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneGame.Render;
begin
  inherited;
  TT := GetTickCount;
  Graph.Clear(0);
  Graph.Bars.Render;
  Log.Render;
  Info();
  if IsGlobalMap then
    Creatures.Character.World.Render
  else
    Map.Render;
  TT := GetTickCount - TT;
  if (MaxTT < TT) then
    MaxTT := TT;
  if ParamDebug then
    with Graph.Surface.Canvas do
    begin
      Brush.Style := bsClear;
      Font.Color := cWhiteYel;
      TextOut(0, Graph.CharHeight, IntToStr(TT) + '(' + IntToStr(MaxTT) + ')');
      TextOut(0, Graph.CharHeight * 2,
        Format('X%d:Y%d', [Creatures.Character.Pos.X,
        Creatures.Character.Pos.Y]));
      TextOut(0, Graph.CharHeight * 3, Format('LX%d:LY%d',
        [Creatures.Character.Look.X, Creatures.Character.Look.Y]));
    end;
  Graph.Messagebar.Render;
  // if IsGlobalMap then
  // else
  Map.MiniMap.Render;
  Creatures.Character.Effects.Render;
  if ParamDebug then
    Wander.Render;
  Graph.Render;
end;

initialization

finalization

SceneGame.Free;

end.
