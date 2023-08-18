import handy_httpd;
import slf4d;
import slf4d.default_provider;

void main() {
	auto provider = new shared DefaultProvider(true, Levels.INFO);
	provider.getLoggerFactory().setModuleLevelPrefix("handy_httpd", Levels.WARN);
	configureLoggingProvider(provider);

	HttpServer server = initServer();
	server.start();
}

private HttpServer initServer() {
	import handy_httpd.handlers.path_delegating_handler;
	import handy_httpd.handlers.filtered_handler;
	import auth;
	import lists;

	ServerConfig config = ServerConfig.defaultValues();
	config.enableWebSockets = false;
	config.workerPoolSize = 3;
	config.port = 8080;
	config.connectionQueueSize = 10;
	config.defaultHeaders["Access-Control-Allow-Origin"] = "*";
	config.defaultHeaders["Access-Control-Allow-Credentials"] = "true";
	config.defaultHeaders["Access-Control-Allow-Methods"] = "*";
	config.defaultHeaders["Vary"] = "origin";
	config.defaultHeaders["Access-Control-Allow-Headers"] = "Authorization";


	auto mainHandler = new PathDelegatingHandler();
	mainHandler.addMapping(Method.GET, "/status", (ref HttpRequestContext ctx) {
		ctx.response.writeBodyString("online");
	});

	auto optionsHandler = toHandler((ref HttpRequestContext ctx) {
		ctx.response.setStatus(HttpStatus.OK);
	});

	mainHandler.addMapping(Method.POST, "/register", &createNewUser);
	mainHandler.addMapping(Method.POST, "/login", &handleLogin);
	mainHandler.addMapping(Method.GET, "/me", &getMyUser);
	mainHandler.addMapping(Method.OPTIONS, "/**", optionsHandler);
	mainHandler.addMapping(Method.DELETE, "/me", &deleteMyUser);

	mainHandler.addMapping(Method.GET, "/lists", &getNoteLists);
	mainHandler.addMapping(Method.POST, "/lists", &createNoteList);
	mainHandler.addMapping(Method.GET, "/lists/{id}", &getNoteList);
	mainHandler.addMapping(Method.DELETE, "/lists/{id}", &deleteNoteList);
	mainHandler.addMapping(Method.POST, "/lists/{listId}/notes", &createNote);
	mainHandler.addMapping(Method.DELETE, "/lists/{listId}/notes/{noteId}", &deleteNote);

	return new HttpServer(mainHandler, config);
}
