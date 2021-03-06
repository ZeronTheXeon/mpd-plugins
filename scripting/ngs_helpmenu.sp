#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION "1.1.0"

bool showRulesMenu[MAXPLAYERS + 1];

Menu helpMenu;
Menu serverRulesMenu;
Menu serverCommandsMainMenu;
Menu serverCommandsSubMenu;

public Plugin myinfo = {
	name = "[NGS] Help Menu",
	author = "TheXeon",
	description = "A help menu for NGS.",
	version = PLUGIN_VERSION,
	url = "https://neogenesisnetwork.net"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_helpmenu", CommandHelpMenu, "Usage: sm_helpmenu");
	RegConsoleCmd("sm_vip", CommandVIP, "Usage: sm_vip");
	RegConsoleCmd("sm_commands", CommandCmdList, "Usage: sm_commands");
	LoadTranslations("common.phrases");
	
	HookEvent("post_inventory_application", OnPlayerFirstSpawn);
	
	helpMenu = new Menu(HelpMenuHandler);
	helpMenu.SetTitle("=== NGS Help Menu ===");
	helpMenu.AddItem("serverrules", "Server rules!");
	helpMenu.AddItem("servercommands", "Server commands!");
	helpMenu.AddItem("extrasettings", "Change some extra settings!");
	
	serverRulesMenu = new Menu(ServerRulesMenuHandler);
	serverRulesMenu.SetTitle("=== NGS Server Rules ===");
	serverRulesMenu.ExitBackButton = true;
	
	serverCommandsMainMenu = new Menu(ServerCommandsMenuHandler);
	serverCommandsMainMenu.SetTitle("=== NGS Server Commands ===");
	serverCommandsMainMenu.AddItem("players", "Player Commands!");
	serverCommandsMainMenu.AddItem("donors", "Donor Commands!");
	serverCommandsMainMenu.ExitBackButton = true;
	
	serverCommandsSubMenu = new Menu(ServerCommandsSubMenuHandler);
}

public void OnAllPluginsLoaded()
{
	RuleMenuBuilder();
}

public void OnClientConnected(int client)
{
	showRulesMenu[client] = true;
}

public Action CommandHelpMenu(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	helpMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action CommandVIP(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	FillCommands(false);
	serverCommandsSubMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action CommandCmdList(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	FillCommands(true);
	serverCommandsSubMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int HelpMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "serverrules", false))
			serverRulesMenu.Display(param1, MENU_TIME_FOREVER);
		else if (StrEqual(info, "servercommands", false))
			serverCommandsMainMenu.Display(param1, MENU_TIME_FOREVER);
		else if (StrEqual(info, "extrasettings", false))
			FakeClientCommand(param1, "sm_settings");
	}
}

public int ServerRulesMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		helpMenu.Display(param1, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "donorrulelink", false))
			FakeClientCommand(param1, "say /donorperks");
		else if (StrEqual(info, "playerrulelink", false))
			FakeClientCommand(param1, "say /rules");
	}
}

public int ServerCommandsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		helpMenu.Display(param1, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "players", false))
		{
			FillCommands(true);
			serverCommandsSubMenu.Display(param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "donors", false))
		{
			FillCommands(false);
			serverCommandsSubMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
}

public int ServerCommandsSubMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		serverCommandsMainMenu.Display(param1, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		serverCommandsSubMenu.Display(param1, MENU_TIME_FOREVER);
	}
}

public void FillCommands(bool regularPlayers)
{
	serverCommandsSubMenu.RemoveAllItems();
	char command[MAX_BUFFER_LENGTH], description[MAX_BUFFER_LENGTH], buffer[MAX_BUFFER_LENGTH];
	int flags;
	Handle hIterator = GetCommandIterator();
	if (regularPlayers)
	{
		serverCommandsSubMenu.SetTitle("=== NGS Player Commands ===");
		while (ReadCommandIterator(hIterator, command, sizeof(command), flags, description, sizeof(description)))
		{
			if (flags == 0)
			{
				Format(buffer, sizeof(buffer), "%s - %s", command, description);
				serverCommandsSubMenu.AddItem(command, buffer);
			}
		}
	}
	else
	{
		serverCommandsSubMenu.SetTitle("=== NGS Donor Commands ===");
		while (ReadCommandIterator(hIterator, command, sizeof(command), flags, description, sizeof(description)))
		{
			if (flags & ADMFLAG_RESERVATION)
			{
				Format(buffer, sizeof(buffer), "%s - %s", command, description);
				serverCommandsSubMenu.AddItem(command, buffer);
			}
		}
	}
	CloseHandle(hIterator);
	serverCommandsSubMenu.ExitBackButton = true;
}

public void OnPlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (showRulesMenu[client])
	{
		serverRulesMenu.Display(client, MENU_TIME_FOREVER);
		showRulesMenu[client] = false;
	}
}
public void RuleMenuBuilder()
{
	serverRulesMenu.AddItem("rule1", "No hacks or glitches!");
	serverRulesMenu.AddItem("rule2", "No scamming/running from agreed gambles!");
	serverRulesMenu.AddItem("rule3", "Don\'t spam chat/binds/earrape mic spam!");
	serverRulesMenu.AddItem("rule4", "Make room on the mic for advertisments");
	serverRulesMenu.AddItem("rule5", "Avoid politics, religion, and race in conversation!");
	serverRulesMenu.AddItem("rule6", "Don\'t impersonate staff!");
	serverRulesMenu.AddItem("rule7", "Don\'t beg for items or ask for donations!");
	serverRulesMenu.AddItem("playerrulelink", "Select me to go to regular rules.");
	serverRulesMenu.AddItem("donorrulelink", "Select me to go to donor rules.");
}

public bool IsValidClient(int client)
{
	if(client > 4096) client = EntRefToEntIndex(client);
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsFakeClient(client)) return false;
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}
