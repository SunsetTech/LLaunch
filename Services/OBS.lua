local websocket = require"http.websocket"
local dkjson = require"dkjson"
local lsha2 = require"lsha2"
local mime = require"mime"

local OOP = require"Moonrise.OOP"

local OBS = OOP.Declarator.Shortcuts(
	"LLaunch.Services.OBS", {
		require"Service.Program"
	}
)

function OBS:Initialize(Instance, StartStreaming, StartRecording, StartScene, WebsocketPort, WebsocketPassword)
	self.WebsocketPort = WebsocketPort or 4455
	self.WebsocketPassword = WebsocketPassword or "qwiorjqwioasjd"
		OBS.Parents.Program:Initialize(
			Instance, "obs", {
				"--minimize-to-tray";
				"--multi";
				"--scene", StartScene or "Gaming";
				"--websocket_port", self.WebsocketPort;
				"--websocket_password", self.WebsocketPassword;
				StartStreaming and "--startstreaming" or "";
				StartRecording and "--startrecording" or "";
			}
		)
end

local function hexToBytes(hex)
    local bytes = {}
    for i = 1, #hex, 2 do
        local hexByte = string.sub(hex, i, i + 1)
        local byte = tonumber(hexByte, 16)
        table.insert(bytes, string.char(byte))
    end
    return table.concat(bytes)
end

local function GenerateAuthResponse(Password, Salt, Challenge)
    local concat1 = Password .. Salt
    local hash1 = hexToBytes(lsha2.hash256(concat1))
    local base64_secret = mime.b64(hash1)
    local concat2 = base64_secret .. Challenge
    local hash2 = hexToBytes(lsha2.hash256(concat2))
	--print(hash2)
    return mime.b64(hash2)
end

function OBS:Stop()
	local OBSSocket = websocket.new_from_uri("ws://127.0.0.1:".. self.WebsocketPort)
	OBSSocket:connect()

	local ResponseString = OBSSocket:receive()
	local ResponseObject = dkjson.decode(ResponseString)
	local ResponseData = ResponseObject.d
	local AuthData = ResponseData.authentication

	local IdentifyResponse = {
		op = 1;
		d = {
			rpcVersion = ResponseData.rpcVersion;
			authentication = GenerateAuthResponse(
				self.WebsocketPassword, 
				AuthData.salt, AuthData.challenge
			);
		};
	}

	OBSSocket:send(dkjson.encode(IdentifyResponse))

	print(OBSSocket:receive())
	OBSSocket:send(
		dkjson.encode{
			op = 6;
			d = {
				requestType = "CallVendorRequest";
				requestId = "1";
				requestData = {
					vendorName = "obs-shutdown-plugin";
					requestType = "shutdown";
					requestData = {
						reason = "Bye bye bye";
						support_url = "no.com/plaints";
						force = true;
					};
				};
			};
		}
	)

	print(OBSSocket:receive())
end

return OBS
