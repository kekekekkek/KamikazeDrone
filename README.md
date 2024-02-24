# KamikazeDrone
You have probably seen the videos from FPV drones. They are very popular not only among people, but also among the military. This plugin is an attempt to create exactly the same drone from these videos.<br><br>
You can watch this short [video](https://www.youtube.com/watch?v=tBbA9CWrM7o) to understand how this plugin works.

# Installation
Installing the plugin consists of several steps:
1. [Download](https://github.com/kekekekkek/KamikazeDrone/archive/refs/heads/main.zip) this plugin;
2. Go to the directory `..\Sven Co-op\svencoop\scripts\plugins` and put the folder `KamikazeDrone` there;
3. Then move the `models` and `sprites` folders from the `..\Sven Co-op\sven coop\scripts\plugins\KamikazeDrone` to the `..\Sven Co-op\svencoop` folder;
5. Next, go to the `..\Sven Co-op\svencoop` folder and find there the text file `default_plugins.txt`;
6. Open this file and paste the following text into it:
```
    	"plugin"
    	{
        	"name" "KamikazeDrone"
        	"script" "KamikazeDrone/KamikazeDrone"
    	}
```
5. After completing the previous steps, you can run the game and check the result.

# Commands
When you start the game and connect to your server, you will have the following plugin commands at your disposal, which you will have to write in the game chat to activate them.
| Command | MinValue | MaxValue | DefValue | Description | Usage | 
| ------- | -------- | -------- | -------- | ----------- | ----- |
| `.kamikazedrone`, `/kamikazedrone` or `!kamikazedrone` | `0` | `1` | `1` | Allows you to enable or disable this feature. | Usage: `.kamikazedrone//kamikazedrone/!kamikazedrone <enabled>`. Example: `!kamikazedrone 1` |
| `.drone`, `/drone` or `!drone` | `-` | `-` | `-` | Allows you to launch a drone. | `No arguments.` |
| `.kd_reset`, `/kd_reset` or `!kd_reset` | `-` | `-` | `-` | Allows you to reset the settings to the default settings. | `No arguments.` |
| `.kd_model`, `/kd_model` or `!kd_model` | `1` | `2` | `2` | Allows you to change the drone model. | Usage: `.kd_model//kd_model/!kd_model <modelnum>.` Example: `!kd_model 2` |
| `.kd_explampl`, `/kd_explampl` or `!kd_explampl` | `1` | `5000` | `500` | Allows you to specify the amplitude of the drone's explosion. | Usage: `.kd_explampl//kd_explampl/!kd_explampl <amplitude>.` Example: `!kd_explampl 500` |
| `.kd_drtime`, `/kd_drtime` or `!kd_drtime` | `15.0` | `120.0` | `30.0` | Allows you to specify the flight time of the drone. | Usage: `.kd_drtime//kd_drtime/!kd_drtime <time>.` Example: `!kd_drtime 27.5` |
| `.kd_grtime`, `/kd_grtime` or `!kd_grtime` | `0.5` | `5.0` | `3.0` | Allows you to specify the time of the grenade explosion. | Usage: `.kd_grtime//kd_grtime/!kd_grtime <time>.` Example: `!kd_grtime 3.0` |
| `.kd_maxgr`, `/kd_maxgr` or `!kd_maxgr` | `1` | `15` | `5` | Allows you to specify the maximum number of grenades. | Usage: `.kd_maxgr//kd_maxgr/!kd_maxgr <maxgrenades>.` Example: `!kd_maxgr 5` |
| `.kd_lang`, `/kd_lang` or `!kd_lang` | `-` | `-` | `En` | Allows you to specify the language of the drone's interface. | Usage: `.kd_lang//kd_lang/!kd_lang <lang>.` Example: `!kd_lang ru` or `!kd_lang en` |
| `.kd_ao`, `/kd_ao` or `!kd_ao` | `0` | `1` | `0` | Allows you to enable this feature only for admins or for all players.<br>`0 - For everyone;`<br>`1 - Admins only.` | Usage: `.kd_ao//kd_ao/!kd_ao <adminsonly>.` Example: `!kd_ao 0` |

**REMEMBER**: This plugin is not the final version, as it has a lot of bugs. In the future, it will be completed.<br>
**REMEMBER**: The drone model has size issues.<br>
**REMEMBER**: The plugin has a folder `Templates` in which all the images that were used to create the interface for the drone are located. You can edit them and compile the sprite using the `SpriteExplorer` program. And you will need `Photoshop` to edit the image and make several frames out of it.<br>
**REMEMBER**: Also, the original drone models that were used are shown in the links below.<br>

# Drone Control
`LMB` (Left Mouse Button) / `IN_ATTACK` - Forced drone explosion;<br>
`RMB` (Right Mouse Button) / `IN_ATTACK2` - Throw grenade;<br>
`Space` / `IN_JUMP` - Move up;<br>
`W (ASD)` / `IN_FORWARD` - Move forward;<br>
`E` / `IN_USE` - Go down.

# Additionally
1. SpriteExplorer - https://gamebanana.com/tools/4775;
2. Military drones models - https://gamebanana.com/mods/39913.

# Screenshots
* Screenshot 1<br><br>
![Screenshot_1](https://github.com/kekekekkek/KamikazeDrone/blob/main/KamikazeDrone/Images/Screenshot_1.png)
* Screenshot 2<br><br>
![Screenshot_2](https://github.com/kekekekkek/KamikazeDrone/blob/main/KamikazeDrone/Images/Screenshot_2.png)
* Screenshot 3<br><br>
![Screenshot_3](https://github.com/kekekekkek/KamikazeDrone/blob/main/KamikazeDrone/Images/Screenshot_3.png)
