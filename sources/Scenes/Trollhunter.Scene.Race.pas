unit Trollhunter.Scene.Race;

interface

uses
  Classes,
  Graphics,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseMenu;

type
  TSceneRace = class(TSceneBaseMenu)
  private
    CursorPos: Integer;
    function GetAtrValue(A: Byte): Integer;
    function GetRaceDescription(ARaceIndex: Integer): string;
  public
    procedure MakePC(I: Byte = 0);
    procedure Render(); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneRace: TSceneRace;

implementation

uses
  Windows,
  SysUtils,
  Types,
  Trollhunter.Graph,
  Trollhunter.Error,
  Trollhunter.Scene.Game,
  Trollhunter.Lang,
  Trollhunter.Creatures,
  Dragonhunter.MainForm,
  Trollhunter.Scenes,
  Dragonhunter.Color,
  Trollhunter.Scene.Inv,
  Trollhunter.Race,
  Trollhunter.Utils,
  Dragonhunter.Item,
  Trollhunter.Skill,
  Trollhunter.Item.Pattern;

{ TSceneRace }

constructor TSceneRace.Create;
begin
  inherited Create(4);
  CursorPos := 1;
end;

destructor TSceneRace.Destroy;
begin

  inherited;
end;

function TSceneRace.GetAtrValue(A: Byte): Integer;
begin
  Result := 0;
  case A of
    1:
      Result := Creatures.Character.Prop.Strength;
    2:
      Result := Creatures.Character.Prop.Dexterity;
    3:
      Result := Creatures.Character.Prop.Intelligence;
    4:
      Result := Creatures.Character.Prop.Perception;
    5:
      Result := Creatures.Character.Prop.Speed;
  end;
end;

procedure TSceneRace.KeyDown(var Key: Word; Shift: TShiftState);
var
  LRaceIndex: Byte;
  K: Word;
begin
  inherited;
  try
    case Key of
      38, 40:
        begin
          if (Races.RaceList.Count > 0) then
          begin
            CursorPos := CursorPos + (Key - 39);
            CursorPos := ClampCycle(CursorPos, 1, Races.RaceList.Count);
            MakePC(CursorPos - 1);
            Render;
          end;
        end;
      13:
        begin
          if (Races.RaceList.Count > 0) then
          begin
            K := (ord('A') + CursorPos) - 1;
            KeyDown(K, Shift);
          end;
        end;
      ord('A') .. ord('Z'):
        begin
          LRaceIndex := Key - (ord('A'));
          if (LRaceIndex < Races.RaceList.Count) then
          begin
            Creatures.Character.Race := LRaceIndex;
            Graph.Messagebar.Add(Format(Language.GetLang(20),
              [Creatures.Character.Name, MainForm.Caption]));
            Creatures.Character.Redraw;
            Scenes.Scene := SceneGame;
          end;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneRace.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneRace.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneRace.MakePC(I: Byte);
var
  J: Integer;
begin
  try
    Creatures.Character.Clear;
    // Equipment
    for J := 0 to Races.RaceList[I].Equipment.Count - 1 do
    begin
      Items.AddAndEquip(Races.RaceList[I].Equipment[J], 1);
    end;
    // Skills
    for J := 0 to Races.RaceList[I].Skills.Count - 1 do
    begin
      Skills.AddLevel(Races.RaceList[I].Skills[J], 10);
    end;

    // Items.Add('SMITH');
    // Items.Add('MINIOILPOTION', 3);
    Items.Add('MINILIFEPOTION', 3);
    Items.Add('MINIMANAPOTION', 3);

    // Items.Add('POTIONA', 5);
    // Items.Add('POTIONB', 5);
    // Items.Add('POTIONC', 5);
    // Items.Add('POTIOND', 5);
    // Items.Add('POTIONE', 5);
    // Items.Add('POTIONF', 5);
    // Items.Add('POTIONG', 5);
    Items.Add('POTIONH', 5);

    // Items.Add('SCROLLA', 5);
    // Items.Add('SCROLLB', 5);
    // Items.Add('SCROLLC', 5);
    // Items.Add('SCROLLD', 5);
    Items.Add('SCROLLE', 3);
    // Items.Add('SCROLLF', 5);
    // Items.Add('SCROLLG', 5);
    // Items.Add('SCROLLH', 5);
    Items.Add('SCROLLI', 3);

    // Items.Add('TAMARILIS', 12);
    Items.Add('KEY', 7);

    Creatures.Character.Prop.Strength := Creatures.Character.Prop.Strength +
      Races.RaceList[I].Strength;
    Creatures.Character.Prop.Dexterity := Creatures.Character.Prop.Dexterity +
      Races.RaceList[I].Dexterity;
    Creatures.Character.Prop.Intelligence :=
      Creatures.Character.Prop.Intelligence + Races.RaceList[I].Intelligence;
    Creatures.Character.Prop.Perception := Creatures.Character.Prop.Perception +
      Races.RaceList[I].Perception;
    Creatures.Character.Prop.Speed := Creatures.Character.Prop.Speed +
      Races.RaceList[I].Speed;
    Creatures.Character.Calc;
    Creatures.Character.Fill;
  except
    on E: Exception do
      Error.Add('SceneRace.MakePC', E.Message);
  end;
end;

function TSceneRace.GetRaceDescription(ARaceIndex: Integer): string;
const
  L1 = 1;
  L2 = 4;
begin
  // Begin race description
  Result := Language.GetLang(Races.RaceList[ARaceIndex].BeginDescr);
  // Strength
  if Races.RaceList[ARaceIndex].Strength >= L2 then
    Result := Result + ' ' + Language.GetLang(324)
  else if Races.RaceList[ARaceIndex].Strength > L1 then
    Result := Result + ' ' + Language.GetLang(321)
  else if Races.RaceList[ARaceIndex].Strength <= -L2 then
    Result := Result + ' ' + Language.GetLang(325)
  else if Races.RaceList[ARaceIndex].Strength < -L1 then
    Result := Result + ' ' + Language.GetLang(322)
  else
    Result := Result + ' ' + Language.GetLang(323);
  // Dexterity
  if Races.RaceList[ARaceIndex].Dexterity >= L2 then
    Result := Result + ' ' + Language.GetLang(329)
  else if Races.RaceList[ARaceIndex].Dexterity > L1 then
    Result := Result + ' ' + Language.GetLang(326)
  else if Races.RaceList[ARaceIndex].Dexterity <= -L2 then
    Result := Result + ' ' + Language.GetLang(330)
  else if Races.RaceList[ARaceIndex].Dexterity < -L1 then
    Result := Result + ' ' + Language.GetLang(327)
  else
    Result := Result + ' ' + Language.GetLang(328);
  // Intelligence
  if Races.RaceList[ARaceIndex].Intelligence >= L2 then
    Result := Result + ' ' + Language.GetLang(334)
  else if Races.RaceList[ARaceIndex].Intelligence > L1 then
    Result := Result + ' ' + Language.GetLang(331)
  else if Races.RaceList[ARaceIndex].Intelligence <= -L2 then
    Result := Result + ' ' + Language.GetLang(335)
  else if Races.RaceList[ARaceIndex].Intelligence < -L1 then
    Result := Result + ' ' + Language.GetLang(332)
  else
    Result := Result + ' ' + Language.GetLang(333);
  // Perception
  // End race description
  Result := Result + ' ' + Language.GetLang
    (Races.RaceList[ARaceIndex].EndDescr);
end;

procedure TSceneRace.Render;
var
  T, I, J, Y, H, L, K, LRaceIndex, R, V, U: Integer;
  F, S, D, M, Q: string;
  A: ShortInt;
  LSkillIdent: string;
begin
  inherited;
  try
    LRaceIndex := CursorPos - 1;
    T := ((Graph.Surface.Width div 5) div Graph.CharWidth);
    with Graph.Surface.Canvas do
    begin
      for I := 0 to Races.RaceList.Count - 1 do
      begin
        if (I > 25) then
          Break;
        Y := (I + 3) * Graph.CharHeight;
        S := Chr(I + 97) + '.';
        CursorPos := Clamp(CursorPos, 1, Races.RaceList.Count);
        if (CursorPos = I + 1) then
        begin
          Font.Style := [fsBold];
          Font.Color := cAcColor;
          Graph.RenderMenuLine(I + 3, 0, True, 20, cDkGray);
        end
        else
        begin
          Font.Style := [];
          Font.Color := cBgColor;
        end;
        TextOut((Graph.CharWidth * 3) - TextWidth(S), Y, S);
        TextOut(Graph.CharWidth * 3, Y,
          Language.GetLang(Races.RaceList[I].Name));
        Font.Style := [];
        Font.Color := cAcColor;
        Graph.Text.DrawAll(T, 3, Round(T * 2.5),
          GetRaceDescription(LRaceIndex));
      end;
      Font.Style := [];
      if (Races.RaceList.Count > 0) then
      begin
        Font.Color := cDkYellow;
        Graph.Text.DrawOut(1, 2, '#');
        Graph.Text.DrawOut(3, 2, Language.GetLang(180));
        Graph.Text.TextCenter(2, Language.GetLang(320));
      end;
      H := Races.RaceList.Count + 5;
      Font.Style := [fsBold];
      Q := Creatures.Character.Name + ':';
      Graph.Text.DrawOut(T, H - 1, Q);
      M := '';
      for I := 1 to Length(Q) do
        M := M + '-';
      Graph.Text.DrawOut(T, H, M);
      Font.Style := [];
      { L := 0;
        for I := 1 to 4 do
        begin
        if (Length(GetLang(I + 14)) > L) then
        L := Length(GetLang(I + 14));
        end; }
      L := T;
      for I := 1 to 5 do
      begin
        D := '';
        S := Language.GetLang(I + 14) + ': ' + IntToStr(GetAtrValue(I));
        Font.Color := cBgColor;
        Graph.Text.DrawOut(L, H + I, S);
        A := 0;
        case I of
          1:
            A := Races.RaceList[LRaceIndex].Strength;
          2:
            A := Races.RaceList[LRaceIndex].Dexterity;
          3:
            A := Races.RaceList[LRaceIndex].Intelligence;
          4:
            A := Races.RaceList[LRaceIndex].Perception;
          5:
            A := Races.RaceList[LRaceIndex].Speed;
        end;
        if (A > 0) then
        begin
          D := ' (+' + IntToStr(A) + ')';
          Font.Color := cRdBlue;
        end;
        if (A < 0) then
        begin
          D := #32 + '(' + IntToStr(A) + ')';
          Font.Color := cRdRed;
        end;
        K := L + Length(S);
        Graph.Text.DrawOut(K, H + I, D);
        U := I + 1;
      end;
      //
      Font.Color := cRdRed;;
      Graph.Text.DrawOut(T, H + U + 1, Format('%s: %d/%d',
        [Language.GetLang(22), Creatures.Character.Life.Max,
        Creatures.Character.Life.Max]));
      Font.Color := cRdBlue;
      Graph.Text.DrawOut(T, H + U + 2, Format('%s: %d/%d',
        [Language.GetLang(23), Creatures.Character.Mana.Max,
        Creatures.Character.Mana.Max]));
      Font.Color := cDkYellow;
      Graph.Text.DrawOut(T, H + U + 3, Format('%s: %d-%d',
        [Language.GetLang(32), Creatures.Character.Prop.MinDamage,
        Creatures.Character.Prop.MaxDamage]));
      Font.Color := cDkYellow;
      Graph.Text.DrawOut(T, H + U + 4, Format('%s: %d', [Language.GetLang(33),
        Creatures.Character.Prop.Protect]));

      R := 0;
      Font.Style := [fsBold];
      Q := Language.GetLang(200) + ':';
      Graph.Text.DrawOut(T * 2, H - 1, Q);
      M := '';
      for I := 1 to Length(Q) do
        M := M + '-';
      Graph.Text.DrawOut(T * 2, H, M);
      Font.Style := [];

      Font.Color := cDkYellow;
      for J := 0 to Races.RaceList[LRaceIndex].Skills.Count - 1 do
      begin
        LSkillIdent := Races.RaceList[LRaceIndex].Skills[J];
        Graph.Text.DrawOut(T * 2, H + J + 1,
          Language.GetLang(Skills.GetSkill(LSkillIdent).Name) + ': ' +
          IntToStr(Skills.GetSkill(LSkillIdent).Level));
      end;
      R := 0;
      Font.Style := [fsBold];
      Q := Language.GetLang(25) + ':';
      Graph.Text.DrawOut(T * 3, H - 1, Q);
      M := '';
      for I := 1 to Length(Q) do
        M := M + '-';
      Graph.Text.DrawOut(T * 3, H, M);
      Font.Style := [];
      for J := 1 to Creatures.Character.Inv.Count do
      begin
        Inc(R);
        Font.Color := cDkYellow;
        V := Items.ItemIndex(J);
        if Creatures.Character.Inv.GetDoll(J) then
          Font.Style := [fsBold]
        else
          Font.Style := [];
        if (Creatures.Character.Inv.GetCount(J) > 1) then
          F := ' (' + IntToStr(Creatures.Character.Inv.GetCount(J)) + 'x)'
        else
          F := '';
        Graph.Text.DrawText(T * 3, H + R,
          Language.GetItemLang(ItemPatterns.Patterns[V].ID) + F +
          Items.GetDollText(J, V));
      end;
      //
      if (Races.RaceList.Count = 1) then
        Graph.Text.BarOut('a', Language.GetLang(181), False)
      else if (Races.RaceList.Count > 1) then
        Graph.Text.BarOut('a-' + Chr(96 + Races.RaceList.Count),
          Language.GetLang(181), False);
      //
      Creatures.Character.Race := LRaceIndex;
      SceneInv.RedrawPCIcon;
      Draw((L * Graph.CharWidth) - 72, (H + 1) * Graph.CharHeight,
        SceneInv.Hero);
    end;
    Graph.Render;
  except
    on E: Exception do
      Error.Add('SceneRace.Render', E.Message);
  end;
end;

initialization

SceneRace := TSceneRace.Create;

finalization

SceneRace.Free;

end.
