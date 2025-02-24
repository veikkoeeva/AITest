using AITest.API.Server.HealthCheck;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.OpenApi.Models;
using System.Reflection;

namespace AITest.API
{

    public static class Program
    {
        /// <summary>
        /// The name of the assembly. This is hardcoded like to avoid reflection at runtime
        /// to query it.
        /// </summary>
        private static string AssemblyName { get; } = "AITest.API";

        private static Dictionary<string, string> EmptyDictionary => [];

        private static ChatMessage SystemPrompt { get; } = new ChatMessage(ChatRole.System, """          
            You are a friendly AI Explorer who helps to discover fun AI and data intensive systems facts.
            You introduce yourself when first saying hello.
            When helping people out, you always ask them for this information to inform the facts you provide:

            1. The purpose
            2. The environment                    

            You will then provide the information. You will also share what you think about potential bias in society and potential harms to natur.
            At the end of your response, ask if there is anything else you can help with.            
        """);
        

        public static WebApplication InternalMain(WebApplication app)
        {
            if(app.Environment.IsDevelopment())
            {
                app.UseWebAssemblyDebugging();
                app.UseDeveloperExceptionPage();
            }
            else
            {
                //app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                //app.UseHsts();
            }

            app.UseHttpsRedirection();

            app.MapOpenApi();

            var aiApi = app.MapGroup("/ai");
            aiApi.MapGet("", AIApi.GetById)
                .WithSummary("Get a personalized greeting")
                .WithDescription("This endpoint returns a personalized greeting based on the provided name.")
                .WithTags("Greetings");
                                    
            app.MapPost("/azurechat", AIApi.HandleChatMessageAzureAsync)
                .WithSummary("Get a personalized AI generated information from Azure.")
                .WithDescription("This endpoint returns a personalized AI generated information from Azure (not from a local model).")
                .WithTags(["Personalized", "AI", "Azure"]);

            app.MapPost("/localchat", AIApi.HandleChatMessageLocalAsync)
                .WithSummary("Get a personalized AI generated information from a local model.")
                .WithDescription("This endpoint returns a personalized AI generated information from a local model.")
                .WithTags(["Personalized", "AI", "local", "onnx"]);

            app.MapGet("/openapi", IResult () =>
            {
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "openapi.html");
                if(File.Exists(filePath))
                {
                    var fileContents = File.ReadAllText(filePath);
                    return TypedResults.Content(fileContents, contentType: "text/html");
                }
                return TypedResults.NotFound("No file found with the supplied file name");
            }).ExcludeFromDescription()/*.WithName("GetFileByName").RequireAuthorization("AuthenticatedUsers")*/;

            app.MapGet($"{AssemblyName}.json", IResult () =>
            {
                var n = Assembly.GetExecutingAssembly().GetName().Name;
                Console.Write(n);
                var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", $"{AssemblyName}.json");
                if(File.Exists(filePath))
                {
                    var fileContents = File.ReadAllText(filePath);
                    return TypedResults.Content(fileContents, contentType: "text/json");
                }
                return TypedResults.NotFound("No file found with the supplied file name");
            }).ExcludeFromDescription()/*.WithName("GetFileByName").RequireAuthorization("AuthenticatedUsers")*/;

            /*
            app.Use(async (context, next) =>
            {
                if(context.Request.Path == "/WeatherForecast")
                {
                    await context.Response.WriteAsJsonAsync<List<WeatherForecast>>(new List<WeatherForecast>(new[] { new WeatherForecast() }));
                    return;
                }

                await next(context);
            });*/

            app.UseAntiforgery();

            return app;
        }

        public static void Main(string[] args)
        {
            var builder = CreateWebHostBuilder(args, EmptyDictionary);

            var app = builder.Build();

            InternalMain(app).Run();
        }

        public static WebApplicationBuilder CreateWebHostBuilder(string[] args, Dictionary<string, string> extraSettings)
        {
            WebApplicationBuilder builder;
            bool isTest = extraSettings.ContainsKey("IsTest");
            if(isTest)
            {
                builder = WebApplication.CreateBuilder(new WebApplicationOptions
                {
                    ApplicationName = extraSettings[nameof(WebApplicationOptions.ApplicationName)],
                    ContentRootPath = extraSettings[nameof(WebApplicationOptions.ContentRootPath)],
                    WebRootPath = extraSettings[nameof(WebApplicationOptions.WebRootPath)]
                });
            }
            else
            {
                builder = WebApplication.CreateBuilder(args);
            }

            builder
                .Services
                .AddHealthChecks()
                .AddCheck("startup", check => HealthCheckResult.Healthy(), tags: ["startup"])
                .AddCheck<SampleHealthCheckWithDI>("SampleCheck");

            builder.Services.AddOpenApi(options =>
            {
                options.AddDocumentTransformer((document, context, cancellationToken) =>
                {
                    document.Info.Contact = new OpenApiContact
                    {
                        Name = "Test",
                        Email = "support@test.org"
                    };
                    return Task.CompletedTask;
                });
            });

            builder.AddAIServices();

            string environmentName = builder.Environment.EnvironmentName;

            builder.Services.AddAntiforgery();
            builder.Services.AddHttpClient();
            builder.Services.AddOptions();
            if(isTest)
            {
                int testPort = int.Parse(extraSettings["TestPort"]);
                builder.WebHost.ConfigureKestrel(options =>
                {
                    options.AddServerHeader = false;
                    options.ListenLocalhost(testPort, configure => configure.UseHttps());
                });
            }
            else
            {
                builder.WebHost.ConfigureKestrel(options =>
                {
                    options.AddServerHeader = false;
                    //options.ListenLocalhost(5092);
                });
            }

            return builder;
        }


        private static void AddAIServices(this IHostApplicationBuilder builder)
        {
            var loggerFactory = builder.Services.BuildServiceProvider().GetService<ILoggerFactory>();
            //string? ollamaEndpoint = builder.Configuration["AI:Ollama:Endpoint"];
            string? ollamaEndpoint = "http://localhost:11434";
            string? ollamaModel = builder.Configuration["AI:Ollama:ChatModel"] ?? "llama3.1:latest";
            if(!string.IsNullOrWhiteSpace(ollamaEndpoint))
            {
                builder.Services.AddChatClient(new OllamaChatClient(ollamaEndpoint, ollamaModel))
                    .UseFunctionInvocation()
                    //.UseOpenTelemetry(configure: t => t.EnableSensitiveData = true)
                    //.UseLogging(loggerFactory)
                    .Build();
            }
        }
    }
}