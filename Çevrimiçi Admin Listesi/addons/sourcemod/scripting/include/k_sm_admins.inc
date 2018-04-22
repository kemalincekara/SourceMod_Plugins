#if defined _k_sm_admins_included
  #endinput
#endif
#define _k_sm_admins_included

#define REQUIRE_PLUGIN
#define PLUGIN_VERSION_CORE "1.0.0.1"

native bool IsAdminValid(int client, bool serverAllow = true);
native bool IsSMAdmin(int client)
native bool IsManiAdmin(int client)

public SharedPlugin:_pl_k_sm_admins = 
{
	name = "k_sm_admins",
	file = "k_sm_admins.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public _pl_k_sm_admins_SetNTVOptional()
{
	MarkNativeAsOptional("IsAdminValid");
	MarkNativeAsOptional("IsSMAdmin");
	MarkNativeAsOptional("IsManiAdmin");
}
#endif

stock char GetName(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	return name;
}

stock char GetPassword(int client)
{
	decl String:info[50]; 
	info[0] = '\0'; 
	GetClientInfo(client, "_password", info, sizeof(info));
	return info;
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