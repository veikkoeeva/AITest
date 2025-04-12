using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;


namespace AITest.API
{
    public static class AIApi
    {
        public static Results<Ok<string>, NotFound> GetById(string id)
        {
            return TypedResults.Ok("Hello, World!");
        }


        public static async Task<IResult> HandleChatMessageAzureAsync(
            DTOs.ChatMessage chatMessage,
            [FromServices] IChatClient chatClient,
            [FromServices] List<ChatMessage> history, CancellationToken cancellationToken)
        {
            var cm = new ChatMessage(ChatRole.User, chatMessage.Message);
            history.Add(cm);

            ChatResponse response = await chatClient.GetResponseAsync(cm, cancellationToken: cancellationToken);

            //history.Add(new ChatMessage(ChatRole.Assistant, response.Messages));

            return TypedResults.Ok("Some text" ?? string.Empty);
        }


        public static async Task<IResult> HandleChatMessageLocalAsync(
            DTOs.ChatMessage chatMessage,            
            [FromServices] List<ChatMessage> history, CancellationToken cancellationToken)
        {
            var cm = new ChatMessage(ChatRole.User, chatMessage.Message);
            history.Add(cm);
                       

            return await Task.FromResult(TypedResults.Ok("some text" ?? string.Empty));
        }
    }
}
