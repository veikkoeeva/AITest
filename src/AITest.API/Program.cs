using AITest.API.DTOs;
using AITest.API.Server.HealthCheck;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using OllamaSharp.Models.Chat;

namespace AITest.API
{

    public static class Program
    {
        private static Dictionary<string, string> EmptyDictionary => new();


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

            var aiApi = app.MapGroup("/ai");
            aiApi.MapGet("", AIApi.GetById);

            var history = new ChatHistory();
            history.AddSystemMessage("You are a helpful assistant.");

            app.MapPost("/chat", AIApi.HandleChatMessageAsync);

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

            builder.Services.AddOllamaChatCompletion("llama3.1:latest", new Uri("http://localhost:11434"));

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
    }
}