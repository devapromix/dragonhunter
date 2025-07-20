unit Trollhunter.Trap;

interface

uses
  Dragonhunter.Entity;

type
  TBaseTrap = class(TEntity)
  private

  public

  end;

type
  TTrap = class(TBaseTrap)
  private
    procedure Miss;
    procedure Damage(ADamage: Integer);
  public
    procedure Fire;
    procedure Lightning;
  end;

implementation

uses
  SysUtils,
  Dragonhunter.Map,
  Trollhunter.Graph,
  Trollhunter.Creatures,
  Dragonhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Lang,
  Trollhunter.Decorator,
  Trollhunter.Projectiles;

procedure TTrap.Fire;
var
  D: Integer;
begin
  if (Map.Level > 0) then
  begin
    D := (Rand(1, Map.Level * 3) *
      (100 - Creatures.Character.Prop.Protect)) div 100;
    if (D > 0) then
      Damage(D)
    else
      Miss;
  end;
end;

procedure TTrap.Lightning;
var
  D: Integer;
begin
  if (Map.Level > 0) then
  begin
    D := (Rand(1, Map.Level * 5) *
      (100 - Creatures.Character.Prop.Protect)) div 100;
    if (D > 0) then
      Damage(D)
    else
      Miss;
  end;
end;

procedure TTrap.Miss;
begin
  Log.Add(Language.GetLang(78));
end;

procedure TTrap.Damage(ADamage: Integer);
begin
  if (ADamage < 0) then
    ADamage := 0;
  with TAnimNumber.Create(-ADamage) do
    Free;
  Creatures.Character.Life.Dec(ADamage);
  Log.Add(Format(Language.GetLang(77), [ADamage]));
end;

end.
