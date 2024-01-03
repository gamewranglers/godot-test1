## 2024-01-03
### Added
- XP bar and level indicator
- On level up, attacks get faster, stronger, and larger (area-wise) while enemies spawn faster

### Changed
- Death behavior:
  - Player movement is disabled and the player sprite turns dark red
  - Enemies wander around

### Removed
- Attack button from the UI


## 2024-01-02
### Added
- Enemy knockback during player attacks
- Enemy and player hurt flashes
- Floating damage numbers and "miss" text
- Basic UI elements:
  - toggles for auto-attack and hold-to-attack
  - player healthbar with values
  - Attack button?


## 2023-12-31
### Added
- Hurtboxes for Player and Enemy
- Player and Enemy health bars, showing decreasing health points when attack is triggered and hurtboxes are entered

### Changed
- Enemies now spawn from path instead of being loaded from the beginning


## 2023-12-30
Demo video [link](https://www.youtube.com/watch?v=V1uBrWeMzxg)
### Added
- Enemy movement and Player tracking
- Town & Battle tiles, along with a grass texture rectangle
- Base Weapon class with Axe and Sword instances with weapon pickup/drop/swap
- Axe attack swing animation 🪓 based off of player pivot/anchor point
- Player attack range signal

### Removed
- The original tilemap with the little fortress and tileset collision masks 🥲


## 2023-12-22
### Added
- Player and Enemy placeholders
- Basic Player movement
- Tilemap with simple collision boundaries
