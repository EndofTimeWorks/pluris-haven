package support.plurishaven.core.friends

import support.plurishaven.core.security.DataClass

data class FriendSharingPolicy(
	val friendId: String,
	val status: FriendStatus,
	val allowedScopes: Set<FriendShareScope>
) {
	val canSharePrivateContent: Boolean
		get() = allowedScopes.any { it.dataClass == DataClass.LocalPrivate }
}

enum class FriendStatus {
	Pending,
	Accepted,
	Blocked
}

enum class FriendShareScope(val dataClass: DataClass) {
	FrontStatus(DataClass.IntegrationReadable),
	SelectedProfiles(DataClass.IntegrationReadable),
	SelectedLogs(DataClass.LocalPrivate),
	SharedPolls(DataClass.LocalPrivate)
}
