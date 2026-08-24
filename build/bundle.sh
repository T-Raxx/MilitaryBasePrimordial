#!/usr/bin/env bash
# bundler: embebe PrimordialUI + concatena modulos -> dist/MilitaryBase.lua (un solo loadstring)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUI="$ROOT/../PrimordialUI/dist/PrimordialUI.lua"
OUT="$ROOT/dist/MilitaryBase.lua"
# orden importa: Registry antes de los modulos que lo usan; finalize al final
MODULES=(bootstrap tabs core/Registry services/EntityService services/VelocityService services/AimService services/SpoofService modules/combat/InstantReload modules/combat/Aimbot modules/combat/FireBlink modules/combat/TargetStrafe modules/combat/Autofire modules/combat/TargetMelee modules/combat/SilentAim modules/visuals/ESP modules/tycoon/AutoBuy modules/tycoon/CrateFarm modules/tycoon/SoldierFarm modules/misc/ClientDesync modules/misc/About finalize)
mkdir -p "$ROOT/dist"
{
  echo "-- MilitaryBasePrimordial bundle (auto-generado) --"
  echo "local Lib = (function()"
  cat "$PUI"
  printf '\nend)()\n'
  echo "local U = { Library = Lib, Services = {}, Tabs = {}, Registry = nil, Flags = Lib.Flags }"
  for m in "${MODULES[@]}"; do
    if [ -f "$ROOT/$m.lua" ]; then
      echo "-- ==== $m ===="
      echo "do local __m = (function()"
      cat "$ROOT/$m.lua"
      printf '\nend)(); __m(U) end\n'
    else
      echo "-- MISSING module: $m.lua" >&2
    fi
  done
  echo "return U"
} > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") lines)"

# sync al workspace del executor (Potassium) para readfile live
POT="$HOME/AppData/Local/Potassium/workspace/MilitaryBasePrimordial/dist"
if [ -d "$(dirname "$(dirname "$POT")")" ]; then
  mkdir -p "$POT" && cp "$OUT" "$POT/MilitaryBase.lua" && echo "synced -> Potassium"
fi
