unit Dragonhunter.Item.Script;

interface

type
  TItemScript = class(TObject)
  public
    procedure DoCommands(const AScript: string);
  end;

implementation

uses
  SysUtils,
  Trollhunter.Creatures,
  Trollhunter.Item.Pattern,
  Dragonhunter.Item,
  Trollhunter.Formulas,
  Dragonhunter.Utils,
  Dragonhunter.Effect;

{ TItemScript }

type
  TCommand = record
    ScriptCommand: string;
    Effect: TEffectEnum;
  end;

const
  Commands: array [0 .. 2] of TCommand = (
    //
    (ScriptCommand: 'REPAIR'; Effect: efPoison),
    //
    (ScriptCommand: 'LIFE'; Effect: efLife),
    //
    (ScriptCommand: 'MANA'; Effect: efMana)
    //
    );

procedure TItemScript.DoCommands(const AScript: string);
var
  LScriptCommand: TArray<string>;
  I, J, LValue: Integer;
begin
  LScriptCommand := AScript.Split([',']);
  for I := 0 to Length(LScriptCommand) - 1 do
    with Creatures.Character do
      with TempSys do
      begin
        //
        for J := 0 to Length(Commands) - 1 do
        begin
          if (LScriptCommand[I].StartsWith(Commands[J].ScriptCommand + #32))
          then
          begin
            LValue := GetStrValue(#32, LScriptCommand[I]).ToInteger;
            Add(UpperCase(EffectName[Commands[J].Effect]), LValue, 10);
          end;
        end;
        //
        if ('LIFE' = LScriptCommand[I]) then
          Life.SetToMax;
        if ('MANA' = LScriptCommand[I]) then
          Mana.SetToMax;
        if ('FILL' = LScriptCommand[I]) then
          Fill;
        if ('ANTIDOTE' = LScriptCommand[I]) then
          ClearVar('Poison');
        if ('KEY' = LScriptCommand[I]) then
          Items.Key;
        if ('TELEPORT' = LScriptCommand[I]) then
          Creatures.Teleport(False);
        if ('SUMMON' = LScriptCommand[I]) then
          Creatures.Summon;
        if ('IDENTIFY' = LScriptCommand[I]) then
          Items.Identify;
        if ('PORTAL' = LScriptCommand[I]) then
          Portal;
        if ('WIZARDEYE' = LScriptCommand[I]) then
          Add('WizardEye', GetWizardEyePower, Mana.Max);
        if ('DISPEL' = LScriptCommand[I]) then
          Clear;
        if ('REPAIRALL' = LScriptCommand[I]) then
          Items.RepairAll;
        if ('STRENGTH' = LScriptCommand[I]) then
          AddStrength;
        if ('DEXTERITY' = LScriptCommand[I]) then
          AddDexterity;
        if ('INTELLIGENCE' = LScriptCommand[I]) then
          AddIntelligence;
        if ('PERCEPTION' = LScriptCommand[I]) then
          AddPerception;
        if ('SPEED' = LScriptCommand[I]) then
          AddSpeed;
      end;
end;

end.
