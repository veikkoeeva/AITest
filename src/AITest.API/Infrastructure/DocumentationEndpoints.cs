using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.IO;

namespace AITest.API.Infrastructure;

/// <summary>
/// Provides endpoints to serve static OpenAPI documentation assets from wwwroot.
/// </summary>
public static class DocumentationEndpoints
{
    /// <summary>
    /// Maps OpenAPI-related documentation endpoints.
    /// </summary>
    /// <param name="app">The application's endpoint route builder.</param>
    /// <param name="assemblyName">The name of the assembly (used to locate the JSON spec).</param>
    public static void MapDocumentation(this IEndpointRouteBuilder app, string assemblyName)
    {
        var group = app.MapGroup("/openapi");

        group.MapGet("", () => ServeFromWwwroot("openapi.html", "text/html")).ExcludeFromDescription();
        group.MapGet("/spec", () => ServeFromWwwroot($"{assemblyName}.json", "application/json")).ExcludeFromDescription();
    }


    /// <summary>
    /// Serves a static file from wwwroot with the given content type.
    /// </summary>
    private static IResult ServeFromWwwroot(string fileName, string contentType)
    {
        var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", fileName);
        if(!File.Exists(filePath))
        {
            return TypedResults.NotFound($"File not found: {fileName}");
        }

        var contents = File.ReadAllText(filePath);
        return TypedResults.Content(contents, contentType);
    }
}
