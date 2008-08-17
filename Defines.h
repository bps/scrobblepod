#pragma mark Preferences Keys

	#define BGPrefUserKey @"lastFMUsername"
	#define BGPrefFirstRunKey @"BGFirstRun"
	#define BGPrefLastScrobbled @"LastScrobbled"
	#define BGPrefShouldPlaySound @"PlaySound"
	#define BGPrefWantMultiPost @"WantMultiPost"
	#define BGPrefWantStatusItem @"WantStatusItem"
	#define BGPrefShouldIgnoreComments @"IgnoreComments"
	#define BGPrefIgnoreCommentString @"IgnoreCommentsComment"
	#define BGPrefShouldIgnorePodcasts @"IgnorePodcasts"
	#define BGPrefShouldIgnoreVideo @"IgnoreVideo"
	#define BGPrefShouldIgnoreShort @"IgnoreShort"
	#define BGPrefIgnoreShortLength @"IgnoreShortLength"
	#define BGPrefShouldDoMultiPlay @"DoMultiPlay"
	
	#define BGPrefWantOldIcon @"WantOldIcon"

	#define BGPrefUsePodFreshnessInterval @"UseiPodFreshnessInterval"
	#define BGPrefPodFreshnessInterval @"iPodFreshnessInterval"
	
	#define BGPref_Growl_SongChange @"GrowlSongChange"
	#define BGPref_Growl_ScrobbleFail @"GrowlScrobbleFail"
	#define BGPref_Growl_ScrobbleDecisionChanged @"GrowlScrobbleDecisionChanged"

	#define BGNotificationPodMounted @"iPodWatcher_PodMounted"
	#define BGLoginChangedNotification @"LoginChangedNotification"

	#define BGOperationType_Song 0
	#define BGOperationType_Artist 1
	#define BGOperationType_Album 2

	#define BGPrefWantNowPlaying @"PostNowPlaying"
	#define BGPrefXmlLocation @"XMLLocation"

#pragma mark Growl Keys
	#define SP_Growl_StartedScrobbling @"Started Scrobbling"
	#define SP_Growl_FinishedScrobbling @"Finished Scrobbling"
	#define SP_Growl_FailedScrobbling @"Scrobbling Failed"
	#define SP_Growl_TrackChanged @"Track Changed"
	#define SP_Growl_DecisionChanged @"Automatic Scrobbling Decision Changed"

#pragma mark Localise
	#define DATE_FORMAT_STRING @"%Y-%m-%d %H-%M-%S"

#pragma mark Persistent Strings
	#define BGLastSyncDate @"iPodLastSynchronized"
	#define BGActivityHistoryArray "ActivityHistory"
	#define BGTracksScrobbledTotal @"TracksScrobbled"

	#define ServiceWorker_LoveCommand @"loveTrack"
	#define ServiceWorker_BanCommand @"banTrack"

#pragma mark Leavin for Later (Commented)
//#define applescriptCalFormat @"%A, %e %B %Y %I:%M:%S %p"
//NSTimeDateFormatString
//#define BGPrefPassKey @"lastFMPassword"