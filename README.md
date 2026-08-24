# MilitaryBasePrimordial

Cheat suite para **Base Militar Tycoon** (place `23380021`) sobre [PrimordialUI](https://github.com/T-Raxx/PrimordialUI).

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/T-Raxx/MilitaryBasePrimordial/main/dist/MilitaryBase.lua"))()
```

> Repo privado: para que el `loadstring` pueda leer el raw, el repo debe ser público **o** usar un token/proxy en la URL.

## Features

**Combat**
- InstantReload — `Configuration.ReloadTime=0` en todas las armas
- Aimbot — camera/mouse, auto-predict (`dist/BulletSpeed`), FOV-gate
- Autofire — `tool:Activate()` (full-auto safe) o MouseEvent directo
- Target Strafe — orbita al target por desync (Normal/Random XYZ/Behind/Spiral/Inside)
- Melee Aura — **void-spoof unhittable** + KnifeFire spam (soldados clientside), gather To Me / Cluster Far
- Fire Blink — encola disparos y libera en burst

**Visuals**
- ESP — players / NPCs / capture points / crates (Drawing)

**Tycoon**
- Auto Buy — teleport a botones, filtro Cash Only (salta R$/rebirth)
- Crate Farm — colecta Crates/GunCrates (cash + armas)

**Misc**
- Client Desync — desync propio anti-ragebot

## Arquitectura

Módulos `return function(U)` sobre el contexto `U = {Library, Services, Tabs, Registry, Flags}`.
Motor de desync compartido en `services/SpoofService.lua` (`__index` hook, port de LifeInPrisonPrimordial).

## Build

```bash
bash build/bundle.sh   # embebe PrimordialUI dist + concatena modulos -> dist/MilitaryBase.lua
```
