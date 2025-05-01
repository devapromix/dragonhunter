unit Dragonhunter.Item;

interface

uses
  Windows,
  Graphics,
  Classes,
  Dragonhunter.Color,
  Trollhunter.Craft,
  Dragonhunter.Entity,
  Dragonhunter.Item.Random,
  Trollhunter.Item.Pattern,
  Dragonhunter.Item.Script;

const
  RandomScrollsCount = 9;
  RandomPotionsCount = 9;

const
  ArmorCategories = 'LHAND,HEAD,BODY,FOOT';
  WeaponCategories = 'RHAND';
  AmuRingCategories = 'AMULET,RING';
  ScrollCategories = 'SCROLL';
  PotionCategories = 'POTION';
  FoodCategories = 'PLANT';
  CraftCategories = 'CRAFT';
  RepairCategories = 'REPAIR';
  KeyCategories = 'KEY';
  UseCategories = PotionCategories + ',' + RepairCategories + ',' +
    CraftCategories;
  EquipmentCategories = WeaponCategories + ',' + ArmorCategories + ',' +
    AmuRingCategories;
  DropCategories = EquipmentCategories + ',' + PotionCategories + ',' +
    RepairCategories + ',' + KeyCategories + ',' + CraftCategories + ',' +
    FoodCategories + ',' + ScrollCategories;

var
  RandomScrolls, RandomPotions: string;

type
  TBaseItem = class(TEntity)
  private
    FCount: Integer;
    SmallImage: Graphics.TBitmap;
    HeroImage: Graphics.TBitmap;
    procedure SetCount(const Value: Integer);
  public
    Prop: TItemPattern;
    constructor Create(AX, AY: Integer);
    destructor Destroy; override;
    property Count: Integer read FCount write SetCount;
  end;

  TItem = array of TBaseItem;

  TItems = class(TObject)
  private
    FItem: TItem;
    FItemScript: TItemScript;
    procedure SetItem(const Value: TItem);
  public
    function Use(ItemA, ItemB: string; I: Integer): Boolean;
    property Item: TItem read FItem write SetItem;
    procedure Clear;
    procedure Pickup(Index: Integer = 0);
    procedure PickupAll;
    function Craft(A, B: string): string;
    procedure Damage(const ACategories: string; Chance: Byte = 3);
    function IsDollScript(const AScript: string): Boolean;
    function IsBow: Boolean;
    function IsCrossBow: Boolean;
    function IsRangedWeapon: Boolean;
    function GetDollItemID(ACategories: string): string;
    function GetDollItemScript(const AScript: string): string;
    procedure Add(const X, Y: Integer; AName: string); overload;
    procedure Add(const AIdent: string; const ACount: Integer = 1); overload;
    procedure AddAndEquip(ID: string; ACount: Integer = 1);
    procedure Render(X, Y, DX, DY: Integer);
    procedure Colors(var Icon: Graphics.TBitmap; ItemIndex: Integer);
    procedure SetColor(const AColor: Integer);
    procedure UseItem(const AIndex: Integer; const AScript: string);
    procedure UseScript(const Index: Integer);
    function CellItemsCount(X, Y: Integer): Integer;
    function ItemIndex(AIdent: string): Integer; overload;
    function ItemIndex(AIdent: Integer): Integer; overload;
    function GetDollText(AItemIndex, AItemIdent: Integer): string;
    procedure RepairAll;
    procedure Key;
    procedure Identify;
    function GetItemProp(ACount, ATough, I, V: Integer): string;
    function GetWeight(Index: Integer): string;
    procedure RenderPCInvStat(Y: Integer);
    constructor Create;
    destructor Destroy; override;
    function IsCategory(const ACategory, ACategories: string): Boolean;
    property ItemScript: TItemScript read FItemScript write FItemScript;
    function Count: Integer;
  end;

var
  Items: TItems;

implementation

uses
  SysUtils,
  Trollhunter.Utils,
  Trollhunter.Error,
  Dragonhunter.Map,
  Trollhunter.Graph,
  Trollhunter.Creatures,
  Trollhunter.Scenes,
  Trollhunter.Log,
  Dragonhunter.Scene.Item,
  Trollhunter.Map.Tiles,
  Trollhunter.Scene.Items,
  Trollhunter.Lang,
  Trollhunter.TempSys,
  Trollhunter.Inv,
  Trollhunter.Skill,
  Trollhunter.Formulas;

{ TBaseItem }

constructor TBaseItem.Create(AX, AY: Integer);
begin
  try
    inherited Create;
    SmallImage := Graphics.TBitmap.Create;
    HeroImage := Graphics.TBitmap.Create;
    HeroImage.Transparent := True;
    Count := 1;
    SetPosition(AX, AY);
  except
    on E: Exception do
      Error.Add('BaseItem.Create', E.Message);
  end;
end;

destructor TBaseItem.Destroy;
begin
  SmallImage.Free;
  HeroImage.Free;
  inherited;
end;

procedure TBaseItem.SetCount(const Value: Integer);
begin
  FCount := Value;
end;

{ TItems }

procedure TItems.Add(const X, Y: Integer; AName: string);
var
  I, LIndex: Integer;
  Tileset: Graphics.TBitmap;
begin
  Tileset := Graphics.TBitmap.Create;
  try
    AName := UpperCase(AName);
    if (AName = '') then
      Exit;
    LIndex := ItemIndex(AName);
    if (LIndex < 0) then
      Exit;
    I := Length(FItem) + 1;
    SetLength(FItem, I);
    FItem[I - 1] := TBaseItem.Create(X, Y);
    with FItem[I - 1] do
      with ItemPatterns.Patterns[LIndex] do
      begin
        Name := AName;
        Prop := ItemPatterns.Patterns[LIndex];
        Count := Rand(MinCount, MaxCount);
        if Prop.IsStack and (Category = 'GOLD') then
          Count := Map.Level * Count;
        Prop.Tough := Rand(Prop.MaxTough div 3, Prop.MaxTough - 1);

        if (Sprite = '') then
          Tileset.Handle := Windows.LoadBitmap(hInstance, PChar(Name))
        else
          Tileset.Handle := Windows.LoadBitmap(hInstance, PChar(Sprite));

        Graph.BitmapFromTileset(Image, Tileset, 1);
        HeroImage.Assign(Image);
        Graph.BitmapFromTileset(Image, Tileset, 0);
        SmallImage.Assign(Image);
        Colors(SmallImage, LIndex);
        ScaleBmp(SmallImage, TileSize div 2, TileSize div 2);
        SmallImage.Transparent := True;
      end;
    Tileset.Free;
  except
    on E: Exception do
      Error.Add('Items.Add', E.Message);
  end;
end;

procedure TItems.Add(const AIdent: string; const ACount: Integer = 1);
var
  LIndex, LCount: Integer;
  LIdent: string;
begin
  try
    if (AIdent = '') then
      Exit;
    LIdent := UpperCase(AIdent);
    LIndex := ItemIndex(LIdent);
    if (LIndex < 0) then
      Exit;
    with Creatures.Character do
    begin
      LCount := ACount;
      if (LCount > 1) and not ItemPatterns.Patterns[LIndex].IsStack then
        LCount := 1;
      if not Inv.Add(LIdent, LCount, ItemPatterns.Patterns[LIndex].Weight,
        ItemPatterns.Patterns[LIndex].MaxTough,
        ItemPatterns.Patterns[LIndex].IsStack) then
        Exit;
    end;
  except
    on E: Exception do
      Error.Add('Items.Add', E.Message);
  end;
end;

function TItems.CellItemsCount(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  if (Length(Items.Item) > 0) then
    for I := 0 to High(Items.Item) do
      if (Items.Item[I].Pos.X = X) and (Items.Item[I].Pos.Y = Y) then
        Inc(Result);
end;

procedure TItems.Colors(var Icon: Graphics.TBitmap; ItemIndex: Integer);
begin
  with ItemPatterns.Patterns[ItemIndex] do
    try
      if (ColorTag > 0) then
      begin
        if Category = 'POTION' then
          Graph.ModTileColor(Icon, Sprite,
            Creatures.Character.Potions.GetColor(ColorTag));
        if Category = 'SCROLL' then
          Graph.ModTileColor(Icon, Sprite,
            Creatures.Character.Scrolls.GetColor(ColorTag));
        Exit;
      end;
      if (Color = 'NONE') then
        Exit;
      if (Sprite = '') then
        Graph.ModTileColor(Icon, Sprite, ColorToInt(Color))
      else
        Graph.ModTileColor(Icon, Sprite, ColorToInt(Color));
    except
      on E: Exception do
        Error.Add('Items.Colors', E.Message);
    end;
end;

function TItems.Count: Integer;
begin
  Result := Length(Items.Item)
end;

function TItems.Craft(A, B: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(CraftItems) do
    if ((A = CraftItems[I].A) and (B = CraftItems[I].B)) or
      ((A = CraftItems[I].B) and (B = CraftItems[I].A)) then
    begin
      Result := CraftItems[I].C;
      Exit;
    end;
end;

procedure TItems.Damage(const ACategories: string; Chance: Byte);
var
  I, J: Integer;
begin
  with Creatures.Character do
    for I := 1 to Inv.Count do
    begin
      if Inv.GetDoll(I) and not(ItemPatterns.Patterns[Items.ItemIndex(I)
        ].IsStack) and IsCategory(ItemPatterns.Patterns[Items.ItemIndex(I)
        ].Category, ACategories) then
      begin
        if (Rand(1, Chance) > 1) then
          Continue;
        J := Inv.GetTough(I);
        if (J > 0) then
          Dec(J);
        Inv.SetTough(I, J);
        if (Inv.GetTough(I) = 0) then
        begin
          SceneItem.UnEquip(I, False);
          Redraw;
        end;
        Exit;
      end;
    end;
end;

constructor TItems.Create;
var
  I: Byte;
begin
  RandomPotions := '';
  for I := 1 to RandomPotionsCount do
    RandomPotions := RandomPotions + 'POTION' + Chr(I + 64) + ',';
  RandomScrolls := '';
  for I := 1 to RandomScrollsCount do
    RandomScrolls := RandomScrolls + 'SCROLL' + Chr(I + 64) + ',';
  FItemScript := TItemScript.Create;
end;

destructor TItems.Destroy;
begin
  FreeAndNil(FItemScript);
  inherited;
end;

procedure TItems.Key;
begin
  Graph.Messagebar.Clear;
  if (Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile
    in [tlLockedWoodChest, tlLockedBestChest]) then
  begin
    OpenChest(True);
    Log.Apply;
    Scenes.Render;
  end;
  Scenes.Render;
end;

procedure TItems.UseScript(const Index: Integer);
begin
  try
    ItemScript.DoCommands(ItemPatterns.Patterns[Index].Script);
  except
    on E: Exception do
      Error.Add('Items.UseScript', E.Message);
  end;
end;

procedure TItems.UseItem(const AIndex: Integer; const AScript: string);
begin
  try
    if IsCategory(ItemPatterns.Patterns[AIndex].Category, AScript) then
      UseScript(AIndex);
  except
    on E: Exception do
      Error.Add('Items.UseItem', E.Message);
  end;
end;

procedure TItems.Clear;
begin
  SetLength(FItem, 0);
end;

function TItems.GetItemProp(ACount, ATough, I, V: Integer): string;
begin
  Result := '';
  with ItemPatterns.Patterns[V] do
  begin
    if (MaxDamage > 0) then
      Result := Result + Format(' [%d-%d]', [MinDamage, MaxDamage]);
    if (Protect > 0) then
      Result := Result + Format(' [%d]', [Protect]);
    if (ACount > 1) then
      Result := Result + Format(' (%dx)', [ACount]);
    if not IsStack and (MaxTough > 0) then
      Result := Result + Format(' <%d/%d>', [ATough, MaxTough]);
  end;
end;

function TItems.GetWeight(Index: Integer): string;
begin
  if (ItemPatterns.Patterns[Index].Weight > 0) then
    Result := Format(' %ds', [ItemPatterns.Patterns[Index].Weight])
  else
    Result := '';
end;

function TItems.ItemIndex(AIdent: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to ItemPatterns.Patterns.Count - 1 do
    if (Trim(AIdent) = ItemPatterns.Patterns[I].ID) then
    begin
      Result := I;
      Break;
    end;
end;

function TItems.ItemIndex(AIdent: Integer): Integer;
var
  LIdent: string;
begin
  Result := -1;
  LIdent := Creatures.Character.Inv.GetIdent(AIdent);
  if (LIdent = '') then
    Exit;
  Result := ItemIndex(LIdent);
end;

procedure TItems.Pickup(Index: Integer = 0);
var
  I, H: Integer;
  S: string;

  function IsAddToInv(I: Integer): Boolean;
  begin
    with Items.Item[I] do
      Result := Creatures.Character.Inv.Add(Name, Count, Prop.Weight,
        Prop.Tough, Prop.IsStack);
  end;

  procedure RenderText();
  begin
    Log.Add(Format(Language.GetLang(12), [S]));
    Log.Apply;
    Scenes.Render;
  end;

  procedure Add(I: Integer);
  var
    J: Integer;
  begin
    if not IsAddToInv(I) then
    begin
      Log.Add(Language.GetLang(11));
      Log.Apply;
      Scenes.Render;
      Exit;
    end;
    Graph.Messagebar.Clear;
    S := Language.GetItemLang(Items.Item[I].Prop.ID);
    if (Items.Item[I].Count > 1) then
      S := S + ' (' + IntToStr(Items.Item[I].Count) + ')';
    if (Length(Items.Item) > 1) then
    begin
      for J := I to High(Items.Item) - 1 do
        Items.Item[J] := Items.Item[J + 1];
      SetLength(FItem, Length(Items.Item) - 1);
    end
    else
      Self.Clear;
    RenderText();
  end;

begin
  try
    H := 0;
    if (Index > 0) then
    begin
      if (Length(Items.Item) > 0) then
        for I := 0 to High(Items.Item) do
          if (Creatures.Character.Pos.X = Items.Item[I].Pos.X) and
            (Creatures.Character.Pos.Y = Items.Item[I].Pos.Y) then
          begin
            Inc(H);
            if (Index > 0) and (Index = H) then
            begin
              Add(I);
              Exit;
            end;
          end;
    end;
    if (Items.CellItemsCount(Creatures.Character.Pos.X,
      Creatures.Character.Pos.Y) > 1) then
    begin
      Graph.Messagebar.Clear;
      Scenes.Scene := SceneItems;
    end
    else if (Length(Items.Item) > 0) then
      for I := 0 to High(Items.Item) do
        if (Creatures.Character.Pos.X = Items.Item[I].Pos.X) and
          (Creatures.Character.Pos.Y = Items.Item[I].Pos.Y) then
        begin
          Add(I);
          Exit;
        end;
  except
    on E: Exception do
      Error.Add('Items.Pickup', E.Message);
  end;
end;

procedure TItems.PickupAll;
var
  C, I: Integer;
begin
  try
    C := Items.CellItemsCount(Creatures.Character.Pos.X,
      Creatures.Character.Pos.Y);
    for I := 0 to C do
      Pickup(I);
  except
    on E: Exception do
      Error.Add('Items.PickupAll', E.Message);
  end;
end;

procedure TItems.Render(X, Y, DX, DY: Integer);
var
  I: Integer;
begin
  try
    with Graph.Surface.Canvas do
      if (Length(Items.Item) > 0) then
      begin
        for I := High(Items.Item) downto 0 do
          if (X = Items.Item[I].Pos.X) and (Y = Items.Item[I].Pos.Y) then
          begin
            if (Map.Cell[Y][X].Tile in [tlOpenWoodChest, tlOpenBestChest,
              tlOpenBarrel]) then
              Continue;
            Draw(DX + (TileSize div 4), DY + (TileSize div 4),
              Items.Item[I].SmallImage);
            // TextOut(DX, DY, IntToStr(X) + IntToStr(Y));
            // LBAR.Assign(LIFEBAR);
            // LBAR.Width := BarWidth(Creatures.Enemy[I].Life, Creatures.Enemy[I].MaxLife);
            // Draw(DX + 1, DY, LBAR);
          end;
      end;
  except
    on E: Exception do
      Error.Add('Items.Render', E.Message);
  end;
end;

procedure TItems.RenderPCInvStat(Y: Integer);
begin
  with Graph.Surface.Canvas do
  begin
    Font.Style := [fsBold];
    Font.Color := cRdYellow;
    with Creatures.Character.Inv do
      Trollhunter.Graph.Graph.Text.TextCenter(Y,
        Format('%s: %d/%d | %s: %d/%ds', [Language.GetLang(41), Count, MaxCount,
        Language.GetLang(42), Weight, MaxWeight]));
  end;
end;

procedure TItems.SetColor(const AColor: Integer);
begin
  with Graph.Surface.Canvas do
    if ItemPatterns.Patterns[AColor].Category = 'GOLD' then
      Font.Color := clYellow
    else
      Font.Color := clSkyBlue;
end;

procedure TItems.SetItem(const Value: TItem);
begin
  FItem := Value;
end;

function TItems.Use(ItemA, ItemB: string; I: Integer): Boolean;
var
  A, B, C, LTough, LMaxTough, LScriptTough: Integer;
  ItemC: string;
begin
  Result := False;
  // if (ItemA = ItemB) then Exit; {?}
  with Creatures.Character.Inv do
  begin
    if (GetCount(ItemA) > 0) and (GetCount(ItemB) > 0) then
    begin
      A := ItemIndex(ItemA);
      B := ItemIndex(ItemB);
      C := ItemIndex(ItemC);

      // Repair item (oils, hammers)
      if (Items.IsCategory(ItemPatterns.Patterns[A].Category, PotionCategories)
        or Items.IsCategory(ItemPatterns.Patterns[A].Category, RepairCategories)
        ) and ((ItemPatterns.Patterns[A].Script.StartsWith('REPAIR'))) and
        (Items.IsCategory(ItemPatterns.Patterns[B].Category, WeaponCategories)
        or Items.IsCategory(ItemPatterns.Patterns[B].Category, ArmorCategories))
      then
      begin
        LTough := GetTough(I);
        LMaxTough := ItemPatterns.Patterns[B].MaxTough;
        if (LTough < LMaxTough) then
        begin
          if (ItemPatterns.Patterns[A].Script = 'REPAIR') then
            SetTough(I, LMaxTough)
          else if ItemPatterns.Patterns[A].Script.StartsWith('REPAIR'#32) then
          begin
            LScriptTough := GetStrValue(#32, ItemPatterns.Patterns[A].Script)
              .ToInteger;
            SetTough(I, LTough + LScriptTough);
          end;
          if (GetTough(I) > LMaxTough) then
            SetTough(I, LMaxTough);
          Del(ItemA);
          Result := True;
        end;
        Exit;
      end;

      // Mix potions
      if Items.IsCategory(ItemPatterns.Patterns[A].Category, UseCategories) or
        Items.IsCategory(ItemPatterns.Patterns[B].Category, PotionCategories)
      then
      begin
        ItemC := Craft(ItemA, ItemB);
        if (ItemC <> '') then
        begin
          Del(ItemA);
          Del(ItemB);
          Add(ItemC, 1, ItemPatterns.Patterns[C].Weight, 0, True);
          Result := True;
        end;
        Exit;
      end;

    end;
  end;
end;

function TItems.GetDollItemID(ACategories: string): string;
var
  I: Integer;
begin
  Result := '';
  with Creatures.Character do
    for I := 1 to Inv.Count do
      if Inv.GetDoll(I) and Items.IsCategory
        (ItemPatterns.Patterns[Items.ItemIndex(I)].Category, ACategories) then
      begin
        Result := Inv.GetIdent(I);
        Exit;
      end;
end;

function TItems.IsDollScript(const AScript: string): Boolean;
var
  K, J: Integer;
begin
  Result := False;
  with Creatures.Character do
  begin
    for K := 1 to Inv.Count do
    begin
      J := ItemIndex(K);
      if Inv.GetDoll(K) then
      begin
        if (AScript = ItemPatterns.Patterns[J].Script) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

function TItems.GetDollItemScript(const AScript: string): string;
begin
  Result := ItemPatterns.Patterns[ItemIndex(GetDollItemID(AScript))].Script;
end;

function TItems.IsBow: Boolean;
begin
  Result := ('BOW' = GetDollItemScript(WeaponCategories)) and
    ('BOW' = GetDollItemScript(ArmorCategories))
end;

function TItems.IsCrossBow: Boolean;
begin
  Result := ('CROSSBOW' = GetDollItemScript(WeaponCategories)) and
    ('CROSSBOW' = GetDollItemScript(ArmorCategories))
end;

function TItems.IsRangedWeapon: Boolean;
begin
  Result := (GetDollItemID(WeaponCategories) <> '') and
    (GetDollItemID(ArmorCategories) <> '') and (IsBow or IsCrossBow);
end;

procedure TItems.Identify;
var
  LSlot: TSlot;
  LIndex, LTag: Integer;
begin
  try
    with Creatures.Character do
      for LSlot := 1 to Inv.Count do
      begin
        LIndex := ItemIndex(LSlot);
        LTag := ItemPatterns.Patterns[LIndex].ColorTag;
        if (LTag > 0) and (ItemPatterns.Patterns[LIndex].Category = 'POTION')
          and not Potions.IsDefined(LTag) then
          Potions.SetDefined(LTag);
        if (LTag > 0) and (ItemPatterns.Patterns[LIndex].Category = 'SCROLL')
          and not Scrolls.IsDefined(LTag) then
          Scrolls.SetDefined(LTag);
      end;
  except
    on E: Exception do
      Error.Add('Items.Identify', E.Message);
  end;
end;

function TItems.IsCategory(const ACategory, ACategories: string): Boolean;
var
  I: Integer;
  LCategories: TArray<string>;
begin
  LCategories := ExplodeString(ACategories);
  for I := 0 to Length(LCategories) - 1 do
    if UpperCase(Trim(ACategory)) = UpperCase(Trim(LCategories[I])) then
      Exit(True);
  Exit(False);
end;

procedure TItems.RepairAll;
var
  LSlot: TSlot;
  LTough: Word;
begin
  try
    with Creatures.Character.Inv do
      for LSlot := 1 to Count do
      begin
        LTough := ItemPatterns.Patterns[ItemIndex(LSlot)].MaxTough;
        if (GetTough(LSlot) < LTough) then
          SetTough(LSlot, LTough);
      end;
  except
    on E: Exception do
      Error.Add('Items.RepairAll', E.Message);
  end;
end;

procedure TItems.AddAndEquip(ID: string; ACount: Integer = 1);
begin
  ID := Trim(ID);
  if (ID = '') then
    Exit;
  Add(ID, ACount);
  SceneItem.Equip(Creatures.Character.Inv.Count, False);
end;

function TItems.GetDollText(AItemIndex, AItemIdent: Integer): string;
var
  LStr: string;
  I: Integer;
  LCategories: TArray<string>;
begin
  Result := '';
  LStr := '';
  LCategories := ExplodeString(EquipmentCategories);
  for I := 0 to Length(LCategories) - 1 do
    if UpperCase(Trim(ItemPatterns.Patterns[AItemIdent].Category))
      = UpperCase(Trim(LCategories[I])) then
    begin
      LStr := Language.GetLang(I + 231);
      Break;
    end;
  if Creatures.Character.Inv.GetDoll(AItemIndex) then
    Result := ' - ' + LStr;
end;

initialization

Items := TItems.Create;

finalization

Items.Free;

end.
