// API Endpoints — all routes are POST per the backend definition.
// Prefix: the base URL already includes /api/v1

// Config
const String zConfigEndpoint = '/config';

// Auth
const String zLoginEndpoint = '/auth/login';
const String zLogoutEndpoint = '/auth/logout';
const String zMeEndpoint = '/me'; // POST /api/v1/me

// Modules
const String zPostsEndpoint = '/posts';
const String zEventsEndpoint = '/events';
const String zDocumentsEndpoint = '/documents';

// Devices (notifications)
const String zDevicesRegisterEndpoint = '/devices';
const String zDevicesDeregisterEndpoint = '/devices/deregister';
