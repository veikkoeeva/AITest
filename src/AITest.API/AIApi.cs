using AITest.API.DTOs;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.SemanticKernel.ChatCompletion;

namespace AITest.API
{
    public static class AIApi
    {
        public static Results<Ok<string>, NotFound> GetById(string id)
        {            
            return TypedResults.Ok("Hello, World!");
        }


        public static async Task<IResult> HandleChatMessageAsync(
            ChatMessage chatMessage,
            [FromServices] IChatCompletionService chatCompletionService,
            [FromServices] ChatHistory history, CancellationToken cancellationToken)
        {
            history.AddUserMessage(chatMessage.Message);
            var response = await chatCompletionService.GetChatMessageContentAsync(chatMessage.Message, cancellationToken: cancellationToken);
            history.AddMessage(response.Role, response.Content ?? string.Empty);

            return TypedResults.Ok(response.Content ?? string.Empty);
        }
    }
}
