local Utils = require"Utils"

return {
	Key = Utils.ReadSecret"Steam/Key";
	UserID = Utils.ReadSecret"Steam/UserID";
}
