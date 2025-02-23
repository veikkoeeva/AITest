using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;


namespace AITest.API
{
    public static class AIApi
    {
        public static Results<Ok<string>, NotFound> GetById(string id)
        {
            return TypedResults.Ok("Hello, World!");
        }


        public static async Task<IResult> HandleChatMessageAsync(
            DTOs.ChatMessage chatMessage,
            [FromServices] IChatClient chatClient,
            [FromServices] List<ChatMessage> history, CancellationToken cancellationToken)
        {
            var cm = new ChatMessage(ChatRole.User, chatMessage.Message);
            history.Add(cm);

            ChatResponse response = await chatClient.GetResponseAsync(cm, cancellationToken: cancellationToken);

            history.Add(new ChatMessage(ChatRole.Assistant, response.Message.Text));

            return TypedResults.Ok(response.Message.Text ?? string.Empty);
        }
    }
}
