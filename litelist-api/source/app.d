import handy_httpd;
import slf4d;
import slf4d.default_provider;

void main() {
	auto provider = new shared DefaultProvider(true, Levels.INFO);
	// provider.getLoggerFactory().setModuleLevelPrefix("handy_httpd", Levels.WARN);
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
	import std.file;
	import std.conv;

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

	auto mainHandler = new PathDelegatingHandler();
	mainHandler.addMapping(Method.GET, API_PATH ~ "/status", &handleStatus);

	auto optionsHandler = toHandler((ref HttpRequestContext ctx) {
		ctx.response.setStatus(HttpStatus.OK);
	});

	mainHandler.addMapping(Method.POST, API_PATH ~ "/register", &createNewUser);
	mainHandler.addMapping(Method.POST, API_PATH ~ "/login", &handleLogin);
	mainHandler.addMapping(Method.GET, API_PATH ~ "/me", &getMyUser);
	mainHandler.addMapping(Method.DELETE, API_PATH ~ "/me", &deleteMyUser);
	mainHandler.addMapping(Method.GET, API_PATH ~ "/renew-token", &renewToken);

	mainHandler.addMapping(Method.GET, API_PATH ~ "/lists", &getNoteLists);
	mainHandler.addMapping(Method.POST, API_PATH ~ "/lists", &createNoteList);
	mainHandler.addMapping(Method.GET, API_PATH ~ "/lists/{id}", &getNoteList);
	mainHandler.addMapping(Method.DELETE, API_PATH ~ "/lists/{id}", &deleteNoteList);
	mainHandler.addMapping(Method.POST, API_PATH ~ "/lists/{listId}/notes", &createNote);
	mainHandler.addMapping(Method.DELETE, API_PATH ~ "/lists/{listId}/notes/{noteId}", &deleteNote);

	mainHandler.addMapping(Method.OPTIONS, API_PATH ~ "/**", optionsHandler);

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
