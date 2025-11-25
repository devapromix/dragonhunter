unit Dragonhunter.Scene.Item;

interface

uses
  Classes,
  Graphics,
  Windows,
  Trollhunter.Scene;

type
  TSceneItem = class(TScene)
  private
    FMenuCount: Integer;
    Icon: Graphics.TBitmap;
    Commands: string;
    FCursorPos: Integer;
    FItemIndex: Integer;
    procedure Drink(AItemIndex: Integer);
    procedure Drop(AItemIndex: Integer);
    procedure Read(AItemIndex: Integer);
    procedure Use(AItemIndex: Integer);
    procedure SetCursorPos(const Value: Integer);
    procedure SetItemIndex(const Value: Integer);
  public
    property CursorPos: Integer read FCursorPos write SetCursorPos;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    function KeyIDToInvItemID(AItemIndex: Integer): Integer;
    procedure Equip(AItemIndex: Integer; IsShowLog: Boolean = True);
    procedure UnEquip(AItemIndex: Integer; IsShowLog: Boolean = True);
    procedure KeyPress(var Key: Char); override;
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneItem: TSceneItem;

implementation

uses
  SysUtils,
  Trollhunter.Error,
  Trollhunter.Log,
  Trollhunter.Creatures,
  Trollhunter.Scenes,
  Dragonhunter.Scene.Inv,
  Dragonhunter.Item,
  Trollhunter.Graph,
  Trollhunter.Game,
  Trollhunter.Scene.Game,
  Dragonhunter.Color,
  Dragonhunter.Utils,
  Dragonhunter.Map,
  Trollhunter.Map.Tiles,
  Trollhunter.Lang,
  Trollhunter.Skill,
  Trollhunter.Item.Pattern,
  Dragonhunter.Terminal,
  Dragonhunter.Frame;

{ TSceneItem }

constructor TSceneItem.Create;
begin
  Icon := Graphics.TBitmap.Create;
  FMenuCount := 0;
  CursorPos := 0;
end;

destructor TSceneItem.Destroy;
begin
  Icon.Free;
  inherited;
end;

procedure TSceneItem.Equip(AItemIndex: Integer; IsShowLog: Boolean = True);
var
  LPatItemIndex, LItemIndex: Integer;
  // B: Boolean;
begin
  try
    LPatItemIndex := KeyIDToInvItemID(AItemIndex);
    { B := True;{((DungeonItems[V].MaxTough > 0)
      and (Creatures.PC.Inv.GetTough(I) > 0))
      or (DungeonItems[V].MaxTough = 0); }
    { for LItemIndex := 1 to 26 do
      if (ItemPatterns.Patterns[LPatItemIndex].Category = ItemPatterns.Patterns
      [KeyIDToInvItemID(LItemIndex)].Category) then
      UnEquip(LItemIndex); }

    // if (B and (DungeonItems[V].Category in WeapArmSet))
    // or (DungeonItems[V].Category in AmuRingSet)
    if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
      EquipmentCategories) and Creatures.Character.Inv.Equip(AItemIndex) then
    begin
      Creatures.Character.Prop.MinDamage := Creatures.Character.Prop.MinDamage +
        ItemPatterns.Patterns[LPatItemIndex].MinDamage;
      Creatures.Character.Prop.MaxDamage := Creatures.Character.Prop.MaxDamage +
        ItemPatterns.Patterns[LPatItemIndex].MaxDamage;
      Creatures.Character.Prop.Protect := Creatures.Character.Prop.Protect +
        ItemPatterns.Patterns[LPatItemIndex].Protect;
      Creatures.Character.Calc;

      if IsShowLog then
        Log.Add(Format(Language.GetLang(96),
          [Language.GetItemLang(ItemPatterns.Patterns[LPatItemIndex].ID)]));
      // You equip a %s.
      Scenes.Render;
    end;
  except
    on E: Exception do
      Error.Add('SceneItem.Equip', E.Message);
  end;
end;

procedure TSceneItem.UnEquip(AItemIndex: Integer; IsShowLog: Boolean = True);
begin
  try
    if Creatures.Character.Inv.UnEquip(AItemIndex) then
    begin
      Creatures.Character.Prop.MinDamage := Creatures.Character.Prop.MinDamage +
        ItemPatterns.Patterns[KeyIDToInvItemID(AItemIndex)].MinDamage;
      Creatures.Character.Prop.MaxDamage := Creatures.Character.Prop.MaxDamage +
        ItemPatterns.Patterns[KeyIDToInvItemID(AItemIndex)].MaxDamage;
      Creatures.Character.Prop.Protect := Creatures.Character.Prop.Protect +
        ItemPatterns.Patterns[KeyIDToInvItemID(AItemIndex)].Protect;
      Creatures.Character.Calc;

      if IsShowLog then
        Log.Add(Format(Language.GetLang(97),
          [Language.GetItemLang(ItemPatterns.Patterns
          [KeyIDToInvItemID(AItemIndex)].ID)]));
      // You unequip a %s.
      Scenes.Render;
    end;
  except
    on E: Exception do
      Error.Add('SceneItem.UnEquip', E.Message);
  end;
end;

procedure TSceneItem.KeyDown(var Key: Word; Shift: TShiftState);
var
  LPatItemIndex: Integer;
  K: Word;
  C: Char;
begin
  try
    LPatItemIndex := KeyIDToInvItemID(ItemIndex);
    case Key of
      27, 123:
        Scenes.Scene := SceneInv;
      38, 40:
        begin
          CursorPos := CursorPos + (Key - 39);
          CursorPos := ClampCycle(CursorPos, 0, FMenuCount - 1);
          Render;
        end;
      13:
        begin
          if (Length(Commands) > 0) then
          begin
            C := Commands[CursorPos + 1];
            K := ord(C);
            KeyDown(K, Shift);
            Exit;
          end;
        end;
      ord('W'):
        if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
          EquipmentCategories) then
        begin
          if not Creatures.Character.Inv.GetDoll(ItemIndex) then
            Equip(ItemIndex)
          else
            UnEquip(ItemIndex);
          SceneInv.RedrawPCIcon;
          Scenes.Scene := SceneInv;
        end;
      ord('U'):
        if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
          UseCategories) then
        begin
          Use(ItemIndex);
          Log.Apply;
          Game.Save;
          Scenes.Scene := SceneInv;
        end;
      ord('R'):
        if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
          ScrollCategories) then
        begin
          Read(ItemIndex);
          Log.Apply;
          Game.Save;
          Scenes.Scene := SceneGame;
        end;
      ord('Q'):
        if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
          PotionCategories) then
        begin
          Drink(ItemIndex);
          Log.Apply;
          Game.Save;
          Scenes.Scene := SceneGame;
        end;
      ord('D'):
        if Items.IsCategory(ItemPatterns.Patterns[LPatItemIndex].Category,
          DropCategories) and not Creatures.Character.Inv.GetDoll(ItemIndex)
        then
        begin
          Drop(ItemIndex);
          Log.Apply;
          Game.Save;
          Creatures.Character.Redraw;
          Scenes.Scene := SceneGame;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneItem.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneItem.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneItem.Render;
var
  Tileset: Graphics.TBitmap;
  P, I, T: Integer;
  ID: string;

  procedure Add(S: string);
  begin
    S := Trim(S);
    if (S = '') then
      Exit;
    Graph.Text.TextCenter(P, S);
    Inc(P);
  end;

  procedure AddMenu(S: string);
  begin
    with Graph.Surface.Canvas do
    begin
      if (CursorPos = FMenuCount) then
      begin
        Font.Color := cAcColor;
        Font.Style := [fsBold];
        Graph.RenderMenuLine(FMenuCount + P, Graph.CharHeight, False,
          50, cDkGray);
      end
      else
      begin
        Font.Color := cBgColor;
        Font.Style := [];
      end;
      Graph.Text.TextCenter((FMenuCount + P) + 1, S);
      Inc(FMenuCount);
    end;
  end;

  procedure AddCommand(C: Char; S: string);
  begin
    Graph.Text.BarOut(LowerCase(C), AnsiLowerCase(S), False);
    Commands := Commands + UpperCase(C);
    AddMenu(S);
  end;

  procedure RenderItemInfo(AItemIndex: Integer);
  const
    Effects = 'LIFE,MANA,FILL,ANTIDOTE,KEY,TELEPORT,SUMMON,' +
      'IDENTIFY,PORTAL,DISPEL,REPAIR,REPAIRALL,DETECTION';
    EffLangNums: array [0 .. 12] of Integer = (223, 224, 80, 79, 112, 272, 273,
      274, 275, 230, 270, 271, 276);
    Atributes = 'STRENGTH,DEXTERITY,INTELLIGENCE,PERCEPTION,SPEED';
  var
    LEffects, LAtributes: TArray<string>;
    J: Integer;
  begin
    with Graph.Surface.Canvas do
    begin
      Font.Color := cWhiteGre;
      with ItemPatterns.Patterns[AItemIndex] do
      begin
        // Effects
        LEffects := ExplodeString(Effects);
        for J := 0 to Length(LEffects) do
          if UpperCase(Trim(Script)) = UpperCase(Trim(LEffects[J])) then
            Add(Language.GetLang(EffLangNums[J]));
        // Atributes
        LAtributes := ExplodeString(Atributes);
        for J := 0 to Length(LAtributes) do
          if UpperCase(Trim(Script)) = UpperCase(Trim(LAtributes[J])) then
            Add(Format('%s +1.', [Language.GetLang(J + 15)]));
        // Misc
        if (UpperCase(Trim(Script)) = 'WIZARDEYE') then
          Add(Format('%s %d.', [Language.GetLang(115),
            Creatures.Character.TempSys.Power('WizardEye')]));
        // Repair
        { if (scRepair3 = SubCats) then
          Add(Format('%s 3.', [Language.GetLang(89)]));
          if (scRepair6 = SubCats) then
          Add(Format('%s 6.', [Language.GetLang(89)]));
          if (scRepair9 = SubCats) then
          Add(Format('%s 9.', [Language.GetLang(89)]));
          if (scRepair12 = SubCats) then
          Add(Format('%s 12.', [Language.GetLang(89)]));
          if (scRepair15 = SubCats) then
          Add(Format('%s 15.', [Language.GetLang(89)]));
          if (scRepair25 = SubCats) then
          Add(Format('%s 25.', [Language.GetLang(89)])); }
        // Life
        { if (scLife25 = SubCats) then
          Add(Format(Language.GetLang(81), [25]));
          if (scLife50 = SubCats) then
          Add(Format(Language.GetLang(81), [50]));
          if (scLife75 = SubCats) then
          Add(Format(Language.GetLang(81), [75]));
          if (scLife100 = SubCats) then
          Add(Format(Language.GetLang(81), [100]));
          if (scLife200 = SubCats) then
          Add(Format(Language.GetLang(81), [200])); }
        // Mana
        { if (scMana25 = SubCats) then
          Add(Format(Language.GetLang(82), [25]));
          if (scMana50 = SubCats) then
          Add(Format(Language.GetLang(82), [50]));
          if (scMana75 = SubCats) then
          Add(Format(Language.GetLang(82), [75]));
          if (scMana100 = SubCats) then
          Add(Format(Language.GetLang(82), [100]));
          if (scMana200 = SubCats) then
          Add(Format(Language.GetLang(82), [200])); }
      end;
      //
      Font.Color := cSkyBlue;
      if (ItemPatterns.Patterns[AItemIndex].MaxDamage > 0) then
        Add(Format('%s %d-%d', [Language.GetLang(32),
          ItemPatterns.Patterns[AItemIndex].MinDamage,
          ItemPatterns.Patterns[AItemIndex].MaxDamage]));
      if (ItemPatterns.Patterns[AItemIndex].Protect > 0) then
        Add(Format('%s %d', [Language.GetLang(33),
          ItemPatterns.Patterns[AItemIndex].Protect]));
      // Bonuses
      { Font.Color := cSkyBlue;
        if (DungeonItems[I].BonusStrength > 0) then
        Add(Format('%s %d', [Language.GetLang(15),
        DungeonItems[I].BonusStrength]));
        if (DungeonItems[I].BonusDexterity > 0) then
        Add(Format('%s %d', [Language.GetLang(16),
        DungeonItems[I].BonusDexterity]));
        if (DungeonItems[I].BonusIntelligence > 0) then
        Add(Format('%s %d', [Language.GetLang(17),
        DungeonItems[I].BonusIntelligence]));
        if (DungeonItems[I].BonusSpeed > 0) then
        Add(Format('%s %d', [Language.GetLang(19),
        DungeonItems[I].BonusSpeed]));
        if (DungeonItems[I].BonusLife > 0) then
        Add(Format('%s %d', [Language.GetLang(22), DungeonItems[I].BonusLife]));
        if (DungeonItems[I].BonusMana > 0) then
        Add(Format('%s %d', [Language.GetLang(23), DungeonItems[I].BonusMana])); }
      //
      Font.Color := cWhiteGre;
      if (ItemPatterns.Patterns[AItemIndex].ManaCost > 0) then
        Add(Format('%s -%d (%d/%d)', [Language.GetLang(23),
          ItemPatterns.Patterns[AItemIndex].ManaCost,
          Creatures.Character.Mana.Cur, Creatures.Character.Mana.Max]));
      { if (ItemPatterns.Patterns[I].NeedMagic > 0) then
        Add(Format('%s %d (%d)', [Language.GetLang(280),
        ItemPatterns.Patterns[I].NeedMagic, Skills.GetSkill('MAGIC').Level])); }
      //
      Font.Color := cSkyBlue;
      if (ItemPatterns.Patterns[AItemIndex].Weight > 0) then
        Add(Language.GetLang(42) + Items.GetWeight(AItemIndex));
      if (ItemPatterns.Patterns[AItemIndex].MaxTough > 0) then
      begin
        if (Creatures.Character.Inv.GetTough(ItemIndex) <= 0) then
          Font.Color := cRdRed;
        Add(Format('%s %d/%d', [Language.GetLang(40),
          Creatures.Character.Inv.GetTough(ItemIndex),
          ItemPatterns.Patterns[AItemIndex].MaxTough]));
      end;
    end;
  end;

  procedure Unidentified();
  begin
    Terminal.TextColor(cLtRed);
    Terminal.BoldFont;
    Add(Language.GetLang(382));
    Terminal.TextColor(cBgColor);
    Terminal.NormalFont;
  end;

begin
  Commands := '';
  FMenuCount := 0;
  Tileset := Graphics.TBitmap.Create;
  with Graph do
    try
      I := KeyIDToInvItemID(ItemIndex);
      ID := ItemPatterns.Patterns[I].ID;
      P := Height div CharHeight div 2 - 5;
      Clear(0);
      if (ItemPatterns.Patterns[I].Sprite = '') then
        Tileset.Handle := Windows.LoadBitmap(hInstance, PChar(ID))
      else
        Tileset.Handle := Windows.LoadBitmap(hInstance,
          PChar(ItemPatterns.Patterns[I].Sprite));
      BitmapFromTileset(Icon, Tileset, 0);
      Items.Colors(Icon, I);
      ScaleBmp(Icon, 64, 64);
      Icon.Transparent := True;
      with Surface.Canvas do
      begin
        Draw((Surface.Width div 2) - 32, ((P - 2) * CharHeight) - 64, Icon);
        Text.TitleOut(Language.GetItemLang(ItemPatterns.Patterns[I].ID), P - 1);
        Inc(P, 2);
        T := ItemPatterns.Patterns[I].ColorTag;
        if (T = 0) then
          RenderItemInfo(I)
        else
        begin
          if (ItemPatterns.Patterns[I].Category = 'SCROLL') then
            if Creatures.Character.Scrolls.IsDefined(T) then
              RenderItemInfo(I)
            else
              Unidentified();
          if (ItemPatterns.Patterns[I].Category = 'POTION') then
            if Creatures.Character.Potions.IsDefined(T) then
              RenderItemInfo(I)
            else
              Unidentified();
        end;
      end;
      Text.BarOut('esc', Language.GetLang(49), True);
      if Items.IsCategory(ItemPatterns.Patterns[I].Category, EquipmentCategories)
      then
        AddCommand('W', Language.GetLang(95));
      if Items.IsCategory(ItemPatterns.Patterns[I].Category, PotionCategories)
      then
        AddCommand('Q', Language.GetLang(93));
      if Items.IsCategory(ItemPatterns.Patterns[I].Category, ScrollCategories)
      then
        AddCommand('R', Language.GetLang(99));
      if Items.IsCategory(ItemPatterns.Patterns[I].Category, UseCategories) then
        AddCommand('U', Language.GetLang(98));
      if Items.IsCategory(ItemPatterns.Patterns[I].Category, DropCategories) and
        not Creatures.Character.Inv.GetDoll(ItemIndex) then
        AddCommand('D', Language.GetLang(90));
      Frame.Draw((Terminal.Width div 2) - 30, Terminal.Height div 2 -
        14, 60, 22);
      Render;
      Tileset.Free;
    except
      on E: Exception do
        Error.Add('SceneItem.Render', E.Message);
    end;
end;

function TSceneItem.KeyIDToInvItemID(AItemIndex: Integer): Integer;
begin
  Result := Items.ItemIndex(AItemIndex);
end;

procedure TSceneItem.Drop(AItemIndex: Integer);
var
  LItemIndex, LTough, LCount: Integer;
begin
  try
    if not(Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile
      in FloorSet + [tlOpenWoodChest, tlOpenBestChest, tlOpenBarrel]) then
      Exit;
    LTough := Creatures.Character.Inv.GetTough(AItemIndex);
    LItemIndex := KeyIDToInvItemID(AItemIndex);
    LCount := Creatures.Character.Inv.GetCount
      (ItemPatterns.Patterns[LItemIndex].ID);
    if Creatures.Character.Inv.Del(AItemIndex, LCount) then
    begin
      if (LCount = 1) then
      begin
        Log.Add(Format(Language.GetLang(91),
          [Language.GetItemLang(ItemPatterns.Patterns[LItemIndex].ID)]));
        Items.Add(Creatures.Character.Pos.X, Creatures.Character.Pos.Y,
          ItemPatterns.Patterns[LItemIndex].ID);
        with Items.Item[High(Items.Item)] do
        begin
          Prop.Tough := LTough;
          Count := 1;
        end;
      end
      else
      begin
        Log.Add(Format(Language.GetLang(92),
          [Language.GetItemLang(ItemPatterns.Patterns[LItemIndex].ID),
          LCount]));
        Items.Add(Creatures.Character.Pos.X, Creatures.Character.Pos.Y,
          ItemPatterns.Patterns[LItemIndex].ID);
        Items.Item[High(Items.Item)].Count := LCount;
      end;
    end;
  except
    on E: Exception do
      Error.Add('SceneItem.Drop', E.Message);
  end;
end;

procedure TSceneItem.Use(AItemIndex: Integer);
var
  LItemIndex: Integer;
begin
  try
    LItemIndex := KeyIDToInvItemID(AItemIndex);
    SceneInv.ItemUseID := ItemPatterns.Patterns[LItemIndex].ID;
    Scenes.Scene := SceneInv;
  except
    on E: Exception do
      Error.Add('SceneItem.Use', E.Message);
  end;
end;

procedure TSceneItem.Drink(AItemIndex: Integer);
var
  LItemIndex, LTag: Integer;
begin
  try
    LItemIndex := KeyIDToInvItemID(AItemIndex);
    with Creatures.Character do
      if Inv.Del(AItemIndex, 1) then
      begin
        LTag := ItemPatterns.Patterns[LItemIndex].ColorTag;
        Log.Add(Format(Language.GetLang(94),
          [Language.GetItemLang(ItemPatterns.Patterns[LItemIndex].ID)]));
        if (LTag > 0) and not Creatures.Character.Potions.IsDefined(LTag) then
        begin
          Creatures.Character.Potions.SetDefined(LTag);
          Log.Add(Language.GetLang(225) + ' ' +
            AnsiLowerCase(Language.GetItemLang(ItemPatterns.Patterns[LItemIndex]
            .ID)) + '.');
        end;
        Items.UseItem(LItemIndex, PotionCategories);
      end;
  except
    on E: Exception do
      Error.Add('SceneItem.Drink', E.Message);
  end;
end;

procedure TSceneItem.Read(AItemIndex: Integer);
var
  LItemIndex, LTag: Integer;
begin
  try
    LItemIndex := KeyIDToInvItemID(AItemIndex);
    with Creatures.Character do
    begin
      if (Mana.Cur >= ItemPatterns.Patterns[LItemIndex].ManaCost) then
      begin
        if Inv.Del(AItemIndex, 1) then
        begin
          LTag := ItemPatterns.Patterns[LItemIndex].ColorTag;
          Log.Add(Format(Language.GetLang(100),
            [Language.GetItemLang(ItemPatterns.Patterns[LItemIndex].ID)]));
          if (LTag > 0) and not Creatures.Character.Scrolls.IsDefined(LTag) then
          begin
            Creatures.Character.Scrolls.SetDefined(LTag);
            Log.Add(Language.GetLang(220) + ' ' +
              AnsiLowerCase(Language.GetItemLang(ItemPatterns.Patterns
              [LItemIndex].ID)) + '.');
          end;
          Mana.Dec(ItemPatterns.Patterns[LItemIndex].ManaCost);
          Items.UseItem(LItemIndex, ScrollCategories);
        end;
      end
      else
      begin
        Log.Add(Language.GetLang(67));
      end;
    end;
  except
    on E: Exception do
      Error.Add('SceneItem.Read', E.Message);
  end;
end;

procedure TSceneItem.SetCursorPos(const Value: Integer);
begin
  FCursorPos := Value;
end;

procedure TSceneItem.SetItemIndex(const Value: Integer);
begin
  FItemIndex := Value;
end;

initialization

SceneItem := TSceneItem.Create;

finalization

SceneItem.Free;

end.
