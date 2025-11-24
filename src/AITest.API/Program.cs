using AITest.API.Features.Chat;
using AITest.API.HealthCheck;
using AITest.API.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi;
using System.Collections.Generic;
using System.Threading.Tasks;

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

            app.MapOpenApi().CacheOutput();

            var aiApi = app.MapGroup("/ai");
            aiApi.MapGet("", AIApi.GetById)
                .WithSummary("Get a personalized greeting")
                .WithDescription("This endpoint returns a personalized greeting based on the provided name.")
                .WithTags("Greetings");

            app.MapChatGroup().WithTags("Chat");

            app.MapDocumentation(AssemblyName);

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

                options.AddDocumentTransformer((document, context, cancellationToken) =>
                {
                    document.Info.Title = "AI Test Server";
                    document.Info.Description = "Friendly endpoints to test AI-powered interactions";

                    document.Servers = new List<OpenApiServer>
                    {
                        new OpenApiServer
                        {
                            Url = "https://localhost:7211",
                            Description = "Local development server"
                        }
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
            var ollamaEndpoint = "http://localhost:11434";
            var ollamaModel = builder.Configuration["AI:Ollama:ChatModel"] ?? "llama3.1:latest";
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