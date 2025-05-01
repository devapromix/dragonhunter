unit Dragonhunter.Resources;

interface

uses
  Windows,
  Graphics,
  System.JSON,
  Trollhunter.Map.Tiles;

type
  TObjCell = record
    IMG, FOG: Graphics.TBitmap;
  end;

  TResources = class(TObject)
  private
  public
    UP, FOGUP: Graphics.TBitmap;
    DOWN, FOGDOWN: Graphics.TBitmap;
    WALL, FOGWALL: Graphics.TBitmap;
    FLOOR, FOGFLOOR: Graphics.TBitmap;
    GRASS, FOGGRASS: Graphics.TBitmap;
    GATE, FOGGATE: Graphics.TBitmap;
    CDOOR, FOGCDOOR: Graphics.TBitmap;
    ODOOR, FOGODOOR: Graphics.TBitmap;
    LOCK, TREASURE, FOG: Graphics.TBitmap;
    STONE, FOGSTONE: Graphics.TBitmap;
    TREE, FOGTREE: Graphics.TBitmap;
    BUSH, FOGBUSH: Graphics.TBitmap;
    CHEST: array [tlOpenWoodChest .. tlClosedBarrel] of TObjCell;
    SHRINE: array [tlEmptyShrine .. tlMegaShrine] of TObjCell;
    constructor Create;
    destructor Destroy; override;
  end;

  TJSONData = class(TObject)
    function LoadFromFile(const AFileName: string): TJSONArray;
  end;

var
  GameResources: TResources;

implementation

uses
  System.SysUtils,
  Trollhunter.Utils,
  Trollhunter.Graph,
  Dragonhunter.Color,
  Trollhunter.Light,
  Dragonhunter.Map,
  Engine.MainForm,
  Trollhunter.Decorator,
  Trollhunter.Game,
  Dragonhunter.Map.Pattern,
  Trollhunter.Log,
  Trollhunter.Error,
  Trollhunter.Zip;

{ TResources }

constructor TResources.Create;
var
  T: Graphics.TBitmap;
  F: Graphics.TBitmap;
  I: Tiles;

  procedure ChestBitmap(A: PChar; B: Integer);
  begin
    T.Handle := LoadBitmap(HInstance, A);
    Graph.BitmapFromTileset(CHEST[I].IMG, T, B);
  end;

  procedure SetTile(var AImg, AFog: Graphics.TBitmap;
    ResName, AResPatName: string; IsTransparent: Boolean = False);
  begin
    if (AResPatName = '') then
      AResPatName := ResName;
    { Png := TPNGImage.Create;
      Png.LoadFromResourceName(HInstance, PChar(AResPatName)); }
    AImg.Handle := LoadBitmap(HInstance, PChar(AResPatName));
    ScaleBmp(AImg, TileSize, TileSize);
    if IsTransparent then
    begin
      AImg.Transparent := True;
      AImg.TransparentColor := clFuchsia;
      T.Assign(AImg);
      AImg.Assign(F);
      AImg.Canvas.Draw(0, 0, T);
    end;
    AFog.Assign(AImg);
    AFog.Canvas.Draw(0, 0, FOG);
    if not ParamLight then
      Gamma(AFog, LightMin);
  end;

begin
  T := Graphics.TBitmap.Create;
  F := Graphics.TBitmap.Create;
  // Fog
  FOG := Graphics.TBitmap.Create;
  FOG.Handle := LoadBitmap(HInstance, 'FOG');
  ScaleBmp(FOG, TileSize, TileSize);
  FOG.TransparentColor := clWhite;
  FOG.Transparent := True;

  // Floors
  FLOOR := Graphics.TBitmap.Create;
  FOGFLOOR := Graphics.TBitmap.Create;
  SetTile(FLOOR, FOGFLOOR, 'FLOOR0', MapPatterns.GetPattern.FloorRes);
  GRASS := Graphics.TBitmap.Create;
  FOGGRASS := Graphics.TBitmap.Create;
  SetTile(GRASS, FOGGRASS, 'GRASS0', MapPatterns.GetPattern.FloorRes);

  if MapPatterns.GetPattern.FloorTile = 'GRASS' then
    F.Assign(GRASS);
  if MapPatterns.GetPattern.FloorTile = 'FLOOR' then
    F.Assign(FLOOR);

  // Walls
  WALL := Graphics.TBitmap.Create;
  FOGWALL := Graphics.TBitmap.Create;
  SetTile(WALL, FOGWALL, 'WALL0', MapPatterns.GetPattern.WallRes);

  // Shrines
  with Graph do
  begin
    for I := tlEmptyShrine to tlMegaShrine do
    begin
      SHRINE[I].IMG := Graphics.TBitmap.Create;
      SHRINE[I].FOG := Graphics.TBitmap.Create;
      case I of
        tlEmptyShrine:
          begin
            T.Handle := LoadBitmap(HInstance, 'EMPTYSHRINE');
            ScaleBmp(T, TileSize, TileSize);
          end;
        tlLifeShrine:
          ModTileColor(T, 'BASESHRINE', cRdRed);
        tlManaShrine:
          ModTileColor(T, 'BASESHRINE', cRdBlue);
        tlMegaShrine:
          ModTileColor(T, 'BASESHRINE', cDkPurple);
      end;
      T.Transparent := True;
      SHRINE[I].IMG.Assign(F);
      SHRINE[I].IMG.Canvas.Draw(0, 0, T);
      SHRINE[I].FOG.Assign(SHRINE[I].IMG);
      SHRINE[I].FOG.Canvas.Draw(0, 0, FOG);
      if not ParamLight then
        Gamma(SHRINE[I].FOG, LightMin);
    end;
    for I := tlOpenWoodChest to tlClosedBarrel do
    begin
      CHEST[I].IMG := Graphics.TBitmap.Create;
      CHEST[I].FOG := Graphics.TBitmap.Create;
      case I of
        tlOpenWoodChest:
          ChestBitmap('WOODCHEST', 0);
        tlClosedWoodChest, tlLockedWoodChest:
          ChestBitmap('WOODCHEST', 1);
        tlOpenBestChest:
          ChestBitmap('BESTCHEST', 0);
        tlLockedBestChest:
          ChestBitmap('BESTCHEST', 1);
        tlClosedBarrel:
          ChestBitmap('BARREL', 0);
        tlOpenBarrel:
          ChestBitmap('BARREL', 1);
      end;
      CHEST[I].IMG.Transparent := True;
      T.Assign(F);
      T.Canvas.Draw(0, 0, CHEST[I].IMG);
      CHEST[I].IMG.Assign(T);
      CHEST[I].FOG.Assign(CHEST[I].IMG);
      CHEST[I].FOG.Canvas.Draw(0, 0, FOG);
      if not ParamLight then
        Gamma(CHEST[I].FOG, LightMin);
    end;
  end;
  // Lock
  LOCK := Graphics.TBitmap.Create;
  LOCK.Handle := LoadBitmap(HInstance, 'LOCK');
  ScaleBmp(LOCK, TileSize, TileSize);
  LOCK.Transparent := True;

  // Treasure
  TREASURE := Graphics.TBitmap.Create;
  TREASURE.Handle := LoadBitmap(HInstance, 'TREASURE');
  ScaleBmp(TREASURE, TileSize, TileSize);
  TREASURE.Transparent := True;

  // Stone
  STONE := Graphics.TBitmap.Create;
  FOGSTONE := Graphics.TBitmap.Create;
  SetTile(STONE, FOGSTONE, 'STONE', '', True);

  // Plants
  TREE := Graphics.TBitmap.Create;
  FOGTREE := Graphics.TBitmap.Create;
  SetTile(TREE, FOGTREE, 'TREE0', MapPatterns.GetPattern.TreeRes, True);
  BUSH := Graphics.TBitmap.Create;
  FOGBUSH := Graphics.TBitmap.Create;
  SetTile(BUSH, FOGBUSH, 'BUSH0', MapPatterns.GetPattern.BushRes, True);

  // Up and Down
  UP := Graphics.TBitmap.Create;
  FOGUP := Graphics.TBitmap.Create;
  SetTile(UP, FOGUP, 'UP', '', True);
  DOWN := Graphics.TBitmap.Create;
  FOGDOWN := Graphics.TBitmap.Create;
  SetTile(DOWN, FOGDOWN, 'DOWN', '', True);

  // Gate
  GATE := Graphics.TBitmap.Create;
  GATE.Handle := LoadBitmap(HInstance, 'GATE');
  ScaleBmp(GATE, TileSize, TileSize);
  GATE.Transparent := True;
  T.Assign(WALL);
  T.Canvas.Draw(0, 0, GATE);
  GATE.Assign(T);
  GATE.TransparentColor := GATE.Canvas.Pixels[TileSize div 2, TileSize div 2];
  GATE.Transparent := True;
  T.Assign(GATE);
  GATE.Assign(F);
  GATE.Canvas.Draw(0, 0, T);
  FOGGATE := Graphics.TBitmap.Create;
  FOGGATE.Assign(GATE);
  FOGGATE.Canvas.Draw(0, 0, FOG);
  if not ParamLight then
    Gamma(FOGGATE, LightMin);

  // Doors
  CDOOR := Graphics.TBitmap.Create;
  CDOOR.Handle := LoadBitmap(HInstance, 'CDOOR');
  ScaleBmp(CDOOR, TileSize, TileSize);
  CDOOR.Transparent := True;
  T.Assign(CDOOR);
  CDOOR.Assign(WALL);
  CDOOR.Canvas.Draw(0, 0, T);
  FOGCDOOR := Graphics.TBitmap.Create;
  FOGCDOOR.Assign(CDOOR);
  FOGCDOOR.Canvas.Draw(0, 0, FOG);
  if not ParamLight then
    Gamma(FOGCDOOR, LightMin);

  ODOOR := Graphics.TBitmap.Create;
  ODOOR.Handle := LoadBitmap(HInstance, 'ODOOR');
  ScaleBmp(ODOOR, TileSize, TileSize);
  ODOOR.Transparent := True;
  T.Assign(WALL);
  T.Canvas.Draw(0, 0, ODOOR);
  ODOOR.Assign(T);
  ODOOR.TransparentColor := ODOOR.Canvas.Pixels[TileSize div 2, TileSize div 2];
  ODOOR.Transparent := True;
  T.Assign(ODOOR);
  ODOOR.Assign(F);
  ODOOR.Canvas.Draw(0, 0, T);
  FOGODOOR := Graphics.TBitmap.Create;
  FOGODOOR.Assign(ODOOR);
  FOGODOOR.Canvas.Draw(0, 0, FOG);
  if not ParamLight then
    Gamma(FOGODOOR, LightMin);

  T.Free;
  F.Free;

  Decorators := TDecorators.Create;
end;

destructor TResources.Destroy;
var
  I: Tiles;
begin
  for I := tlEmptyShrine to tlMegaShrine do
  begin
    SHRINE[I].IMG.Free;
    SHRINE[I].FOG.Free;
  end;
  for I := tlOpenWoodChest to tlClosedBarrel do
  begin
    CHEST[I].IMG.Free;
    CHEST[I].FOG.Free;
  end;
  UP.Free;
  FOGUP.Free;
  DOWN.Free;
  FOGDOWN.Free;
  WALL.Free;
  FOGWALL.Free;
  GATE.Free;
  FOGGATE.Free;
  CDOOR.Free;
  FOGCDOOR.Free;
  ODOOR.Free;
  FOGODOOR.Free;
  FLOOR.Free;
  FOGFLOOR.Free;
  GRASS.Free;
  FOGGRASS.Free;
  TREASURE.Free;
  FOG.Free;
  LOCK.Free;
  STONE.Free;
  FOGSTONE.Free;
  TREE.Free;
  FOGTREE.Free;
  BUSH.Free;
  FOGBUSH.Free;

  Decorators.Free;
  inherited;
end;

{ TJSONData }

function TJSONData.LoadFromFile(const AFileName: string): TJSONArray;
var
  LJSONData: string;
  LZip: TZip;
  LFileName: string;
begin
  Result := nil;
  LFileName := Path + 'resources.res';
  try
    if not FileExists(LFileName) then
      Exit;
    LZip := TZip.Create(nil);
    try
      LJSONData := LZip.ExtractTextFromFile(LFileName, AFileName);
      Result := TJSONObject.ParseJSONValue(LJSONData) as TJSONArray;
    finally
      FreeAndNil(LZip);
    end;
  except
    on E: Exception do
      Error.Add('Resources.LoadFromResources', E.Message);
  end;
end;

initialization

finalization

GameResources.Free;

end.
