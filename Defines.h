#pragma mark Preferences Keys

	#define BGPrefFirstRunKey @"BGFirstRun"
	#define BGPrefLastScrobbled @"LastScrobbled"
	#define BGPrefShouldPlaySound @"PlaySound"
	#define BGPrefWantMultiPost @"WantMultiPost"
	#define BGPrefWantStatusItem @"WantStatusItem"
	#define BGPrefShouldIgnoreComments @"IgnoreCommented"
	#define BGPrefIgnoreCommentString @"IgnoreCommentsComment"
	#define BGPrefShouldIgnoreGenre @"IgnoreGenre"
	#define BGPrefIgnoreGenreString @"IgnoreGenreString"
	#define BGPrefShouldIgnorePodcasts @"IgnorePodcasts"
	#define BGPrefShouldIgnoreVideo @"IgnoreVideo"
	#define BGPrefShouldIgnoreShort @"IgnoreShort"
	#define BGPrefIgnoreShortLength @"IgnoreShortLength"
	#define BGPrefShouldDoMultiPlay @"DoMultiPlay"
	#define BGPrefShouldUseAlbumArtist @"UseAlbumArtist"
	#define BGPrefShouldUseComposerInsteadOfArtist @"UseComposer"
	#define BGPrefShouldUseGroupingInTitle @"UseGroupingInTitle"
	#define INSTALLATIONID @"AnonymousInstallNumber"
	
	#define BGPrefWantOldIcon @"WantOldIcon"

	#define BGPrefUsePodFreshnessInterval @"UseiPodFreshnessInterval"
	#define BGPrefPodFreshnessInterval @"iPodFreshnessInterval"
	
	#define BGPref_Growl_SongChange @"GrowlSongChange"
	#define BGPref_Growl_ScrobbleFail @"GrowlScrobbleFail"
	#define BGPref_Growl_ScrobbleDecisionChanged @"GrowlScrobbleDecisionChanged"

	#define BGNotificationPodMounted @"iPodWatcher_PodMounted"
	
	#define BGScrobbleDecisionChangedNotification @"BGScrobbleDecisionChangedNotification"
	#define BGXmlLocationChangedNotification @"BGXmlLocationChangedNotification"

	#define BGOperationType_Song 0
	#define BGOperationType_Artist 1
	#define BGOperationType_Album 2

	#define BGPrefWantNowPlaying @"PostNowPlaying"
	#define BGPrefXmlLocation @"XMLLocation"
	
	#define XMLChangedNotification @"XMLChangedNotification"
	
	#define BGPrefUsername @"Username"

#pragma mark Growl Keys
	#define SP_Growl_StartedScrobbling @"Started Scrobbling"
	#define SP_Growl_FinishedScrobbling @"Finished Scrobbling"
	#define SP_Growl_FailedScrobbling @"Scrobbling Failed"
	#define SP_Growl_TrackChanged @"Track Changed"
	#define SP_Growl_DecisionChanged @"Automatic Scrobbling Decision Changed"
	#define SP_Growl_LoginComplete @"Authorization Complete"

#pragma mark Localise
	#define DATE_FORMAT_STRING @"%Y-%m-%d %H-%M-%S"

#pragma mark Persistent Strings
	#define BGLastSyncDate @"iPodLastSynchronized"
	#define BGActivityHistoryArray "ActivityHistory"
	#define BGTracksScrobbledTotal @"TracksScrobbled"

	#define ServiceWorker_LoveCommand @"track.love"
	#define ServiceWorker_BanCommand  @"track.ban"

#pragma mark Leavin for Later (Commented)
//#define applescriptCalFormat @"%A, %e %B %Y %I:%M:%S %p"
//NSTimeDateFormatString
//#define BGPrefPassKey @"lastFMPassword"