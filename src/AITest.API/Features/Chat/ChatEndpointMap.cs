using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace AITest.API.Features.Chat
{
    /// <summary>
    /// Provides extension methods to map all chat endpoints to the route builder.
    /// </summary>
    public static class ChatEndpointMap
    {
        extension(IEndpointRouteBuilder endpoints)
        {
            /// <summary>
            /// Maps the Chat group and its endpoints under the base chat route.
            /// </summary>
            /// <param name="endpoints">The application endpoint builder (app).</param>
            /// <returns>The route group builder for chaining or further customization.</returns>
            public RouteGroupBuilder MapChatGroup()
            {
                RouteGroupBuilder group = endpoints.MapGroup(ChatRoutes.Base);
                
                _ = group.MapPost(ChatRoutes.Azure, ChatApi.HandleChatMessageAzureAsync)
                     .WithSummary("Chat with Azure-hosted model.")
                     .WithDescription("Returns a personalized AI-generated response from the Azure-hosted model.");
                
                _ = group.MapPost(ChatRoutes.Local, ChatApi.HandleChatMessageLocalAsync)
                     .WithSummary("Chat with local model.")
                     .WithDescription("Returns a personalized AI-generated response from the local model (e.g., ONNX).");

                _ = group.MapGet(ChatRoutes.Responses, ChatApi.HandleStreamingChatAsync)
                    .WithSummary("A chat message response.")
                    .WithDescription("Streams a response token by token using Server-Sent Events.");                

                return group;
            }
        }
    }
}
