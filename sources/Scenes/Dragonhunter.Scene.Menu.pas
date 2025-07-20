unit Dragonhunter.Scene.Menu;

interface

uses
  Classes,
  Trollhunter.Scene;

type
  TSceneMenu = class(TScene)
  private
    Count, P: Integer;
    CursorPos: Integer;
    procedure MenuItem(S: string);
    procedure DrawCopyright;
    procedure DrawLogo;
  public
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneMenu: TSceneMenu;

implementation

uses
  Graphics,
  SysUtils,
  Dragonhunter.Terminal,
  Dragonhunter.Item,
  Dragonhunter.Color,
  Dragonhunter.Scene.Name,
  Trollhunter.Scenes,
  Dragonhunter.MainForm,
  Trollhunter.Scene.Records,
  Trollhunter.Creatures,
  Trollhunter.Game,
  Trollhunter.Scene.Load,
  Trollhunter.Error,
  Trollhunter.Utils,
  Dragonhunter.Scene.Settings,
  Trollhunter.Lang,
  Trollhunter.Settings,
  Trollhunter.Creature,
  Dragonhunter.Map,
  Trollhunter.Race,
  Trollhunter.Creature.Pattern,
  Dragonhunter.Map.Pattern,
  Trollhunter.Item.Pattern,
  Dragonhunter.Frame;

{ TSceneMenu }

procedure TSceneMenu.DrawCopyright;
var
  I, W: Integer;
  S, T: string;
begin
  S := '';
  if ParamDebug then
  begin
    for I := 1 to ParamCount do
      S := S + ParamStr(I) + #32;
    S := Trim(S);
  end;
  Terminal.NormalFont;
  Terminal.TextColor(0);
  if ParamDebug and (S <> '') then
  begin
    Terminal.TextColor(cRdGray);
    T := Format('[Races: %d, Items: %d, Enemies: %d, Maps: %d]',
      [Races.RaceList.Count, ItemPatterns.Patterns.Count,
      CreaturePatterns.Patterns.Count, MapPatterns.Patterns.Count]);
    W := Terminal.TextWidth(T);
    Terminal.TextOut((Terminal.Width div 2) - (W div 2),
      Terminal.Height - 3, T);
    S := '[' + S + ']';
    W := Terminal.TextWidth(S);
    Terminal.TextOut((Terminal.Width div 2) - (W div 2),
      Terminal.Height - 4, S);
  end;
end;

constructor TSceneMenu.Create;
begin
  CursorPos := 0;
  Count := 5;
end;

destructor TSceneMenu.Destroy;
begin

  inherited;
end;

procedure TSceneMenu.KeyDown(var Key: Word; Shift: TShiftState);
var
  S: TSettings;
begin
  try
    case Key of
      38, 40:
        begin
          CursorPos := CursorPos + (Key - 39);
          CursorPos := ClampCycle(CursorPos, 0, Count - 1);
          Render;
        end;
      13:
        case CursorPos of
          0:
            begin
              with Creatures do
                if (Character.Name = '') then
                begin
                  S := TSettings.Create;
                  try
                    Character.Name := S.Read('Settings', 'LastName', '');
                  finally
                    S.Free;
                  end;
                end;
              Scenes.Scene := SceneName;
            end;
          1:
            begin
              SceneLoad.ReadSaveDir;
              Scenes.Scene := SceneLoad;
            end;
          2:
            begin
              Scenes.Scene := SceneSettings;
            end;
          3:
            begin
              Scenes.Scene := SceneRecords;
            end;
          4:
            MainForm.Close;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneMenu.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneMenu.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneMenu.MenuItem(S: string);
begin
  try
    if (CursorPos = P) then
    begin
      Terminal.TextColor(cAcColor);
      Terminal.BoldFont;
      Terminal.MenuLine(Terminal.Width div 2 - 27, Terminal.Height div 2 -
        1 + P, 54);
    end
    else
    begin
      Terminal.TextColor(cBGColor);
      Terminal.NormalFont;
    end;
    Terminal.TextOut((Terminal.Width div 2) - (Terminal.TextWidth(S) div 2),
      P + (Terminal.Height div 2 - 1), S);
    Inc(P);
    Terminal.TextColor(cBGColor);
    Terminal.NormalFont;
  except
    on E: Exception do
      Error.Add('SceneMenu.MenuItem', E.Message);
  end;
end;

procedure TSceneMenu.Render;
var
  I, N: Integer;
begin
  inherited;
  try
    P := 0;
    Terminal.Clear;
    for I := 0 to Count - 1 do
    begin
      if (I < Count - 1) then
        N := I
      else
        N := 9;
      MenuItem(Language.GetLang(N));
    end;
    IsGame := False;
    DrawLogo();
    DrawCopyright();
    Terminal.TextColor(cAcColor);
    Frame.Draw((Terminal.Width div 2) - 30, Terminal.Height div 2 - 3, 60, 9);
    Terminal.Render;
  except
    on E: Exception do
      Error.Add('SceneMenu.Render', E.Message);
  end;
end;

procedure TSceneMenu.DrawLogo;
var
  X, Y, H: Word;
const
  Logo: array [0 .. 17] of string =
    (' ______________                                                                                  ',
    '| ____  . ____ |              ___ ___ ___                               ___                       ',
    '|/    |. |    \|              \ .\\ .\\. \                              \ .\                      ',
    '      | .|                    | .||. || .|                              | .|                      ',
    '      |. |____  ___   ______  |. || .||. | ____ ____   ____ ____  ____  |. |__   ______ ____  ___ ',
    '      |::|\:::|/:::\ /::::::\ |::||::||::|/::::\\:::\  \:::|\:::|/::::\ |:::::| /::::::\\:::|/:::\',
    '      |xx| |xx|  \x||xx/  \xx||xx||xx||xx|   \xx\|xx|   |xx| |xx|   \xx\|xx|   |xx/__\xx||xx|  \x|',
    '      |xx| |xx|     |xx|  |xx||xx||xx||xx|   |xx||xx|   |xx| |xx|   |xx||xx|   |xx|xxxxx||xx|     ',
    '      |XX| |XX|     |XX\__/XX||XX||XX||XX|   |XX||XX\___|XX| |XX|   |XX||XX\___|XX\_____ |XX|     ',
    '      |XX| \XX\      \XXXXXX/ \XX\\XX\\XX\   \XX\ \XXXX/|XX\ \XX\   \XX\ \XXXX/ \XXXXXX/ \XX\     ',
    '      |XX|                                                                                        ',
    '      |XX|                                                                                        ',
    '      |XX|                                                                                        ',
    '     _|XX|                                                                                        ',
    '     \XXX|                                                                                        ',
    '      \XX|                                                                                        ',
    '       \X|                                                                                        ',
    '        \|                                                                                        ');

begin

end;

initialization

SceneMenu := TSceneMenu.Create;

finalization

SceneMenu.Free;

end.
