import handy_httpd;
import slf4d;
import slf4d.default_provider;

void main() {
	auto provider = new shared DefaultProvider(true, Levels.INFO);
	// provider.getLoggerFactory().setModuleLevelPrefix("handy_httpd", Levels.DEBUG);
	configureLoggingProvider(provider);

	HttpServer server = initServer();
	server.start();
}

/**
 * Initializes the HTTP server that this app will run.
 * Returns: The HTTP server to use.
 */
private HttpServer initServer() {
	import handy_httpd.handlers.path_delegating_handler;
	import handy_httpd.handlers.filtered_handler;
	import d_properties;
	import endpoints.auth;
	import endpoints.lists;
	import endpoints.admin;
	import std.file;
	import std.conv;

	import auth : TokenFilter, AdminFilter, loadTokenSecret;

	ServerConfig config = ServerConfig.defaultValues();
	config.enableWebSockets = false;
	config.workerPoolSize = 3;
	config.connectionQueueSize = 10;
	bool useCorsHeaders = true;
	if (exists("application.properties")) {
		Properties props = Properties("application.properties");
		if (props.has("port")) {
			config.port = props.get("port").to!ushort;
		}
		if (props.has("workers")) {
			config.workerPoolSize = props.get("workers").to!size_t;
		}
		if (props.has("hostname")) {
			config.hostname = props.get("hostname");
		}
		if (props.has("useCorsHeaders")) {
			useCorsHeaders = props.get("useCorsHeaders").to!bool;
		}
	}

	if (useCorsHeaders) {
		// Set some CORS headers to prevent headache.
		config.defaultHeaders["Access-Control-Allow-Origin"] = "*";
		config.defaultHeaders["Access-Control-Allow-Credentials"] = "true";
		config.defaultHeaders["Access-Control-Allow-Methods"] = "*";
		config.defaultHeaders["Vary"] = "origin";
		config.defaultHeaders["Access-Control-Allow-Headers"] = "Authorization";
	}

	immutable string API_PATH = "/api";

	PathDelegatingHandler mainHandler = new PathDelegatingHandler();
	mainHandler.addMapping(Method.GET, API_PATH ~ "/status", &handleStatus);
	mainHandler.addMapping(Method.POST, API_PATH ~ "/register", &createNewUser);
	mainHandler.addMapping(Method.POST, API_PATH ~ "/login", &handleLogin);
	// mainHandler.addMapping(Method.GET, API_PATH ~ "/shutdown", (ref HttpRequestContext ctx) {
	// 	ctx.response.writeBodyString("Shutting down!");
	// 	ctx.server.stop();
	// });

	HttpRequestHandler optionsHandler = toHandler((ref HttpRequestContext ctx) {
		ctx.response.setStatus(HttpStatus.OK);
	});
	mainHandler.addMapping(Method.OPTIONS, API_PATH ~ "/**", optionsHandler);

	// Separate handler for authenticated paths, protected by a TokenFilter.
	PathDelegatingHandler authHandler = new PathDelegatingHandler();
	authHandler.addMapping(Method.GET, API_PATH ~ "/me", &getMyUser);
	authHandler.addMapping(Method.DELETE, API_PATH ~ "/me", &deleteMyUser);
	authHandler.addMapping(Method.GET, API_PATH ~ "/renew-token", &renewToken);

	authHandler.addMapping(Method.GET, API_PATH ~ "/lists", &getNoteLists);
	authHandler.addMapping(Method.POST, API_PATH ~ "/lists", &createNoteList);
	authHandler.addMapping(Method.GET, API_PATH ~ "/lists/{id}", &getNoteList);
	authHandler.addMapping(Method.DELETE, API_PATH ~ "/lists/{id}", &deleteNoteList);
	authHandler.addMapping(Method.POST, API_PATH ~ "/lists/{listId}/notes", &createNote);
	authHandler.addMapping(Method.DELETE, API_PATH ~ "/lists/{listId}/notes/{noteId}", &deleteNote);
	HttpRequestFilter tokenFilter = new TokenFilter(loadTokenSecret());
	HttpRequestFilter adminFilter = new AdminFilter();

	// Separate handler for admin paths, protected by an AdminFilter.
	PathDelegatingHandler adminHandler = new PathDelegatingHandler();
	adminHandler.addMapping(Method.GET, API_PATH ~ "/admin/users", &getAllUsers);
	mainHandler.addMapping(API_PATH ~ "/admin/**", new FilteredRequestHandler(adminHandler, [tokenFilter, adminFilter]));

	mainHandler.addMapping(API_PATH ~ "/**", new FilteredRequestHandler(authHandler, [tokenFilter]));

	return new HttpServer(mainHandler, config);
}

void handleStatus(ref HttpRequestContext ctx) {
	import resusage;
	import std.process;
	import std.json;

	immutable int pId = thisProcessID();
	ProcessMemInfo procInfo = processMemInfo(pId);
	JSONValue data = JSONValue(string[string].init);
	data.object["virtualMemory"] = JSONValue(procInfo.usedVirtMem);
	data.object["physicalMemory"] = JSONValue(procInfo.usedRAM);
	ctx.response.writeBodyString(data.toString(), "application/json");
}
