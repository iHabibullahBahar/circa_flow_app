// API Endpoints — all routes are POST per the backend definition.
// Prefix: the base URL already includes /api/v1
// NOTE: endpoints here should NOT start with a slash if baseUrl ends with one.

// Config
const String zConfigEndpoint = 'config';
const String zDashboardEndpoint = 'dashboard';

// Auth
const String zLoginEndpoint = 'auth/login';
const String zRegisterEndpoint = 'auth/register';
const String zForgotPasswordEndpoint = 'auth/forgot-password';
const String zLogoutEndpoint = 'auth/logout';
const String zMeEndpoint = 'me';

// Modules
const String zPostsEndpoint = 'posts';
const String zPostsShowEndpoint = 'posts/show';
const String zPostsReactEndpoint = 'posts/react';
const String zPostsCommentsListEndpoint = 'posts/comments/list';
const String zPostsCommentsStoreEndpoint = 'posts/comments/store';

// Communities
const String zCommunitiesEndpoint = 'communities';
const String zCommunitiesMineEndpoint = 'communities/mine';
const String zCommunitiesLookupEndpoint = 'communities/lookup';
const String zCommunitiesShowEndpoint = 'communities/show';
const String zCommunitiesJoinEndpoint = 'communities/join';
const String zCommunitiesLeaveEndpoint = 'communities/leave';

const String zEventsEndpoint = 'events';
const String zEventsShowEndpoint = 'events/show';
const String zMyEventsEndpoint = 'events/my';
const String zEventRegisterEndpoint = 'events/register';
const String zEventCancelEndpoint = 'events/cancel';

const String zDocumentsEndpoint = 'documents';
const String zDocumentsShowEndpoint = 'documents/show';
const String zDocumentsDownloadEndpoint = 'documents/download';

// Comments & Replies
const String zCommentsUpdateEndpoint = 'comments/update';
const String zCommentsDeleteEndpoint = 'comments/delete';
const String zCommentsRepliesListEndpoint = 'comments/replies/list';
const String zCommentsRepliesStoreEndpoint = 'comments/replies/store';

// Devices (notifications)
const String zDevicesRegisterEndpoint = 'devices';
const String zDevicesDeregisterEndpoint = 'devices/deregister';

// Notifications
const String zNotificationsEndpoint = 'notifications';
const String zNotificationsUnreadCountEndpoint = 'notifications/unread-count';
const String zNotificationsReadEndpoint = 'notifications/read';
const String zNotificationsReadAllEndpoint = 'notifications/read-all';
const String zNotificationsDeleteEndpoint = 'notifications/delete';

// Messaging
const String zMessagingInboxEndpoint = 'messaging/inbox';
const String zMessagingConvShowEndpoint = 'messaging/conversations/show';
const String zMessagingDirectEndpoint = 'messaging/conversations/direct';
const String zMessagingGroupEndpoint = 'messaging/conversations/group';
const String zMessagingMembersEndpoint = 'messaging/conversations/members';
const String zMessagingMessagesEndpoint = 'messaging/messages';
const String zMessagingSendEndpoint = 'messaging/messages/send';
const String zMessagingReadEndpoint = 'messaging/messages/read';
const String zMessagingTypingEndpoint = 'messaging/typing';
const String zMessagingDmSettingEndpoint = 'messaging/dm-setting';
const String zMessagingPresenceEndpoint = 'messaging/presence';
const String zBroadcastingAuthEndpoint = 'broadcasting/auth';
