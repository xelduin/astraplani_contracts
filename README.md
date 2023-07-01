# Astraplani Game Contracts (Legacy)

On-chain esoteric sandbox game in which player interactions directly affect the creation of a cosmic plane. 
Casual users will find familiar styles of play, such as those found in Strategy and Roleplaying games; those who dare can ascend into increasingly abstract layers of mechanics, culminating in what is, at its core, a game mechanics sandbox.

# Architecture

Users interact with game modules by controlling entities and resources.

## Modules

Module design philosophy should respect the following:

- Modules need to be as succinct and atomic as possible
- Modules encapsule an easily understood set of concerns
- Interdependecy between modules should be avoided as much as possible
- Updates to any module should be proposed first to the Anima community

## Entities 

Entities are ingame units that players control to interact with game modules. 

Currently, the only entity is the Star, which is created by users who are in control of an Anima on Starknet. 
Stars yield resources overtime in the form of elemental essence. 

## Resources

Resources are assets that can be used to execute various spells ingame. Spells are actions performed by entities, and include upgrades, offensive and defensive effects ingame.

Currently, there is Elemental Essence as the sole resource category, which includes the 4 platonic elements: Fire, Water, Air and Earth; Elemental Essence is created by Stars, and will be used for all higher order astral spells, as well as a basal ingredient for future resource types.