#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <morecolors>
#include <basecomm>
#include <sourcecomms>

#define PLUGIN_VERSION "2.0" 

ConVar cvarLimit, cvarMenuTitle;
Menu g_hVoteMenu;

#define VOTE_CLIENTID	0
#define VOTE_USERID		1
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

int g_voteClient[2];
char g_voteInfo[3][MAXPLAYERS + 1];

bool basecommsExists, sourcecommsExists;

int g_votetype = 0;

public Plugin myinfo = {
	name = "[NGS] Vote Mute/Vote Silence",
	author = "<eVa>Dog / AlliedModders LLC / TheXeon",
	description = "Vote Muting and Silencing",
	version = PLUGIN_VERSION,
	url = "https://www.neogenesisnetwork.net"
}

public void OnPluginStart()
{
	CreateConVar("sm_votemute_version", PLUGIN_VERSION, "Version of votemute/votesilence", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	cvarLimit = CreateConVar("sm_votemute_limit", "0.70", "percent required for successful mute vote or mute silence.");
	cvarMenuTitle = CreateConVar("sm_votemute_menutitle", "=== NGS Vote Menu ===", "Title for sm_votemenu (has branding so configurable)");
	
	//Allowed for ALL players
	RegConsoleCmd("sm_votemute", Command_Votemute, "sm_votemute <player> ");
	RegConsoleCmd("sm_votesilence", Command_Votesilence, "sm_votesilence <player> ");
	RegConsoleCmd("sm_votegag", Command_Votegag, "sm_votegag <player> ");
	RegConsoleCmd("sm_votemenu", Command_Votemenu, "sm_votemenu");
	
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual("basecomm", name)) basecommsExists = true;
	else if (StrEqual("sourcecomms", name)) sourcecommsExists = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual("basecomm", name)) basecommsExists = false;
	else if (StrEqual("sourcecomms", name)) sourcecommsExists = false;
}

public Action Command_Votemute(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (basecommsExists && BaseComm_IsClientGagged(client) || sourcecommsExists && SourceComms_GetClientGagType(client) != bNot)
	{
		CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Sorry, you may not call a vote at this time.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 0;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, 64);
		
		int target = FindTarget(client, arg);

		if (target == -1 || CheckCommandAccess(target, "sm_admin", ADMFLAG_GENERIC) || target == client)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 0;
		DisplayVoteMuteMenu(client, target);
	}
	
	return Plugin_Handled;
}

public Action Command_Votesilence(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (basecommsExists && BaseComm_IsClientGagged(client) || sourcecommsExists && SourceComms_GetClientGagType(client) != bNot)
	{
		CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Sorry, you may not call a vote at this time.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 1;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, 64);
		
		int target = FindTarget(client, arg);

		if (target == -1 || CheckCommandAccess(target, "sm_admin", ADMFLAG_GENERIC) || target == client)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 1;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled;
}

public Action Command_Votemenu(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (basecommsExists && BaseComm_IsClientGagged(client) || sourcecommsExists && SourceComms_GetClientGagType(client) != bNot)
	{
		CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Sorry, you may not call a vote at this time.");
		return Plugin_Handled;
	}
	
	char title[MAX_BUFFER_LENGTH];
	cvarMenuTitle.GetString(title, sizeof(title));
	Menu mVoteMenu = new Menu(VoteChooserMenuHandler);
	mVoteMenu.SetTitle(title);
	mVoteMenu.AddItem("gag", "Gag: Mute text chat.");
	mVoteMenu.AddItem("mute", "Mute: Mute voice chat.");
	mVoteMenu.AddItem("silence", "Silence: Mute both.");
	mVoteMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_Votegag(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	if (basecommsExists && BaseComm_IsClientGagged(client) || sourcecommsExists && SourceComms_GetClientGagType(client) != bNot)
	{
		CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Sorry, you may not call a vote at this time.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		g_votetype = 2;
		DisplayVoteTargetMenu(client);
	}
	else
	{
		char arg[64];
		GetCmdArg(1, arg, 64);
		
		int target = FindTarget(client, arg);

		if (target == -1 || CheckCommandAccess(target, "sm_admin", ADMFLAG_GENERIC) || target == client)
		{
			return Plugin_Handled;
		}
		
		g_votetype = 2;
		DisplayVoteMuteMenu(client, target);
	}
	return Plugin_Handled;
}

void DisplayVoteMuteMenu(int client, int target)
{
	g_voteClient[VOTE_CLIENTID] = target;
	g_voteClient[VOTE_USERID] = GetClientUserId(target);

	GetClientName(target, g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]));

	if (g_votetype == 0)
	{
		LogAction(client, target, "\"%L\" initiated a mute vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Mute", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		g_hVoteMenu.SetTitle("Mute Player:");
	}
	else if (g_votetype == 1)
	{
		LogAction(client, target, "\"%L\" initiated a silence vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Silence", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		g_hVoteMenu.SetTitle("Silence Player:");
	}
	else 
	{
		LogAction(client, target, "\"%L\" initiated a gag vote against \"%L\"", client, target);
		ShowActivity(client, "%s", "Initiated Vote Gag", g_voteInfo[VOTE_NAME]);
		
		g_hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		g_hVoteMenu.SetTitle("Gag Player:");
	}
	g_hVoteMenu.AddItem(VOTE_YES, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);
}

void DisplayVoteTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Vote);
	
	char playername[128];
	char identifier[64];
	menu.SetTitle("Choose player:");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC) && client != i)
		{
			GetClientName(i, playername, sizeof(playername));
			Format(identifier, sizeof(identifier), "%i", i);
			menu.AddItem(identifier, playername);
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char info[32], name[32];
		int target;
		
		menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
		target = StringToInt(info);

		if (target == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else
		{
			DisplayVoteMuteMenu(param1, target);
		}
	}
}

public int VoteChooserMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, "gag"))
			FakeClientCommand(param1, "sm_votegag");
		else if (StrEqual(info, "silence"))
			FakeClientCommand(param1, "sm_votesilence");
		else if (StrEqual(info, "mute"))
			FakeClientCommand(param1, "sm_votemute");
	}
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		char title[64];
		menu.GetTitle(title, sizeof(title));
		
		char buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, g_voteInfo[VOTE_NAME]);

		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %t", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = GetVotePercent(votes, totalVotes);
		
		limit = cvarLimit.FloatValue;
		
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);			
			if (g_votetype == 0)
			{
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote mute successful, muted \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				if (sourcecommsExists) SourceComms_SetClientMute(g_voteClient[VOTE_CLIENTID], true, 20, true, "Vote-Muted");
				else if (basecommsExists) BaseComm_SetClientMute(g_voteClient[VOTE_CLIENTID], true);
			}
			else if (g_votetype == 1)
			{
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote silence successful, silenced \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				if (sourcecommsExists)
				{
					SourceComms_SetClientMute(g_voteClient[VOTE_CLIENTID], true, 20, true, "Vote-Silenced");
					SourceComms_SetClientGag(g_voteClient[VOTE_CLIENTID], true, 20, true, "Vote-Silenced");
				}
				else if (basecommsExists)
				{
					BaseComm_SetClientMute(g_voteClient[VOTE_CLIENTID], true);
					BaseComm_SetClientGag(g_voteClient[VOTE_CLIENTID], true);
				}
			}		
			else 
			{
				LogAction(-1, g_voteClient[VOTE_CLIENTID], "Vote gag successful, gagged \"%L\" ", g_voteClient[VOTE_CLIENTID]);
				if (sourcecommsExists) SourceComms_SetClientGag(g_voteClient[VOTE_CLIENTID], true, 20, true, "Vote-Gagged");
				else if (basecommsExists) BaseComm_SetClientGag(g_voteClient[VOTE_CLIENTID], true);
			}
		}
	}
	return 0;
}

void VoteMenuClose()
{
	delete g_hVoteMenu;
	g_hVoteMenu = null;
}

float GetVotePercent(int votes, int totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

bool TestVoteDelay(int client)
{
	int delay = CheckVoteDelay();
	
	if (delay > 0)
	{
		if (delay > 60)
			CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Vote delay: %i mins", delay % 60);
 		else
 			CReplyToCommand(client, "{GREEN}[SM]{DEFAULT} Vote delay: %i secs", delay);
 		return false;
 	}
	return true;
}