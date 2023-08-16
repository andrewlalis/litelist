import handy_httpd;
import slf4d;
import slf4d.default_provider;

void main() {
	auto provider = new shared DefaultProvider(true, Levels.INFO);
	configureLoggingProvider(provider);

	HttpServer server = initServer();
	server.start();
}

private HttpServer initServer() {
	import handy_httpd.handlers.path_delegating_handler;
	import handy_httpd.handlers.filtered_handler;
	import auth;

	ServerConfig config = ServerConfig.defaultValues();
	config.enableWebSockets = false;
	config.workerPoolSize = 3;
	config.port = 8080;
	config.connectionQueueSize = 10;
	config.defaultHeaders["Access-Control-Allow-Origin"] = "*";


	auto mainHandler = new PathDelegatingHandler();
	mainHandler.addMapping(Method.GET, "/status", (ref HttpRequestContext ctx) {
		ctx.response.writeBodyString("online");
	});
	mainHandler.addMapping(Method.POST, "/login", &handleLogin);

	// Authenticated endpoints are protected by the TokenFilter.
	auto authEndpoints = new PathDelegatingHandler();
	auto authHandler = new FilteredRequestHandler(
		authEndpoints,
		[new TokenFilter]
	);

	return new HttpServer(mainHandler, config);
}
