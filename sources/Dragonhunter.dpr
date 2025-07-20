program Dragonhunter;

uses
  Windows,
  Forms,
  Dragonhunter.MainForm in 'Forms\Dragonhunter.MainForm.pas' {MainForm},
  Trollhunter.Scenes in 'Scenes\Trollhunter.Scenes.pas',
  Trollhunter.Scene in 'Scenes\Trollhunter.Scene.pas',
  Trollhunter.Scene.BaseMenu in 'Scenes\Trollhunter.Scene.BaseMenu.pas',
  Dragonhunter.Scene.Menu in 'Scenes\Dragonhunter.Scene.Menu.pas',
  Trollhunter.Scene.BaseGame in 'Scenes\Trollhunter.Scene.BaseGame.pas',
  Trollhunter.Scene.Game in 'Scenes\Trollhunter.Scene.Game.pas',
  Trollhunter.Scene.About in 'Scenes\Trollhunter.Scene.About.pas',
  Trollhunter.Scene.Inv in 'Scenes\Trollhunter.Scene.Inv.pas',
  Dragonhunter.Scene.Name in 'Scenes\Dragonhunter.Scene.Name.pas',
  Trollhunter.Scene.Records in 'Scenes\Trollhunter.Scene.Records.pas',
  Trollhunter.Scene.Load in 'Scenes\Trollhunter.Scene.Load.pas',
  Trollhunter.Scene.Items in 'Scenes\Trollhunter.Scene.Items.pas',
  Dragonhunter.Scene.LevelUp in 'Scenes\Dragonhunter.Scene.LevelUp.pas',
  Dragonhunter.Scene.Item in 'Scenes\Dragonhunter.Scene.Item.pas',
  Trollhunter.Scene.Char in 'Scenes\Trollhunter.Scene.Char.pas',
  Dragonhunter.Scene.Settings in 'Scenes\Dragonhunter.Scene.Settings.pas',
  Trollhunter.Scene.Intro in 'Scenes\Trollhunter.Scene.Intro.pas',
  Trollhunter.Scene.Statistics in 'Scenes\Trollhunter.Scene.Statistics.pas',
  Trollhunter.Scene.Help in 'Scenes\Trollhunter.Scene.Help.pas',
  Trollhunter.Scene.Race in 'Scenes\Trollhunter.Scene.Race.pas',
  Trollhunter.Creatures in 'Trollhunter.Creatures.pas',
  Trollhunter.Graph in 'Trollhunter.Graph.pas',
  Trollhunter.Craft in 'Trollhunter.Craft.pas',
  Dragonhunter.Map in 'Dragonhunter.Map.pas',
  Dragonhunter.Utils in 'Dragonhunter.Utils.pas',
  Dragonhunter.Item in 'Dragonhunter.Item.pas',
  Trollhunter.Trap in 'Trollhunter.Trap.pas',
  Dragonhunter.Script in 'Dragonhunter.Script.pas',
  Trollhunter.Map.Tiles in 'Trollhunter.Map.Tiles.pas',
  Trollhunter.Screenshot in 'Trollhunter.Screenshot.pas',
  Trollhunter.Log in 'Trollhunter.Log.pas',
  Trollhunter.Game in 'Trollhunter.Game.pas',
  Trollhunter.Scores in 'Trollhunter.Scores.pas',
  Dragonhunter.Color in 'Dragonhunter.Color.pas',
  Trollhunter.Name in 'Trollhunter.Name.pas',
  Trollhunter.Map.Generator in 'Trollhunter.Map.Generator.pas',
  Dragonhunter.AStar in 'Dragonhunter.AStar.pas',
  Trollhunter.Error in 'Trollhunter.Error.pas',
  Trollhunter.Inv in 'Trollhunter.Inv.pas',
  Trollhunter.Projectiles in 'Trollhunter.Projectiles.pas',
  Trollhunter.TempSys in 'Trollhunter.TempSys.pas',
  Trollhunter.Decorator in 'Trollhunter.Decorator.pas',
  Trollhunter.Settings in 'Trollhunter.Settings.pas',
  Trollhunter.Lang in 'Trollhunter.Lang.pas',
  Trollhunter.Light in 'Trollhunter.Light.pas',
  Dragonhunter.Effect in 'Dragonhunter.Effect.pas',
  Trollhunter.Look in 'Trollhunter.Look.pas',
  Dragonhunter.Resources in 'Dragonhunter.Resources.pas',
  Trollhunter.Time in 'Trollhunter.Time.pas',
  Trollhunter.Race in 'Trollhunter.Race.pas',
  Trollhunter.Skill in 'Trollhunter.Skill.pas',
  Dragonhunter.Entity in 'Dragonhunter.Entity.pas',
  Dragonhunter.Bar in 'Dragonhunter.Bar.pas',
  Dragonhunter.MiniMap in 'Dragonhunter.MiniMap.pas',
  Trollhunter.CustomMap in 'Trollhunter.CustomMap.pas',
  Dragonhunter.Item.Random in 'Dragonhunter.Item.Random.pas',
  Dragonhunter.Character in 'Dragonhunter.Character.pas',
  Dragonhunter.BaseCreature in 'Dragonhunter.BaseCreature.pas',
  Trollhunter.Creature in 'Trollhunter.Creature.pas',
  Trollhunter.Enemy in 'Trollhunter.Enemy.pas',
  Trollhunter.Formulas in 'Trollhunter.Formulas.pas',
  Trollhunter.GlobalMap in 'Trollhunter.GlobalMap.pas',
  Trollhunter.Statistics in 'Trollhunter.Statistics.pas',
  Trollhunter.Zip in 'Trollhunter.Zip.pas',
  Trollhunter.Town in 'Trollhunter.Town.pas',
  Trollhunter.Creature.Pattern in 'Trollhunter.Creature.Pattern.pas',
  Trollhunter.Item.Pattern in 'Trollhunter.Item.Pattern.pas',
  Dragonhunter.Item.Script in 'Dragonhunter.Item.Script.pas',
  Dragonhunter.Item.Default in 'Dragonhunter.Item.Default.pas',
  Dragonhunter.Terminal in 'Dragonhunter.Terminal.pas',
  Dragonhunter.Wander in 'Dragonhunter.Wander.pas',
  Dragonhunter.Frame in 'Dragonhunter.Frame.pas',
  Dragonhunter.Map.Pattern in 'Dragonhunter.Map.Pattern.pas',
  Dragonhunter.Item.Level in 'Dragonhunter.Item.Level.pas';

{$R *.res}

var
  UniqueMapping: THandle;

begin
  UniqueMapping := CreateFileMapping($FFFFFFFF, nil, PAGE_READONLY, 0, 32,
    'm6gh7jq2lb6mbghsdhgksakbrjtvqm7lsrnuaiopfrwchmaltdr45');
  if UniqueMapping = 0 then
    Halt
  else if GetLastError = ERROR_ALREADY_EXISTS then
    Halt;
  Application.Initialize;
  Application.Title := 'Dragonhunter';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.
