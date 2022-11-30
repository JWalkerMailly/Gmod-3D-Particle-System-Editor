# 3D Particle System Editor

## Description
GUI tool to easily create 3D Particle Effects using the 3D Particle System Base. The tool will be found in the 'Effects' category of the spawn menu.

## How to use
If you are familiar with Source's PCFs, you'll be comfortable with this tool. If not, here is the data structure behind it. Particles are contained inside a Particle system. A Particle system is also considered an emitter in some engines.

### Particle systems
Tool opens up to an empty particle system by default. From there, you can add particles to it using the 'Add Particle' button. If you have created particle system's already with this tool, you will be able to load them up using the 'Config' section of the tool.

#### Working directory
Particle systems will be save to your 'data' folder. From there you'll be able to reuse that file in your addons. More on that later. By default, the tool will save particle systems to the following directory:
```
garrysmod/garrysmod/data/3d_particle_system_editor
```
You can save your particle files where ever you like as long as the folder already exists inside the 'data' directory.

### Particles
To add particles to your system, simply press 'Add Particle' and a new category will be appended to the end of your menu. From there you'll be able to modify all the parameters of that particle. Here is a comprehensive list of all the properties:

| Property | Type | Usage |
|--|--|--|
| 

#### Data structures
It is important to understand the data structure behind the properties in the editor since this tool is not suited for value validation. It is easy to crash this tool if you are not careful or if your value does not respect the data structure. Here are the rules for each data structure:

| Type | Rules |
|--|--|
| String | No particular rule. |
| Number | Numeric only. |
| Boolean | No particular rule. |
| Vector | Vectors must respect the following representation: [# # #]. Numbers must be space separated and surrounded by square brackets.
| Angle | Angles must respect the following representation: {# # #}. Number must be space separated and surrounded by regular brackets.
| Color | No particular rule. |
| Function | No particular rule. |