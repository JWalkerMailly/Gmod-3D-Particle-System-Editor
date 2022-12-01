![Banner](images/banner.png?raw=true "Banner")

## Description
GUI tool to easily create 3D Particle Effects using the 3D Particle System Base. The tool will be found in the 'Effects' category of the spawn menu.

## How to use
If you are familiar with Source's PCFs, you'll be comfortable with this tool. If not, here is the data structure behind it. Particles are contained inside a particle system. A particle system is also considered an emitter in some engines. It is strongly recommended to type the following command in the console to see where your particle system is located in the world.
```
developer 1
```

### Controls
| Input | Description |
|--|--|
| Left click | Play particle system. Requires particles to be inside the system to do anything. |
| Right click | Move particle system where you are looking at. Will also align the system to the surface. If aimed at an entity, will parent the system to it. |
| Reload | Will parent the particle system to you. You can use the attachment slider in the tool menu to change its position on yourself. You need to reload to apply changes. |

## Particle systems
The tool opens up to an empty particle system by default. From there, you can add particles to it using the 'Add Particle' button. If you have already created particle systems with this tool, you will be able to load them up using the 'Config' section.

### Working directory
Particle systems will be saved to your 'data' folder. From there you'll be able to reuse that file in your addons. More on that later. By default, the tool will save particle systems to the following directory:
```
garrysmod/garrysmod/data/3d_particle_system_editor
```
You can save your particle files wherever you like as long as the folder already exists inside the 'data' directory.

### Particles
To add particles to your system, simply press 'Add Particle' and a new category will be appended to the end of your menu. From there you'll be able to modify all the parameters of that particle. Here is a comprehensive list of all the properties:

#### ![Render](images/render.png?raw=true "Render")  Rendering
| Property | Type | Usage |
|--|--|--|
| Model | String | Sets the model of that particle. |
| Skin | Number | Used to change the skin of the model being used for the particle. |
| Body Groups | String | Used to change the body groups of the model being used. For more information, see this link: https://wiki.facepunch.com/gmod/Entity:SetBodyGroups |
| Material | String | Override the model's material with this one. |

#### ![Transform](images/transform.png?raw=true "Transform")  Transform
| Property | Type | Usage |
|--|--|--|
| Inherit Pos | Boolean | If set to true, will ignore positioning and use the system's position instead. |
| Pos | Vector | The particle's position relative to the system (local). |
| Angles | Angle | The particle's angles. |
| Inherit System Angles | Boolean | If set to true, will inherit the angles of the system and update all transforms. If set to true while the system has a parent, will transform the particle using the parent's angles. |

#### ![Timing](images/timing.png?raw=true "Timing")  Timing
| Property | Type | Usage |
|--|--|--|
| Delay | Number | Delay before spawning the particle in the system. |
| Inherit Life Time | Boolean | If set to true, will always use the system's lifetime instead of the particle's lifetime. |
| Life Time | Number | The lifetime of the particle. |
| Looping | Boolean | If set to true, the particle's lifetime will reset once it is dead in order to 'loop'. |

#### ![Rotation](images/rotation.png?raw=true "Rotation")  Rotation
| Property | Type | Usage |
|--|--|--|
| Function | Combo | The lua function to use to animate the particle's rotation. |
| Rotation Normal | Vector | The 'up' vector to use for the rotation. |
| Constant Rotation | Boolean | If set to true, will ignore the rotation function and rotation rate to rotate at a constant speed. End rotation will be used as the rate. |
| Start Rotation | Number | The starting angle of the rotation. |
| Use End Rotation | Boolean | If set to true, will use the end rotation in order to start animating. |
| End Rotation | Number | The desired final rotation angle. |
| Rotation Rate | Number | Speed modifier for the rotation function. This can also mean the 'domain' of the function. |

#### ![Color](images/color.png?raw=true "Color")  Color
| Property | Type | Usage |
|--|--|--|
| Function | Combo | The lua function to use to animate the particle's color. |
| Start Color | Color | The initial color of the particle. |
| Use End Color | Boolean | If set to true, will begin animating the particle's color towards the end color. |
| End Color | Color | The final color of the particle. |
| Color Rate | Number | Speed modifier for the color function. This can also mean the 'domain' of the function. |

#### ![Alpha](images/alpha.png?raw=true "Alpha")  Alpha
| Property | Type | Usage |
|--|--|--|
| Function | Combo | The lua function to use to animate the particle's alpha. |
| Start Alpha | Number | The initial alpha of the particle. |
| Use End Alpha | Boolean | If set to true, will begin animating the particle's alpha towards the end alpha. |
| End Alpha | Number | The final alpha of the particle. |
| Alpha Rate | Number | Speed modifier for the alpha function. This can also mean the 'domain' of the function. |

#### ![Scale](images/size.png?raw=true "Scale")  Scale
| Property | Type | Usage |
|--|--|--|
| Function | Combo | The lua function to use to animate the particle's scale. |
| Start Scale | Number | The initial scale of the particle. |
| Use End Scale | Boolean | If set to true, will begin animating the particle's scale towards the end scale. |
| End Scale | Number | The final scale of the particle. |
| Scale Rate | Number | Speed modifier for the scale function. This can also mean the 'domain' of the function. |

#### ![Axis](images/scale.png?raw=true "Axis")  Axis Scale
| Property | Type | Usage |
|--|--|--|
| Function | Combo | The lua function to use to animate the particle's axis scale. |
| Start Axis Scale | Vector | The initial axis scale of the particle. |
| Use End Axis Scale | Boolean | If set to true, will begin animating the particle's axis scale towards the end axis scale. |
| End Axis Scale | Vector | The final axis scale of the particle. |
| Axis Scale Rate | Number | Speed modifier for the axis scale function. This can also mean the 'domain' of the function. |

### Data structures
It is important to understand the data structure behind the properties in the editor since this tool is not suited for value validation. It is easy to crash this tool if you are not careful or if your value does not respect the defined structure. Here are the rules for each:

| Type | Rules |
|--|--|
| String | No particular rule. |
| Number | Numeric only. |
| Boolean | No particular rule. |
| Vector | Vectors must respect the following representation: [# # #]. Numbers must be space separated and surrounded by square brackets.
| Angle | Angles must respect the following representation: {# # #}. Number must be space separated and surrounded by regular brackets.
| Color | Must respect the following representation: # # #. Colors use a [0 - 255] range for each value (rgb). Must be space separated. |
| Function | No particular rule. |

## Using your particles
Once you have created your particle system, you will be left with a *.json* file. This file represents the configuration of your particle system to be reused in your addons/gamemodes/etc.

### ![Shared](images/shared.png?raw=true "Shared")  Caching your particle system
The .json file acts like a PCF, to add it to the cache, you must call:
```lua
game.Add3DParticles(particleFile, path = "GAME");
```
This line should be called in an autorun script shipping with your addon. The *particleFile* parameter represents the path to your *json* file (relative path). It is strongly advised to place these files inside a *particles* folder. If you are shipping this file with an addon, you should place it here:
```
/your_addon/particles/your_system.json
```
The *path* parameter describes where to look. By default, the *GAME* path will be used. You shouldn't need to change that value, but if you need to, refer to this link: https://wiki.facepunch.com/gmod/File_Search_Paths.

### ![Server](images/server.png?raw=true "Server")  Spawning your particle system
A convenience function is included with this framework to easily spawn your particle system. To do so, use:
```lua
ParticleSystem3D(particleName, position, angles, lifetime, parent = NULL, attach = 0);
```
You can ignore the *parent* and *attach* parameters if you are not planning on parenting your system. The *particleName* parameter denotes the name of your system (filename without .json extension). The *lifetime* parameter is important, it should be longer than any of the particles found inside your system taking into account the delay.

## Putting it all together
If you've placed your system inside a *particles* folder and have not touched the *path* parameter, your code should look like the following.

Caching your particle system:
```lua
game.Add3DParticles("particles/your_system.json");
```

Spawning your particle system:
```lua
ParticleSystem3D("your_system", Vector(0, 0, 0), Angle(0, 0, 0), 2.5);
```

This would spawn the particle system at the map's origin for 2.5 seconds.

## Disclaimer
There is **no auto-saving** for this tool, you need to save your work frequently. The editor's lifetime is also dependent on your tool's lifetime, so **if you die while creating a particle system, you risk losing your work** if you have not saved. If this were to happen, do not spawn the tool as it will reset your editor, simply navigate to the panel and 'Print' the configuration to your console. This tool **may not be compatible with servers**, it was mainly designed for singleplayer use. The particle systems created with this tool **are compatible with servers**.