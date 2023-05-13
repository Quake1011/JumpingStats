public Plugin myinfo =
{ 
	name = "JumpStat", 
	author = "Palonez", 
	description = "JumpStat", 
	version = "1.0", 
	url = "https://github.com/Quake1011" 
};

bool Status;
float fOrg[MAXPLAYERS+1][2][3], fMaxJump[MAXPLAYERS+1], fTopJumps[MAXPLAYERS+1], fGlobalJump;
int iIndex[MAXPLAYERS+1], iGlobalJump;

enum eState
{
	air = 0,
	ground = -1
};

enum 
{
	start = 0,
	end
};

eState State[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("player_jump", jump);
	HookEvent("player_spawn", spawn, EventHookMode_Pre);
	
	CreateTimer(1.0, Updater, _, TIMER_REPEAT);
	
	RegAdminCmd("sm_reset", reset, ADMFLAG_ROOT);
	
	RegAdminCmd("sm_jump", jjump, ADMFLAG_ROOT);
	RegAdminCmd("sm_nojump", nojump, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	rs();
}

public Action jjump(int client, int args)
{
	Status = true;
	rs();
	return Plugin_Handled;
}

public Action nojump(int client, int args)
{
	Status = false;
	return Plugin_Handled;
}

public Action reset(int client, int args)
{
	rs();
	PrintToChatAll("Рейтинг прыжков обнулен!");
	return Plugin_Handled;
}

void rs()
{
	for(int i = 0; i < sizeof(fTopJumps); i++)
	{
		fTopJumps[i] = fGlobalJump = fMaxJump[i] = 0.0;
		fOrg[i][0] = {0.0,0.0,0.0};
		fOrg[i][1] = {0.0,0.0,0.0};
		iIndex[i] = -1;
		iGlobalJump = 0;
	}
}

public Action Updater(Handle hTimer)
{
	if(!Status) return Plugin_Continue;
	char rating[5][512];
	SetHudTextParams(0.02, 0.7, 1.0, 255, 255, 255, 255, 2, 0.0 , 0.0, 0.0);
	
	for(int i = 0; i < 5; i++)
	{
		if(0 < iIndex[i] <= MaxClients && IsClientInGame(iIndex[i]) && !IsFakeClient(iIndex[i]) && fTopJumps[i] > 0.0) Format(rating[i], sizeof(rating[]), "%N - %.2f", iIndex[i], fTopJumps[i])
		else strcopy(rating[i], sizeof(rating[]), "");
	}
	
	char gj[300];
	if(fGlobalJump == 0.0 || !IsClientInGame(iGlobalJump)) strcopy(gj, sizeof(gj), "");
	else Format(gj, sizeof(gj), "%N - %.2f\n\n", iGlobalJump, fGlobalJump)
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			ShowHudText(i, -1, "%s%s\n%s\n%s\n%s\n%s\n%s", gj, rating[0][0] ? "-=Лучшие прыжки=-":"", rating[0], rating[1], rating[2], rating[3], rating[4]);
	return Plugin_Continue;
}

public void spawn(Event hEvent, const char[] sEvent, bool bdb)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(State[client] == air)
		{
			State[client] = ground;
			fOrg[client][start] = {0.0, 0.0, 0.0};
			fOrg[client][end] = {0.0, 0.0, 0.0};
		}
	}
}

public void jump(Event hEvent, const char[] sEvent, bool bdb)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		GetClientAbsOrigin(client, fOrg[client][start]);
		State[client] = air;
	}
	
	iGlobalJump = client;
}

public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(0 < i <= MaxClients && IsClientInGame(i) && !IsFakeClient(i))
		{
			if(State[i] == air)
			{
				if(GetEntPropEnt(i, Prop_Send, "m_hGroundEntity") == 0)
				{
					State[i] = ground;
					GetClientAbsOrigin(i, fOrg[i][end]);
					
					if(fOrg[i][start][0] != 0.0 && fOrg[i][start][0] != 0.0 && fOrg[i][start][0] != 0.0) fGlobalJump = GetVectorDistance(fOrg[i][start], fOrg[i][end]);
					else fGlobalJump = 0.0;
					iGlobalJump = i;
					
					if(GetVectorDistance(fOrg[i][start], fOrg[i][end]) > fMaxJump[i]) 
					{
						if(fOrg[i][start][0] != 0.0 && fOrg[i][start][0] != 0.0 && fOrg[i][start][0] != 0.0) fMaxJump[i] = GetVectorDistance(fOrg[i][start], fOrg[i][end]);
						else fMaxJump[i] = 0.0;
					}
					
					for(int t = 0; t <= MaxClients; t++) 
					{	
						fTopJumps[t] = fMaxJump[t];
						iIndex[t] = t;
					}
					
					for(int n = 0; n < MaxClients; n++)
					{
						for(int x = 0; x < MaxClients-1; x++)
						{
							if(fTopJumps[x] < fTopJumps[x+1])
							{
								float s = fTopJumps[x];
								fTopJumps[x] = fTopJumps[x+1];
								fTopJumps[x+1] = s;
								
								int c = iIndex[x];
								iIndex[x] = iIndex[x+1];
								iIndex[x+1] = c;
							}
						}
					}
				}
			}
		}
	}
}