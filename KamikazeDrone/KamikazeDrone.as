array<CDrone> g_Drone;
CDroneParam g_DroneParam;

class CDrone
{
	CSprite@ pSprite = null;
	string strSaveModel = "";

	string strAuthId = "";
	float fSaveTime = 0.0f;

	int iGetFrame = 0;
	CBasePlayer@ pPlayer = null;
	
	Vector vecSaveOrigin = Vector();
	Vector vecSaveAngles = Vector();
	
	bool bDroneTime = false;
	float fDroneTime = 0.0f;
	
	bool bCanDrone = false;
	bool bThrowGrenade = false;
	
	/*Количество гранат для сброса. По умолчанию 5 - 
	параметр iMaxGrenades класса CDroneParam.*/
	
	int iGrenades = 0;
	int iGrenadeType = 0;
	uint iModelNum = 2;
	string strLang = "En";
}

class CDroneParam
{
	/*Количество фреймов (в спрее 4 кадра) не должно изменяться,
	так как текущий фрейм зависит от указанного времени полёта
	дрона. Вы можете изменить это число, если Ваш спрайт будет содержать
	более 4 кадров*/
	
	bool bIsEnabled = true;
	bool bAdminsOnly = false;
	
	int iMaxFrames = 4;
	int iMaxGrenades = 5;
	int iExplodeAmplitude = 500;
	float fDroningTime = 30.0f;
	float fGrenadeTime = 3.0f;
	
	array<string> strModels = {
		"default",
		"kamikazedrone_t",
		"kamikazedrone_ct",
	};
}

void MapInit() 
{
	g_Game.PrecacheModel("sprites/kamikazedrone_gui/DroneGUIRu.spr");
	g_Game.PrecacheModel("sprites/kamikazedrone_gui/DroneGUIEn.spr");
	g_Game.PrecacheModel("sprites/kamikazedrone_gui/Point.spr");
	
	g_Game.PrecacheModel("models/player/kamikazedrone_t/kamikazedrone_t.mdl");
	g_Game.PrecacheModel("models/player/kamikazedrone_ct/kamikazedrone_ct.mdl");
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("kek");
	g_Module.ScriptInfo.SetContactInfo("https://github.com/kekekekkek/KamikazeDrone");
	
	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, @PlayerPreThink);
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
}

void ShowHUD(CBasePlayer@ pPlayer, bool bShow)
{
	NetworkMessage NetMsg(MSG_ONE, NetworkMessages::NetworkMessageType((bShow ? 78 : 91)), pPlayer.edict());	
	NetMsg.WriteByte(1 << 2);
	NetMsg.End();
}

void HideHUD(CBasePlayer@ pPlayer)
{
	NetworkMessage NetMsg(MSG_ONE, NetworkMessages::NetworkMessageType(91), pPlayer.edict());	
	NetMsg.WriteByte((1) | (1 << 3));
	NetMsg.End();
}

void ChangeModel(CBasePlayer@ pPlayer, string strModelName)
{
	NetworkMessage NetMsg(MSG_ONE, NetworkMessages::NetworkMessageType(9), pPlayer.edict());	
	NetMsg.WriteString("model " + strModelName);
	NetMsg.End();
}

void ChangeModel2(CBasePlayer@ pPlayer, string strModelName) 
{
	pPlayer.SetOverriddenPlayerModel(strModelName);
}

bool IsPlayerAdmin(CBasePlayer@ pPlayer)
{
	return (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES);
}

bool IsNaN(string strValue)
{
	int iPointCount = 0;

	for (uint i = 0; i < strValue.Length(); i++)
	{
		if (i == 0 && strValue[i] == '-')
			continue;
			
		if (strValue[i] == '.')
		{
			iPointCount++;
		
			if (iPointCount < 2)
				continue;
		}
	
		if (!isdigit(strValue[i]))
			return true;
	}
	
	return false;
}

void StartDrone(CDrone@ pDrone, CDroneParam@ pDroneParam)
{
	if (pDrone.bCanDrone)
	{
		bool bExplode = false;
		pDrone.pPlayer.pev.gravity = 0.001f;
		
		/*Так как амплитуда взрыва слишком большая, делаем
		локального игрока временно бессмертным*/
		
		pDrone.pPlayer.pev.flags = FL_GODMODE;
		ChangeModel2(pDrone.pPlayer, pDroneParam.strModels[pDrone.iModelNum]);
	
		Vector vVecAngles = pDrone.pPlayer.pev.v_angle;
		Vector vVecEyePos = pDrone.pPlayer.EyePosition();
	
		pDrone.pPlayer.BlockWeapons(pDrone.pPlayer);
		
		if (!pDrone.bDroneTime)
		{
			pDrone.fDroneTime = g_Engine.time;
			pDrone.bDroneTime = true;
		}
		
		if (pDrone.bDroneTime)
		{
			int iCurSecond = atoi(g_Engine.time - pDrone.fDroneTime);
			float fCurFrame = Math.Floor(pDroneParam.iMaxFrames / pDroneParam.fDroningTime * iCurSecond);
			
			pDrone.iGetFrame = atoi(fCurFrame);
			
			/*При достижении последнего кадра, делаем тот же самый
			сброс, только без взрыва*/
			
			if (fCurFrame >= pDroneParam.iMaxFrames)
			{
				ShowHUD(pDrone.pPlayer, true);
				ChangeModel2(pDrone.pPlayer, pDrone.strSaveModel);
				
				pDrone.pPlayer.pev.effects = 0;
				pDrone.pPlayer.pev.gravity = 1.0f;				
				pDrone.pPlayer.pev.flags = FL_CLIENT;
				pDrone.pPlayer.pev.origin = pDrone.vecSaveOrigin;
				
				pDrone.pPlayer.pev.angles = pDrone.vecSaveAngles;
				pDrone.pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
				
				pDrone.pPlayer.pev.velocity = (pDrone.pPlayer.pev.velocity * 0.0f);	
				pDrone.pPlayer.UnblockWeapons(pDrone.pPlayer);	
				
				pDrone.bCanDrone = false;
				pDrone.bDroneTime = false;
				pDrone.pSprite.TurnOff();
			}
		}
	
		for (float y = 0.0f; y < 1275.0f; y += 25.0f)
		{
			Vector vVecDirection, vVecIntermediate;
			g_EngineFuncs.AngleVectors(vVecAngles.opAdd(Vector(0.0f, y, 0.0f)), vVecDirection, vVecIntermediate, vVecIntermediate);

			TraceResult trResult;
			g_Utility.TraceLine(vVecEyePos, (vVecEyePos + (vVecDirection * Math.INT32_MAX)), dont_ignore_monsters, pDrone.pPlayer.edict(), trResult);
			
			/*Взрываем дрона в том случае, если расcтояние между игроком и одним из лучей < 35.0f
			или если игрока убили в момент запуска дрона, или если его скорость слишком мала, чтобы привести
			дрона к взрыву*/
			
			if (pDrone.pPlayer.pev.velocity.Length() > 250.0f)
			{
				if (vVecEyePos.opSub(trResult.vecEndPos).Length() < 35.0f
					|| !pDrone.pPlayer.IsAlive())
						bExplode = true;
			}
			
			//Лучше убрать
			for (float z = -1.0f; z <= 1.0f; z += 2.0f)
			{
				float fDistance = 0.0f;
				g_Utility.TraceLine(pDrone.pPlayer.pev.origin, (Vector(pDrone.pPlayer.pev.origin.x, pDrone.pPlayer.pev.origin.y, Math.INT32_MAX * z) * Math.INT32_MAX), dont_ignore_monsters, pDrone.pPlayer.edict(), trResult);
				
				if (z == 1.0f)
					fDistance = 5.0f;
				else
					fDistance = 75.0f;

				if (z == -1.0f || pDrone.pPlayer.pev.velocity.Length() > 250.0f)
				{
					if (vVecEyePos.opSub(trResult.vecEndPos).Length() < fDistance 
						|| !pDrone.pPlayer.IsAlive())
							bExplode = true;
				}
			}
			
			if ((pDrone.pPlayer.pev.button & IN_ATTACK) != 0)
			{
				ShowHUD(pDrone.pPlayer, true);
				ChangeModel2(pDrone.pPlayer, pDrone.strSaveModel);
				g_PlayerFuncs.HudToggleElement(pDrone.pPlayer, 0, false);
				
				pDrone.bCanDrone = false;
				pDrone.bDroneTime = false;
				pDrone.pSprite.TurnOff();
				
				g_EntityFuncs.CreateExplosion(pDrone.pPlayer.pev.origin, Vector(), pDrone.pPlayer.edict(), pDroneParam.iExplodeAmplitude, true);
				
				pDrone.pPlayer.pev.effects = 0;
				pDrone.pPlayer.pev.gravity = 1.0f;		
				pDrone.pPlayer.pev.flags = FL_CLIENT;
				pDrone.pPlayer.pev.origin = pDrone.vecSaveOrigin;
				
				pDrone.pPlayer.pev.angles = pDrone.vecSaveAngles;
				pDrone.pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
				
				pDrone.pPlayer.pev.velocity = (pDrone.pPlayer.pev.velocity * 0.0f);	
				pDrone.pPlayer.UnblockWeapons(pDrone.pPlayer);
				
				return;
			}
			
			if ((pDrone.pPlayer.pev.button & IN_ATTACK2) != 0)
			{
				if (pDrone.iGrenades > 0)
				{
					if (!pDrone.bThrowGrenade)
					{
						pDrone.fSaveTime = g_Engine.time;
						pDrone.bThrowGrenade = true;
						
						pDrone.iGrenades--;
					}
				}
			}
			
			if (pDrone.bThrowGrenade)
			{
				if ((pDrone.fSaveTime + 0.1f) < g_Engine.time)
				{
					(pDrone.iGrenadeType == 0 
						? g_EntityFuncs.ShootTimed(pDrone.pPlayer.pev, pDrone.pPlayer.pev.origin, Vector(), pDroneParam.fGrenadeTime)
						: g_EntityFuncs.ShootContact(pDrone.pPlayer.pev, pDrone.pPlayer.pev.origin, Vector()));
					
					pDrone.bThrowGrenade = false;
					
					string strMsg = ("Grenades: " + pDrone.iGrenades);
					g_PlayerFuncs.ShowMessage(pDrone.pPlayer, strMsg);
				}
			}
			
			if (y == 0.0f)
			{
				//Думаю, можно было сделать лучше, но я не так силён в математике
			
				if ((pDrone.pPlayer.pev.button & IN_JUMP) != 0)
					pDrone.pPlayer.pev.velocity.z += 5.0f;
				
				if ((pDrone.pPlayer.pev.button & IN_USE) != 0)
					pDrone.pPlayer.pev.velocity.z += (pDrone.pPlayer.pev.angles.x / 1.2f);
					
				if ((pDrone.pPlayer.pev.button & IN_JUMP) == 0
					&& (pDrone.pPlayer.pev.button & IN_USE) == 0)
						pDrone.pPlayer.pev.velocity.z = (pDrone.pPlayer.pev.velocity.z * 0.0f);
				
				if ((pDrone.pPlayer.pev.button & IN_FORWARD) != 0)
				{
					pDrone.pPlayer.pev.velocity.x += (vVecDirection.x / 0.5f);
					pDrone.pPlayer.pev.velocity.y += (vVecDirection.y / 0.5f);
				}
			}
			
			if (bExplode)
			{
				ShowHUD(pDrone.pPlayer, true);
				ChangeModel2(pDrone.pPlayer, pDrone.strSaveModel);
				g_PlayerFuncs.HudToggleElement(pDrone.pPlayer, 0, false);
				
				pDrone.bCanDrone = false;
				pDrone.bDroneTime = false;
				pDrone.pSprite.TurnOff();
				
				g_EntityFuncs.CreateExplosion(trResult.vecEndPos, Vector(), pDrone.pPlayer.edict(), pDroneParam.iExplodeAmplitude, true);
				
				pDrone.pPlayer.pev.effects = 0;
				pDrone.pPlayer.pev.gravity = 1.0f;		
				pDrone.pPlayer.pev.flags = FL_CLIENT;
				pDrone.pPlayer.pev.origin = pDrone.vecSaveOrigin;
				
				pDrone.pPlayer.pev.angles = pDrone.vecSaveAngles;
				pDrone.pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
				
				pDrone.pPlayer.pev.velocity = (pDrone.pPlayer.pev.velocity * 0.0f);		
				pDrone.pPlayer.UnblockWeapons(pDrone.pPlayer);
				
				return;
			}
		}
	}
}

void DrawDrone(CDrone@ pDrone, string strFileName)
{
	HUDSpriteParams pHudSpriteParams;
	pHudSpriteParams.spritename = strFileName;
	pHudSpriteParams.flags = (HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X); 
	pHudSpriteParams.x = 0;
	pHudSpriteParams.y = 0;
	pHudSpriteParams.frame = pDrone.iGetFrame;
	pHudSpriteParams.holdTime = 0.1;
	pHudSpriteParams.color1 = RGBA(255, 255, 255, 125);
	
	g_PlayerFuncs.HudCustomSprite(pDrone.pPlayer, pHudSpriteParams);
}

int GetPlayerNum(CBasePlayer@ pPlayer, array<CDrone> pDrone)
{
	int iPlayerNum = -1;

	for (uint i = 0; i < pDrone.length(); i++)
	{
		if (pDrone[i].strAuthId == g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()))
		{
			iPlayerNum = i;
			break;
		}
	}
	
	return iPlayerNum;
}

HookReturnCode ClientSay(SayParameters@ pSayParam)
{
	array<string> strCommands = 
	{
		".kamikazedrone", "/kamikazedrone", "!kamikazedrone",
		".kd_model", "/kd_model", "!kd_model",
		".kd_explampl", "/kd_explampl", "!kd_explampl",
		".kd_drtime", "/kd_drtime", "!kd_drtime",
		".kd_grtime", "/kd_grtime", "!kd_grtime",
		".kd_maxgr", "/kd_maxgr", "!kd_maxgr",
		".kd_grtype", "/kd_grtype", "!kd_grtype",
		".kd_lang", "/kd_lang", "!kd_lang",
		".kd_ao", "/kd_ao", "!kd_ao",
	};
	
	array<string> strDescriptions =
	{
		"[KDInfo]: Usage: .kamikazedrone//kamikazedrone/!kamikazedrone <enabled>. Example: !kamikazedrone 1\n",
		"[KDInfo]: Usage: .kd_model//kd_model/!kd_model <modelnum>. Example: !kd_model 2\n",
		"[KDInfo]: Usage: .kd_explampl//kd_explampl/!kd_explampl <amplitude>. Example: !kd_explampl 500\n",
		"[KDInfo]: Usage: .kd_drtime//kd_drtime/!kd_drtime <time>. Example: !kd_drtime 27.5\n",
		"[KDInfo]: Usage: .kd_grtime//kd_grtime/!kd_grtime <time>. Example: !kd_grtime 3.0\n",
		"[KDInfo]: Usage: .kd_maxgr//kd_maxgr/!kd_maxgr <maxgrenades>. Example: !kd_maxgr 5\n",
		"[KDInfo]: Usage: .kd_grtype//kd_grtype/!kd_grtype <grenadetype>. Example: !kd_grtype 0\n",
		"[KDInfo]: Usage: .kd_lang//kd_lang/!kd_lang <lang>. Example: !kd_lang ru or !kd_lang en\n",
		"[KDInfo]: Usage: .kd_ao//kd_ao/!kd_ao <adminsonly>. Example: !kd_ao 0\n",
	};
	
	bool bError = false;
	string strValue = "";
	
	int iPlayerNum = GetPlayerNum(pSayParam.GetPlayer(), g_Drone);
	
	if (iPlayerNum == -1)
	{
		CDrone l_Drone;
		
		@l_Drone.pPlayer = pSayParam.GetPlayer();
		l_Drone.strAuthId = g_EngineFuncs.GetPlayerAuthId(pSayParam.GetPlayer().edict());
		
		g_Drone.insertAt(g_Drone.length(), l_Drone);
		iPlayerNum = (g_Drone.length() - 1);
		
		@g_Drone[iPlayerNum].pSprite = g_EntityFuncs.CreateSprite("sprites/kamikazedrone_gui/Point.spr", Vector(), false);
		g_Drone[iPlayerNum].pSprite.SetTransparency(kRenderTransAdd, 0, 0, 0, 255, kRenderFxNone);
		g_Drone[iPlayerNum].pSprite.SetScale(0.07f);
		g_Drone[iPlayerNum].pSprite.TurnOff();
	}
	else
	{
		if (!g_Drone[iPlayerNum].bCanDrone)
		{
			@g_Drone[iPlayerNum].pSprite = g_EntityFuncs.CreateSprite("sprites/kamikazedrone_gui/Point.spr", Vector(), false);
			g_Drone[iPlayerNum].pSprite.SetTransparency(kRenderTransAdd, 0, 0, 0, 255, kRenderFxNone);
			g_Drone[iPlayerNum].pSprite.SetScale(0.07f);
			@g_Drone[iPlayerNum].pPlayer = pSayParam.GetPlayer();
		}
	}

	if (pSayParam.GetArguments().ArgC() == 1)
	{
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".drone"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/drone"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!drone")
		{
			if (g_DroneParam.bIsEnabled)
			{
				if ((pSayParam.GetPlayer().pev.flags & FL_ONGROUND) != 0)
				{
					if (g_Drone[iPlayerNum].pPlayer.IsAlive())
					{
						if (!g_Drone[iPlayerNum].bCanDrone && (IsPlayerAdmin(pSayParam.GetPlayer()) || !g_DroneParam.bAdminsOnly))
						{
							g_Drone[iPlayerNum].bCanDrone = true;
							g_Drone[iPlayerNum].iGrenades = g_DroneParam.iMaxGrenades;
							g_Drone[iPlayerNum].vecSaveOrigin = pSayParam.GetPlayer().GetOrigin();
							g_Drone[iPlayerNum].vecSaveAngles = pSayParam.GetPlayer().pev.angles;
							g_Drone[iPlayerNum].pPlayer.SetOrigin(Vector(g_Drone[iPlayerNum].vecSaveOrigin.x, g_Drone[iPlayerNum].vecSaveOrigin.y, g_Drone[iPlayerNum].vecSaveOrigin.z + 30.0f));
							
							g_Drone[iPlayerNum].pSprite.SetOrigin(g_Drone[iPlayerNum].vecSaveOrigin);
							g_Drone[iPlayerNum].pSprite.TurnOn();
							
							g_Drone[iPlayerNum].strSaveModel = g_EngineFuncs.GetInfoKeyBuffer(pSayParam.GetPlayer().edict()).GetValue("model");
							g_PlayerFuncs.ConcussionEffect(g_Drone[iPlayerNum].pPlayer, 25.0f, 1.0f, g_DroneParam.fDroningTime);
						}
						else
							g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The drone feature is now available only to admins.\n");
					}
				}
				else
				{
					if (!g_Drone[iPlayerNum].bCanDrone)
						g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: You can only launch a drone on the ground.\n");
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The kamikaze drone feature is disabled at the moment.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_reset"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_reset"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_reset")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				g_DroneParam.bIsEnabled = true;
				g_DroneParam.bAdminsOnly = false;
				g_DroneParam.iMaxGrenades = 5;
				g_DroneParam.iExplodeAmplitude = 500;
				g_DroneParam.fDroningTime = 30.0f;
				g_DroneParam.fGrenadeTime = 3.0f;
			
				g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDInfo]: All settings of the kamikaze drone have been reset to the default values.\n");
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
				
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		for (uint i = 0; i < strCommands.length(); i++)
		{
			if (pSayParam.GetArguments().Arg(0).ToLowercase() == strCommands[i])
			{
				uint uLine = atoi(Math.Floor((strDescriptions.length() * 1.0f / strCommands.length() * 1.0f) * (i == 0 ? 1 : i) - (0.02f * i)));
				
				if (!IsPlayerAdmin(pSayParam.GetPlayer()) 
					&& (uLine == 1 || uLine == 2 || uLine == 3 || uLine == 4 || uLine == 6))
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
				else
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), strDescriptions[uLine]);
				
				pSayParam.ShouldHide = true;
				return HOOK_HANDLED;
			}
		}
	}
	
	if (pSayParam.GetArguments().ArgC() == 2)
	{
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kamikazedrone"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kamikazedrone"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kamikazedrone")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					g_DroneParam.bIsEnabled = (Math.clamp(0, 1, atoi(strValue)) == 0 ? false : true);
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), (!g_DroneParam.bIsEnabled
						? "[KDSuccess]: The kamikaze drone feature is disabled!\n" 
						: "[KDSuccess]: The kamikaze drone feature is enabled!\n"));
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
	
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_model"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_model"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_model")
		{
			strValue = pSayParam.GetArguments().Arg(1);
			
			if (IsNaN(strValue))
			{
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
				bError = true;
			}
			
			if (!bError)
			{
				if (!g_Drone[iPlayerNum].bCanDrone)
				{
					g_Drone[iPlayerNum].iModelNum = Math.clamp(1, 2, atoi(strValue));
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDSuccess]: The \"" + g_DroneParam.strModels[g_Drone[iPlayerNum].iModelNum] + "\" model has been successfully selected!\n");
				}
				else
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The drone model cannot be changed during droning!\n");
			}
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_explampl"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_explampl"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_explampl")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					g_DroneParam.iExplodeAmplitude = Math.clamp(1, 5000, atoi(strValue));
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDSuccess]: The value of the explosion amplitude has been successfully changed to \"" + g_DroneParam.iExplodeAmplitude + "\"!\n");
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_drtime"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_drtime"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_drtime")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					g_DroneParam.fDroningTime = Math.clamp(15.0f, 120.0f, atof(strValue));
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDSuccess]: The value of the droning time has been successfully changed to \"" + g_DroneParam.fDroningTime + "\"!\n");
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_grtime"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_grtime"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_grtime")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					g_DroneParam.fGrenadeTime = Math.clamp(0.5f, 5.0f, atof(strValue));
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDSuccess]: The value of the grenade explosion time has been successfully changed to \"" + g_DroneParam.fGrenadeTime + "\"!\n");
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_maxgr"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_maxgr"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_maxgr")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					g_DroneParam.iMaxGrenades = Math.clamp(1, 15, atoi(strValue));
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDSuccess]: The value of the maximum number of grenades has been successfully changed to \"" + g_DroneParam.iMaxGrenades + "\"!\n");
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_grtype"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_grtype"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_grtype")
		{
			strValue = pSayParam.GetArguments().Arg(1);
			
			if (IsNaN(strValue))
			{
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
				bError = true;
			}
			
			if (!bError)
			{
				if (!g_Drone[iPlayerNum].bCanDrone)
				{
					g_Drone[iPlayerNum].iGrenadeType = Math.clamp(0, 1, atoi(strValue));
					g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), "[KDSuccess]: The value of the grenade type has been successfully changed to \"" + g_Drone[iPlayerNum].iGrenadeType + "\"!\n");
				}
				else
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The type of grenade cannot be changed during droning!\n");
			}
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_lang"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_lang"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_lang")
		{
			if (!g_Drone[iPlayerNum].bCanDrone)
			{
				strValue = pSayParam.GetArguments().Arg(1).ToLowercase();
				
				if (!IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The language of the interface to be selected must be text!\n");
					bError = true;
				}
				
				if (!bError)
				{
					if (strValue != "ru"
						&& strValue != "en")
					{
						g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The specified interface language was not found!\n");
						bError = true;
					}
				}
				
				if (!bError)
				{
					if (strValue.Length() > 2)
						g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The name of the interface language must consist of two characters!\n");
					else
					{
						strValue = strValue.Replace("r", "R");
						strValue = strValue.Replace("e", "E");
					
						g_Drone[iPlayerNum].strLang = strValue;	
						g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDSuccess]: The interface language has been successfully changed!\n");
					}
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: Interface language cannot be changed during droning!\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
		
		if (pSayParam.GetArguments().Arg(0).ToLowercase() == ".kd_ao"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "/kd_ao"
			|| pSayParam.GetArguments().Arg(0).ToLowercase() == "!kd_ao")
		{
			if (IsPlayerAdmin(pSayParam.GetPlayer()))
			{
				strValue = pSayParam.GetArguments().Arg(1);
				
				if (IsNaN(strValue))
				{
					g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: The argument is not a number!\n");
					bError = true;
				}
				
				if (!bError)
				{
					(atoi(strValue) >= 1 ? g_DroneParam.bAdminsOnly = true : g_DroneParam.bAdminsOnly = false);				
						g_PlayerFuncs.SayTextAll(pSayParam.GetPlayer(), (g_DroneParam.bAdminsOnly == true
							? "[KDInfo]: The drone feature is now available only to admins.\n" 
							: "[KDInfo]: The drone feature is now available to everyone!\n"));
				}
			}
			else
				g_PlayerFuncs.SayText(pSayParam.GetPlayer(), "[KDError]: This command is for admins only.\n");
			
			pSayParam.ShouldHide = true;
			return HOOK_HANDLED;
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint& out)
{
	for (uint i = 0; i < g_Drone.length(); i++)
	{
		if (g_Drone[i].bCanDrone)
		{
			HideHUD(g_Drone[i].pPlayer);
			DrawDrone(g_Drone[i], "kamikazedrone_gui/DroneGUI" + g_Drone[i].strLang + ".spr");
			StartDrone(g_Drone[i], g_DroneParam);
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
{
	if (GetPlayerNum(pPlayer, g_Drone) != -1)
	{
		g_Drone[GetPlayerNum(pPlayer, g_Drone)].pSprite.TurnOff();
		g_Drone.removeAt(GetPlayerNum(pPlayer, g_Drone));
	}

	return HOOK_CONTINUE;
}