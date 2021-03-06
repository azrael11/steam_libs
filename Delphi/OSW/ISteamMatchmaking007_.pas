unit ISteamMatchmaking007_;

interface

uses
  SteamTypes, MatchmakingCommon, FriendsCommon;

type
  ISteamMatchmaking007 = class (TObject)
    procedure _Destructor(); virtual; abstract;

    // game server favorites storage
    // saves basic details about a multiplayer game server locally

    // returns the number of favorites servers the user has stored
    function GetFavoriteGameCount(): int; virtual; abstract;

    // returns the details of the game server
    // iGame is of range [0,GetFavoriteGameCount())
    // *pnIP, *pnConnPort are filled in the with IP:port of the game server
    // *punFlags specify whether the game server was stored as an explicit favorite or in the history of connections
    // *pRTime32LastPlayedOnServer is filled in the with the Unix time the favorite was added
    function GetFavoriteGame(iGame: int; var pnAppID, pnIP: uint32; var pnConnPort, pnQueryPort: uint16; var punFlags: uint32; pRTime32LastPlayedOnServer: RTime32): bool; virtual; abstract;
    // returns the new index of the game
    function AddFavoriteGame(nAppID, nIP: uint32; nConnPort, nQueryPort: uint16; unFlags: uint32; rTime32LastPlayedOnServer: RTime32): int; virtual; abstract;
    // removes the game server from the local storage; returns true if one was removed
    function RemoveFavoriteGame(nAppID: AppId_t; nIP: uint32; nConnPort, nQueryPort: uint16; unFlags: uint32): bool; virtual; abstract;

    ///////
    // Game lobby functions

    // Get a list of relevant lobbies
    // this is an asynchronous request
    // results will be returned by LobbyMatchList_t callback & call result, with the number of lobbies found
    // this will never return lobbies that are full
    // to add more filter, the filter calls below need to be call before each and every RequestLobbyList() call
    // use the CCallResult<> object in steam_api.h to match the SteamAPICall_t call result to a function in an object, e.g.
    (*
      class CMyLobbyListManager
      {
        CCallResult<CMyLobbyListManager, LobbyMatchList_t> m_CallResultLobbyMatchList;
        void FindLobbies()
        {
          // SteamMatchmaking()->AddRequestLobbyListFilter*() functions would be called here, before RequestLobbyList()
          SteamAPICall_t hSteamAPICall = SteamMatchmaking()->RequestLobbyList();
          m_CallResultLobbyMatchList.Set( hSteamAPICall, this, &CMyLobbyListManager::OnLobbyMatchList );
        }
        void OnLobbyMatchList( LobbyMatchList_t *pLobbyMatchList, bool bIOFailure )
        {
          // lobby list has be retrieved from Steam back-end, use results
        }
      }
    *)
    //
    procedure RequestLobbyList(); virtual; abstract;

    // filters for lobbies
    // this needs to be called before RequestLobbyList() to take effect
    // these are cleared on each call to RequestLobbyList()
    procedure AddRequestLobbyListFilter(pchKeyToMatch, pchValueToMatch: pAnsiChar); virtual; abstract;
    // numerical comparison
    procedure AddRequestLobbyListNumericalFilter(pchKeyToMatch: pAnsiChar; nValueToMatch, nComparisonType: int); virtual; abstract;
    // returns results closest to the specified value. Multiple near filters can be added, with early filters taking precedence
    procedure AddRequestLobbyListNearValueFilter(pchKeyToMatch: pAnsiChar; nValueToBeCloseTo: int); virtual; abstract;
    // returns only lobbies with the specified number of slots available
    procedure AddRequestLobbyListFilterSlotsAvailable(nSlotsAvailable: int); virtual; abstract;

    // returns the CSteamID of a lobby, as retrieved by a RequestLobbyList call
    // should only be called after a LobbyMatchList_t callback is received
    // iLobby is of the range [0, LobbyMatchList_t::m_nLobbiesMatching)
    // the returned CSteamID::IsValid() will be false if iLobby is out of range
    function GetLobbyByIndex(iLobby: int): CSteamID; virtual; abstract;

    // Create a lobby on the Steam servers.
    // If private, then the lobby will not be returned by any RequestLobbyList() call; the CSteamID
    // of the lobby will need to be communicated via game channels or via InviteUserToLobby()
    // this is an asynchronous request
    // results will be returned by LobbyCreated_t callback and call result; lobby is joined & ready to use at this pointer
    // a LobbyEnter_t callback will also be received (since the local user is joining their own lobby)
    procedure CreateLobby(eLobbyType: ELobbyType); virtual; abstract;

    // Joins an existing lobby
    // this is an asynchronous request
    // results will be returned by LobbyEnter_t callback & call result, check m_EChatRoomEnterResponse to see if was successful
    // lobby metadata is available to use immediately on this call completing
    procedure JoinLobby(steamIDLobby: CSteamID); virtual; abstract;

    // Leave a lobby; this will take effect immediately on the client side
    // other users in the lobby will be notified by a LobbyChatUpdate_t callback
    procedure LeaveLobby(steamIDLobby: CSteamID); virtual; abstract;

    // Invite another user to the lobby
    // the target user will receive a LobbyInvite_t callback
    // will return true if the invite is successfully sent, whether or not the target responds
    // returns false if the local user is not connected to the Steam servers
    // if the other user clicks the join link, a GameLobbyJoinRequested_t will be posted if the user is in-game,
    // or if the game isn't running yet the game will be launched with the parameter +connect_lobby <64-bit lobby id>
    function InviteUserToLobby(steamIDLobby, steamIDInvitee: CSteamID): bool; virtual; abstract;

    // Lobby iteration, for viewing details of users in a lobby
    // only accessible if the lobby user is a member of the specified lobby
    // persona information for other lobby members (name, avatar, etc.) will be asynchronously received
    // and accessible via ISteamFriends interface

    // returns the number of users in the specified lobby
    function GetNumLobbyMembers(steamIDLobby: CSteamID): int; virtual; abstract;
    // returns the CSteamID of a user in the lobby
    // iMember is of range [0,GetNumLobbyMembers())
    function GetLobbyMemberByIndex(steamIDLobby: CSteamID; iMember: int): CSteamID; virtual; abstract;
    // Get data associated with this lobby
    // takes a simple key, and returns the string associated with it
    // "" will be returned if no value is set, or if steamIDLobby is invalid
    function GetLobbyData(SteamIDLobby: CSteamID; pchKey: pAnsiChar): pAnsiChar; virtual; abstract;
    // Sets a key/value pair in the lobby metadata
    // each user in the lobby will be broadcast this new value, and any new users joining will receive any existing data
    // this can be used to set lobby names, map, etc.
    // to reset a key, just set it to ""
    // other users in the lobby will receive notification of the lobby data change via a LobbyDataUpdate_t callback
    procedure SetLobbyData(steamIDLobby: CSteamID; pchKey, pchValue: pAnsiChar); virtual; abstract;

    // returns the number of metadata keys set on the specified lobby
    function GetLobbyDataCount(steamIDLobby: CSteamID): int; virtual; abstract;

    // returns a lobby metadata key/values pair by index, of range [0, GetLobbyDataCount())
    function GetLobbyDataByIndex(steamIDLobby: CSteamID; iLobbyData: int; pchKey: pAnsiChar;
     cchKeyBufferSize: int; pchValue: pAnsiChar; cchValueBufferSize: int): boolean; virtual; abstract;

    // removes a metadata key from the lobby
    function DeleteLobbyData(steamIDLobby: CSteamID; pchKey: pAnsiChar): boolean; virtual; abstract;

    // Gets per-user metadata for someone in this lobby
    function GetLobbyMemberData(steamIDLobby, steamIDUser: CSteamID; pchKey: pAnsiChar): pAnsiChar; virtual; abstract;
    // Sets per-user metadata (for the local user implicitly)
    procedure SetLobbyMemberData(steamIDLobby: CSteamID; pchKey, pchValue: pAnsiChar); virtual; abstract;

    // Broadcasts a chat message to the all the users in the lobby
    // users in the lobby (including the local user) will receive a LobbyChatMsg_t callback
    // returns true if the message is successfully sent
    // pvMsgBody can be binary or text data, up to 4k
    // if pvMsgBody is text, cubMsgBody should be strlen( text ) + 1, to include the null terminator
    function SendLobbyChatMsg(steamIDLobby: CSteamID; pvMsgBody: pAnsiChar; cubMsgBody: int): bool; virtual; abstract;
    // Get a chat message as specified in a LobbyChatMsg_t callback
    // iChatID is the LobbyChatMsg_t::m_iChatID value in the callback
    // *pSteamIDUser is filled in with the CSteamID of the member
    // *pvData is filled in with the message itself
    // return value is the number of bytes written into the buffer
    function GetLobbyChatEntry(steamIDLobby: CSteamID; iChatID: int; var pSteamIDUser: CSteamID; pvData: Pointer; cubData: int; var peChatEntryType: EChatEntryType): int; virtual; abstract;

    // Refreshes metadata for a lobby you're not necessarily in right now
    // you never do this for lobbies you're a member of, only if your
    // this will send down all the metadata associated with a lobby
    // this is an asynchronous call
    // returns false if the local user is not connected to the Steam servers
    // restart are returned by a LobbyDataUpdate_t callback
    function RequestLobbyData(steamIDLobby: CSteamID): bool; virtual; abstract;

    // sets the game server associated with the lobby
    // usually at this point, the users will join the specified game server
    // either the IP/Port or the steamID of the game server has to be valid, depending on how you want the clients to be able to connect
    procedure SetLobbyGameServer(steamIDLobby: CSteamID; unGameServerIP: uint32; unGameServerPort: uint16;
     steamIDGameServer: CSteamID); virtual; abstract;
    // returns the details of a game server set in a lobby - returns false if there is no game server set, or that lobby doesn't exist
    function GetLobbyGameServer(steamIDLobby: CSteamID; var punGameServerIP: uint32; var punGameServerPort: uint16;
     var psteamIDGameServer: CSteamID): boolean; virtual; abstract;

    // set the limit on the # of users who can join the lobby
    function SetLobbyMemberLimit(steamIDLobby: CSteamID; cMaxMembers: int): boolean; virtual; abstract;
    // returns the current limit on the # of users who can join the lobby; returns 0 if no limit is defined
    function GetLobbyMemberLimit(steamIDLobby: CSteamID): int; virtual; abstract;

    // updates which type of lobby it is
    // only lobbies that are k_ELobbyTypePublic or k_ELobbyTypeInvisible, and are set to joinable, will be returned by RequestLobbyList() calls
    function SetLobbyType(steamIDLobby: CSteamID; eLobbyType: ELobbyType): boolean; virtual; abstract;

    // sets whether or not a lobby is joinable - defaults to true for a new lobby
    // if set to false, no user can join, even if they are a friend or have been invited
    function SetLobbyJoinable(steamIDLobby: CSteamID; bLobbyJoinable: boolean): boolean; virtual; abstract;

    // returns the current lobby owner
    // you must be a member of the lobby to access this
    // there always one lobby owner - if the current owner leaves, another user will become the owner
    // it is possible (bur rare) to join a lobby just as the owner is leaving, thus entering a lobby with self as the owner
    function GetLobbyOwner(steamIDLobby: CSteamID): CSteamID; virtual; abstract;

    // changes who the lobby owner is
    // you must be the lobby owner for this to succeed, and steamIDNewOwner must be in the lobby
    // after completion, the local user will no longer be the owner
    function SetLobbyOwner(steamIDLobby, steamIDNewOwner: CSteamID): boolean; virtual; abstract;
  end;

implementation

end.
