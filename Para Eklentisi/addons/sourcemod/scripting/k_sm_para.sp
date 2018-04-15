#pragma semicolon 1
#include <sourcemod>

new g_iAccount = -1;

public Plugin:myinfo =
{
	name = "!Para Eklentisi",
	author = "UniTy . TERMINATOR ☪",
	description = "HER ROUND PARA VERİR",
	version = "1.0.0",
	url = "http://www.kemalincekara.tk"
};

public OnPluginStart()
{
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		PrintToServer("[SM] Para eklentisi baslatilamadi.");
		return;
	}
	HookEvent("round_end", Event_RoundEnd);
	RegConsoleCmd("sm_para", Event_ParaVer);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMaxClients = GetMaxClients();
	for (new i = 1; i <= iMaxClients; i++)
		GiveMoney(i);
	PrintToChatAll( "\x01[\x04SM\x01] \x03Paranız bittiyse !para yazınız." );
}

public Action Event_ParaVer(int client, int args)
{
	GiveMoney(client);
	ReplyToCommand(client, "");
	return Plugin_Continue;
}

public GiveMoney(client)
{
	if (!IsClientValid(client))
		return;
	SetEntData(client, g_iAccount, 16000);
	PrintToChat(client,"\x01[\x04SM\x01] \x03Para verildi : 16000$!");
}

/**
* Checks if client is valid, ingame and safe to use.
*
* @param client			Client index.
* @param alive			Check if the client is alive.
* @return				True if the user is valid.
*/
stock bool IsClientValid(int client, bool alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && (alive == false || IsPlayerAlive(client)));
}