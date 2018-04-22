#include <sourcemod>
#include <sdktools>

#define SOUND_FILE	"para/para.mp3"

new g_iAccount = -1;

public Plugin:myinfo =
{
	name = "!Para Eklentisi",
	author = "ℂ⋆İSTİKLAL|TERMINATOR",
	description = "HER ROUND PARA VERİR",
	version = "1.0.0",
	url = "http://www.kemalincekara.tk"
};

public OnPluginStart()
{
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		SetFailState("[SM] Para eklentisi baslatilamadi.");
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
	PrintToChatAll("\x01[\x04SM\x01] \x03Paranız bittiyse \x04!para \x03yazın.");
}

public Action Event_ParaVer(int client, int args)
{
	GiveMoney(client);
	PlaySound(client, SOUND_FILE);
	PrintToChat(client,"\x01[\x04SM\x01] \x03Nakit \x0416000$ \x03verildi!");
	ReplyToCommand(client, "");
	return Plugin_Continue;
}

public GiveMoney(client)
{
	if (!IsClientValid(client))
		return;
	SetEntData(client, g_iAccount, 16000);
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

public OnMapStart()
{
	decl String:ParaSound[100];
	FormatEx(ParaSound, sizeof(ParaSound) - 1, "sound/%s", SOUND_FILE);
	if(FileExists(ParaSound))
	{
		AddFileToDownloadsTable(ParaSound);
		PrecacheSound(SOUND_FILE, true);
	}
}

public void PlaySound(int client, const char[] sesDosyasi)
{
	if (!IsClientValid(client) )
        EmitSoundToAll(sesDosyasi, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	else
		EmitSoundToClient(client, sesDosyasi, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
}