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
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		GiveMoney(client);
	ReplyToCommand(client, "");
	return Plugin_Continue;
}

public GiveMoney(client)
{
	if (!IsClientInGame(client))
		return;
	SetEntData(client, g_iAccount, 16000);
	PrintToChat(client,"\x01[\x04SM\x01] \x03Para verildi : 16000$!");
}
